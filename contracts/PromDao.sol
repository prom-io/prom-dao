// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PromDao is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct TradeProposal {
        uint256 timestamp;
        uint256 votes;
    }

    struct RentalProposal {
        address actionValidator;
        uint256 timestamp;
        uint256 votes;
    }

    mapping(address => RentalProposal) public rentalListingAdditionProposal;
    mapping(address => RentalProposal) public rentalListingRemovalProposal;

    mapping(address => TradeProposal) public tradeListingAdditionProposal;
    mapping(address => TradeProposal) public tradeListingRemovalProposal;

    //Proposal-> User Address -> Already Voted Amount
    mapping(address => mapping(address => uint256)) public votedProposals;

    uint256 public votesThreshold = ((20000000 * 10**18) / 100) * 20;

    address public prom;

    event TradeListingAdditionProposalSubmitted(address collectionToAdd);
    event TradeListingAdditionProposalVoted(address proposalAddress);
    event TradeListingAdditionProposalVoteRemoved(address proposalAddress);

    event TradeListingRemovalProposalSubmitted(address collectionToRemove);
    event TradeListingRemovalProposalVoted(address proposalAddress);
    event TradeListingRemovalProposalVoteRemoved(address proposalAddress);

    event RentalListingAdditionProposalSubmitted(address collectionToAdd);
    event RentalListingAdditionProposalVoted(address proposalAddress);
    event RentalListingAdditionProposalVoteRemoved(address proposalAddress);

    event RentalListingRemovalProposalSubmitted(address collectionToRemove);
    event RentalListingRemovalProposalVoted(address proposalAddress);
    event RentalListingRemovalProposalVoteRemoved(address proposalAddress);

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == address(this)) {
            IERC20(prom).safeTransfer(_to, _amount);
        } else {
            IERC20(prom).safeTransferFrom(_from, _to, _amount);
        }
    }

    function submitTradeListingAdditionProposal(address _collectionToAdd)
        public
    {
        require(
            tradeListingAdditionProposal[_collectionToAdd].timestamp == 0,
            "already created"
        );
        tradeListingAdditionProposal[_collectionToAdd].timestamp = block
            .timestamp;
        emit TradeListingAdditionProposalSubmitted(_collectionToAdd);
    }

    function submitTradeListingRemovalProposal(address _collectionToRemove)
        public
    {
        require(
            tradeListingRemovalProposal[_collectionToRemove].timestamp == 0,
            "already created"
        );
        tradeListingRemovalProposal[_collectionToRemove].timestamp = block
            .timestamp;
        emit TradeListingRemovalProposalSubmitted(_collectionToRemove);
    }

    function submitRentalListingAdditionProposal(
        address _newActionValidator,
        address _collectionToAdd
    ) public {
        require(
            rentalListingAdditionProposal[_collectionToAdd].timestamp == 0,
            "already created"
        );
        rentalListingAdditionProposal[_collectionToAdd].timestamp = block
            .timestamp;
        rentalListingAdditionProposal[_collectionToAdd]
            .actionValidator = _newActionValidator;

        emit RentalListingAdditionProposalSubmitted(_collectionToAdd);
    }

    function submitRentalListingRemovalProposal(
        address _newActionValidator,
        address _collectionToRemove
    ) public {
        require(
            rentalListingRemovalProposal[_collectionToRemove].timestamp == 0,
            "already created"
        );
        rentalListingRemovalProposal[_collectionToRemove].timestamp = block
            .timestamp;
        rentalListingRemovalProposal[_collectionToRemove]
            .actionValidator = _newActionValidator;

        emit RentalListingRemovalProposalSubmitted(_collectionToRemove);
    }

    function rentalRemovalProposalVote(
        address _proposalAddress,
        uint256 _voteAmount
    ) public nonReentrant {
        require(
            rentalListingRemovalProposal[_proposalAddress].timestamp + 14 days >
                block.timestamp,
            "voting ended"
        );
        _transfer(msg.sender, address(this), _voteAmount);
        votedProposals[_proposalAddress][msg.sender] += _voteAmount;

        rentalListingRemovalProposal[_proposalAddress].votes += _voteAmount;
        emit RentalListingRemovalProposalVoted(_proposalAddress);
    }

    function rentalAdditionProposalVote(
        address _proposalAddress,
        uint256 _voteAmount
    ) public nonReentrant {
        require(
            rentalListingAdditionProposal[_proposalAddress].timestamp +
                14 days >
                block.timestamp,
            "voting ended"
        );
        _transfer(msg.sender, address(this), _voteAmount);
        votedProposals[_proposalAddress][msg.sender] += _voteAmount;

        rentalListingAdditionProposal[_proposalAddress].votes += _voteAmount;
        emit RentalListingAdditionProposalVoted(_proposalAddress);
    }

    function tradeAdditionProposalVote(
        address _proposalAddress,
        uint256 _voteAmount
    ) public nonReentrant {
        require(
            tradeListingAdditionProposal[_proposalAddress].timestamp + 14 days >
                block.timestamp,
            "voting ended"
        );
        _transfer(msg.sender, address(this), _voteAmount);
        votedProposals[_proposalAddress][msg.sender] += _voteAmount;

        tradeListingAdditionProposal[_proposalAddress].votes += _voteAmount;
        emit TradeListingAdditionProposalVoted(_proposalAddress);
    }

    function tradeRemovalProposalVote(
        address _proposalAddress,
        uint256 _voteAmount
    ) public nonReentrant {
        require(
            tradeListingRemovalProposal[_proposalAddress].timestamp + 14 days >
                block.timestamp,
            "voting ended"
        );
        _transfer(msg.sender, address(this), _voteAmount);
        votedProposals[_proposalAddress][msg.sender] += _voteAmount;

        tradeListingRemovalProposal[_proposalAddress].votes += _voteAmount;
        emit TradeListingRemovalProposalVoted(_proposalAddress);
    }

    /**
@param _proposalType 0 => rentalAddition, 1 => rentalRemoval, 2=> tradeAddition, 3 tradeRemoval */
    function claimTokens(address _proposalAddress, uint256 _proposalType)
        public
        nonReentrant
    {
        uint256 votedAmount = votedProposals[_proposalAddress][msg.sender];
        if (_proposalType == 0) {
            if (
                rentalListingAdditionProposal[_proposalAddress].timestamp +
                    14 days >
                block.timestamp
            ) {
                rentalListingAdditionProposal[_proposalAddress]
                    .votes -= votedAmount;
                emit RentalListingAdditionProposalVoteRemoved(_proposalAddress);
            }
        } else if (_proposalType == 1) {
            if (
                rentalListingRemovalProposal[_proposalAddress].timestamp +
                    14 days >
                block.timestamp
            ) {
                rentalListingRemovalProposal[_proposalAddress]
                    .votes -= votedAmount;
                emit RentalListingRemovalProposalVoteRemoved(_proposalAddress);
            }
        } else if (_proposalType == 2) {
            if (
                tradeListingAdditionProposal[_proposalAddress].timestamp +
                    14 days >
                block.timestamp
            ) {
                tradeListingAdditionProposal[_proposalAddress]
                    .votes -= votedAmount;
                emit TradeListingAdditionProposalVoteRemoved(_proposalAddress);
            }
        } else if (_proposalType == 3) {
            if (
                tradeListingRemovalProposal[_proposalAddress].timestamp +
                    14 days >
                block.timestamp
            ) {
                tradeListingRemovalProposal[_proposalAddress]
                    .votes -= votedAmount;
                emit TradeListingRemovalProposalVoteRemoved(_proposalAddress);
            }
        }
        _transfer(address(this), msg.sender, votedAmount);
    }
}
