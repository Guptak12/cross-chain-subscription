// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {SubscriptionToken} from "../src/SubscriptionToken.sol";
import {ISubscriptionToken} from "../src/Interfaces/ISubscriptionToken.sol";
contract DeploySubscriptionManager is Script {
    HelperConfig public helperConfig;
    SubscriptionManager public subscriptionManager;
    SubscriptionToken public subscriptionToken;
    function run() external returns(SubscriptionToken, SubscriptionManager,HelperConfig) {
        helperConfig = new HelperConfig();
        (address priceFeed,uint256 deployerKey,) = helperConfig.activeNetworkConfig();
        
        vm.startBroadcast(deployerKey);
        subscriptionToken = new SubscriptionToken();
        subscriptionManager = new SubscriptionManager(ISubscriptionToken(address(subscriptionToken)),priceFeed);
        // subscriptionManager.grantCompanyRole(msg.sender);
        vm.stopBroadcast();
        return (subscriptionToken, subscriptionManager, helperConfig);
    }
}