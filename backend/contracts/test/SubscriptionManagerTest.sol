// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import {SubscriptionManager} from "src/SubscriptionManager.sol";
// import {Test,console} from "forge-std/Test.sol";
// import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
// import {ISubscriptionToken} from "../src/Interfaces/ISubscriptionToken.sol";
// import {SubscriptionToken} from "../src/SubscriptionToken.sol";
// import {DeploySubscriptionManagerSepolia} from "script/DeploySubscriptionManagerSepolia.s.sol";
// import {HelperConfig} from "script/HelperConfig.sol";
// import {TokenVault} from "../src/TokenVault.sol";

// // import {AggregatorV3Mock} from "@chainlink/contracts/mocks/AggregatorV3Mock.sol";
// contract SubscriptionManagerTest is Test {
//     SubscriptionManager private subscriptionManager;
//     SubscriptionToken private subscriptionToken;
//     HelperConfig private helperConfig;
//     DeploySubscriptionManager private deployer;
//     TokenVault private tokenVault;
    
//     address public owner;
//     address public company = makeAddr("company");
//     address public user = makeAddr("user");
//     address public priceFeed;
//     function setUp() public {
       
//         deployer = new DeploySubscriptionManager();
//         (subscriptionToken, subscriptionManager,tokenVault, helperConfig) = deployer.run();
//         (priceFeed,,owner) = helperConfig.activeNetworkConfig();
//         vm.startPrank(owner);
//         // vm.deal(owner, 100 ether);
//         tokenVault.grantDepositWithdrawRole(user);
//         tokenVault.grantDepositWithdrawRole(company);
//         subscriptionManager.grantCompanyRole(company);
//         subscriptionToken.grantMintAndBurnRole(address(tokenVault));

//         vm.deal(company, 1 ether);
//         vm.deal(user, 1 ether);
//         vm.stopPrank();
//     }


//     modifier userHasDepositedTokens() {
//         vm.startPrank(user);
//         tokenVault.depositTokens{value: 1 ether}();
//         vm.stopPrank();
//         _;
//     }
//     function testUserCanDepositTokens() public {
        
//         vm.prank(user);
//                 tokenVault.depositTokens{value: 1 ether}();
//         uint256 userBalance = subscriptionToken.balanceOf(user);
//         uint256 depositvalue = tokenVault.getPriceInUsd(1 ether);
//         assertEq(userBalance, depositvalue);

//     }

//     function testUserCanWithdrawTokens() public {
        
//         vm.startPrank(user);
//         tokenVault.depositTokens{value: 1 ether}();
//         uint256 userBalanceBefore = subscriptionToken.balanceOf(user);
//         subscriptionToken.approve(address(subscriptionManager), 1 ether);
        
//         tokenVault.withdrawTokens(tokenVault.getPriceInUsd(1 ether));
//         uint256 userBalanceAfter = subscriptionToken.balanceOf(user);
//         vm.stopPrank();
//         assertEq(userBalanceAfter, userBalanceBefore - tokenVault.getPriceInUsd(1 ether));
//     }

//     function testComapanyCanCreateSubscription() public {
//         vm.startPrank(company);
//         subscriptionManager.createSubscription("Test Subscription", company,100e18);
//         SubscriptionManager.CompanySubscription memory companySubscription = subscriptionManager.getCompanySubscription("Test Subscription");
//         assertEq(companySubscription.name, "Test Subscription");
//         assertEq(companySubscription.price, 100e18);
//         vm.stopPrank();
//     }

//     function testUserCanSubscribeToSubscription() public userHasDepositedTokens {
//         vm.startPrank(company);
//         subscriptionManager.createSubscription("Test Subscription", company,100e18);
//         vm.stopPrank();
        
//         vm.startPrank(user);
//         console.log("User balance before subscription:", subscriptionToken.balanceOf(user));

//         subscriptionToken.approve(address(subscriptionManager), 100e18);
//         subscriptionManager.enrollSubscription("Test Subscription",30 days);
//         SubscriptionManager.Subscription memory subscription = subscriptionManager.getUserSubscription("Test Subscription",user);
//         assertTrue(subscription.isActive);
//         assertEq(subscription.startTime, block.timestamp);
//         vm.stopPrank();
//     }

//     function testUserCanPayForSubscription() public userHasDepositedTokens {
//         vm.startPrank(company);
//         subscriptionManager.createSubscription("Test Subscription", company,100e18);
//         vm.stopPrank();
        
//         vm.startPrank(user);
//         subscriptionToken.approve(address(subscriptionManager), 200e18);
//         subscriptionManager.enrollSubscription("Test Subscription",30 days);
//         uint256 userBalanceBefore = subscriptionToken.balanceOf(user);
//         vm.warp(block.timestamp + 30 days); // Simulate time passing
//         subscriptionManager.paySubscription("Test Subscription",user);
//         uint256 userBalanceAfter = subscriptionToken.balanceOf(user);
//         assertEq(userBalanceAfter, userBalanceBefore - 100e18);
//         vm.stopPrank();
//     }

//     function testCompanyCanWithdrawFunds() public userHasDepositedTokens {
//         vm.startPrank(company);
//         subscriptionManager.createSubscription("Test Subscription", company,100e18);
//         vm.stopPrank();
        
//         vm.startPrank(user);
//         subscriptionToken.approve(address(subscriptionManager), 100e18);
//         subscriptionManager.enrollSubscription("Test Subscription",30 days);
//         vm.stopPrank();

//         vm.startPrank(company);
//         // uint256 priceInEth = (100e18*1e18) / subscriptionManager.getPriceInUsd(1 ether); 
//         tokenVault.withdrawTokens(100e18);
//         uint256 companyBalanceAfter = subscriptionToken.balanceOf(company);
//         assertEq(companyBalanceAfter,0);
//         vm.stopPrank();
//     }

//     function testGetEthUsdPrice() public view {
//         uint256 ethUsdPrice = tokenVault.getEthUsdPrice();
//         assertTrue(ethUsdPrice > 0);
//     }

//     function testUserCanCancelSubscription() public userHasDepositedTokens {
//         vm.startPrank(company);
//         subscriptionManager.createSubscription("Test Subscription", company,100e18);
//         vm.stopPrank();
        
//         vm.startPrank(user);
//         subscriptionToken.approve(address(subscriptionManager), 100e18);
//         subscriptionManager.enrollSubscription("Test Subscription",30 days);
//         SubscriptionManager.Subscription memory subscription = subscriptionManager.getUserSubscription("Test Subscription",user);
//         assertTrue(subscription.isActive);
        
//         subscriptionManager.cancelSubscription("Test Subscription");
//         subscription = subscriptionManager.getUserSubscription("Test Subscription",user);
//         assertFalse(subscription.isActive);
//         vm.stopPrank();
//     }

   
// }



