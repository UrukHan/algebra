// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlugin {
    function onSwap(
        address sender,
        address receiver,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function onInitialize(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function onCollect(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
