// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

contract StakingApp is Ownable {
    address public stakingToken;
    uint256 public stakingPerdiod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public elapsedTime;

    event ChangeStakingPeriod(uint256 newStakingPeriod_);
    event DepositToken(address userAddress_, uint256 depositAmount_);
    event WithdrawToken(address userAddress_, uint256 withdrawAmount_);
    event EtherSend(uint256 amount_);

    constructor(
        address stakingToken_,
        address owner_,
        uint256 stakingPerdiod_,
        uint256 fixedStakingAmount_,
        uint256 rewardPerPeriod_
    ) Ownable(owner_) {
        stakingToken = stakingToken_;
        stakingPerdiod = stakingPerdiod_;
        fixedStakingAmount = fixedStakingAmount_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    // Functions

    function deposit(uint256 tokenAmountToDeposit_) external {
        require(tokenAmountToDeposit_ == fixedStakingAmount, "Only deposit fixed amount");
        require(userBalance[msg.sender] == 0, "Already deposited");

        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), tokenAmountToDeposit_);
        userBalance[msg.sender] += tokenAmountToDeposit_;
        elapsedTime[msg.sender] = block.timestamp;

        emit DepositToken(msg.sender, tokenAmountToDeposit_);
    }

    function withdraw() external {
        uint256 balance_ = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        IERC20(stakingToken).safeTransfer(msg.sender, balance_);

        emit WithdrawToken(msg.sender, balance_);
    }

    function claimReward() external {
        require(userBalance[msg.sender] == fixedStakingAmount, "No staking");

        uint256 elapsedPeriod_ = block.timestamp - elapsedTime[msg.sender];
        require(elapsedPeriod_ >= stakingPerdiod, "Not yet claimable");

        elapsedTime[msg.sender] = block.timestamp;

        (bool success_,) = msg.sender.call{value: rewardPerPeriod}("");
        require(success_, "transfer failed");
    }

    receive() external payable onlyOwner {
        emit EtherSend(msg.value);
    }

    function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner {
        stakingPerdiod = newStakingPeriod_;
        emit ChangeStakingPeriod(newStakingPeriod_);
    }
}
