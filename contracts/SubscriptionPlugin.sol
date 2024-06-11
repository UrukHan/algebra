// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlugin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SubscriptionPlugin is IPlugin {
    address public admin;
    address public paymentToken;
    uint256 public subscriptionPrice;
    uint256 public subscriptionDuration;

    mapping(address => uint256) public subscriptions;

    event Subscribed(address indexed user, uint256 expiration);

    constructor(address _paymentToken, uint256 _subscriptionPrice, uint256 _subscriptionDuration) {
        admin = msg.sender;
        paymentToken = _paymentToken;
        subscriptionPrice = _subscriptionPrice;
        subscriptionDuration = _subscriptionDuration;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function subscribe() external {
        require(subscriptions[msg.sender] < block.timestamp, "Already subscribed");
        require(IERC20(paymentToken).transferFrom(msg.sender, address(this), subscriptionPrice), "Payment failed");
        subscriptions[msg.sender] = block.timestamp + subscriptionDuration;
        emit Subscribed(msg.sender, subscriptions[msg.sender]);
    }

    function onSwap(
        address sender,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override {
        require(subscriptions[sender] >= block.timestamp, "Subscription required");
    }

    function onInitialize(
        address sender,
        uint256,
        uint256,
        bytes calldata
    ) external view override {
        require(subscriptions[sender] >= block.timestamp, "Subscription required");
    }

    function onCollect(
        address sender,
        uint256,
        uint256,
        bytes calldata
    ) external view override {
        require(subscriptions[sender] >= block.timestamp, "Subscription required");
    }

    function updateSubscriptionPrice(uint256 newPrice) external onlyAdmin {
        subscriptionPrice = newPrice;
    }

    function updateSubscriptionDuration(uint256 newDuration) external onlyAdmin {
        subscriptionDuration = newDuration;
    }

    function withdraw() external onlyAdmin {
        uint256 balance = IERC20(paymentToken).balanceOf(address(this));
        require(IERC20(paymentToken).transfer(admin, balance), "Withdraw failed");
    }
}
