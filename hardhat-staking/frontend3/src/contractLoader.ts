import type { Abi, Address } from 'viem';

import stakeTokenAbiData from '../contracts/StakeToken.contract.json';
import stakingContractAbiData from '../contracts/StakingContract.contract.json';

interface ContractData {
    address: Address;
    abi: Abi;
}

const stakeToken = stakeTokenAbiData as ContractData;
const stakingContract = stakingContractAbiData as ContractData;

export const STAKE_TOKEN_ADDRESS = stakeToken.address;
export const STAKING_CONTRACT_ADDRESS = stakingContract.address;

export const STAKE_TOKEN_ABI = stakeToken.abi;
export const STAKING_CONTRACT_ABI = stakingContract.abi;

if (!STAKING_CONTRACT_ADDRESS || !STAKING_CONTRACT_ADDRESS || STAKING_CONTRACT_ADDRESS.length === 0) {
    const errorMsg = "StakingToken data is missing or empty. Check paths and content.";
    console.error(errorMsg, { stakingContractAbi });
    throw new Error(errorMsg);
}

if (!STAKING_CONTRACT_ADDRESS || !STAKING_CONTRACT_ABI || STAKING_CONTRACT_ABI.length === 0) {
    const errorMsg = "StakingContract data is missing or empty. Check paths and content.";
    console.error(errorMsg, { stakingContractAbi });
    throw new Error(errorMsg);
}
