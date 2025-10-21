# Advanced Token System with Staking & Rewards

A comprehensive Solidity smart contract system featuring two specialized token implementations: RewardToken with transfer fee mechanism and StakingToken with time-based reward distribution. Built and tested with Foundry.

## Features

### RewardToken
- Transfer Fee Mechanism: Configurable fee (0-10%) on all transfers
- Fee Collection: Automated fee collection to designated address
- Fee Tracking: Total collected fees monitoring

### StakingToken
- Staking System: Lock tokens to earn rewards
- Time-Based Rewards: Earn rewards per second based on staked amount
- Flexible Staking: Stake and unstake any amount at any time
- Reward Claims: Automatic reward calculation and claiming

### Base Features (Both Tokens)
- Ownable: Owner-controlled administrative functions
- Pausable: Emergency pause mechanism
- ERC20-like: Standard transfer, approve, and transferFrom functions
- Minting & Burning: Owner-controlled supply management

## Contract Architecture

```
Ownable (Base ownership control)
    ↓
Pausable (Emergency stop mechanism)
    ↓
Token (Abstract base with core ERC20 functionality)
    ↓
    ├── RewardToken (Fee-based transfers)
    └── StakingToken (Staking & rewards)
```

## Installation

### Prerequisites
- Foundry: https://book.getfoundry.sh/getting-started/installation
- Solidity ^0.8.30

### Setup

```bash
# Clone the repository
git clone https://github.com/KAMPUMDAL/token-staking-protocol.git
cd token-staking-protocol

# Install dependencies
forge install

# Build contracts
forge build
```

## Usage

### Deploying Contracts

```solidity
// Deploy RewardToken
RewardToken rewardToken = new RewardToken("Reward Token", "RWD", 1000000);

// Deploy StakingToken
StakingToken stakingToken = new StakingToken("Staking Token", "STK", 1000000);
```

### RewardToken Operations

```solidity
// Transfer with automatic fee deduction
rewardToken.transfer(recipient, 100 * 10**18);

// Set fee percentage (owner only)
rewardToken.setFeePercent(5); // 5% fee

// Change fee collector (owner only)
rewardToken.setFeeCollector(newCollectorAddress);

// Check collected fees
uint256 fees = rewardToken.totalCollectedFees();
```

### StakingToken Operations

```solidity
// Stake tokens
stakingToken.stake(100 * 10**18);

// Check stake information
(uint256 amount, uint256 duration, uint256 pending, uint256 claimed) = 
    stakingToken.getStakeInfo(userAddress);

// Claim rewards
stakingToken.claimReward();

// Unstake tokens
stakingToken.unstake(50 * 10**18);

// Set reward rate (owner only)
stakingToken.setRewardPerSecond(2);
```

## Testing

Run the test suite using Foundry:

```bash
# Run all tests
forge test

# Run tests with verbosity
forge test -vv

# Run specific test
forge test --match-test test_RewardTokenTransfer

# Run tests with gas reporting
forge test --gas-report
```

### Test Coverage

Basic test suite covering core functionality:
- Token transfers with fee calculation
- Fee percentage configuration
- Staking and unstaking operations
- Reward calculation over time
- Pause/unpause functionality
- Access control and error handling

## Contract Details

### RewardToken

| Function | Description | Access |
|----------|-------------|--------|
| transfer | Transfer tokens with automatic fee deduction | Public |
| setFeePercent | Set transfer fee (0-10%) | Owner |
| setFeeCollector | Set fee collection address | Owner |
| totalCollectedFees | View total collected fees | Public |

Fee Calculation: fee = (amount * feePercent) / 100

### StakingToken

| Function | Description | Access |
|----------|-------------|--------|
| stake | Stake tokens to earn rewards | Public |
| unstake | Unstake tokens and claim rewards | Public |
| claimReward | Claim pending rewards | Public |
| calculateReward | View pending rewards | Public |
| getStakeInfo | Get complete stake information | Public |
| setRewardPerSecond | Set reward rate (1-100) | Owner |

Reward Calculation: reward = (duration * rewardPerSecond * stakedAmount) / 1e18

## Security Features

- Ownership Control: Critical functions restricted to contract owner
- Zero Address Checks: Prevents transfers to zero address
- Balance Validation: Ensures sufficient balance before operations
- Pausable Mechanism: Emergency stop for transfers
- Allowance System: Secure delegated transfers
- Fee Limits: Maximum 10% transfer fee cap
- Reward Rate Limits: Bounded reward rates (1-100)

## Token Specifications

| Property | Value |
|----------|-------|
| Decimals | 18 |
| Initial Supply | Configurable (e.g., 1,000,000 tokens) |
| Solidity Version | ^0.8.30 |
| License | MIT |

## Development

### Project Structure

```
├── src/
│   └── Token.sol          # Main contract file
├── test/
│   └── Token.t.sol        # Test suite
├── foundry.toml           # Foundry configuration
└── README.md
```

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Contact

For questions or suggestions, please open an issue in the repository.

---

Built with Foundry

Note: This is a demonstration project for learning purposes. Always conduct thorough audits before deploying smart contracts to production.
