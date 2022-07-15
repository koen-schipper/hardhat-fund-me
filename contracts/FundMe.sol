// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

/** @title   A contract for crowd funding
 *  @author  Koen Schipper
 *  @notice  This contract is to demo a sample funding contract
 *  @dev     This implements price feeds as our libraries
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_Owner;
    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner {
        if(msg.sender != i_Owner) { revert FundMe__NotOwner(); }
        _;
    }

    // Functions
    // Constructor
    constructor(address priceFeedAddress) {
        i_Owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // Receive
    receive() external payable { fund(); }

    // Fallback
    fallback() external payable { fund(); }

    // External
    
    // Public
    /**
    *  @notice  This function funds this contract
    *  @dev     This implements price feeds as our libraries
    */
    function fund() public payable{
        require(msg.value.getConverstionRate(s_priceFeed) >= MINIMUM_USD, "Didn't send enough Ether"); 
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    /**
    *  @notice  This function lets the owner of the contract withdraw funds
    */
    function withdraw() public payable onlyOwner{
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner{
        address[] memory _funders = s_funders;
        for(uint256 funderIndex = 0; funderIndex < _funders.length; funderIndex++) {
            address funder = _funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // Internal

    // Private

    // View / Pure
    function getOwner() public view returns(address) {
        return i_Owner;
    }

    function getFunders(uint256 index) public view returns(address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }
}