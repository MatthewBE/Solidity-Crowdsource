// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// 1. Deploy Mock Contracts to Simulate Alchemy API Contract calls on Anvil
// 2. Keep track of different contract addresses across different chains

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on local anvil, deploy mocks
    // Else, grab the existing address from the live network

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; //Exp. ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getEthMainnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }
    // Create an API endpoint from alchemy to use in the fork URL
    // Get the Chinlink price feed address
    // https://docs.chain.link/data-feeds/price-feeds/

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getEthMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethMainnetonfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});

        return ethMainnetonfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Deploy the mocks
        // Return the mock address

        // This prevents another instance of the mock anvil  network
        // from running
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilEthConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});

        return anvilEthConfig;
    }
}
