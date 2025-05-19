import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";

const config: HardhatUserConfig = {
  networks: {
    aurora: {
      url: "https://testnet.aurora.dev",
      chainId: 1313161555,
      from: "0xf1D0D3C2B0705f767b00E26cF5E8976449988adb",
      accounts: ["0x863108255a3211f108dbf78e478ce5f95b18245ad1d421ac2370b62bc112cf6a"],
    }
  },
  solidity: {
    version: "0.8.28",
    settings: {
      evmVersion: "cancun",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  }
};

export default config;
