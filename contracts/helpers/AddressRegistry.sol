// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";

contract AddressRegistry is Ownable {
    address public vaultManager;
    address public marketplace;
    address public proxyFactory;
    address public royaltyCollector;
    address public bundleMarketplace;
    address public tradeMarketplace;
    address public tradeMarketplaceFeeReceiver;
    address public actionValidator;
    address public promFeesDao;
    address public implementationPower;

    //SafeVault address
    mapping(address => uint256) public vaultVersion;

    event VaultManagerUpdated(address newVaultManager);
    event MarketplaceUpdated(address marketplace);
    event ProxyFactoryUpdated(address proxyFactory);
    event RoyaltyCollectorUpdated(address royaltyCollector);
    event TradeMarketplaceUpdated(address tradeMarketplace);
    event TradeMarketplaceFeeReceiverUpdated(
        address TradeMarketplaceFeeReceiverUpdated
    );
    event bundleMarketplaceUpdated(address bundleMarketplace);
    event ERC721CollectionStatusChanged(
        address collection,
        uint256 minimalVersion
    );
    event ERC1155CollectionStatusChanged(
        address collection,
        uint256 minimalVersion
    );
    event ERC1155TokenStatusChanged(
        address collection,
        uint256 tokenId,
        bool status
    );
    event TradeCollectionStatusChanged(address collection, uint16 fee);
    event ActionValidatorSet(address newActionValidator);

    mapping(address => bool) public isTokenEligible;

    mapping(address => uint256) public ERC721CollectionVaultVersion;
    mapping(address => uint256) public ERC1155CollectionVaultVersion;
    mapping(address => mapping(uint256 => bool)) public isERC1155TokenDisabled;
    mapping(address => uint16) public isTradeCollectionEnabled;

    function setPromFeesDao(address _promFeesDao) external onlyOwner {
        promFeesDao = _promFeesDao;
    }

    function setImplementationPower(
        address _implementationPower
    ) external onlyOwner {
        implementationPower = _implementationPower;
    }

    function setActionValidator(address _actionValidator) public onlyOwner {
        actionValidator = _actionValidator;
    }

    function setBundleMarketplace(address _bundleMarketplace) public onlyOwner {
        bundleMarketplace = _bundleMarketplace;
    }

    function setIsTradeCollectionEnabled(
        address _collectionAddress,
        uint16 _fee
    ) public {
        if (msg.sender != promFeesDao) {
            _checkOwner();
        }
        require(_fee >= 0 && _fee <= 10000, "fee out of range");
        isTradeCollectionEnabled[_collectionAddress] = _fee;

        emit TradeCollectionStatusChanged(_collectionAddress, _fee);
    }

    function setTradeMarketplaceFeeReceiver(
        address _tradeMarketplaceFeeReceiver
    ) public onlyOwner {
        tradeMarketplaceFeeReceiver = _tradeMarketplaceFeeReceiver;
        emit TradeMarketplaceFeeReceiverUpdated(_tradeMarketplaceFeeReceiver);
    }

    function setTradeMarketplace(address _tradeMarketplace) public onlyOwner {
        tradeMarketplace = _tradeMarketplace;
        emit TradeMarketplaceUpdated(_tradeMarketplace);
    }

    function setIsTokenEligible(address _token, bool status) public onlyOwner {
        isTokenEligible[_token] = status;
    }

    function setERC1155CollectionVaultVersion(
        address _erc1155,
        uint256 _minimalVersion
    ) public onlyOwner {
        ERC1155CollectionVaultVersion[_erc1155] = _minimalVersion;
        emit ERC1155CollectionStatusChanged(_erc1155, _minimalVersion);
    }

    function setIsERC1155TokenDisabled(
        address _erc1155,
        uint256 _tokenId,
        bool _status
    ) public onlyOwner {
        isERC1155TokenDisabled[_erc1155][_tokenId] = _status;

        emit ERC1155TokenStatusChanged(_erc1155, _tokenId, _status);
    }

    function isERC1155Enabled(
        address _erc1155,
        uint256 _tokenId
    ) public view returns (bool) {
        return
            ERC1155CollectionVaultVersion[_erc1155] != 0 &&
            !isERC1155TokenDisabled[_erc1155][_tokenId];
    }

    function setERC721CollectionVaultVersion(
        address _erc721,
        uint256 _minimalVersion
    ) public onlyOwner {
        ERC721CollectionVaultVersion[_erc721] = _minimalVersion;

        emit ERC721CollectionStatusChanged(_erc721, _minimalVersion);
    }

    function setRoyaltyCollector(
        address _newRoyaltyCollector
    ) public onlyOwner {
        royaltyCollector = _newRoyaltyCollector;

        emit RoyaltyCollectorUpdated(_newRoyaltyCollector);
    }

    function setVaultManager(address _newVaultManager) public onlyOwner {
        vaultManager = _newVaultManager;

        emit VaultManagerUpdated(_newVaultManager);
    }

    function setMarketplace(address _newMarketplace) public onlyOwner {
        marketplace = _newMarketplace;

        emit MarketplaceUpdated(_newMarketplace);
    }

    function setProxyFactory(address _newProxyFactory) public onlyOwner {
        proxyFactory = _newProxyFactory;

        emit ProxyFactoryUpdated(_newProxyFactory);
    }

    /** 
  @dev SafeVault version setter. Function updates version of all "certified" safeVaults
  Caller must be a registered proxyFactory that creates safeVaults

  @param _safeVault address of new certified safeVault
  @param _version version of deployed safeVault
  */
    function setSafeVaultVersion(
        address _safeVault,
        uint256 _version
    ) external {
        require(msg.sender == proxyFactory, "Only Prom factory allowed");
        vaultVersion[_safeVault] = _version;
    }
}
