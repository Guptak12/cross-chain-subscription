// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISubscriptionToken} from "./Interfaces/ISubscriptionToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
contract TokenVault is AccessControl,Ownable{
    ISubscriptionToken private immutable i_subscriptionToken;
    AggregatorV3Interface private immutable i_priceFeed;

    error TokenVault__DepositAmountZero();
    error TokenVault__WithdrawalFailed();
    error TokenVault__WithdrawAmountZero();

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    bytes32 private constant DEPOSIT_WITHDRAW_ROLE = keccak256("DEPOSIT_WITHDRAW_ROLE");

    constructor(address subscriptionToken, address priceFeed) Ownable(msg.sender) {
        i_subscriptionToken = ISubscriptionToken(subscriptionToken);
        i_priceFeed = AggregatorV3Interface(priceFeed);
    }
    function depositTokens() external payable onlyRole(DEPOSIT_WITHDRAW_ROLE) {

        if (msg.value == 0) revert TokenVault__DepositAmountZero();
        uint256 usdAmount = getPriceInUsd(msg.value);
        i_subscriptionToken.mint(msg.sender, usdAmount);
        emit Deposit(msg.sender, usdAmount);
    }
    function grantDepositWithdrawRole(address account) external onlyOwner{
        _grantRole(DEPOSIT_WITHDRAW_ROLE, account);
    }

    function withdrawTokens(uint256 amount) external onlyRole(DEPOSIT_WITHDRAW_ROLE) {
        if (amount == 0) revert TokenVault__WithdrawAmountZero();

        if (amount == type(uint256).max) {
            amount = i_subscriptionToken.balanceOf(msg.sender);
        }
        uint256 ethAmount = (amount * 1e8) / getEthUsdPrice();

        i_subscriptionToken.burn(msg.sender, amount);

        (bool success,) = msg.sender.call{value: ethAmount}("");
        if (!success) {
            revert TokenVault__WithdrawalFailed();
        }
        emit Withdrawal(msg.sender, amount);
    }
    receive() external payable {}


    function getPriceInUsd(uint256 amount) public view returns (uint256) {
        uint256 ethUsdPrice = getEthUsdPrice();
        return (amount * ethUsdPrice) / 1e8; // Assuming amount is in wei, ethUsdPrice is in 8 decimals, / 1e18*1e8
    }

    function getEthUsdPrice() public view returns (uint256) {
        (, int256 price,,,) = i_priceFeed.latestRoundData();
        return uint256(price);
    }

}