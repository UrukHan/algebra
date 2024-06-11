// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlugin.sol";

contract SwapRouterMock {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    address public plugin;

    function setPlugin(address _plugin) external {
        plugin = _plugin;
    }

    function swapExactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut) {
        if (plugin != address(0)) {
            IPlugin(plugin).onSwap(msg.sender, params.recipient, params.amountIn, params.amountOutMinimum, "");
        }
        // Mock implementation: just return the amountIn as amountOut for testing purposes
        return params.amountIn;
    }
}
