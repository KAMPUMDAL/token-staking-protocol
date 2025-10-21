// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TokenTest is Test {
    RewardToken public rewardToken;
    StakingToken public stakingToken;
    
    address owner = address(this);
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        
        rewardToken = new RewardToken("Reward", "RWD", 1000000);
        stakingToken = new StakingToken("Staking", "STK", 1000000);
        
        
        rewardToken.transfer(alice, 1000 * 10**18);
        stakingToken.transfer(alice, 1000 * 10**18);
    }

    
   function test_RewardTokenTransfer() public {
    uint256 feesBeforeTest = rewardToken.totalCollectedFees();
    
    vm.prank(alice);
    rewardToken.transfer(bob, 100 * 10**18);
    
    assertEq(rewardToken.balanceOf(bob), 98 * 10**18);
    
    uint256 newFees = rewardToken.totalCollectedFees() - feesBeforeTest;
    assertEq(newFees, 2 * 10**18);
}

    function test_SetFeePercent() public {
        rewardToken.setFeePercent(5);
        assertEq(rewardToken.transferFeePercent(), 5);
    }

    
    
    function test_Stake() public {
        vm.prank(alice);
        stakingToken.stake(100 * 10**18);
        
        (uint256 amount,,,) = stakingToken.getStakeInfo(alice);
        assertEq(amount, 100 * 10**18);
        assertEq(stakingToken.totalStaked(), 100 * 10**18);
    }

    function test_UnstakeAfterTime() public {
        vm.startPrank(alice);
        
        stakingToken.stake(100 * 10**18);
        
        
        vm.warp(block.timestamp + 1 days);
        
        stakingToken.unstake(50 * 10**18);
        
        vm.stopPrank();
        
        (uint256 amount,,,) = stakingToken.getStakeInfo(alice);
        assertEq(amount, 50 * 10**18);
    }

    function test_RewardCalculation() public {
        vm.startPrank(alice);
        
        stakingToken.stake(100 * 10**18);
        
        
        vm.warp(block.timestamp + 100);
        
        uint256 reward = stakingToken.calculateReward(alice);
        assertGt(reward, 0); 
        
        vm.stopPrank();
    }

    
    function test_PauseUnpause() public {
        rewardToken.pause();
        assertTrue(rewardToken.paused());
        
        rewardToken.unpause();
        assertFalse(rewardToken.paused());
    }

    function test_TransferWhenPaused() public {
    rewardToken.pause();
    
    vm.expectRevert("Contract is paused");
    vm.prank(alice);
    rewardToken.transfer(bob, 100 * 10**18);
}
    }
