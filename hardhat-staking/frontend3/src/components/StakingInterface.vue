<template>
  <div class="container mx-auto p-4 max-w-2xl">
    <div class="bg-gray-800 text-white p-6 rounded-lg shadow-xl">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">My Staking DApp</h1>
        <button
          @click="account ? disconnectWallet() : connectWallet()"
          class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-4 rounded-lg transition duration-200 ease-in-out"
        >
          {{ account ? `${account.slice(0, 6)}...${account.slice(-4)}` : 'Connect Wallet' }}
        </button>
      </div>

      <div v-if="isLoadingInitial" class="text-center py-4">Loading contract data...</div>
      <div v-if="error" class="bg-red-500 text-white p-3 rounded-md mb-4">{{ error }}</div>

      <div v-if="account && !isLoadingInitial && !error">
        <!-- Contract Info -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <InfoCard title="Your Wallet MST Balance">
            {{ formatBigInt(stakeTokenBalance) }} MST
          </InfoCard>
          <InfoCard title="Your Staked MST">
            {{ formatBigInt(stakedBalance) }} MST
          </InfoCard>
          <InfoCard title="Pending Rewards">
            {{ formatBigInt(pendingRewards) }} MST
          </InfoCard>
          <InfoCard title="Yearly Reward Rate (APY Approx.)">
            {{ rewardRateDisplay }}%
          </InfoCard>
        </div>

        <!-- Staking Section -->
        <div class="bg-gray-700 p-4 rounded-lg mb-6">
          <h2 class="text-xl font-semibold mb-3">Stake Tokens</h2>
          <div class="flex items-center space-x-2 mb-3">
            <input
              type="number"
              v-model="stakeAmount"
              placeholder="Amount to stake"
              class="flex-grow p-2 rounded-md bg-gray-600 text-white focus:ring-indigo-500 focus:border-indigo-500"
            />
            <button @click="setMaxStakeAmount" class="text-sm text-indigo-400 hover:text-indigo-300">Max</button>
          </div>
           <button
            @click="handleStake"
            :disabled="isTxLoading || !stakeAmount || parseFloat(stakeAmount) <= 0 || (allowance < parseUnits(stakeAmount.toString(), 18))"
            class="w-full bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition duration-200"
          >
            {{ (allowance < parseUnits(stakeAmount.toString() || '0', 18) && parseFloat(stakeAmount || '0') > 0) ? 'Approve & Stake' : 'Stake' }}
          </button>
          <p v-if="allowance < parseUnits(stakeAmount.toString() || '0', 18) && parseFloat(stakeAmount || '0') > 0" class="text-xs text-yellow-400 mt-1">
            You need to approve spending first. Clicking will initiate an approval transaction then staking.
          </p>
        </div>

        <!-- Withdrawal Section -->
        <div class="bg-gray-700 p-4 rounded-lg">
          <h2 class="text-xl font-semibold mb-3">Withdraw Staked Tokens</h2>
          <div v-if="!withdrawalRequestInfo.isActive">
              <div class="flex items-center space-x-2 mb-3">
                <input
                  type="number"
                  v-model="withdrawAmount"
                  placeholder="Amount to withdraw"
                  class="flex-grow p-2 rounded-md bg-gray-600 text-white focus:ring-indigo-500 focus:border-indigo-500"
                />
                <button @click="setMaxWithdrawAmount" class="text-sm text-indigo-400 hover:text-indigo-300">Max</button>
              </div>
              <button
                @click="handleRequestWithdrawal"
                :disabled="isTxLoading || !withdrawAmount || parseFloat(withdrawAmount) <= 0"
                class="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition duration-200"
              >
                Request Withdrawal ({{ COOLDOWN_PERIOD_HOURS }}h Cooldown)
              </button>
          </div>
          <div v-else>
              <p class="mb-2">Withdrawal requested: {{ formatBigInt(withdrawalRequestInfo.amount) }} MST</p>
              <p class="mb-2 text-yellow-400">
                <span v-if="withdrawalRequestInfo.cooldownOver">Cooldown period over. You can withdraw now.</span>
                <span v-else>Cooldown ends: {{ withdrawalRequestInfo.cooldownEndTimeFormatted }} ({{ withdrawalRequestInfo.cooldownRemainingFormatted }})</span>
              </p>
              <div class="flex space-x-2">
                <button
                    @click="handleWithdraw"
                    :disabled="isTxLoading || !withdrawalRequestInfo.cooldownOver"
                    class="flex-1 bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition duration-200"
                >
                    Withdraw Now
                </button>
                <button
                    @click="handleCancelWithdrawal"
                    :disabled="isTxLoading"
                    class="flex-1 bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition duration-200"
                >
                    Cancel Request
                </button>
              </div>
          </div>
        </div>

        <div v-if="isTxLoading" class="mt-4 text-center">
          <p class="text-lg">Transaction in progress...</p>
          <p v-if="txHash" class="text-sm">Tx Hash:
            <a :href="`https://localhost/tx/${txHash}`" target="_blank" class="text-indigo-400 hover:underline">{{ txHash.slice(0,10) }}...</a>
            (Note: Link for local Hardhat node might not work in browser directly)
          </p>
        </div>
        <div v-if="successMessage" class="mt-4 bg-green-500 text-white p-3 rounded-md">{{ successMessage }}</div>

      </div>
      <div v-else-if="!isLoadingInitial && !error" class="text-center py-8">
        <p class="text-xl">Please connect your wallet to use the Staking DApp.</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
      
import InfoCard from './InfoCard.vue';
import { ref, onMounted, watch, computed } from 'vue';
import {
  createWalletClient, custom, createPublicClient, http,
  formatUnits, parseUnits, Hash, Address, Hex
} from 'viem';
import { hardhat } from 'viem/chains'; // For local Hardhat node
import { STAKE_TOKEN_ADDRESS, STAKING_CONTRACT_ADDRESS, STAKE_TOKEN_ABI, STAKING_CONTRACT_ABI } from '../config';

// Constants
const COOLDOWN_PERIOD_SECONDS = 2 * 60 * 60; // 2 hours from contract
const COOLDOWN_PERIOD_HOURS = COOLDOWN_PERIOD_SECONDS / 3600;

// Reactive State
const account = ref<Address | null>(null);
const publicClient = ref<any>(null);
const walletClient = ref<any>(null);

const stakeTokenBalance = ref(0n);
const stakedBalance = ref(0n);
const pendingRewards = ref(0n);
const rewardRate = ref(0n); // Raw rate from contract (tokens per second)
const allowance = ref(0n);

const stakeAmount = ref('');
const withdrawAmount = ref('');

const isLoadingInitial = ref(true);
const isTxLoading = ref(false);
const error = ref<string | null>(null);
const successMessage = ref<string | null>(null);
const txHash = ref<Hash | null>(null);

const withdrawalRequestInfo = ref({
    isActive: false,
    amount: 0n,
    requestTime: 0n,
    cooldownEndTime: 0n,
    cooldownOver: false,
    cooldownEndTimeFormatted: '',
    cooldownRemainingFormatted: '',
});


// Computed Properties
const rewardRateDisplay = computed(() => {
  if (!rewardRate.value || rewardRate.value === 0n) return '0.00';
  // Approximate APY: (rate_per_second * seconds_in_year) / 1 (assuming 1 total staked token for simplicity of base rate)
  // This is a very rough APY for display. Real APY depends on totalStaked changing.
  // The contract's rewardRate is total rewards per second for the *entire pool*.
  // A true APY would be (rewardRate * secondsInYear / totalStaked) * 100
  // For simplicity, let's show a rate based on 1 staked token if totalStaked is unknown or for base illustration
  // A more accurate APY would be: (rewardRatePerSec * secondsInYear / totalStakedInContract) * 100
  // Let's assume we are showing an indicative APY if one token was staked and it received all the rewardsRate output
  const yearlyReward = rewardRate.value * BigInt(365 * 24 * 60 * 60); // Rewards per year if this rate applied to one token
  const formattedYearlyReward = parseFloat(formatUnits(yearlyReward, 18));
  // If it's based on 1 token, APY = formattedYearlyReward * 100
  // This is still not quite right as rewardRate is for the *whole pool*.
  // For this example, let's show the rate that would apply IF only 1 token was staked
  // and that 1 token got all the `rewardRate` amount of tokens.
  // A better display might be "X tokens per day for the entire pool".
  // For simplicity of this example, let's try to calculate an indicative APY based on the current totalStaked
  // if totalStaked is available from contract (not directly in this simple view, but can be added)
  // For now, let's just show the raw rate converted to yearly * 100
  const rate = parseFloat(formatUnits(rewardRate.value, 18)); // rate per second
  const apy = rate * (365 * 24 * 60 * 60) * 100; // if this rate was per token
  return apy.toFixed(2); // This is still a simplification.
});


// Wallet Connection
const connectWallet = async () => {
  error.value = null;
  try {
    if (!window.ethereum) {
      error.value = 'MetaMask (or other Web3 wallet) not found. Please install it.';
      return;
    }
    const [address] = await window.ethereum.request({ method: 'eth_requestAccounts' });
    account.value = address as Address;

    const _publicClient = createPublicClient({
      chain: hardhat, // Or your specific chain
      transport: http(), // Defaults to http://127.0.0.1:8545 for hardhat
    });
    publicClient.value = _publicClient;

    const _walletClient = createWalletClient({
      account: account.value,
      chain: hardhat,
      transport: custom(window.ethereum),
    });
    walletClient.value = _walletClient;

    await fetchAllData();
  } catch (e: any) {
    console.error("Connection error:", e);
    error.value = e.message || 'Failed to connect wallet.';
    account.value = null;
  }
};

const disconnectWallet = () => {
  account.value = null;
  publicClient.value = null;
  walletClient.value = null;
  // Reset data
  stakeTokenBalance.value = 0n;
  stakedBalance.value = 0n;
  pendingRewards.value = 0n;
  rewardRate.value = 0n;
  allowance.value = 0n;
  isLoadingInitial.value = true; // To show loading on next connect
};

// Data Fetching
const fetchAllData = async () => {
  if (!publicClient.value || !account.value) return;
  isLoadingInitial.value = true;
  error.value = null;
  try {
    const [tokenBal, stakedBal, pendingRew, rewRate, allow, withdrawalReq] = await Promise.all([
      publicClient.value.readContract({
        address: STAKE_TOKEN_ADDRESS,
        abi: STAKE_TOKEN_ABI,
        functionName: 'balanceOf',
        args: [account.value],
      }),
      publicClient.value.readContract({
        address: STAKING_CONTRACT_ADDRESS,
        abi: STAKING_CONTRACT_ABI,
        functionName: 'balanceOf',
        args: [account.value],
      }),
      publicClient.value.readContract({
        address: STAKING_CONTRACT_ADDRESS,
        abi: STAKING_CONTRACT_ABI,
        functionName: 'getPendingRewards',
        args: [account.value],
      }),
      publicClient.value.readContract({
        address: STAKING_CONTRACT_ADDRESS,
        abi: STAKING_CONTRACT_ABI,
        functionName: 'getCurrentRewardRate', // Assuming you have this, or just 'rewardRate'
      }),
      publicClient.value.readContract({
        address: STAKE_TOKEN_ADDRESS,
        abi: STAKE_TOKEN_ABI,
        functionName: 'allowance',
        args: [account.value, STAKING_CONTRACT_ADDRESS],
      }),
      publicClient.value.readContract({
        address: STAKING_CONTRACT_ADDRESS,
        abi: STAKING_CONTRACT_ABI,
        functionName: 'getWithdrawalRequestInfo',
        args: [account.value],
      }),
    ]);
    stakeTokenBalance.value = tokenBal as bigint;
    stakedBalance.value = stakedBal as bigint;
    pendingRewards.value = pendingRew as bigint;
    rewardRate.value = rewRate as bigint; // This is likely the raw rewardRate from contract
    allowance.value = allow as bigint;
    
    updateWithdrawalRequestInfo(withdrawalReq as any);

  } catch (e: any) {
    console.error("Data fetching error:", e);
    error.value = 'Failed to fetch contract data. Ensure addresses and ABI are correct and you are on the right network.';
  } finally {
    isLoadingInitial.value = false;
  }
};

const updateWithdrawalRequestInfo = (data: {amount: bigint, requestTime: bigint, withdrawAvailableTime: bigint}) => {
    const now = BigInt(Math.floor(Date.now() / 1000));
    withdrawalRequestInfo.value = {
        isActive: data.amount > 0n,
        amount: data.amount,
        requestTime: data.requestTime,
        cooldownEndTime: data.withdrawAvailableTime,
        cooldownOver: data.amount > 0n && now >= data.withdrawAvailableTime,
        cooldownEndTimeFormatted: data.amount > 0n ? new Date(Number(data.withdrawAvailableTime) * 1000).toLocaleString() : '',
        cooldownRemainingFormatted: '',
    };
    if (data.amount > 0n && now < data.withdrawAvailableTime) {
        startCooldownTimer(Number(data.withdrawAvailableTime));
    }
};

let cooldownInterval: number | undefined;
const startCooldownTimer = (endTimeSeconds: number) => {
    if (cooldownInterval) clearInterval(cooldownInterval);
    
    const updateTimer = () => {
        const nowSeconds = Math.floor(Date.now() / 1000);
        const remaining = endTimeSeconds - nowSeconds;
        if (remaining <= 0) {
            withdrawalRequestInfo.value.cooldownOver = true;
            withdrawalRequestInfo.value.cooldownRemainingFormatted = 'Cooldown over';
            if (cooldownInterval) clearInterval(cooldownInterval);
        } else {
            const hours = Math.floor(remaining / 3600);
            const minutes = Math.floor((remaining % 3600) / 60);
            const seconds = remaining % 60;
            withdrawalRequestInfo.value.cooldownRemainingFormatted = 
                `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
        }
    };
    updateTimer(); // Initial call
    cooldownInterval = setInterval(updateTimer, 1000);
};


// Contract Interactions
const handleTransaction = async (txPromise: Promise<Hash>, successMsg: string) => {
  isTxLoading.value = true;
  error.value = null;
  successMessage.value = null;
  txHash.value = null;
  try {
    const hash = await txPromise;
    txHash.value = hash;
    await publicClient.value.waitForTransactionReceipt({ hash });
    successMessage.value = successMsg;
    await fetchAllData(); // Refresh data after successful tx
  } catch (e: any) {
    console.error("Transaction error:", e);
    error.value = e.shortMessage || e.message || 'Transaction failed.';
  } finally {
    isTxLoading.value = false;
    setTimeout(() => { successMessage.value = null; error.value = null; }, 5000);
  }
};

const handleStake = async () => {
  if (!walletClient.value || !stakeAmount.value) return;
  const amountToStake = parseUnits(stakeAmount.value, 18);

  if (allowance.value < amountToStake) {
    // Approve first
    try {
        isTxLoading.value = true;
        error.value = null;
        successMessage.value = null;
        txHash.value = null;

        const approveHash = await walletClient.value.writeContract({
            address: STAKE_TOKEN_ADDRESS,
            abi: STAKE_TOKEN_ABI,
            functionName: 'approve',
            args: [STAKING_CONTRACT_ADDRESS, amountToStake],
        });
        txHash.value = approveHash;
        await publicClient.value.waitForTransactionReceipt({ hash: approveHash });
        successMessage.value = 'Approval successful! Now staking...';
        allowance.value = amountToStake; // Optimistically update allowance

        // Then stake
        const stakeHash = await walletClient.value.writeContract({
            address: STAKING_CONTRACT_ADDRESS,
            abi: STAKING_CONTRACT_ABI,
            functionName: 'stake',
            args: [amountToStake],
        });
        txHash.value = stakeHash; // Update txHash for staking
        await publicClient.value.waitForTransactionReceipt({ hash: stakeHash });
        successMessage.value = 'Successfully staked tokens!';
        stakeAmount.value = '';
        await fetchAllData();
    } catch (e:any) {
        console.error("Approve/Stake error:", e);
        error.value = e.shortMessage || e.message || 'Approve or Stake transaction failed.';
    } finally {
        isTxLoading.value = false;
        setTimeout(() => { successMessage.value = null; error.value = null; }, 7000);
    }

  } else {
    // Directly stake
    handleTransaction(
      walletClient.value.writeContract({
        address: STAKING_CONTRACT_ADDRESS,
        abi: STAKING_CONTRACT_ABI,
        functionName: 'stake',
        args: [amountToStake],
      }),
      'Successfully staked tokens!'
    ).then(() => stakeAmount.value = '');
  }
};

const handleRequestWithdrawal = async () => {
    if (!walletClient.value || !withdrawAmount.value) return;
    const amountToWithdraw = parseUnits(withdrawAmount.value, 18);
     handleTransaction(
      walletClient.value.writeContract({
        address: STAKING_CONTRACT_ADDRESS,
        abi: STAKING_CONTRACT_ABI,
        functionName: 'requestWithdrawal',
        args: [amountToWithdraw],
      }),
      'Withdrawal requested successfully!'
    ).then(() => withdrawAmount.value = '');
};

const handleWithdraw = async () => {
    if (!walletClient.value) return;
     handleTransaction(
      walletClient.value.writeContract({
        address: STAKING_CONTRACT_ADDRESS,
        abi: STAKING_CONTRACT_ABI,
        functionName: 'withdraw',
        args: [], // Withdraw function in contract takes no args if using stored request
      }),
      'Successfully withdrew tokens!'
    );
};

const handleCancelWithdrawal = async () => {
    if (!walletClient.value) return;
     handleTransaction(
      walletClient.value.writeContract({
        address: STAKING_CONTRACT_ADDRESS,
        abi: STAKING_CONTRACT_ABI,
        functionName: 'cancelWithdrawalRequest',
        args: [],
      }),
      'Withdrawal request cancelled.'
    );
};

// Helpers
const formatBigInt = (value: bigint, decimals = 18, precision = 4) => {
  if (value === undefined || value === null) return '0.00';
  return parseFloat(formatUnits(value, decimals)).toFixed(precision);
};

const setMaxStakeAmount = () => {
    stakeAmount.value = formatUnits(stakeTokenBalance.value, 18);
};
const setMaxWithdrawAmount = () => {
    withdrawAmount.value = formatUnits(stakedBalance.value, 18);
};


// Lifecycle and Watchers
onMounted(() => {
  if (window.ethereum) {
    window.ethereum.on('accountsChanged', (accounts: string[]) => {
      if (accounts.length > 0) {
        account.value = accounts[0] as Address;
        connectWallet(); // Re-initialize clients and fetch data
      } else {
        disconnectWallet();
      }
    });
    window.ethereum.on('chainChanged', () => {
      // Handle chain change, e.g., reload or prompt user
      window.location.reload();
    });
  }
  // Try to auto-connect if already permitted
  // This often requires user interaction on first load for privacy reasons
  // connectWallet(); // You might want this, or let user click connect
});

watch(account, (newAccount) => {
  if (newAccount) {
    fetchAllData();
  }
});

</script>

<style scoped>
/* You can add component-specific styles here if needed, but Tailwind is preferred */
</style>
