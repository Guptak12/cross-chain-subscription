// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {SubscriptionToken} from "../src/SubscriptionToken.sol";
import {ISubscriptionToken} from "../src/Interfaces/ISubscriptionToken.sol";
import {TokenVault} from "../src/TokenVault.sol";
import {CrossChainManager} from "../src/CrossChainManager.sol";

contract DeploySubscriptionManagerAvalanche is Script {
    HelperConfig public helperConfig;
    SubscriptionManager public subscriptionManager;
    SubscriptionToken public subscriptionToken;
    TokenVault public tokenVault;
    CrossChainManager public crossChainManager;
    function run() external returns(SubscriptionToken, SubscriptionManager,TokenVault,CrossChainManager,HelperConfig) {
        helperConfig = new HelperConfig();
        (address priceFeed,uint256 deployerKey,address account,address router, address linkToken) = helperConfig.activeNetworkConfig();
        
        vm.startBroadcast(deployerKey);
        subscriptionToken = new SubscriptionToken();
        tokenVault = new TokenVault(address(subscriptionToken),priceFeed);
        subscriptionManager = new SubscriptionManager(ISubscriptionToken(address(subscriptionToken)));
        crossChainManager= new CrossChainManager(router,linkToken,address(subscriptionManager));
        subscriptionManager.setCrossChainManager(crossChainManager);
        subscriptionToken.grantMintAndBurnRole(address(subscriptionManager));
        subscriptionToken.grantMintAndBurnRole(address(tokenVault));
        subscriptionManager.grantCCIPRole(address(crossChainManager));
        subscriptionManager.grantUserRole(account);
        subscriptionToken.approve(address(subscriptionManager), type(uint256).max);
        tokenVault.grantDepositWithdrawRole(0xfD3Bdc30862BFabB48ADf880Da8DF343dc2bBE92);
        // subscriptionManager.grantUserRole();
        vm.stopBroadcast();
        return (subscriptionToken, subscriptionManager, tokenVault,crossChainManager,helperConfig);
    }
}

// contract 