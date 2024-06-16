// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "./Wallet.sol";

contract WalletFactory {
    mapping(address => address) public wallets;

    function createWallet() public {
        require(wallets[msg.sender] == address(0), "Wallet already exists");
        Wallet newWallet = new Wallet(msg.sender);
        wallets[msg.sender] = address(newWallet);
    }

    function getWallet() public view returns (address) {
        return wallets[msg.sender];
    }
}