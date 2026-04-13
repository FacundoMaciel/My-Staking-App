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
}
