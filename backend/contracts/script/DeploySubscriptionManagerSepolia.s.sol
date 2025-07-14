// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {SubscriptionToken} from "../src/SubscriptionToken.sol";
import {ISubscriptionToken} from "../src/Interfaces/ISubscriptionToken.sol";
import {TokenVault} from "../src/TokenVault.sol";
import {CrossChainManager} from "../src/CrossChainManager.sol";

contract DeploySubscriptionManagerSepolia is Script {
    HelperConfig public helperConfig;
    SubscriptionManager public subscriptionManager;
    SubscriptionToken public subscriptionToken;
    TokenVault public tokenVault;
    CrossChainManager public crossChainManager;
    function run() external returns(SubscriptionToken, SubscriptionManager,TokenVault,CrossChainManager,HelperConfig) {
        helperConfig = new HelperConfig();
        (address priceFeed,uint256 deployerKey,,address router, address linkToken) = helperConfig.activeNetworkConfig();
        
        vm.startBroadcast(deployerKey);
        subscriptionToken = new SubscriptionToken();
        tokenVault = new TokenVault(address(subscriptionToken),priceFeed);
        subscriptionManager = new SubscriptionManager(ISubscriptionToken(address(subscriptionToken)));
        crossChainManager= new CrossChainManager(router,linkToken,address(subscriptionManager));
        subscriptionManager.setCrossChainManager(crossChainManager);
        subscriptionToken.grantMintAndBurnRole(address(subscriptionManager));
        subscriptionManager.grantCCIPRole(address(crossChainManager));
        subscriptionToken.grantMintAndBurnRole(address(tokenVault));
       
        
        vm.stopBroadcast();
        return (subscriptionToken, subscriptionManager, tokenVault,crossChainManager,helperConfig);
    }
}

// contract 