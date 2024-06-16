// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./AssetTypes.sol";
import "./Wallet.sol";
import "./WalletFactory.sol";

contract Trade {
    mapping(AssetTypes.AssetType => AggregatorV3Interface) public priceFeeds;
    WalletFactory public walletFactory;

    constructor(
        address _walletFactory,
        address rubPriceFeed,
        address eurPriceFeed,
        address usdPriceFeed,
        address cnyPriceFeed,
        address goldPriceFeed,
        address silverPriceFeed
    ) {
        walletFactory = WalletFactory(_walletFactory);
        priceFeeds[AssetTypes.AssetType.RUB] = AggregatorV3Interface(rubPriceFeed);
        priceFeeds[AssetTypes.AssetType.EUR] = AggregatorV3Interface(eurPriceFeed);
        priceFeeds[AssetTypes.AssetType.USD] = AggregatorV3Interface(usdPriceFeed);
        priceFeeds[AssetTypes.AssetType.CNY] = AggregatorV3Interface(cnyPriceFeed);
        priceFeeds[AssetTypes.AssetType.GOLD] = AggregatorV3Interface(goldPriceFeed);
        priceFeeds[AssetTypes.AssetType.SILVER] = AggregatorV3Interface(silverPriceFeed);
    }

    function getPrice(AssetTypes.AssetType asset) public view returns (int) {
        (,int price,,,) = priceFeeds[asset].latestRoundData();
        return price;
    }

    function buyAsset(AssetTypes.AssetType asset, uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than 0");

        address walletAddress = walletFactory.getWallet();
        require(walletAddress != address(0), "Wallet not found");

        Wallet wallet = Wallet(walletAddress);
        
        int price = getPrice(asset);
        require(price > 0, "Invalid asset price");

        uint256 totalCost = uint256(price) * amount;
        require(msg.value >= totalCost, "Insufficient funds sent");

        wallet.deposit{value: msg.value}();

        wallet.addAsset(asset, amount);

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function sellAsset(AssetTypes.AssetType asset, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        address walletAddress = walletFactory.getWallet();
        require(walletAddress != address(0), "Wallet not found");

        Wallet wallet = Wallet(walletAddress);

        int price = getPrice(asset);
        require(price > 0, "Invalid asset price");

        uint256 totalReturn = uint256(price) * amount;

        require(address(this).balance >= totalReturn, "Insufficient contract balance");

        wallet.removeAsset(asset, amount);

        payable(msg.sender).transfer(totalReturn);
    }

    function fundContract() public payable {
        require(msg.value > 0, "Must send more than 0");
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}