// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@cryptoalgebra/periphery/contracts/interfaces/ISwapRouter.sol';
import '@cryptoalgebra/periphery/contracts/libraries/TransferHelper.sol';

// Custom error definitions
    error OnlyAdmin();
    error AlreadySubscribed();
    error PaymentFailed();
    error SubscriptionRequired();
    error WithdrawFailed();

contract SubscriptionPlugin {
    using SafeERC20 for IERC20;

    // Storage variables with 's_' prefix
    address public s_admin;
    IERC20 public s_paymentToken;
    uint256 public s_subscriptionPrice;
    uint256 public s_subscriptionDuration;
    ISwapRouter public swapRouter;

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
     * @param _swapRouter Address of the swap router contract.
     */
    constructor(
        address _paymentToken,
        uint256 _subscriptionPrice,
        uint256 _subscriptionDuration,
        address _swapRouter
    ) {
        s_admin = msg.sender;
        s_paymentToken = IERC20(_paymentToken);
        s_subscriptionPrice = _subscriptionPrice;
        s_subscriptionDuration = _subscriptionDuration;
        swapRouter = ISwapRouter(_swapRouter);
    }

    // Modifier to restrict access to admin only
    modifier onlyAdmin() {
        if (msg.sender != s_admin) {
            revert OnlyAdmin();
        }
        _;
    }

    // Modifier to check subscription status
    modifier checkSubscription(address sender) {
        if (s_subscriptions[sender] < block.timestamp) {
            revert SubscriptionRequired();
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
     * @notice swapExactInputSingle swaps a fixed amount of input tokens for a maximum possible amount of output tokens.
     * @dev The calling address must approve this contract to spend at least `amountIn` worth of its input tokens for this function to succeed.
     * @param amountIn The exact amount of input tokens that will be swapped.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @return amountOut The amount of output tokens received.
     */
    function swapExactInputSingle(uint256 amountIn, address tokenIn, address tokenOut) external checkSubscription(msg.sender) returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
                            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                limitSqrtPrice: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    /**
     * @notice swapExactOutputSingle swaps a minimum possible amount of input tokens for a fixed amount of output tokens.
     * @dev The calling address must approve this contract to spend at least `amountInMaximum` worth of its input tokens for this function to succeed.
     * @param amountOut The exact amount of output tokens to receive from the swap.
     * @param amountInMaximum The amount of input tokens we are willing to spend to receive the specified amount of output tokens.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @return amountIn The amount of input tokens actually spent in the swap.
     */
    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum, address tokenIn, address tokenOut) external checkSubscription(msg.sender) returns (uint256 amountIn) {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInMaximum);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
                            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: 3000, // Fee for the pool
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                limitSqrtPrice: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
            TransferHelper.safeTransfer(tokenIn, msg.sender, amountInMaximum - amountIn);
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
