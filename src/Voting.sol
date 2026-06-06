// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Voting {
    address public owner;
    uint256 public proposalCount;

    enum ProposalStatus { Active, Passed, Rejected, Expired }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 deadline;
        ProposalStatus status;
        address creator;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(uint256 indexed id, string title, address indexed creator, uint256 deadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalFinalized(uint256 indexed id, ProposalStatus status);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposalCount, "Proposal does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
        proposalCount = 0;
    }

    function createProposal(
        string memory title,
        string memory description,
        uint256 durationInSeconds
    ) public returns (uint256) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(durationInSeconds > 0, "Duration must be positive");

        uint256 proposalId = proposalCount;
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: title,
            description: description,
            voteFor: 0,
            voteAgainst: 0,
            deadline: block.timestamp + durationInSeconds,
            status: ProposalStatus.Active,
            creator: msg.sender
        });

        proposalCount++;
        emit ProposalCreated(proposalId, title, msg.sender, block.timestamp + durationInSeconds);
        return proposalId;
    }

    function vote(uint256 proposalId, bool support) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.voteFor++;
        } else {
            proposal.voteAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function finalizeProposal(uint256 proposalId) public proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal already finalized");
        require(block.timestamp >= proposal.deadline, "Voting period not ended");

        if (proposal.voteFor > proposal.voteAgainst) {
            proposal.status = ProposalStatus.Passed;
        } else if (proposal.voteAgainst > proposal.voteFor) {
            proposal.status = ProposalStatus.Rejected;
        } else {
            proposal.status = ProposalStatus.Expired;
        }

        emit ProposalFinalized(proposalId, proposal.status);
    }

    function getProposal(uint256 proposalId) public view proposalExists(proposalId)
        returns (
            uint256 id,
            string memory title,
            string memory description,
            uint256 voteFor,
            uint256 voteAgainst,
            uint256 deadline,
            ProposalStatus status,
            address creator
        )
    {
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.voteFor,
            proposal.voteAgainst,
            proposal.deadline,
            proposal.status,
            proposal.creator
        );
    }

    function getVoteCount(uint256 proposalId) public view proposalExists(proposalId)
        returns (uint256 forVotes, uint256 againstVotes)
    {
        return (proposals[proposalId].voteFor, proposals[proposalId].voteAgainst);
    }
}
