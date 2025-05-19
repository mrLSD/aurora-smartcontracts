// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {
    IERC20 public immutable stakeToken;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdateTime; // To calculate rewards

    uint256 public totalStaked;
    uint256 public rewardRatePerSecond; // e.g., 0.00001 STK per second per STK staked (needs 1e18 precision)
        // For simplicity, let's make it total rewards distributed per second
    uint256 public constant REWARD_PRECISION = 1e18; // For rewardRatePerSecond if it's a rate
    uint256 public lastGlobalUpdateTime;
    uint256 public accumulatedRewardsPerShare; // Accumulated rewards per share

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);

    constructor(address _stakeTokenAddress, uint256 _initialRewardRatePerSecond) Ownable(msg.sender) {
        stakeToken = IERC20(_stakeTokenAddress);
        rewardRatePerSecond = _initialRewardRatePerSecond; // e.g., STK per second for the whole pool
        lastGlobalUpdateTime = block.timestamp;
    }

    // Modifier to update rewards for a user
    modifier updateReward(address _account) {
        _updateUserRewards(_account);
        _;
    }

    function _updateUserRewards(address _account) internal {
        uint256 currentGlobalRewardsPerShare = accumulatedRewardsPerShare;
        if (totalStaked > 0) {
            uint256 timeElapsed = block.timestamp - lastGlobalUpdateTime;
            currentGlobalRewardsPerShare += (timeElapsed * rewardRatePerSecond * REWARD_PRECISION) / totalStaked;
        }

        rewards[_account] +=
            (stakedBalance[_account] * (currentGlobalRewardsPerShare - lastUpdateTime[_account])) / REWARD_PRECISION;
        lastUpdateTime[_account] = currentGlobalRewardsPerShare;
    }

    function _updateGlobalRewards() internal {
        if (totalStaked == 0) {
            lastGlobalUpdateTime = block.timestamp;
            return;
        }
        uint256 timeElapsed = block.timestamp - lastGlobalUpdateTime;
        accumulatedRewardsPerShare += (timeElapsed * rewardRatePerSecond * REWARD_PRECISION) / totalStaked;
        lastGlobalUpdateTime = block.timestamp;
    }

    function stake(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "Cannot stake 0");
        _updateGlobalRewards(); // Update global state before user stakes

        totalStaked += _amount;
        stakedBalance[msg.sender] += _amount;

        // Update user's reward baseline after staking
        rewards[msg.sender] = (stakedBalance[msg.sender] * accumulatedRewardsPerShare) / REWARD_PRECISION;
        lastUpdateTime[msg.sender] = accumulatedRewardsPerShare; // Set their starting point

        stakeToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        require(stakedBalance[msg.sender] >= _amount, "Insufficient staked balance");
        _updateGlobalRewards(); // Update global state before user withdraws

        stakedBalance[msg.sender] -= _amount;
        totalStaked -= _amount;

        // Update user's reward baseline after withdrawing
        rewards[msg.sender] = (stakedBalance[msg.sender] * accumulatedRewardsPerShare) / REWARD_PRECISION;
        lastUpdateTime[msg.sender] = accumulatedRewardsPerShare; // Update their baseline

        stakeToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function claimRewards() external nonReentrant updateReward(msg.sender) {
        _updateGlobalRewards(); // Ensure global state is current
        _updateUserRewards(msg.sender); // Calculate final rewards for the user

        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount > 0, "No rewards to claim");

        rewards[msg.sender] = 0; // Reset pending rewards
        // The baseline `lastUpdateTime[msg.sender]` is already updated by `_updateUserRewards`

        stakeToken.transfer(msg.sender, rewardAmount);
        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    function getPendingRewards(address _user) external view returns (uint256) {
        uint256 currentGlobalRewardsPerShare = accumulatedRewardsPerShare;
        if (totalStaked > 0) {
            uint256 timeElapsed = block.timestamp - lastGlobalUpdateTime;
            currentGlobalRewardsPerShare += (timeElapsed * rewardRatePerSecond * REWARD_PRECISION) / totalStaked;
        }
        return rewards[_user]
            + ((stakedBalance[_user] * (currentGlobalRewardsPerShare - lastUpdateTime[_user])) / REWARD_PRECISION);
    }

    function setRewardRate(uint256 _newRate) public onlyOwner {
        _updateGlobalRewards(); // Update rewards with the old rate first
        rewardRatePerSecond = _newRate;
        emit RewardRateUpdated(_newRate);
    }

    // A simple APY representation. In a real scenario, this would be more complex
    // or based on historical data. Here, it's an indicative APY based on current rate.
    // Assumes rewardRatePerSecond is total rewards for the pool.
    function getAPY() external view returns (uint256) {
        if (totalStaked == 0) return 0;
        // (Rewards per year / Total Staked) * 100
        uint256 rewardsPerYear = rewardRatePerSecond * 365 days;
        uint8 decimals = 18;

        return (rewardsPerYear * 100 * (10 ** decimals)) / totalStaked; // APY in percentage points with token decimals
    }
}
