// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
//Error Codes
error FundMe__NotOwner();

contract FundMe {
    //Type Declarations
    using PriceConverter for uint256;
    //State Variables
    mapping(address => uint256) public s_addressToAmountFunded;
    address[] public s_funders;
    address public s_owner;
    AggregatorV3Interface public s_priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != s_owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        s_owner = msg.sender;
    }

    /// @notice Allows a address to send funds to the contract.
    /// @dev Funds sent must be equal or higher than the minimum
    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18;
        require(
            msg.value.getConversionRate(s_priceFeed) >= minimumUSD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    /// @notice Gets the price feed version
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    ///@notice Allows the withdrawn of funds holded by this contract
    ///@dev only owner can withdrawn
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
    }

    function cheaperWithdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
    }
}