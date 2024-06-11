// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    function exactInputSingle(ExactInputSingleParams calldata params) external pure returns (uint256 amountOut) {
        // Mock implementation: just return the amountIn as amountOut for testing purposes
        return params.amountIn;
    }

    // Implement other necessary mock functions if required
}