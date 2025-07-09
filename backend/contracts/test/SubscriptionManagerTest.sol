// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SubscriptionManager} from "src/SubscriptionManager.sol";
import {Test,console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ISubscriptionToken} from "../src/Interfaces/ISubscriptionToken.sol";
import {SubscriptionToken} from "../src/SubscriptionToken.sol";
import {DeploySubscriptionManager} from "script/DeploySubscriptionManager.s.sol";
import {HelperConfig} from "script/HelperConfig.sol";
// import {AggregatorV3Mock} from "@chainlink/contracts/mocks/AggregatorV3Mock.sol";
contract SubscriptionManagerTest is Test {
    SubscriptionManager private subscriptionManager;
    SubscriptionToken private subscriptionToken;
    HelperConfig private helperConfig;
    DeploySubscriptionManager private deployer;
    
    address public owner;
    address public company = makeAddr("company");
    address public user = makeAddr("user");
    address public priceFeed;
    function setUp() public {
       
        deployer = new DeploySubscriptionManager();
        (subscriptionToken, subscriptionManager, helperConfig) = deployer.run();
        (priceFeed,,owner) = helperConfig.activeNetworkConfig();
        vm.startPrank(owner);
        // vm.deal(owner, 100 ether);
        subscriptionToken.transferOwnership(address(subscriptionManager));

        subscriptionManager.grantCompanyRole(company);
        vm.deal(company, 1 ether);
        vm.deal(user, 1 ether);
        vm.stopPrank();
    }


    modifier userHasDepositedTokens() {
        vm.startPrank(user);
        subscriptionManager.depositTokens{value: 1 ether}();
        
        vm.stopPrank();
        _;
    }
    function testUserCanDepositTokens() public {
        
        vm.prank(user);
        subscriptionManager.depositTokens{value: 1 ether}();
        uint256 userBalance = subscriptionToken.balanceOf(user);
        uint256 depositvalue = subscriptionManager.getPriceInUsd(1 ether);
        assertEq(userBalance, depositvalue);

    }

    function testUserCanWithdrawTokens() public {
        
        vm.startPrank(user);
        subscriptionManager.depositTokens{value: 1 ether}();
        uint256 userBalanceBefore = subscriptionToken.balanceOf(user);
        subscriptionToken.approve(address(subscriptionManager), 1 ether);
        subscriptionManager.withdrawTokens(1 ether);
        uint256 userBalanceAfter = subscriptionToken.balanceOf(user);
        vm.stopPrank();
        assertEq(userBalanceAfter, userBalanceBefore - subscriptionManager.getPriceInUsd(1 ether));
    }

    function testComapanyCanCreateSubscription() public {
        vm.startPrank(company);
        subscriptionManager.createSubscription("Test Subscription", company,30 days,100e18);
        SubscriptionManager.Subscription memory subscription = subscriptionManager.getComapanySubscription("Test Subscription");
        assertEq(subscription.name, "Test Subscription");
        assertEq(subscription.price, 100e18);
        assertEq(subscription.interval, 30 days);
        assertTrue(subscription.isActive);
        vm.stopPrank();
    }

    function testUserCanSubscribeToSubscription() public userHasDepositedTokens {
        vm.startPrank(company);
        subscriptionManager.createSubscription("Test Subscription", company,30 days,100e18);
        vm.stopPrank();
        
        vm.startPrank(user);
        console.log("User balance before subscription:", subscriptionToken.balanceOf(user));

        subscriptionToken.approve(address(subscriptionManager), 100e18);
        subscriptionManager.enrollSubscription("Test Subscription");
        SubscriptionManager.Subscription memory subscription = subscriptionManager.getUserSubscription("Test Subscription",user);
        assertTrue(subscription.isActive);
        assertEq(subscription.startTime, block.timestamp);
        vm.stopPrank();
    }

    function testUserCanPayForSubscription() public userHasDepositedTokens {
        vm.startPrank(company);
        subscriptionManager.createSubscription("Test Subscription", company,30 days,100e18);
        vm.stopPrank();
        
        vm.startPrank(user);
        subscriptionToken.approve(address(subscriptionManager), 200e18);
        subscriptionManager.enrollSubscription("Test Subscription");
        uint256 userBalanceBefore = subscriptionToken.balanceOf(user);
        vm.warp(block.timestamp + 30 days); // Simulate time passing
        subscriptionManager.paySubscription("Test Subscription",user);
        uint256 userBalanceAfter = subscriptionToken.balanceOf(user);
        assertEq(userBalanceAfter, userBalanceBefore - 100e18);
        vm.stopPrank();
    }

    function testCompanyCanWithdrawFunds() public userHasDepositedTokens {
        vm.startPrank(company);
        subscriptionManager.createSubscription("Test Subscription", company,30 days,100e18);
        vm.stopPrank();
        
        vm.startPrank(user);
        subscriptionToken.approve(address(subscriptionManager), 100e18);
        subscriptionManager.enrollSubscription("Test Subscription");
        vm.stopPrank();

        vm.startPrank(company);
        uint256 priceInEth = (100e18*1e18) / subscriptionManager.getPriceInUsd(1 ether); 
        subscriptionManager.withdrawTokens(priceInEth);
        uint256 companyBalanceAfter = subscriptionToken.balanceOf(company);
        assertEq(companyBalanceAfter,0);
        vm.stopPrank();
    }

    function testGetEthUsdPrice() public view {
        uint256 ethUsdPrice = subscriptionManager.getEthUsdPrice();
        assertTrue(ethUsdPrice > 0);
    }

    function testUserCanCancelSubscription() public userHasDepositedTokens {
        vm.startPrank(company);
        subscriptionManager.createSubscription("Test Subscription", company,30 days,100e18);
        vm.stopPrank();
        
        vm.startPrank(user);
        subscriptionToken.approve(address(subscriptionManager), 100e18);
        subscriptionManager.enrollSubscription("Test Subscription");
        SubscriptionManager.Subscription memory subscription = subscriptionManager.getUserSubscription("Test Subscription",user);
        assertTrue(subscription.isActive);
        
        subscriptionManager.cancelSubscription("Test Subscription");
        subscription = subscriptionManager.getUserSubscription("Test Subscription",user);
        assertFalse(subscription.isActive);
        vm.stopPrank();
    }

   
}

