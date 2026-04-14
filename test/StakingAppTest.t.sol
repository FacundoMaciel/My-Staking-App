// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";

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

    address randomUser_ = vm.addr(2);

    function setUp() public {
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp =
            new StakingApp(address(stakingToken), owner_, stakingPerdiod_, fixedStakingAmount_, rewardPerPeriod_);
    }

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
}
