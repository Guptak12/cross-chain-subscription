// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address priceFeed;
        uint256 deployerKey;
        address account;
    }

    NetworkConfig public activeNetworkConfig;
    address public constant SEPOLIA_PRICE_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address public constant SEPOLIA_ACCOUNT_ADDRESS = 0xfD3Bdc30862BFabB48ADf880Da8DF343dc2bBE92;
    address public constant LOCAL_ANVIL_ACCOUNT_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11155111) {
            // Sepolia
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            // Local Anvil
            activeNetworkConfig = getLocalEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig =
            NetworkConfig({priceFeed: SEPOLIA_PRICE_FEED, deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY"),account: SEPOLIA_ACCOUNT_ADDRESS});
    }

    function getLocalEthConfig() public returns (NetworkConfig memory localNetworkConfig) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        localNetworkConfig = NetworkConfig({
            priceFeed: address(new MockV3Aggregator(18, 2000e8)), // Mock price feed with 2000 USD
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY,
            account: LOCAL_ANVIL_ACCOUNT_ADDRESS
        });
    }
}
