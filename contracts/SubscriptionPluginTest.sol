// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionPlugin.sol";
import '@cryptoalgebra/periphery/contracts/interfaces/ISwapRouter.sol';
import '@cryptoalgebra/periphery/contracts/libraries/TransferHelper.sol';

contract SubscriptionPluginTest {
    SubscriptionPlugin public subscriptionPlugin;
    ISwapRouter public swapRouter;
    IERC20 public paymentToken;
    address public admin;

    constructor(
        address _paymentToken,
        address _swapRouter,
        uint256 _subscriptionPrice,
        uint256 _subscriptionDuration
    ) {
        admin = msg.sender;
        paymentToken = IERC20(_paymentToken);
        swapRouter = ISwapRouter(_swapRouter);
        subscriptionPlugin = new SubscriptionPlugin(_paymentToken, _subscriptionPrice, _subscriptionDuration);
    }

    function testSubscribeAndSwap(uint256 amountIn) external {

        paymentToken.approve(address(subscriptionPlugin), amountIn);
        subscriptionPlugin.subscribe();

        TransferHelper.safeTransferFrom(address(paymentToken), msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(address(paymentToken), address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(paymentToken),
            tokenOut: address(paymentToken),
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            limitSqrtPrice: 0
        });

        swapRouter.exactInputSingle(params);
    }
}
