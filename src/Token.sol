//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier OnlyOwner() {
        require(owner == msg.sender, "You are not owner");
        _;
    }

    function transferOwnership(address newOwner) public OnlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    bool public paused;

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    function pause() public OnlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public OnlyOwner whenPaused {
        paused = false;
    }
}

abstract contract Token is Ownable, Pausable {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public decimals;

    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public allowance; 

    event Mint(address indexed owner, uint256 indexed amount);
    event Burn(address indexed owner, uint256 indexed amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approve(address indexed from, address indexed spender, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint256 initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = 18; 
        totalSupply = initialSupply * 10**decimals; 
        balance[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function getTokenType() public pure virtual returns (string memory);

    function getBalance() public view returns (uint256) {
        return balance[msg.sender];
    }

    function balanceOf(address account) public view returns (uint256) {
        return balance[account];
    }

    function mint(address to, uint256 amount) public OnlyOwner whenNotPaused returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(to != address(0), "Cannot mint to zero address");
        
        balance[to] += amount;
        totalSupply += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount; 
        emit Approve(msg.sender, spender, amount);
        return true;
    }

    
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(amount <= allowance[from][msg.sender], "Allowance exceeded");
        require(amount <= balance[from], "Insufficient balance");
        
        allowance[from][msg.sender] -= amount;
        balance[from] -= amount;
        balance[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual whenNotPaused returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(amount <= balance[msg.sender], "Insufficient balance");
        
        balance[msg.sender] -= amount;
        balance[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function burn(uint256 amount) public OnlyOwner returns (bool) {
        require(amount <= balance[msg.sender], "Insufficient balance to burn");
        
        balance[msg.sender] -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }
}

contract RewardToken is Token {
    uint256 public transferFeePercent = 2;
    address public feeCollector;
    uint256 public totalCollectedFees;

    constructor(string memory _name, string memory _symbol, uint256 initialSupply) 
        Token(_name, _symbol, initialSupply) 
    {
        feeCollector = msg.sender;
    }

    function getTokenType() public pure override returns (string memory) {
        return "Reward Token";
    }

    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(amount <= balance[msg.sender], "Insufficient balance");
        
        uint256 fee = (amount * transferFeePercent) / 100;
        uint256 amountAfterFee = amount - fee;

        balance[msg.sender] -= amount;
        balance[to] += amountAfterFee;
        balance[feeCollector] += fee;
        totalCollectedFees += fee;

        emit Transfer(msg.sender, to, amountAfterFee);
        emit Transfer(msg.sender, feeCollector, fee);
        return true;
    }

    function setFeePercent(uint256 _feePercent) public OnlyOwner {
        require(_feePercent <= 10, "Fee cannot exceed 10%");
        transferFeePercent = _feePercent;
    }

    function setFeeCollector(address newCollector) public OnlyOwner {
        require(newCollector != address(0), "Cannot set zero address as fee collector");
        feeCollector = newCollector;
    }
}

contract StakingToken is Token {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 rewardClaimed;
    }

    uint256 public rewardPerSecond = 1;
    uint256 public totalStaked;

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(string memory _name, string memory _symbol, uint256 initialSupply) 
        Token(_name, _symbol, initialSupply) 
    {}

    function getTokenType() public pure override returns (string memory) {
        return "Staking Token";
    }

    function calculateReward(address staker) public view returns (uint256) {
        Stake memory userStake = stakes[staker];
        if (userStake.amount == 0) {
            return 0;
        }
        uint256 stakingDuration = block.timestamp - userStake.startTime;
        uint256 rewards = (stakingDuration * rewardPerSecond * userStake.amount) / 1e18;
        return rewards;
    }

    function claimReward() public {
        uint256 rewards = calculateReward(msg.sender);
        require(rewards > 0, "No rewards to claim");
        
        totalSupply += rewards;
        balance[msg.sender] += rewards;
        stakes[msg.sender].rewardClaimed += rewards;
        stakes[msg.sender].startTime = block.timestamp;

        emit RewardClaimed(msg.sender, rewards);
        emit Mint(msg.sender, rewards);
        emit Transfer(address(0), msg.sender, rewards);
    }

    function stake(uint256 amount) public {
        require(amount <= balance[msg.sender], "Insufficient balance"); 
        require(amount > 0, "Amount must be greater than zero");

        if (stakes[msg.sender].amount > 0) {
            claimReward();
        }

        balance[msg.sender] -= amount;
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].startTime = block.timestamp;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        require(stakes[msg.sender].amount >= amount, "Insufficient staked amount");

        claimReward();

        stakes[msg.sender].amount -= amount;
        balance[msg.sender] += amount;
        totalStaked -= amount;

        if (stakes[msg.sender].amount == 0) {
            delete stakes[msg.sender];
        } else {
            stakes[msg.sender].startTime = block.timestamp;
        }

        emit Unstaked(msg.sender, amount);
    }

    function getStakeInfo(address staker) 
        public 
        view 
        returns (
            uint256 amount, 
            uint256 duration, 
            uint256 pendingReward, 
            uint256 totalClaimed
        ) 
    {
        Stake memory userStake = stakes[staker];
        return (
            userStake.amount,
            block.timestamp - userStake.startTime,
            calculateReward(staker),
            userStake.rewardClaimed
        );
    }

    function setRewardPerSecond(uint256 newRate) public OnlyOwner {
        require(newRate > 0 && newRate <= 100, "Rate must be between 1-100"); 
        rewardPerSecond = newRate;
    }
}