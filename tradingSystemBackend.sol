// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library AssetTypes {
    enum AssetType { RUB, EUR, USD, CNY, GOLD, SILVER }
}

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