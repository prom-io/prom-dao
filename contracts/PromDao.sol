// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.7;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PromDao is ReentrancyGuard {
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

    uint256 public votesThreshold = 20000000 * 10**18;

    address prom;

    event tradeListingAdditionProposalSubmitted(address collectionToAdd);
    event tradeListingRemovalProposalSubmitted(address collectionToAdd);

    function submitTradeListingAdditionProposal(address _collectionToAdd)
        public
    {
        require(
            tradeListingAdditionProposal[_collectionToAdd].timestamp == 0,
            "already created"
        );
        tradeListingAdditionProposal[_collectionToAdd].timestamp = block
            .timestamp;
        emit tradeListingAdditionProposalSubmitted(_collectionToAdd);
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
        emit tradeListingRemovalProposalSubmitted(_collectionToRemove);
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
    }

    function rentalRemovalProposalVote(address _proposalAddress)
        public
        nonReentrant
    {
        if (rentalListingRemovalProposal[_proposalAddress].votes != 0) {
            rentalListingRemovalProposal[_proposalAddress]
                .votes -= rentalListingRemovalProposal[_proposalAddress].votes;
            rentalListingRemovalProposal[_proposalAddress].votes = 0;
        }

        rentalListingRemovalProposal[_proposalAddress].votes += IERC20(prom)
            .balanceOf(msg.sender);
    }

    function rentalAdditionProposalVote(address _proposalAddress)
        public
        nonReentrant
    {
        if (rentalListingRemovalProposal[_proposalAddress].votes != 0) {
            rentalListingRemovalProposal[_proposalAddress]
                .votes -= rentalListingRemovalProposal[_proposalAddress].votes;
            rentalListingRemovalProposal[_proposalAddress].votes = 0;
        }
        rentalListingAdditionProposal[_proposalAddress].votes += IERC20(prom)
            .balanceOf(msg.sender);
    }

    function tradeAdditionProposalVote(address _proposalAddress)
        public
        nonReentrant
    {
        if (tradeListingAdditionProposal[_proposalAddress].votes != 0) {
            tradeListingAdditionProposal[_proposalAddress]
                .votes -= tradeListingAdditionProposal[_proposalAddress].votes;
            tradeListingAdditionProposal[_proposalAddress].votes = 0;
        }
        tradeListingAdditionProposal[_proposalAddress].votes += IERC20(prom)
            .balanceOf(msg.sender);
    }

    function tradeRemovalProposalVote(address _proposalAddress)
        public
        nonReentrant
    {
        if (tradeListingRemovalProposal[_proposalAddress].votes != 0) {
            tradeListingRemovalProposal[_proposalAddress]
                .votes -= tradeListingRemovalProposal[_proposalAddress].votes;
            tradeListingRemovalProposal[_proposalAddress].votes = 0;
        }
        tradeListingRemovalProposal[_proposalAddress].votes += IERC20(prom)
            .balanceOf(msg.sender);
    }
}
