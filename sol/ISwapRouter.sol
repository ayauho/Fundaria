// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface SwapRouter {
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);        
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}