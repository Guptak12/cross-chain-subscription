// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ISubscriptionToken {
    /**
     * @dev Mints `amount` tokens to the `to` address.
     * Can only be called by the owner of the contract.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burns `amount` tokens from the `from` address.
     * Can only be called by the owner of the contract.
     */
    function burn(address from, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    
}