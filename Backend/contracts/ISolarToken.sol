// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISolarToken {
    function mintTokensForEnergy(address producer, uint256 energyProduced) external;
    function BurnTokens(uint256 tokenAmount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}