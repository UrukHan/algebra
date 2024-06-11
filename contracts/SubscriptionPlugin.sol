// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlugin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Custom error definitions
    error OnlyAdmin();
    error AlreadySubscribed();
    error PaymentFailed();
    error SubscriptionRequired();
    error WithdrawFailed();

contract SubscriptionPlugin is IPlugin {
    using SafeERC20 for IERC20;

    // Storage variables with 's_' prefix
    address public s_admin;
    IERC20 public s_paymentToken;
    uint256 public s_subscriptionPrice;
    uint256 public s_subscriptionDuration;

    // Mapping to store subscription expiration timestamps
    mapping(address => uint256) public s_subscriptions;

    // Event emitted when a user subscribes
    event Subscribed(address indexed user, uint256 expiration);
    event SubscriptionPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event SubscriptionDurationUpdated(uint256 oldDuration, uint256 newDuration);
    event Withdrawn(address admin, uint256 amount);

    /**
     * @dev Constructor to initialize the contract with necessary parameters.
     * @param _paymentToken Address of the ERC20 token used for payment.
     * @param _subscriptionPrice Price of the subscription in the specified token.
     * @param _subscriptionDuration Duration of the subscription in seconds.
     */
    constructor(address _paymentToken, uint256 _subscriptionPrice, uint256 _subscriptionDuration) {
        s_admin = msg.sender;
        s_paymentToken = IERC20(_paymentToken);
        s_subscriptionPrice = _subscriptionPrice;
        s_subscriptionDuration = _subscriptionDuration;
    }

    // Modifier to restrict access to admin only
    modifier onlyAdmin() {
        if (msg.sender != s_admin) {
            revert OnlyAdmin();
        }
        _;
    }

    /**
     * @dev Allows users to subscribe by paying the subscription fee.
     */
    function subscribe() external {
        if (s_subscriptions[msg.sender] >= block.timestamp) {
            revert AlreadySubscribed();
        }
        s_paymentToken.safeTransferFrom(msg.sender, address(this), s_subscriptionPrice);
        s_subscriptions[msg.sender] = block.timestamp + s_subscriptionDuration;
        emit Subscribed(msg.sender, s_subscriptions[msg.sender]);
    }

    /**
     * @dev Hook that is called when a swap occurs.
     * @param sender Address of the sender initiating the swap.
     */
    function onSwap(
        address sender,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override {
        if (s_subscriptions[sender] < block.timestamp) {
            revert SubscriptionRequired();
        }
    }

    /**
     * @dev Hook that is called when a pool is initialized.
     * @param sender Address of the sender initializing the pool.
     */
    function onInitialize(
        address sender,
        uint256,
        uint256,
        bytes calldata
    ) external view override {
        if (s_subscriptions[sender] < block.timestamp) {
            revert SubscriptionRequired();
        }
    }

    /**
     * @dev Hook that is called when a pool collects fees.
     * @param sender Address of the sender collecting fees.
     */
    function onCollect(
        address sender,
        uint256,
        uint256,
        bytes calldata
    ) external view override {
        if (s_subscriptions[sender] < block.timestamp) {
            revert SubscriptionRequired();
        }
    }

    /**
     * @dev Updates the subscription price. Can only be called by the admin.
     * @param newPrice New subscription price.
     */
    function updateSubscriptionPrice(uint256 newPrice) external onlyAdmin {
        uint256 oldPrice = s_subscriptionPrice;
        s_subscriptionPrice = newPrice;
        emit SubscriptionPriceUpdated(oldPrice, newPrice);
    }

    /**
     * @dev Updates the subscription duration. Can only be called by the admin.
     * @param newDuration New subscription duration in seconds.
     */
    function updateSubscriptionDuration(uint256 newDuration) external onlyAdmin {
        uint256 oldDuration = s_subscriptionDuration;
        s_subscriptionDuration = newDuration;
        emit SubscriptionDurationUpdated(oldDuration, newDuration);
    }

    /**
     * @dev Withdraws the balance of the payment token to the admin's address.
     */
    function withdraw() external onlyAdmin {
        uint256 balance = s_paymentToken.balanceOf(address(this));
        s_paymentToken.safeTransfer(s_admin, balance);
        emit Withdrawn(s_admin, balance);
    }
}
