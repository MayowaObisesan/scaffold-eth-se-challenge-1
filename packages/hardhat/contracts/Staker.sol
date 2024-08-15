// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping(address => uint256) public balances;
  uint256 public deadline;
  uint256 public threshold = 1 ether;
  uint256 public totalBalance;
  bool private executed = false;

  event Stake(address indexed staker, uint256 amount);
  event Withdraw(address indexed staker, uint256 amount);
  event Execute(uint256 totalAmount);

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "Operation not allowed, contract already completed");
    _;
  }

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      deadline = block.timestamp + 72 hours; // Setting deadline to 72 hours from now
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() public payable {
    require(msg.value > 0, "Cannot stake 0 ETH");
    require(block.timestamp < deadline, "Staking period has ended");
    balances[msg.sender] += msg.value;
    totalBalance += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public notCompleted {
    require(!executed, "Execute has already been called");
    require(block.timestamp > deadline, "Deadline has not passed yet");

    if (address(this).balance >= threshold) {
      executed = true; // Mark as executed
      exampleExternalContract.complete{value: address(this).balance}();
      emit Execute(address(this).balance);
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public notCompleted {
    require(block.timestamp > deadline, "Deadline has not passed yet");
    require(address(this).balance < threshold, "Threshold was met, cannot withdraw");

    uint256 amount = balances[msg.sender];
    require(amount > 0, "No balance to withdraw");

    balances[msg.sender] = 0;
    totalBalance -= amount;  // Update total balance
    payable(msg.sender).transfer(amount);
    emit Withdraw(msg.sender, amount);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

  function openForWithdrawal() public view returns (bool) {
    return block.timestamp > deadline && address(this).balance < threshold;
  }
}
