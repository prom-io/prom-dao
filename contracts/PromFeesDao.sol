// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface IAddressRegistry {
    function tradeMarketplace() external returns (address);

    function setIsTradeCollectionEnabled(address, uint16) external;

    function implementationPower() external returns (address);
}

interface ITradeMarketplace {
    function setIsTradeCollectionEnabled(address, uint16) external;
}

error IneligibleImplementation();
error UnauthorizedCleanse();
error ExpiredProposal();

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

    modifier OngoingProposal(uint256 _proposalIndex) {
        if (proposal[_proposalIndex].deadlineTimestamp < block.timestamp) {
            revert ExpiredProposal();
        }
        _;
    }

    constructor(
        IAddressRegistry _addressRegistry,
        uint256 _initialVotesThreshold
    ) {
        addressRegistry = _addressRegistry;
        votesThreshold = _initialVotesThreshold;
        //Initializing proposal index;
        currentProposalIndex++;
    }

    function getOngoingProposals() public view returns (uint256[] memory) {
        uint256 len = currentProposalIndex;
        uint256 i = 0;
        uint256[] memory ongoingProposals = new uint256[](len);

        while (len != 0) {
            len--;

            // TODO: Check if it's cheaper to read timestamp just once and store in variable
            if (block.timestamp <= proposal[len].deadlineTimestamp) {
                ongoingProposals[i] = len;
                i++;
            } else break;
        }

        uint256[] memory resizedOngoingProposals = new uint256[](i);
        for (uint256 j; j < i; j++) {
            resizedOngoingProposals[j] = ongoingProposals[j];
        }

        return resizedOngoingProposals;
    }

    function getAllParticipatedProposalsByUser(
        address _user
    ) public view returns (uint256[] memory) {
        uint256[] memory indexes = getOngoingProposals();
        uint256[] memory participatedIndexes = new uint256[](indexes.length);
        uint256 index = 0;

        for (uint256 i = 0; i < indexes.length; i++) {
            if (proposalUpvotesByUser[_user][indexes[i]] != 0) {
                participatedIndexes[index] = indexes[i];
                index++;
            } else if (proposalDownvotesByUser[_user][indexes[i]] != 0) {
                participatedIndexes[index] = indexes[i];
                index++;
            }
        }

        // Resize the array to the actual length of participated proposals
        uint256[] memory resizedParticipatedIndexes = new uint256[](index);
        for (uint256 j = 0; j < index; j++) {
            resizedParticipatedIndexes[j] = participatedIndexes[j];
        }

        return resizedParticipatedIndexes;
    }

    function cleanse(
        address _voter,
        uint256 _proposalIndex,
        uint256 _amount
    ) external nonReentrant OwnerOrWrapper(_voter) {
        _cleanse(_voter, _proposalIndex, _amount);
    }

    function _cleanse(
        address _voter,
        uint256 _proposalIndex,
        uint256 _amount
    ) internal {
        if (proposalDownvotesByUser[_voter][_proposalIndex] != 0) {
            if (_amount > proposalDownvotesByUser[_voter][_proposalIndex]) {
                proposal[_proposalIndex].downvotes -= proposalDownvotesByUser[
                    _voter
                ][_proposalIndex];
                proposalDownvotesByUser[_voter][_proposalIndex] = 0;
            } else {
                proposalDownvotesByUser[_voter][_proposalIndex] -= _amount;
                proposal[_proposalIndex].downvotes -= _amount;
            }
        } else if (proposalUpvotesByUser[_voter][_proposalIndex] != 0) {
            if (_amount > proposalUpvotesByUser[_voter][_proposalIndex]) {
                proposal[_proposalIndex].upvotes -= proposalUpvotesByUser[
                    _voter
                ][_proposalIndex];
                proposalUpvotesByUser[_voter][_proposalIndex] = 0;
            } else {
                proposalUpvotesByUser[_voter][_proposalIndex] -= _amount;
                proposal[_proposalIndex].upvotes -= _amount;
            }
        }
    }

    function cleanseAll(
        address _voter,
        uint256 _amount
    ) external nonReentrant OwnerOrWrapper(_voter) {
        uint256[] memory participatedI = getAllParticipatedProposalsByUser(
            _voter
        );

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

    function upvote(
        uint256 _proposalIndex
    ) external nonReentrant OngoingProposal(_proposalIndex) {
        uint256 upvotes = IERC20(addressRegistry.implementationPower())
            .balanceOf(msg.sender);
        uint256 downvotes = proposalDownvotesByUser[msg.sender][_proposalIndex];
        if (downvotes > 0) {
            proposalDownvotesByUser[msg.sender][_proposalIndex] = 0;
            proposal[_proposalIndex].downvotes -= downvotes;
        }
        proposal[_proposalIndex].upvotes +=
            upvotes -
            proposalUpvotesByUser[msg.sender][_proposalIndex];
        proposalUpvotesByUser[msg.sender][_proposalIndex] = upvotes;
    }

    function downvote(
        uint256 _proposalIndex
    ) external nonReentrant OngoingProposal(_proposalIndex) {
        uint256 downvotes = IERC20(addressRegistry.implementationPower())
            .balanceOf(msg.sender);
        uint256 upvotes = proposalUpvotesByUser[msg.sender][_proposalIndex];
        if (upvotes > 0) {
            proposalUpvotesByUser[msg.sender][_proposalIndex] = 0;
            proposal[_proposalIndex].upvotes -= upvotes;
        }
        proposal[_proposalIndex].downvotes +=
            downvotes -
            proposalDownvotesByUser[msg.sender][_proposalIndex];
        proposalDownvotesByUser[msg.sender][_proposalIndex] = downvotes;
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
