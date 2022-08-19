// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface PromDao {
    function actionValidatorProposal(address)
        external
        returns (uint256, uint256);

    function rentalListingRemovalProposal(address)
        external
        returns (
            address,
            uint256,
            uint256
        );

    function rentalListingAdditionProposal(address)
        external
        returns (
            address,
            uint256,
            uint256
        );

    function tradeListingAdditionProposal(address)
        external
        returns (uint256, uint256);

    function tradeListingRemovalProposal(address)
        external
        returns (uint256, uint256);

    function votesThreshold() external returns (uint256);
}

contract AddressRegistry is Ownable {
    address public vaultManager;
    address public marketplace;
    address public proxyFactory;
    address public royaltyCollector;
    address public bundleMarketplace;
    address public tradeMarketplace;
    address public tradeMarketplaceFeeReceiver;
    address public actionValidator;
    PromDao public promDao;

    event VaultManagerUpdated(address newVaultManager);
    event MarketplaceUpdated(address marketplace);
    event ProxyFactoryUpdated(address proxyFactory);
    event RoyaltyCollectorUpdated(address royaltyCollector);
    event TradeMarketplaceUpdated(address tradeMarketplace);
    event TradeMarketplaceFeeReceivereUpdated(
        address TradeMarketplaceFeeReceivereUpdated
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
    event TradeCollectionStatusChanged(address collection, bool status);
    event ActionValidatorSet(address newActionValidator);
    event PromDaoSet(address newPromDao);

    event tradeProposalImplemented(address collection, bool status);
    event rentalProposalImplemented(
        address collection,
        address actionValidator,
        bool status
    );

    mapping(address => address) public tokenOracle;
    mapping(address => uint256) public ERC721CollectionVaultVersion;
    mapping(address => uint256) public ERC1155CollectionVaultVersion;
    mapping(address => mapping(uint256 => bool)) public isERC1155TokenDisabled;
    mapping(address => bool) public isTradeCollectionEnabled;
    mapping(address => bool) public implementedProposalAddress;

    function setPromDao(address _newPromDao) public onlyOwner {
        promDao = PromDao(_newPromDao);
        emit PromDaoSet(_newPromDao);
    }

    function checkProposal(uint256 _timestamp, uint256 _votes) internal {
        require(
            _timestamp + 14 days <= block.timestamp,
            "Voting is still in progress"
        );
        require(_votes >= promDao.votesThreshold(), "not enough votes");
    }

    function setProposedTradeCollection(
        address _tradeCollection,
        bool _isEnabled
    ) external {
        require(
            !implementedProposalAddress[_tradeCollection],
            "already implemented"
        );

        uint256 timestamp;
        uint256 votes;
        if (_isEnabled) {
            (timestamp, votes) = promDao.tradeListingAdditionProposal(
                _tradeCollection
            );
        } else {
            (timestamp, votes) = promDao.tradeListingRemovalProposal(
                _tradeCollection
            );
        }

        checkProposal(timestamp, votes);
        isTradeCollectionEnabled[_tradeCollection] = _isEnabled;

        emit tradeProposalImplemented(_tradeCollection, _isEnabled);
    }

    function setProposedRentalCollection(
        address _rentalCollection,
        bool _isEnabled
    ) external {
        require(
            !implementedProposalAddress[_rentalCollection],
            "already implemented"
        );

        uint256 timestamp;
        uint256 votes;
        address _actionValidator;
        if (_isEnabled) {
            (_actionValidator, timestamp, votes) = promDao
                .rentalListingAdditionProposal(_rentalCollection);
        } else {
            (_actionValidator, timestamp, votes) = promDao
                .rentalListingRemovalProposal(_rentalCollection);
        }

        checkProposal(timestamp, votes);
        isTradeCollectionEnabled[_rentalCollection] = _isEnabled;
        actionValidator = _actionValidator;

        emit rentalProposalImplemented(
            _rentalCollection,
            _actionValidator,
            _isEnabled
        );
    }

    function setBundleMarketplace(address _bundleMarketplace) public onlyOwner {
        bundleMarketplace = _bundleMarketplace;
    }

    function setActionValidator(address _actionValidator) public onlyOwner {
        actionValidator = _actionValidator;

        emit ActionValidatorSet(_actionValidator);
    }

    function setIsTradeCollectionEnabled(
        address _collectionAddress,
        bool _status
    ) public onlyOwner {
        require(
            !implementedProposalAddress[_collectionAddress],
            "May not override proposal"
        );

        isTradeCollectionEnabled[_collectionAddress] = _status;

        emit TradeCollectionStatusChanged(_collectionAddress, _status);
    }

    function setTradeMarketplaceFeeReceiver(
        address _tradeMarketplaceFeeReceiver
    ) public onlyOwner {
        tradeMarketplaceFeeReceiver = _tradeMarketplaceFeeReceiver;
        emit TradeMarketplaceFeeReceivereUpdated(_tradeMarketplaceFeeReceiver);
    }

    function setTradeMarketplace(address _tradeMarketplace) public onlyOwner {
        tradeMarketplace = _tradeMarketplace;
        emit TradeMarketplaceUpdated(_tradeMarketplace);
    }

    function setTokenOracle(address _token, address _oracleAddress)
        public
        onlyOwner
    {
        tokenOracle[_token] = _oracleAddress;
    }

    function setERC1155CollectionVaultVersion(
        address _erc1155,
        uint256 _minimalVersion
    ) public onlyOwner {
        require(
            !implementedProposalAddress[_erc1155],
            "May not override proposal"
        );

        ERC1155CollectionVaultVersion[_erc1155] = _minimalVersion;
        emit ERC1155CollectionStatusChanged(_erc1155, _minimalVersion);
    }

    function setIsERC1155TokenDisabled(
        address _erc1155,
        uint256 _tokenId,
        bool _status
    ) public onlyOwner {
        require(
            !implementedProposalAddress[_erc1155],
            "May not override proposal"
        );
        isERC1155TokenDisabled[_erc1155][_tokenId] = _status;

        emit ERC1155TokenStatusChanged(_erc1155, _tokenId, _status);
    }

    function isERC1155Enabled(address _erc1155, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return
            ERC1155CollectionVaultVersion[_erc1155] != 0 &&
            !isERC1155TokenDisabled[_erc1155][_tokenId];
    }

    function setERC721CollectionVaultVersion(
        address _erc721,
        uint256 _minimalVersion
    ) public onlyOwner {
        require(
            !implementedProposalAddress[_erc721],
            "May not override proposal"
        );
        ERC721CollectionVaultVersion[_erc721] = _minimalVersion;

        emit ERC721CollectionStatusChanged(_erc721, _minimalVersion);
    }

    function setRoyaltyCollector(address _newRoyaltyCollector)
        public
        onlyOwner
    {
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
}
