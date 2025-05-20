// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9; // It's good practice to use a specific version or a narrow range like ^0.8.9 for production

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AdvancedERC20Staking
 * @author Your Name/Organization
 * @notice This contract allows users to stake a specific ERC20 token and earn rewards.
 * Rewards are compounded automatically into the staked balance.
 * Withdrawals require a cooldown period.
 * @dev Uses the reward-per-token-stored pattern for efficient reward distribution.
 * Inherits from OpenZeppelin's Ownable for access control and ReentrancyGuard for security.
 */
contract AdvancedERC20Staking is Ownable, ReentrancyGuard {

    // --- Events ---

    /**
     * @notice Emitted when a user stakes tokens.
     * @param user The address of the user who staked.
     * @param amount The amount of tokens staked.
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @notice Emitted when a user withdraws their principal staked amount.
     * @param user The address of the user who withdrew.
     * @param amount The amount of tokens withdrawn.
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @notice Emitted when rewards are compounded into a user's staked balance.
     * @param user The address of the user whose rewards were compounded.
     * @param rewardAmount The amount of rewards compounded.
     */
    event RewardsCompounded(address indexed user, uint256 rewardAmount);

    /**
     * @notice Emitted when a user requests a withdrawal, initiating the cooldown period.
     * @param user The address of the user requesting withdrawal.
     * @param amount The amount of tokens requested for withdrawal.
     * @param requestTime The timestamp when the withdrawal was requested.
     */
    event WithdrawalRequested(address indexed user, uint256 amount, uint256 requestTime);

    /**
     * @notice Emitted when a user cancels their pending withdrawal request.
     * @param user The address of the user who cancelled the withdrawal.
     */
    event WithdrawalCancelled(address indexed user);

    /**
     * @notice Emitted when the owner changes the reward rate.
     * @param newRate The new reward rate per second.
     */
    event RewardRateChanged(uint256 newRate);

    /**
     * @notice Emitted when a user performs an emergency withdrawal.
     * @param user The address of the user who performed the emergency withdrawal.
     * @param amount The amount of tokens withdrawn in the emergency.
     */
    event EmergencyWithdraw(address indexed user, uint256 amount);

    // --- Structs ---

    /**
     * @dev Stores information specific to each staker.
     * @param stakedAmount The total amount of tokens staked by the user, including compounded rewards.
     * @param rewardsPaidPerToken A snapshot of the global `rewardPerTokenStored`
     *                            at the time of the user's last interaction (stake, withdraw, compound).
     *                            This is used to calculate pending rewards accurately.
     */
    struct UserInfo {
        uint256 stakedAmount;
        uint256 rewardsPaidPerToken;
    }

    /**
     * @dev Stores details of a pending withdrawal request.
     * @param amount The amount of tokens requested for withdrawal.
     * @param requestTime The timestamp when the withdrawal request was made.
     */
    struct WithdrawalRequest {
        uint256 amount;
        uint256 requestTime;
    }

    // --- State Variables ---

    /// @notice The ERC20 token that users stake and receive as rewards.
    IERC20 public immutable stakeToken;

    /// @notice Maps user addresses to their staking information.
    mapping(address => UserInfo) public userInfo;
    /// @notice Maps user addresses to their pending withdrawal requests.
    mapping(address => WithdrawalRequest) public withdrawalRequests;

    /// @notice The total amount of tokens staked by all users in the contract.
    uint256 public totalStaked;
    /**
     * @notice The rate at which rewards are generated per second for the entire pool of staked tokens.
     * @dev This value is set by the owner and represents the total new reward tokens distributed per second.
     * For example, if `rewardRate` is 1e18 (1 token) and 1000 tokens are staked,
     * each staked token effectively earns 0.001 tokens per second from this rate.
     */
    uint256 public rewardRate;
    /// @notice The timestamp of the last global reward calculation update.
    uint256 public lastUpdateTime;
    /**
     * @notice The accumulated rewards per single staked token (or share) since the contract's inception or last reset.
     * @dev This value is scaled by `PRECISION_FACTOR` to maintain precision in calculations.
     * It's a global accumulator: `rewardPerTokenStored = rewardPerTokenStored + (elapsedTime * rewardRate * PRECISION_FACTOR / totalStaked)`.
     */
    uint256 public rewardPerTokenStored;

    /// @notice The duration (in seconds) for the withdrawal cooldown period.
    uint256 public constant COOLDOWN_PERIOD = 2 hours; // 7200 seconds
    /// @notice A scaling factor used to maintain precision in reward calculations, especially for `rewardPerTokenStored`.
    uint256 public constant PRECISION_FACTOR = 1e18;

    // --- Modifiers ---

    /**
     * @dev Modifier to update reward calculations before executing a function.
     * It first updates the global reward state (`rewardPerTokenStored`) and then
     * compounds any pending rewards for the specified account if an account is provided.
     * @param _account The address of the user for whom rewards should be compounded.
     *                 If `address(0)`, only global rewards are updated.
     */
    modifier updateReward(address _account) {
        _updateGlobalRewardState();
        if (_account != address(0)) {
            _compoundRewardsForUser(_account);
        }
        _;
    }

    // --- Constructor ---

    /**
     * @notice Initializes the staking contract.
     * @param _stakeTokenAddress The address of the ERC20 token to be used for staking and rewards.
     * @param _initialRewardRate The initial rate of rewards distributed per second for the entire pool.
     * @custom:owner The deployer of the contract will be set as the initial owner.
     */
    constructor(address _stakeTokenAddress, uint256 _initialRewardRate) Ownable(msg.sender) { // Explicitly set msg.sender for clarity, though Ownable() would default to it
        require(_stakeTokenAddress != address(0), "AdvancedERC20Staking: Stake token cannot be zero address");
        stakeToken = IERC20(_stakeTokenAddress);
        rewardRate = _initialRewardRate;
        lastUpdateTime = block.timestamp;
    }

    // --- Owner Functions ---

    /**
     * @notice Allows the owner to set a new reward rate.
     * @dev Updates global rewards with the old rate before applying the new rate.
     * @param _newRate The new reward rate per second for the entire pool.
     * 
     * onlyOwner Can only be called by the contract owner.
     */
    function setRewardRate(uint256 _newRate) external onlyOwner updateReward(address(0)) {
        rewardRate = _newRate;
        emit RewardRateChanged(_newRate);
    }

    /**
     * @notice Allows the owner to deposit reward tokens into the contract.
     * @dev This is crucial if rewards are not minted by the contract itself,
     * ensuring the contract has enough tokens to pay out earned rewards.
     * The owner must have approved the contract to spend their tokens beforehand.
     * @param _amount The amount of reward tokens to deposit.
     * 
     * onlyOwner Can only be called by the contract owner.
     */
    function depositRewardTokens(uint256 _amount) external onlyOwner nonReentrant { // Added nonReentrant as a good practice
        require(_amount > 0, "AdvancedERC20Staking: Amount must be greater than zero");
        uint256 initialBalance = stakeToken.balanceOf(address(this));
        // The contract must have an allowance from msg.sender (owner) to transferFrom
        stakeToken.transferFrom(msg.sender, address(this), _amount);
        require(stakeToken.balanceOf(address(this)) == initialBalance + _amount, "AdvancedERC20Staking: Token transfer failed or partial transfer");
    }

    /**
     * @notice Allows a user to withdraw all their staked tokens in an emergency.
     * @dev This function bypasses the cooldown period and does *not* pay out any pending rewards.
     * It's intended as a safety measure.
     * Global rewards are updated first to ensure `totalStaked` is correct for other users' calculations.
     * Any pending withdrawal request for the user is cancelled.
     * @custom:reentrant Prevents reentrancy attacks.
     */
    function emergencyWithdraw() external nonReentrant {
        // Update global rewards for all users before this user's stake is removed from totalStaked.
        // This ensures `rewardPerTokenStored` calculations are fair for others.
        _updateGlobalRewardState();

        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToWithdraw = user.stakedAmount;
        
        if (amountToWithdraw > 0) {
            // Update totalStaked *before* setting user's stakedAmount to 0.
            // This is crucial for the integrity of reward calculations for other users if _updateGlobalRewardState
            // were to be called again before this function fully completes in a complex scenario.
            totalStaked = totalStaked - amountToWithdraw;

            user.stakedAmount = 0;
            // Since rewards are forfeited, update user's rewardsPaidPerToken to the current global state.
            // This prevents them from claiming rewards for the period they were staked if they re-stake later.
            user.rewardsPaidPerToken = rewardPerTokenStored; 

            // Cancel any active withdrawal request
            if (withdrawalRequests[msg.sender].amount > 0) {
                delete withdrawalRequests[msg.sender];
                emit WithdrawalCancelled(msg.sender);
            }
            
            stakeToken.transfer(msg.sender, amountToWithdraw);
            emit EmergencyWithdraw(msg.sender, amountToWithdraw);
        }
    }

    // --- Public Staking and Withdrawal Functions ---

    /**
     * @notice Allows a user to stake tokens.
     * @dev Rewards are automatically compounded before the new stake is added.
     * The user must have approved the contract to spend their tokens.
     * A user cannot stake if they have a pending withdrawal request.
     * @param _amount The amount of tokens to stake.
     * @custom:reentrant Prevents reentrancy attacks.
     * 
     * updateReward Updates rewards for `msg.sender` before processing the stake.
     */
    function stake(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "AdvancedERC20Staking: Cannot stake 0");
        require(withdrawalRequests[msg.sender].amount == 0, "AdvancedERC20Staking: Complete or cancel pending withdrawal first");

        UserInfo storage user = userInfo[msg.sender]; // UserInfo already updated by updateReward modifier
        
        // The contract must have an allowance from msg.sender to transferFrom
        stakeToken.transferFrom(msg.sender, address(this), _amount);
        
        // Update user's staked amount and the total staked in the contract
        user.stakedAmount = user.stakedAmount + _amount;
        totalStaked = totalStaked + _amount;
        
        // user.rewardsPaidPerToken is already updated by the _compoundRewardsForUser call
        // within the updateReward modifier, reflecting the compounding of previous rewards.
        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Allows a user to request a withdrawal of their staked tokens.
     * @dev This initiates a cooldown period. Rewards are compounded before the request.
     * A user cannot request a new withdrawal if one is already pending.
     * @param _amount The amount of tokens to request for withdrawal.
     * @custom:reentrant Prevents reentrancy attacks.
     * 
     * updateReward Updates rewards for `msg.sender` before processing the request.
     */
    function requestWithdrawal(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "AdvancedERC20Staking: Cannot request withdrawal of 0");
        UserInfo storage user = userInfo[msg.sender]; // UserInfo already updated
        require(user.stakedAmount >= _amount, "AdvancedERC20Staking: Insufficient staked balance");
        require(withdrawalRequests[msg.sender].amount == 0, "AdvancedERC20Staking: Withdrawal request already pending");

        withdrawalRequests[msg.sender] = WithdrawalRequest(_amount, block.timestamp);
        emit WithdrawalRequested(msg.sender, _amount, block.timestamp);
    }

    /**
     * @notice Allows a user to cancel their active withdrawal request.
     * @custom:reentrant Prevents reentrancy attacks.
     */
    function cancelWithdrawalRequest() external nonReentrant {
        WithdrawalRequest storage request = withdrawalRequests[msg.sender];
        require(request.amount > 0, "AdvancedERC20Staking: No active withdrawal request");
        delete withdrawalRequests[msg.sender]; // Clears the struct
        emit WithdrawalCancelled(msg.sender);
    }

    /**
     * @notice Allows a user to withdraw their tokens after the cooldown period has passed.
     * @dev Rewards are automatically compounded before the withdrawal.
     * The pending withdrawal request is cleared.
     * @custom:reentrant Prevents reentrancy attacks.
     * 
     * updateReward Updates rewards for `msg.sender` before processing the withdrawal.
     */
    function withdraw() external nonReentrant updateReward(msg.sender) {
        WithdrawalRequest storage request = withdrawalRequests[msg.sender];
        require(request.amount > 0, "AdvancedERC20Staking: No withdrawal request pending");
        require(block.timestamp >= request.requestTime + COOLDOWN_PERIOD, "AdvancedERC20Staking: Cooldown period not over");

        UserInfo storage user = userInfo[msg.sender]; // UserInfo already updated
        uint256 amountToWithdraw = request.amount;

        // This check is important as stakedAmount might have changed due to compounding
        // since the requestWithdrawal call.
        require(user.stakedAmount >= amountToWithdraw, "AdvancedERC20Staking: Staked balance less than requested withdrawal after compounding");

        // Update user's staked amount and the total staked
        user.stakedAmount = user.stakedAmount - amountToWithdraw;
        totalStaked = totalStaked - amountToWithdraw;
        
        delete withdrawalRequests[msg.sender]; // Clear the request
        
        // user.rewardsPaidPerToken is already updated by the _compoundRewardsForUser.
        stakeToken.transfer(msg.sender, amountToWithdraw);
        emit Withdrawn(msg.sender, amountToWithdraw);
    }

    // --- Internal Reward Calculation Functions ---

    /**
     * @dev Updates the global `rewardPerTokenStored` and `lastUpdateTime`.
     * This function calculates how many rewards have accrued globally since the last update
     * and distributes them proportionally per staked token/share.
     * It should be called before any operation that depends on an up-to-date reward state
     * or changes `totalStaked`.
     */
    function _updateGlobalRewardState() internal {
        // If no tokens are staked, no rewards can be distributed per token.
        // Simply update the lastUpdateTime to the current block timestamp.
        if (totalStaked == 0) {
            lastUpdateTime = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        if (timeElapsed > 0) {
            // Calculate total rewards accrued for the entire pool during the elapsed time
            uint256 totalAccruedRewards = timeElapsed * rewardRate;
            // Distribute these rewards per share (token staked), scaled by PRECISION_FACTOR
            rewardPerTokenStored = rewardPerTokenStored + (totalAccruedRewards * PRECISION_FACTOR / totalStaked);
        }
        // Update the last global update time to the current block timestamp
        lastUpdateTime = block.timestamp;
    }

    /**
     * @dev Calculates the amount of pending rewards for a specific user.
     * This is a view-like calculation that doesn't change state but considers rewards up to `block.timestamp`.
     * @param _account The address of the user.
     * @return The amount of pending rewards for the user.
     */
    function _calculatePendingRewards(address _account) internal view returns (uint256) {
        UserInfo storage user = userInfo[_account];
        // Start with the last globally stored rewardPerToken value
        uint256 currentRewardPerTokenSnapshot = rewardPerTokenStored;

        // If time has passed since the last global update, calculate what rewardPerTokenStored *would be* now.
        // This is done for the calculation without actually modifying the global state variable here.
        if (totalStaked > 0 && block.timestamp > lastUpdateTime) {
             uint256 timeElapsed = block.timestamp - lastUpdateTime;
             uint256 totalAccruedRewardsFromElapsed = timeElapsed * rewardRate;
             currentRewardPerTokenSnapshot = currentRewardPerTokenSnapshot + (totalAccruedRewardsFromElapsed * PRECISION_FACTOR / totalStaked);
        }
        
        // If, due to some edge case (e.g., reward rate becoming negative or large fluctuations),
        // the current rewards per token is less than what the user has already accounted for,
        // then pending rewards are zero. This prevents underflow.
        if (currentRewardPerTokenSnapshot < user.rewardsPaidPerToken) {
            return 0;
        }

        // Pending rewards = (user's_stake * current_rewards_per_token) - rewards_already_accounted_for_by_user
        // All scaled by PRECISION_FACTOR.
        return (user.stakedAmount * (currentRewardPerTokenSnapshot - user.rewardsPaidPerToken)) / PRECISION_FACTOR;
    }

    /**
     * @dev Compounds a user's pending rewards into their `stakedAmount`.
     * @dev It assumes `_updateGlobalRewardState()` has already been called, so `rewardPerTokenStored` is current.
     * @param _account The address of the user.
     */
    function _compoundRewardsForUser(address _account) internal {
        // Calculate pending rewards based on the (now current) rewardPerTokenStored.
        uint256 pendingRewards = _calculatePendingRewards(_account);

        if (pendingRewards > 0) {
            UserInfo storage user = userInfo[_account]; // Access storage only if rewards exist
            // Add pending rewards to the user's staked amount
            user.stakedAmount = user.stakedAmount + pendingRewards;
            // Add these compounded rewards to the total staked in the contract
            totalStaked = totalStaked + pendingRewards; 
            emit RewardsCompounded(_account, pendingRewards);
        }
        // Always update the user's rewardsPaidPerToken to the current global rewardPerTokenStored.
        // This marks that all rewards up to this point have been accounted for (either compounded or were zero).
        userInfo[_account].rewardsPaidPerToken = rewardPerTokenStored; 
    }
    
    // --- View Functions ---

    /**
     * @notice Returns the amount of tokens staked by a user, including compounded rewards.
     * @param _account The address of the user.
     * @return The user's total staked balance.
     */
    function balanceOf(address _account) external view returns (uint256) {
        return userInfo[_account].stakedAmount;
    }

    /**
     * @notice Returns the amount of rewards pending compounding for a user.
     * @dev These rewards will be automatically compounded upon the user's next
     * interaction (stake, requestWithdrawal, withdraw).
     * @param _account The address of the user.
     * @return The amount of rewards pending for the user.
     */
    function getPendingRewards(address _account) external view returns (uint256) {
        // This public view function uses the internal _calculatePendingRewards,
        // which accurately computes rewards "on the fly" up to the current block.timestamp.
        return _calculatePendingRewards(_account);
    }

    /**
     * @notice Returns information about a user's active withdrawal request.
     * @param _account The address of the user.
     * @return amount The amount requested for withdrawal.
     * @return requestTime The timestamp of the withdrawal request.
     * @return withdrawAvailableTime The timestamp when the tokens will be available for withdrawal.
     *         Returns (0,0,0) if no active request.
     */
    function getWithdrawalRequestInfo(address _account) external view returns (uint256 amount, uint256 requestTime, uint256 withdrawAvailableTime) {
        WithdrawalRequest storage request = withdrawalRequests[_account];
        if (request.amount == 0) {
            return (0, 0, 0); // No active request
        }
        return (request.amount, request.requestTime, request.requestTime + COOLDOWN_PERIOD);
    }

    /**
     * @notice Returns the address of the token being staked.
     * @return The ERC20 token address.
     */
    function getStakeTokenAddress() external view returns (address) {
        return address(stakeToken);
    }

    /**
     * @notice Returns the current reward rate per second for the entire pool.
     * @return The current reward rate.
     */
    function getCurrentRewardRate() external view returns (uint256) {
        return rewardRate;
    }

    /**
     * @notice Returns the total amount of tokens staked in the contract by all users.
     * @return The total staked tokens.
     */
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    /**
     * @notice Calculates an approximate Annual Percentage Yield (APY) based on the current state.
     * @dev APY = ((Total Rewards Per Year / Total Staked) * 100).
     * This is an estimate and can fluctuate with `rewardRate` and `totalStaked`.
     * @return The APY, scaled by 100 (e.g., 525 means 5.25%). Returns 0 if no tokens are staked or no reward rate.
     */
    function getApproximateAPY() external view returns (uint256) {
        if (totalStaked == 0 || rewardRate == 0) {
            return 0;
        }
        uint256 secondsInYear = 365 days; // Solidity time unit
        uint256 yearlyRewardsFromRate = rewardRate * secondsInYear;
        
        // To return APY as a percentage multiplied by 100 (e.g., 5.25% as 525)
        // (yearlyRewardsFromRate * 100 * 100) / totalStaked, where the second 100 is for 2 decimal places.
        // So, (yearlyRewardsFromRate * 10000) / totalStaked
        return (yearlyRewardsFromRate * 10000) / totalStaked;
    }
}