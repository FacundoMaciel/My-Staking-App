// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test {
    StakingApp stakingApp;
    StakingToken stakingToken;

    // Token parameters
    string name_ = "Staking Token";
    string symbol_ = "STK";

    // App parameters
    address owner_ = vm.addr(1);
    uint256 stakingPerdiod_ = 1 days;
    uint256 fixedStakingAmount_ = 10 ether;
    uint256 rewardPerPeriod_ = 1 ether;

    // User
    address randomUser_ = vm.addr(2);

    // Setup function to deploy the contracts before each test
    function setUp() public {
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp =
            new StakingApp(address(stakingToken), owner_, stakingPerdiod_, fixedStakingAmount_, rewardPerPeriod_);
    }

    // Test cases
    function testStakingTokenCorrectlyDeployed() external view {
        assert(address(stakingToken) != address(0));
    }

    function testStakingAppCorrectlyDeployed() external view {
        assert(address(stakingApp) != address(0));
    }

    function testShowRevertIfNotOwner() external {
        uint256 newStakingPeriod_ = 1;

        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
    }

    function testShouldChangeStakingPeriod() external {
        vm.startPrank(owner_);
        uint256 newStakingPeriod_ = 1;

        uint256 stakingPeriodBefore_ = stakingApp.stakingPerdiod();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
        uint256 stakingPeriodAfter_ = stakingApp.stakingPerdiod();

        assert(stakingPeriodBefore_ != newStakingPeriod_);
        assert(stakingPeriodAfter_ == newStakingPeriod_);
        vm.stopPrank();
    }

    function testContractReceiveEtherCorrectly() external {
        vm.startPrank(owner_);
        vm.deal(owner_, 1 ether);

        uint256 etherValue_ = 1 ether;
        uint256 balanceBefore_ = address(stakingApp).balance;
        (bool success,) = address(stakingApp).call{value: etherValue_}("");
        uint256 balanceAfter_ = address(stakingApp).balance;
        require(success, "Failed to send");

        assert(balanceAfter_ - balanceBefore_ == etherValue_);

        vm.stopPrank();
    }

    function testIncorrectAmountShouldRevert() external {
        vm.startPrank(randomUser_);

        uint256 despositAmount = 1;
        vm.expectRevert("Only deposit fixed amount");
        stakingApp.deposit(despositAmount);

        vm.stopPrank();
    }

    // Test that a user can deposit the correct amount of tokens and that their balance and elapsed time are updated correctly
    function testDepositTokenCorrectly() external {
        vm.startPrank(randomUser_);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 balanceBefore = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodBefore = stakingApp.elapsedTime(randomUser_);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.deposit(tokenAmount);

        uint256 balanceAfter = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodAfter = stakingApp.elapsedTime(randomUser_);

        assert(balanceAfter - balanceBefore == tokenAmount);
        assert(elapsedPeriodBefore == 0);
        assert(elapsedPeriodAfter == block.timestamp);

        vm.stopPrank();
    }

    // Test that a user cannot deposit more than once and that their balance and elapsed time are not updated after the second deposit attempt
    function testuserCannotDepositThanOnce() external {
        vm.startPrank(randomUser_);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 balanceBefore = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodBefore = stakingApp.elapsedTime(randomUser_);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.deposit(tokenAmount);

        uint256 balanceAfter = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodAfter = stakingApp.elapsedTime(randomUser_);

        assert(balanceAfter - balanceBefore == tokenAmount);
        assert(elapsedPeriodBefore == 0);
        assert(elapsedPeriodAfter == block.timestamp);

        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        vm.expectRevert("Already deposited");
        stakingApp.deposit(tokenAmount);

        vm.stopPrank();
    }

    // Test that a user can only withdraw if their balance is greater than zero and that their balance is updated correctly after withdrawal
    function testCanOnlyWithdrawIfBalanceIsGreaterThanZero() external {
        vm.startPrank(randomUser_);

        uint256 balanceBefore = stakingApp.userBalance(randomUser_);
        stakingApp.withdraw();
        uint256 balanceAfter = stakingApp.userBalance(randomUser_);

        assert(balanceBefore == balanceAfter);

        vm.stopPrank();
    }

    // Test that a user can withdraw their staked tokens and that their balance is updated correctly after withdrawal
    function testWithdrawTokenCorrectly() external {
        vm.startPrank(randomUser_);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 balanceBefore = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodBefore = stakingApp.elapsedTime(randomUser_);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.deposit(tokenAmount);
        uint256 balanceAfter = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodAfter = stakingApp.elapsedTime(randomUser_);

        assert(balanceAfter - balanceBefore == tokenAmount);
        assert(elapsedPeriodBefore == 0);
        assert(elapsedPeriodAfter == block.timestamp);

        uint256 balanceBefore2 = IERC20(stakingToken).balanceOf(randomUser_);
        uint256 userBalanceInMapping = stakingApp.userBalance(randomUser_);
        stakingApp.withdraw();
        uint256 balanceAfter2 = IERC20(stakingToken).balanceOf(randomUser_);

        assert(balanceAfter2 == balanceBefore2 + userBalanceInMapping);
        vm.stopPrank();
    }

    // Test that a user cannot claim rewards if they are not currently staking and that the appropriate error message is returned
    function testCannotClaimIfNotStaking() external {
        vm.startPrank(randomUser_);

        vm.expectRevert("Not staking");
        stakingApp.claimReward();
        vm.stopPrank();
    }

    // Test that a user cannot claim rewards if the required staking period has not elapsed and that the appropriate error message is returned
    function testCannotClaimIfNotElapsedTime() external {
        vm.startPrank(randomUser_);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 balanceBefore = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodBefore = stakingApp.elapsedTime(randomUser_);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.deposit(tokenAmount);
        uint256 balanceAfter = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodAfter = stakingApp.elapsedTime(randomUser_);

        assert(balanceAfter - balanceBefore == tokenAmount);
        assert(elapsedPeriodBefore == 0);
        assert(elapsedPeriodAfter == block.timestamp);

        vm.expectRevert("Not yet claimable");
        stakingApp.claimReward();

        vm.stopPrank();
    }

    // Test that a user cannot claim rewards if the contract does not have enough Ether to pay the reward and that the appropriate error message is returned
    function testShouldRevertIfNotEther() external {
        vm.startPrank(randomUser_);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 balanceBefore = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodBefore = stakingApp.elapsedTime(randomUser_);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.deposit(tokenAmount);
        uint256 balanceAfter = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodAfter = stakingApp.elapsedTime(randomUser_);

        assert(balanceAfter - balanceBefore == tokenAmount);
        assert(elapsedPeriodBefore == 0);
        assert(elapsedPeriodAfter == block.timestamp);

        vm.warp(block.timestamp + stakingPerdiod_);
        vm.expectRevert("transfer failed");
        stakingApp.claimReward();

        vm.stopPrank();
    }

    // Test that a user can claim rewards correctly after the required staking period has elapsed and that their balance and elapsed time are updated correctly after claiming rewards
    function testCanClaimRewardsCorrectly() external {
        vm.startPrank(randomUser_);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 balanceBefore = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodBefore = stakingApp.elapsedTime(randomUser_);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.deposit(tokenAmount);
        uint256 balanceAfter = stakingApp.userBalance(randomUser_);
        uint256 elapsedPeriodAfter = stakingApp.elapsedTime(randomUser_);

        assert(balanceAfter - balanceBefore == tokenAmount);
        assert(elapsedPeriodBefore == 0);
        assert(elapsedPeriodAfter == block.timestamp);
        vm.stopPrank();

        vm.startPrank(owner_);
        uint256 etherAmount = 10000 ether;
        vm.deal(owner_, etherAmount);
        (bool success,) = address(stakingApp).call{value: etherAmount}("");
        require(success, "Test transfer failed");
        vm.stopPrank();

        vm.startPrank(randomUser_);
        vm.warp(block.timestamp + stakingPerdiod_);
        uint256 etherAmountBefore = address(randomUser_).balance;
        stakingApp.claimReward();
        uint256 etherAmountAfter = address(randomUser_).balance;
        uint256 elapsedPeriod = stakingApp.elapsedTime(randomUser_);

        assert(etherAmountAfter - etherAmountBefore == rewardPerPeriod_);
        assert(elapsedPeriod == block.timestamp);

        vm.stopPrank();
    }
}
