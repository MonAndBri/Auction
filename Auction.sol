// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/// @title Abstract Auction Contract
/// @notice This contract manages a basic time-limited auction with commission handling
/// @dev This is an abstract contract and should be extended for full functionality
abstract contract Auction {

    address private owner;
    uint startingBid;
    uint maximumBid;
    uint contractRemainingFunds;

    struct Biders {
        uint256 value;
        address bider;
    }

    /// @notice Emitted when a new highest bid is placed
    /// @param bider Address of the bidder
    /// @param amount Amount of the bid
    event NewOffer(address indexed bider, uint256 amount);

    /// @notice Emitted when the auction ends and funds are withdrawn
    event AuctionEnded();

    /// @notice Emitted after all non-winning bids have been refunded
    event AllFundsRefunded();

    Biders winner;
    Biders[] biders;
    mapping(address => uint256) public maxOfferPerBidder;

    uint256 startTime;
    uint256 stopTime;

    uint totalCommission;

    /// @notice Initializes the auction with a 7-day window and a 1 ether starting bid
    constructor(){
        owner = msg.sender;
        startTime = block.timestamp;
        stopTime = startTime + 7 days;
        startingBid = 1 ether;
        maximumBid = startingBid;
        totalCommission = 0;
        contractRemainingFunds = 0;
    }

    /// @notice Restricts function access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Verify that the auction is still active
    modifier isActive() {
        require(block.timestamp<stopTime,"Auction ended");
        _;
    }

    /// @notice Ensures the auction is still active
    modifier isNotActive() {
        require(block.timestamp>stopTime,"Auction has not ended yet");
        _;
    }

    /// @notice Requires the bid to be at least 5% higher than the current highest
    modifier isHighEnough() {
        require(msg.value > (maximumBid*105/100), "Bid not high enough");
        _;
    }

    /// @notice Ensures that there are funds remaining for withdrawal
    modifier enoughFundsToWithdraw() {
        require(contractRemainingFunds > 0, "No remaining funds to withdraw");
        _;
    }

    /// @notice Allows users to place a bid if it's at least 5% higher than the previous highest
    /// @dev Automatically extends auction by 10 minutes if bid is placed near the end
    function bid() external payable isActive isHighEnough{
        //Actualizar el valor del maximo y el nuevo oferente ganador
        maximumBid = msg.value;
        winner.value = msg.value;
        winner.bider = msg.sender;

        // Emit event announcing the new winning offer
        emit NewOffer(msg.sender, msg.value);
        
        // Update the current bidder with their new winning offer
        biders.push(Biders(msg.value, msg.sender));
        maxOfferPerBidder[msg.sender] = msg.value;

        // Check if the offer was made in the last 10 minutes
        if (block.timestamp >= stopTime - 10 minutes) {
            stopTime += 10 minutes;}  // Extend the auction by 10 more minutes
              
    }

    /// @notice Returns the winning bidder and the amount they bid
    /// @return Biders struct with the winning bid information
    function showWiner() view external returns(Biders memory) {
        return winner;
    }

    /// @notice Returns the list of all offers placed during the auction
    /// @return Array of Biders with value and address
    function showOffers() view external returns (Biders[] memory) {
        return biders;
    }

    /// @notice Refunds all bids except for the winning one, and calculates commission
    /// @dev Retains 2% commission from each non-winning bid
    function refund() onlyOwner isNotActive external {
        // Find offers with value greater than zero
        for (uint i = 0; i < biders.length; i++) {
            // Only refund participants with funds to withdraw,
            // excluding the winner (highest bid)
            if(biders[i].value >0 && biders[i].value < maximumBid){
                payable(biders[i].bider).transfer(biders[i].value*98/100); // Retain 2%  
                // Accumulate commissions
                totalCommission += biders[i].value*2/100;
            }
        }

        // Emit event notifying that non-winning offers have been refunded
        emit AllFundsRefunded();

        // Calculate the remaining funds in the contract
        contractRemainingFunds = totalCommission + maximumBid - startingBid;
        // Withdraw the remaining funds from the contract
                
    }

    /// @notice Gets the maximum bid made by a specific address
    /// @param user Address of the bidder
    /// @return Maximum bid amount made by the user
    function getMaxOffer(address user) public view returns (uint) {
        return maxOfferPerBidder[user];
    }

    /// @notice Allows a user to withdraw all their offers that were below their highest bid
    function partialRefund() external isActive {
        // Maximum offer for this sender
        uint256 maxOffer = getMaxOffer(msg.sender); 
        // Accumulate refundable offers from this sender
        uint256 totalRefund = 0;

        // Find offers less than the sender's maximum 
        // and accumulate them to perform a single refund
        for (uint i = 0; i < biders.length; i++) {
            if(biders[i].value < maxOffer && biders[i].bider == msg.sender) {
                totalRefund += biders[i].value;
                biders[i].value = 0;
            }
        }
        // Process the refund if sender has funds to withdraw
        require(totalRefund > 0, "You do not have any funds to withdraw");
        payable(msg.sender).transfer(totalRefund);
    }

    /// @notice Withdraws the remaining funds after auction ends (commission + winner bid)
    /// @dev Only callable by owner after the auction has ended and funds are available
    function withdraw() external onlyOwner isNotActive enoughFundsToWithdraw { 
        payable(owner).transfer((contractRemainingFunds));
        // Emit event notifying that the auction has ended
        emit AuctionEnded();
    }

    /// @notice Fallback receive function to reject direct ETH transfers
    /// @dev Prevents users from accidentally sending ETH without bidding
    /// @custom:reverts Reverts with message "Use the bid() function"
    receive() external payable {
        revert("Use the bid() function");
    }
}
