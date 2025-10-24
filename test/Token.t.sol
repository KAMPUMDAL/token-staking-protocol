// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract OwnableTest is Test {
    RewardToken public token;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        token = new RewardToken("Test Token", "TEST", 1000000);
    }

    function testOwnerIsDeployer() public view{
        assertEq(token.owner(), owner);
    }

    function testTransferOwnership() public {
        token.transferOwnership(user1);
        assertEq(token.owner(), user1);
    }

    function testTransferOwnershipToZeroAddress() public {
        vm.expectRevert("New owner cannot be zero address");
        token.transferOwnership(address(0));
    }

    function testOnlyOwnerCanTransferOwnership() public {
        vm.prank(user1);
        vm.expectRevert("You are not owner");
        token.transferOwnership(user2);
    }
}

contract PausableTest is Test {
    RewardToken public token;
    address public owner;
    address public user1;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        
        token = new RewardToken("Test Token", "TEST", 1000000);
        token.transfer(user1, 1000 * 10**18);
    }

    function testInitiallyNotPaused() public view{
        assertFalse(token.paused());
    }

    function testOwnerCanPause() public {
        token.pause();
        assertTrue(token.paused());
    }

    function testOwnerCanUnpause() public {
        token.pause();
        token.unpause();
        assertFalse(token.paused());
    }

    function testOnlyOwnerCanPause() public {
        vm.prank(user1);
        vm.expectRevert("You are not owner");
        token.pause();
    }

    function testOnlyOwnerCanUnpause() public {
        token.pause();
        vm.prank(user1);
        vm.expectRevert("You are not owner");
        token.unpause();
    }

    function testCannotPauseWhenAlreadyPaused() public {
        token.pause();
        vm.expectRevert("Contract is paused");
        token.pause();
    }

    function testCannotUnpauseWhenNotPaused() public {
        vm.expectRevert("Contract is not paused");
        token.unpause();
    }

    function testTransferFailsWhenPaused() public {
        token.pause();
        vm.prank(user1);
        vm.expectRevert("Contract is paused");
        token.transfer(owner, 100 * 10**18);
    }

    function testMintFailsWhenPaused() public {
        token.pause();
        vm.expectRevert("Contract is paused");
        token.mint(user1, 1000 * 10**18);
    }
}

contract TokenTest is Test {
    RewardToken public token;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        token = new RewardToken("Test Token", "TEST", 1000000);
    }

    function testInitialSupply() public view{
        assertEq(token.totalSupply(), 1000000 * 10**18);
        assertEq(token.balanceOf(owner), 1000000 * 10**18);
    }

    function testTokenMetadata() public view {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
    }

    function testGetBalance() public view {
        assertEq(token.getBalance(), 1000000 * 10**18);
    }

    function testBalanceOf() public view {
        assertEq(token.balanceOf(owner), 1000000 * 10**18);
        assertEq(token.balanceOf(user1), 0);
    }

    function testTransfer() public {
        uint256 amount = 1000 * 10**18;
        token.transfer(user1, amount);
        
        assertEq(token.balanceOf(user1), amount * 98 / 100);
    }

    function testTransferEmitsEvent() public {
        uint256 amount = 1000 * 10**18;
        uint256 afterFee = amount * 98 / 100;
        uint256 fee = amount - afterFee;
        
        vm.expectEmit(true, true, false, true);
        emit Token.Transfer(owner, user1, afterFee);
        
        vm.expectEmit(true, true, false, true);
        emit Token.Transfer(owner, owner, fee);
        
        token.transfer(user1, amount);
    }

    function testTransferFailsToZeroAddress() public {
        vm.expectRevert("Cannot transfer to zero address");
        token.transfer(address(0), 1000 * 10**18);
    }

    function testTransferFailsInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        token.transfer(user2, 1000 * 10**18);
    }

    function testApprove() public {
        uint256 amount = 1000 * 10**18;
        token.approve(user1, amount);
        assertEq(token.allowance(owner, user1), amount);
    }

    function testApproveEmitsEvent() public {
        uint256 amount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Token.Approve(owner, user1, amount);
        
        token.approve(user1, amount);
    }

    function testTransferFrom() public {
        uint256 approveAmount = 1000 * 10**18;
        uint256 transferAmount = 500 * 10**18;
        
        token.approve(user1, approveAmount);
        
        vm.prank(user1);
        token.transferFrom(owner, user2, transferAmount);
        
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(owner, user1), approveAmount - transferAmount);
    }

    function testTransferFromFailsExceedsAllowance() public {
        uint256 approveAmount = 500 * 10**18;
        uint256 transferAmount = 1000 * 10**18;
        
        token.approve(user1, approveAmount);
        
        vm.prank(user1);
        vm.expectRevert("Allowance exceeded");
        token.transferFrom(owner, user2, transferAmount);
    }

    function testTransferFromFailsInsufficientBalance() public {
        vm.prank(user1);
        token.approve(user2, 1000 * 10**18);
        
        vm.prank(user2);
        vm.expectRevert("Insufficient balance");
        token.transferFrom(user1, owner, 100 * 10**18);
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 10**18;
        uint256 initialSupply = token.totalSupply();
        
        token.mint(user1, mintAmount);
        
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), initialSupply + mintAmount);
    }

    function testMintEmitsEvents() public {
        uint256 amount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Token.Mint(user1, amount);
        
        vm.expectEmit(true, true, false, true);
        emit Token.Transfer(address(0), user1, amount);
        
        token.mint(user1, amount);
    }

    function testMintOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert("You are not owner");
        token.mint(user2, 1000 * 10**18);
    }

    function testMintFailsZeroAmount() public {
        vm.expectRevert("Amount must be greater than zero");
        token.mint(user1, 0);
    }

    function testMintFailsZeroAddress() public {
        vm.expectRevert("Cannot mint to zero address");
        token.mint(address(0), 1000 * 10**18);
    }

    function testBurn() public {
        uint256 burnAmount = 1000 * 10**18;
        uint256 initialSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(owner);
        
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(owner), initialBalance - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }

    function testBurnEmitsEvents() public {
        uint256 amount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Token.Burn(owner, amount);
        
        vm.expectEmit(true, true, false, true);
        emit Token.Transfer(owner, address(0), amount);
        
        token.burn(amount);
    }

    function testBurnOnlyOwner() public {
        token.transfer(user1, 1000 * 10**18);
        
        vm.prank(user1);
        vm.expectRevert("You are not owner");
        token.burn(100 * 10**18);
    }

    function testBurnFailsInsufficientBalance() public {
        uint256 ownerBalance = token.balanceOf(owner);
        vm.expectRevert("Insufficient balance to burn");
        token.burn(ownerBalance + 1);
    }
}

contract RewardTokenTest is Test {
    RewardToken public token;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        token = new RewardToken("Reward Token", "RWD", 1000000);
    }

    function testGetTokenType() public view {
        assertEq(token.getTokenType(), "Reward Token");
    }

    function testInitialFeePercent() public view{
        assertEq(token.transferFeePercent(), 2);
    }

    function testInitialFeeCollector() public view  {
        assertEq(token.feeCollector(), owner);
    }

    function testTransferWithFee() public {
        uint256 amount = 1000 * 10**18;
        uint256 fee = (amount * 2) / 100; 
        uint256 amountAfterFee = amount - fee;
        
        token.transfer(user1, amount);
        
        assertEq(token.balanceOf(user1), amountAfterFee);
        assertEq(token.balanceOf(owner), token.totalSupply() - amountAfterFee - fee + fee);
        assertEq(token.totalCollectedFees(), fee);
    }

    function testSetFeePercent() public {
        token.setFeePercent(5);
        assertEq(token.transferFeePercent(), 5);
        
        uint256 amount = 1000 * 10**18;
        uint256 fee = (amount * 5) / 100;
        uint256 amountAfterFee = amount - fee;
        
        token.transfer(user1, amount);
        assertEq(token.balanceOf(user1), amountAfterFee);
    }

    function testSetFeePercentMaxLimit() public {
        vm.expectRevert("Fee cannot exceed 10%");
        token.setFeePercent(11);
    }

    function testSetFeePercentOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert("You are not owner");
        token.setFeePercent(5);
    }

    function testSetFeeCollector() public {
        token.setFeeCollector(user1);
        assertEq(token.feeCollector(), user1);
        
        uint256 amount = 1000 * 10**18;
        uint256 fee = (amount * 2) / 100;
        
        token.transfer(user2, amount);
        assertEq(token.balanceOf(user1), fee);
    }

    function testSetFeeCollectorZeroAddress() public {
        vm.expectRevert("Cannot set zero address as fee collector");
        token.setFeeCollector(address(0));
    }

    function testSetFeeCollectorOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert("You are not owner");
        token.setFeeCollector(user2);
    }

    function testTotalCollectedFees() public {
        uint256 amount = 1000 * 10**18;
        uint256 expectedFee = (amount * 2) / 100;
        
        token.transfer(user1, amount);
        assertEq(token.totalCollectedFees(), expectedFee);
        
        token.transfer(user2, amount);
        assertEq(token.totalCollectedFees(), expectedFee * 2);
    }
}

contract StakingTokenTest is Test {
    StakingToken public token;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        token = new StakingToken("Staking Token", "STK", 1000000);
        
        token.transfer(user1, 10000 * 10**18);
        token.transfer(user2, 10000 * 10**18);
    }

    function testGetTokenType() public view {
        assertEq(token.getTokenType(), "Staking Token");
    }

    function testInitialRewardRate() public view {
        assertEq(token.rewardPerSecond(), 1);
    }

    function testStake() public {
        uint256 stakeAmount = 1000 * 10**18;
        uint256 initialBalance = token.balanceOf(user1);
        
        vm.prank(user1);
        token.stake(stakeAmount);
        
        assertEq(token.balanceOf(user1), initialBalance - stakeAmount);
        assertEq(token.totalStaked(), stakeAmount);
        
        (uint256 amount, , ,) = token.getStakeInfo(user1);
        assertEq(amount, stakeAmount);
    }

    function testStakeEmitsEvent() public {
        uint256 amount = 1000 * 10**18;
        
        vm.expectEmit(true, false, false, true);
        emit StakingToken.Staked(user1, amount);
        
        vm.prank(user1);
        token.stake(amount);
    }

    function testStakeFailsZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than zero");
        token.stake(0);
    }

    function testStakeFailsInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        token.stake(20000 * 10**18);
    }

    function testMultipleStakes() public {
        vm.startPrank(user1);
        
        token.stake(1000 * 10**18);
        vm.warp(block.timestamp + 100);
        token.stake(500 * 10**18);
        
        vm.stopPrank();
        
        (uint256 amount, , ,) = token.getStakeInfo(user1);
        assertEq(amount, 1500 * 10**18);
    }

    function testCalculateReward() public {
        uint256 stakeAmount = 1000 * 10**18;
        
        vm.prank(user1);
        token.stake(stakeAmount);
        
        vm.warp(block.timestamp + 100);
        
        uint256 reward = token.calculateReward(user1);
        uint256 expectedReward = (100 * 1 * stakeAmount) / 1e18;
        
        assertEq(reward, expectedReward);
    }

    function testCalculateRewardNoStake() public view {
        uint256 reward = token.calculateReward(user1);
        assertEq(reward, 0);
    }

    function testClaimReward() public {
        uint256 stakeAmount = 1000 * 10**18;
        
        vm.startPrank(user1);
        token.stake(stakeAmount);
        
        vm.warp(block.timestamp + 100);
        
        uint256 balanceBefore = token.balanceOf(user1);
        uint256 expectedReward = token.calculateReward(user1);
        
        token.claimReward();
        
        uint256 balanceAfter = token.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, expectedReward);
        
        vm.stopPrank();
    }

    function testClaimRewardEmitsEvents() public {
        uint256 stakeAmount = 1000 * 10**18;
        
        vm.startPrank(user1);
        token.stake(stakeAmount);
        vm.warp(block.timestamp + 100);
        
        uint256 expectedReward = token.calculateReward(user1);
        
        vm.expectEmit(true, true, false, true);
        emit StakingToken.RewardClaimed(user1, expectedReward);
        
        token.claimReward();
        vm.stopPrank();
    }

    function testClaimRewardFailsNoRewards() public {
        vm.prank(user1);
        vm.expectRevert("No rewards to claim");
        token.claimReward();
    }

    function testUnstake() public {
        uint256 stakeAmount = 1000 * 10**18;
        uint256 unstakeAmount = 500 * 10**18;
        
        vm.startPrank(user1);
        token.stake(stakeAmount);
        
        vm.warp(block.timestamp + 100);
        
        uint256 balanceBefore = token.balanceOf(user1);
        token.unstake(unstakeAmount);
        
        uint256 balanceAfter = token.balanceOf(user1);
        assertGt(balanceAfter, balanceBefore + unstakeAmount); 
        
        (uint256 amount, , ,) = token.getStakeInfo(user1);
        assertEq(amount, stakeAmount - unstakeAmount);
        
        vm.stopPrank();
    }

    function testUnstakeEmitsEvent() public {
        uint256 amount = 1000 * 10**18;
        
        vm.startPrank(user1);
        token.stake(amount);

                vm.warp(block.timestamp + 100);

        
        vm.expectEmit(true, false, false, true);
        emit StakingToken.Unstaked(user1, amount);
        
        token.unstake(amount);
        vm.stopPrank();
    }

    function testUnstakeAll() public {
        uint256 stakeAmount = 1000 * 10**18;
        
        vm.startPrank(user1);
        token.stake(stakeAmount);
        
        vm.warp(block.timestamp + 100);
        
        token.unstake(stakeAmount);
        
        (uint256 amount, , ,) = token.getStakeInfo(user1);
        assertEq(amount, 0);
        assertEq(token.totalStaked(), 0);
        
        vm.stopPrank();
    }

    function testUnstakeFailsInsufficientStake() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient staked amount");
        token.unstake(1000 * 10**18);
    }

    function testGetStakeInfo() public {
        uint256 stakeAmount = 1000 * 10**18;
        
        vm.startPrank(user1);
        token.stake(stakeAmount);
        
        vm.warp(block.timestamp + 100);
        
        (uint256 amount, uint256 duration, uint256 pendingReward, uint256 totalClaimed) = 
            token.getStakeInfo(user1);
        
        assertEq(amount, stakeAmount);
        assertEq(duration, 100);
        assertGt(pendingReward, 0);
        assertEq(totalClaimed, 0);
        
        vm.stopPrank();
    }

    function testSetRewardPerSecond() public {
        token.setRewardPerSecond(10);
        assertEq(token.rewardPerSecond(), 10);
    }

    function testSetRewardPerSecondOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert("You are not owner");
        token.setRewardPerSecond(10);
    }

    function testSetRewardPerSecondLimits() public {
        vm.expectRevert("Rate must be between 1-100");
        token.setRewardPerSecond(0);
        
        vm.expectRevert("Rate must be between 1-100");
        token.setRewardPerSecond(101);
    }

    function testMultipleUsersStaking() public {
        vm.prank(user1);
        token.stake(1000 * 10**18);
        
        vm.prank(user2);
        token.stake(2000 * 10**18);
        
        assertEq(token.totalStaked(), 3000 * 10**18);
        
        vm.warp(block.timestamp + 100);
        
        uint256 reward1 = token.calculateReward(user1);
        uint256 reward2 = token.calculateReward(user2);
        
        assertGt(reward2, reward1); 
    }

    function testRewardAccrualOverTime() public {
        uint256 stakeAmount = 1000 * 10**18;
        
        vm.prank(user1);
        token.stake(stakeAmount);
        
        vm.warp(block.timestamp + 100);
        uint256 reward100 = token.calculateReward(user1);
        
        vm.warp(block.timestamp + 100);
        uint256 reward200 = token.calculateReward(user1);
        
        assertGt(reward200, reward100);
        assertEq(reward200, reward100 * 2);
    }
}

contract FuzzTest is Test {
    RewardToken public rewardToken;
    StakingToken public stakingToken;
    address public owner;

    function setUp() public {
        owner = address(this);
        rewardToken = new RewardToken("Reward Token", "RWD", 1000000);
        stakingToken = new StakingToken("Staking Token", "STK", 1000000);
    }

    function testFuzzTransfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount > 0 && amount <= rewardToken.totalSupply());
        
        rewardToken.transfer(to, amount);
        
        uint256 fee = (amount * 2) / 100;
        uint256 amountAfterFee = amount - fee;
        
        assertEq(rewardToken.balanceOf(to), amountAfterFee);
    }

    function testFuzzMint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount > 0 && amount <= type(uint128).max);
        
        uint256 supplyBefore = rewardToken.totalSupply();
        rewardToken.mint(to, amount);
        
        assertEq(rewardToken.totalSupply(), supplyBefore + amount);
        assertEq(rewardToken.balanceOf(to), amount);
    }

    function testFuzzStake(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 10000 * 10**18);
        
        stakingToken.transfer(owner, amount);
        stakingToken.stake(amount);
        
        (uint256 staked, , ,) = stakingToken.getStakeInfo(owner);
        assertEq(staked, amount);
    }

    function testFuzzRewardCalculation(uint256 stakeAmount, uint256 timeElapsed) public {
        vm.assume(stakeAmount > 0 && stakeAmount <= 10000 * 10**18);
        vm.assume(timeElapsed > 0 && timeElapsed <= 365 days);
        
        stakingToken.transfer(owner, stakeAmount);
        stakingToken.stake(stakeAmount);
        
        vm.warp(block.timestamp + timeElapsed);
        
        uint256 reward = stakingToken.calculateReward(owner);
        uint256 expectedReward = (timeElapsed * 1 * stakeAmount) / 1e18;
        
        assertEq(reward, expectedReward);
    }
}
