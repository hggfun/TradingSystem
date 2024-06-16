// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "./AssetTypes.sol";

contract Wallet {
    address public owner;
    uint256 public balance;

    mapping(AssetTypes.AssetType => uint256) public assetBalances;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function deposit() public payable onlyOwner {
        require(msg.value > 0, "Must deposit more than 0");
        balance += msg.value;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= balance, "Insufficient balance");
        balance -= amount;
        payable(owner).transfer(amount);
    }

    function addAsset(AssetTypes.AssetType asset, uint256 amount) public onlyOwner {
        assetBalances[asset] += amount;
    }

    function removeAsset(AssetTypes.AssetType asset, uint256 amount) public onlyOwner {
        require(assetBalances[asset] >= amount, "Insufficient asset balance");
        assetBalances[asset] -= amount;
    }

    function getAssetBalance(AssetTypes.AssetType asset) public view returns (uint256) {
        return assetBalances[asset];
    }
}