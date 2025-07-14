// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {SubscriptionToken} from "../src/SubscriptionToken.sol";
import {ISubscriptionToken} from "../src/Interfaces/ISubscriptionToken.sol";
import {TokenVault} from "../src/TokenVault.sol";
import {CrossChainManager} from "../src/CrossChainManager.sol";
import {DeploySubscriptionManagerAvalanche} from "./DeploySubscriptionManagerAvalanche.s.sol";
import {DeploySubscriptionManagerSepolia} from "./DeploySubscriptionManagerSepolia.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract ProcessTxns is Script {
    HelperConfig public helperConfig;
    SubscriptionManager public subscriptionManager;
    SubscriptionToken public subscriptionToken;
    TokenVault public tokenVault;
    CrossChainManager public crossChainManager;
    address[2] public receivers; // 0 -> sepolia, 1 -> avalanche
    uint256 public account1 = vm.envUint("ACCOUNT1_PRIVATE_KEY");
    uint256 count = 0;
    function run() external returns(SubscriptionToken, SubscriptionManager, TokenVault, CrossChainManager, HelperConfig) {
        if (block.chainid == 43113) {
            DeploySubscriptionManagerAvalanche deployer = new DeploySubscriptionManagerAvalanche();
            (subscriptionToken, subscriptionManager, tokenVault, crossChainManager, helperConfig) = deployer.run();
            receivers[1]=address(crossChainManager);
            
        } else if (block.chainid == 11155111) {
            DeploySubscriptionManagerSepolia deployer = new DeploySubscriptionManagerSepolia();
            (subscriptionToken, subscriptionManager, tokenVault, crossChainManager, helperConfig) = deployer.run();
            receivers[0] = address(crossChainManager);
            
        } else {
            revert("Unsupported network");
        }

        (,uint256 deployerKey,,, address linkToken) = helperConfig.activeNetworkConfig();
        if (block.chainid == 43113){
            vm.startBroadcast(deployerKey);
            tokenVault.depositTokens{value: 0.001 ether}();
            IERC20(linkToken).transfer(address(crossChainManager), 2000000000000000000); // Transfer 2 LINK to CrossChainManager
            // subscriptionManager.enrollSubscription("NETFLIX", 60, user,0x64fbc59bbbb1B43f2EdA83835610CFc233f26282,1,11155111);

               
        }
        if (block.chainid == 11155111){
            vm.startBroadcast(deployerKey);
            IERC20(linkToken).transfer(address(crossChainManager), 2000000000000000000); // Transfer 2 LINK to CrossChainManager
            vm.stopBroadcast();
            vm.broadcast(account1);
            subscriptionManager.createSubscription("NETFLIX",1e15);

        }
            return (subscriptionToken, subscriptionManager, tokenVault, crossChainManager, helperConfig);
    }
}
