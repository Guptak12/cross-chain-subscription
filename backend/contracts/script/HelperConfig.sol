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
        address router;
        address feetoken;
    }

    NetworkConfig public activeNetworkConfig;
    address public constant SEPOLIA_PRICE_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address public constant SEPOLIA_ACCOUNT_ADDRESS = 0xC92e3022219A8Bb6C6d8D04C0346A8147478dcC5;
    address public constant SEPOLIA_ROUTER = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address public constant SEPOLIA_FEETOKEN = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address public constant LOCAL_ANVIL_ACCOUNT_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address public constant AVALANCHE_ACCOUNT_ADDRESS = 0xfD3Bdc30862BFabB48ADf880Da8DF343dc2bBE92;
    address public constant AVALANCHE_ROUTER = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address public constant AVALANCHE_PRICE_FEED = 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD;
    address public constant AVALANCHE_FEETOKEN = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;

    constructor() {
        if (block.chainid == 11155111) {
            // Sepolia
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 43113) {
            activeNetworkConfig = getAvalancheAVAXConfig();
        } else {
            // Local Anvil
            activeNetworkConfig = getLocalEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            priceFeed: SEPOLIA_PRICE_FEED,
            deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY"),
            account: SEPOLIA_ACCOUNT_ADDRESS,
            router: SEPOLIA_ROUTER,
            feetoken: SEPOLIA_FEETOKEN
        });
    }

    function getLocalEthConfig() public returns (NetworkConfig memory localNetworkConfig) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        localNetworkConfig = NetworkConfig({
            priceFeed: address(new MockV3Aggregator(18, 2000e8)), // Mock price feed with 2000 USD
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY,
            account: LOCAL_ANVIL_ACCOUNT_ADDRESS,
            router: address(0), // No router in local environment
            feetoken: address(new ERC20Mock())
        });
    }

    function getAvalancheAVAXConfig() public view returns (NetworkConfig memory avalancheNetworkConfig) {
        avalancheNetworkConfig = NetworkConfig({
            priceFeed: 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD,
            deployerKey: vm.envUint("AVALANCHE_PRIVATE_KEY"),
            account: AVALANCHE_ACCOUNT_ADDRESS,
            router: AVALANCHE_ROUTER,
            feetoken: AVALANCHE_FEETOKEN
        });
    }
}
