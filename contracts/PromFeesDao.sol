// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAddressRegistry {
    function tradeMarketplace() external returns (address);

    function setIsTradeCollectionEnabled(address, uint16) external;

    function implementationPower() external returns (address);
}

interface ITradeMarketplace {
    function setIsTradeCollectionEnabled(address, uint16) external;
}

error IneligibleImplementation();
error AlreadyVotedAgainst();
error UnauthorizedCleanse();
error InvalidCleanseAmount();

contract PromFieldSettingDao is ReentrancyGuard {
    IAddressRegistry public addressRegistry;
    uint256 public currentProposalIndex;
    uint256 public votesThreshold;

    struct Proposal {
        uint256 deadlineTimestamp;
        address marketplace;
        address targetCollection;
        uint16 targetPlatformFee;
        address proposalCreator;
        uint256 upvotes;
        uint256 downvotes;
    }

    // Proposal Index -> Proposal
    mapping(uint256 => Proposal) public proposal;

    // User -> Proposal index -> Upvotes
    mapping(address => mapping(uint256 => uint256))
        public proposalUpvotesByUser;
    // User -> Proposal index -> Upvotes
    mapping(address => mapping(uint256 => uint256))
        public proposalDownvotesByUser;

    event FeeProposalImplemented(
        uint256 proposalIndex,
        address targetCollection,
        uint16 targetFee,
        address proposalCreator,
        uint256 upvotes,
        uint256 downvotes,
        uint256 threshold
    );

    modifier OwnerOrWrapper(address _voter) {
        if (msg.sender != addressRegistry.implementationPower()) {
            if (msg.sender != _voter) {
                revert UnauthorizedCleanse();
            }
        }
        _;
    }

    constructor(
        IAddressRegistry _addressRegistry,
        uint256 _initialVotesThreshold
    ) {
        addressRegistry = _addressRegistry;
        votesThreshold = _initialVotesThreshold;
    }

    function getOngoingProposals()
        public
        view
        returns (uint256[] memory ongoingProposals)
    {
        uint256 len = currentProposalIndex;
        uint256 i;
        if (len > 0) {
            while (len != 0) {
                len--;
                // TODO: Check if it's cheaper to read timestamp just once and store in variable
                if (
                    block.timestamp > proposal[len].deadlineTimestamp ||
                    proposal[len].deadlineTimestamp != 0
                ) {
                    ongoingProposals[i] = len;
                    i++;
                } else break;
            }
        }
    }

    function getAllParticipatedProposalsByUser()
        public
        view
        returns (uint256[] memory participatedIndexes)
    {
        uint256[] memory indexes = getOngoingProposals();
        uint256 index;

        for (uint256 i; i < indexes.length; i++) {
            if (proposalUpvotesByUser[msg.sender][indexes[i]] != 0) {
                participatedIndexes[index] = indexes[i];
                index++;
            } else if (proposalDownvotesByUser[msg.sender][indexes[i]] != 0) {
                participatedIndexes[index] = indexes[i];
                index++;
            }
        }
    }

    function cleanse(
        address _voter,
        uint256 _proposalIndex,
        uint256 _amount
    ) public nonReentrant OwnerOrWrapper(_voter) {
        _cleanse(_voter, _proposalIndex, _amount);
    }

    function _cleanse(
        address _voter,
        uint256 _proposalIndex,
        uint256 _amount
    ) internal {
        if (proposalDownvotesByUser[_voter][_proposalIndex] != 0) {
            if (_amount > proposalDownvotesByUser[_voter][_proposalIndex]) {
                proposalDownvotesByUser[_voter][_proposalIndex] = 0;
            }
            proposalDownvotesByUser[_voter][_proposalIndex] -= _amount;
        } else if (proposalUpvotesByUser[_voter][_proposalIndex] != 0) {
            if (_amount > proposalUpvotesByUser[_voter][_proposalIndex]) {
                proposalDownvotesByUser[_voter][_proposalIndex] = 0;
            }
            proposalUpvotesByUser[_voter][_proposalIndex] -= _amount;
        }
    }

    function cleanseAll(
        address _voter,
        uint256 _amount
    ) external nonReentrant OwnerOrWrapper(_voter) {
        uint256[] memory participatedI = getAllParticipatedProposalsByUser();
        for (uint256 i; i < participatedI.length; i++) {
            _cleanse(_voter, participatedI[i], _amount);
        }
    }

    function createFeeUpdateProposal(
        address _targetCollection,
        uint16 _targetPlatformFee
    ) external nonReentrant {
        proposal[currentProposalIndex] = Proposal({
            deadlineTimestamp: block.timestamp + 14 days,
            marketplace: addressRegistry.tradeMarketplace(),
            targetCollection: _targetCollection,
            targetPlatformFee: _targetPlatformFee,
            proposalCreator: msg.sender,
            upvotes: 0,
            downvotes: 0
        });
        currentProposalIndex++;
    }

    function upvote(uint256 _proposalIndex) external nonReentrant {
        proposalDownvotesByUser[msg.sender][_proposalIndex] = 0;
        proposalUpvotesByUser[msg.sender][_proposalIndex] = IERC20(
            addressRegistry.implementationPower()
        ).balanceOf(msg.sender);
    }

    function downvote(uint256 _proposalIndex) external nonReentrant {
        proposalUpvotesByUser[msg.sender][_proposalIndex] = 0;
        proposalDownvotesByUser[msg.sender][_proposalIndex] = IERC20(
            addressRegistry.implementationPower()
        ).balanceOf(msg.sender);
    }

    function implementProposal(uint256 _proposalIndex) external nonReentrant {
        Proposal memory prop = proposal[_proposalIndex];
        if (
            prop.upvotes < prop.downvotes ||
            prop.upvotes - prop.downvotes < votesThreshold
        ) {
            revert IneligibleImplementation();
        }

        addressRegistry.setIsTradeCollectionEnabled(
            prop.targetCollection,
            prop.targetPlatformFee
        );

        emit FeeProposalImplemented(
            _proposalIndex,
            prop.targetCollection,
            prop.targetPlatformFee,
            prop.proposalCreator,
            prop.upvotes,
            prop.downvotes,
            votesThreshold
        );
        delete proposal[_proposalIndex];
    }
}
