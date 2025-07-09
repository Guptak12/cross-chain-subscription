// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISubscriptionToken} from "./Interfaces/ISubscriptionToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract SubscriptionManager is Ownable, AccessControl {
    ISubscriptionToken private immutable i_subscriptionToken;
    mapping(address => mapping(string => Subscription)) private subscriptionRecord;
    mapping(string => Subscription) private subscribingCompanies;
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant COMPANY_ROLE = keccak256("COMPANY_ROLE");

    struct Subscription {
        string name;
        address subscriptionAddress;
        uint256 price;
        uint256 interval;
        uint256 startTime;
        bool isActive;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event SubscriptionPayed(string name, uint256 pricePayed, address subscriptionAddress, uint256 startTime);
    event SubscriptionUpdated(string name, address subscriptionAddress, uint256 interval, uint256 price);
    event SubscriptionCancelled(string name);

    error SubscriptionManager__DepositAmountZero();
    error SubscriptionManager__WithdrawalFailed();
    error SubscriptionManager__WithdrawAmountZero();
    error SubscriptionManager__InvalidInput();
    error SubscriptionManager__SubscriptionAlreadyExists();
    error SubscriptionManager__SubscriptionInactive();

    AggregatorV3Interface private immutable i_priceFeed;

    constructor(ISubscriptionToken subscriptionTokenAddress, address priceFeed) Ownable(msg.sender) {
        i_subscriptionToken = subscriptionTokenAddress;
        i_priceFeed = AggregatorV3Interface(priceFeed);
    }

    receive() external payable {
        // Handle incoming Ether deposits
    }

    function grantCompanyRole(address company) external onlyOwner {
        _grantRole(COMPANY_ROLE, company);
    }

    function depositTokens() external payable {
        if (msg.value == 0) revert SubscriptionManager__DepositAmountZero();
        uint256 usdAmount = getPriceInUsd(msg.value);
        i_subscriptionToken.mint(msg.sender, usdAmount);
        emit Deposit(msg.sender, usdAmount);
    }

    function withdrawTokens(uint256 amount) external {
        if (amount <= 0) revert SubscriptionManager__WithdrawAmountZero();

        if (amount == type(uint256).max) {
            amount = i_subscriptionToken.balanceOf(msg.sender);
        }
        i_subscriptionToken.burn(msg.sender, getPriceInUsd(amount));

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            revert SubscriptionManager__WithdrawalFailed();
        }
        emit Withdrawal(msg.sender, amount);
    }

    /// @param price Price in USD tokens (18 decimals). Example: $10 => 10 * 1e18

    function createSubscription(string memory name, address _address, uint256 _interval, uint256 price)
        external
        onlyRole(COMPANY_ROLE)
    {
        if (bytes(name).length == 0 || _address == address(0)) {
            revert SubscriptionManager__InvalidInput();
        }
        if (subscribingCompanies[name].subscriptionAddress != address(0)) {
            revert SubscriptionManager__SubscriptionAlreadyExists();
        }

        subscribingCompanies[name] = Subscription({
            name: name,
            subscriptionAddress: _address,
            interval: _interval,
            price: price,
            startTime: block.timestamp,
            isActive: true
        });
    }

    function enrollSubscription(string memory name) external {
        if (bytes(name).length == 0) {
            revert SubscriptionManager__InvalidInput();
        }
        Subscription storage subscription = subscribingCompanies[name];
        if (subscription.subscriptionAddress == address(0)) {
            revert SubscriptionManager__SubscriptionInactive();
        }
        i_subscriptionToken.transferFrom(msg.sender, subscription.subscriptionAddress, subscription.price);

        emit SubscriptionPayed(name, subscription.price, subscription.subscriptionAddress, subscription.startTime);

        subscriptionRecord[msg.sender][name] = Subscription({
            name: name,
            subscriptionAddress: subscription.subscriptionAddress,
            interval: subscription.interval,
            price: subscribingCompanies[name].price,
            startTime: block.timestamp,
            isActive: true
        });
    }
    // function subscribe(string memory name, uint256 interval) external{
    //     i_subscriptionToken.super.allowance()
    // }

    function paySubscription(string memory name, address user) external {
        if (bytes(name).length == 0) {
            revert SubscriptionManager__InvalidInput();
        }
        Subscription storage subscription = subscriptionRecord[user][name];
        if (!subscription.isActive) {
            revert SubscriptionManager__SubscriptionInactive();
        }

        if (block.timestamp >= subscription.startTime + subscription.interval) {
            // i_subscriptionToken.transfer(subscription.subscriptionAddress, subscription.price);
        i_subscriptionToken.transferFrom(user, subscription.subscriptionAddress, subscription.price);

            subscription.startTime = block.timestamp;
            emit SubscriptionPayed(name, subscription.price, subscription.subscriptionAddress, subscription.startTime);
        }
    }

    function cancelSubscription(string memory name) external {
        if (bytes(name).length == 0) {
            revert SubscriptionManager__InvalidInput();
        }
        Subscription storage subscription = subscriptionRecord[msg.sender][name];
        subscription.isActive = false;
        emit SubscriptionCancelled(name);
    }

    function updateCompanySubscription(string memory name, address _address, uint256 _interval, uint256 price)
        external
        onlyRole(COMPANY_ROLE)
    {
        if (bytes(name).length == 0) {
            revert SubscriptionManager__InvalidInput();
        }
        Subscription storage subscription = subscribingCompanies[name];

        subscription.subscriptionAddress = _address;
        subscription.interval = _interval;
        subscription.price = price;
        emit SubscriptionUpdated(name, _address, _interval, price);
    }

    function getPriceInUsd(uint256 amount) public view returns (uint256) {
        uint256 ethUsdPrice = getEthUsdPrice();
        return (amount * ethUsdPrice) / 1e8; // Assuming amount is in wei, ethUsdPrice is in 8 decimals, / 1e18*1e8
    }

    function getEthUsdPrice() public view returns (uint256) {
        (, int256 price,,,) = i_priceFeed.latestRoundData();
        return uint256(price);
    }

    function getComapanySubscription(string memory name) external view returns (Subscription memory) {
        return subscribingCompanies[name];
    }

    function getUserSubscription(string memory name, address user) external view returns (Subscription memory) {
        return subscriptionRecord[user][name];
    }

    function getSubscriptionTokenAddress() external view returns (address) {
        return address(i_subscriptionToken);
    }

    function getSubscriptionStatus(string memory name, address user) external view returns (bool) {
        return subscriptionRecord[user][name].isActive;
    }

    function getSubscriptionCurrentPrice(string memory name, address user) external view returns (uint256) {
        return subscriptionRecord[user][name].price;
    }

    function getSubscriptionStartTime(string memory name, address user) external view returns (uint256) {
        return subscriptionRecord[user][name].startTime;
    }

    function getSubscriptionAddress(string memory name, address user) external view returns (address) {
        return subscriptionRecord[user][name].subscriptionAddress;
    }

    function getSubscriptionInterval(string memory name, address user) external view returns (uint256) {
        return subscriptionRecord[user][name].interval;
    }
}
