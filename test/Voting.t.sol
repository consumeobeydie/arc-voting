// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/Voting.sol";

contract VotingTest is Test {
    Voting voting;
    address owner;
    address user1;
    address user2;
    address user3;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1234);
        user2 = address(0x5678);
        user3 = address(0x9abc);
        voting = new Voting();
    }

    function testInitialState() public view {
        assertEq(voting.proposalCount(), 0);
        assertEq(voting.owner(), owner);
    }

    function testCreateProposal() public {
        uint256 id = voting.createProposal("Test Proposal", "Test Description", 1 days);
        assertEq(id, 0);
        assertEq(voting.proposalCount(), 1);
    }

    function testCannotCreateEmptyTitle() public {
        vm.expectRevert("Title cannot be empty");
        voting.createProposal("", "Description", 1 days);
    }

    function testVoteFor() public {
        voting.createProposal("Test Proposal", "Description", 1 days);
        vm.prank(user1);
        voting.vote(0, true);
        (uint256 forVotes, uint256 againstVotes) = voting.getVoteCount(0);
        assertEq(forVotes, 1);
        assertEq(againstVotes, 0);
    }

    function testVoteAgainst() public {
        voting.createProposal("Test Proposal", "Description", 1 days);
        vm.prank(user1);
        voting.vote(0, false);
        (uint256 forVotes, uint256 againstVotes) = voting.getVoteCount(0);
        assertEq(forVotes, 0);
        assertEq(againstVotes, 1);
    }

    function testCannotVoteTwice() public {
        voting.createProposal("Test Proposal", "Description", 1 days);
        vm.prank(user1);
        voting.vote(0, true);
        vm.prank(user1);
        vm.expectRevert("Already voted");
        voting.vote(0, true);
    }

    function testCannotVoteAfterDeadline() public {
        voting.createProposal("Test Proposal", "Description", 1 days);
        vm.warp(block.timestamp + 2 days);
        vm.prank(user1);
        vm.expectRevert("Voting period has ended");
        voting.vote(0, true);
    }

    function testFinalizeProposalPassed() public {
        voting.createProposal("Test Proposal", "Description", 1 days);
        vm.prank(user1);
        voting.vote(0, true);
        vm.prank(user2);
        voting.vote(0, true);
        vm.prank(user3);
        voting.vote(0, false);
        vm.warp(block.timestamp + 2 days);
        voting.finalizeProposal(0);
        (,,,,,, Voting.ProposalStatus status,) = voting.getProposal(0);
        assertEq(uint256(status), uint256(Voting.ProposalStatus.Passed));
    }

    function testFinalizeProposalRejected() public {
        voting.createProposal("Test Proposal", "Description", 1 days);
        vm.prank(user1);
        voting.vote(0, false);
        vm.prank(user2);
        voting.vote(0, false);
        vm.prank(user3);
        voting.vote(0, true);
        vm.warp(block.timestamp + 2 days);
        voting.finalizeProposal(0);
        (,,,,,, Voting.ProposalStatus status,) = voting.getProposal(0);
        assertEq(uint256(status), uint256(Voting.ProposalStatus.Rejected));
    }

    function testFinalizeProposalExpired() public {
        voting.createProposal("Test Proposal", "Description", 1 days);
        vm.prank(user1);
        voting.vote(0, true);
        vm.prank(user2);
        voting.vote(0, false);
        vm.warp(block.timestamp + 2 days);
        voting.finalizeProposal(0);
        (,,,,,, Voting.ProposalStatus status,) = voting.getProposal(0);
        assertEq(uint256(status), uint256(Voting.ProposalStatus.Expired));
    }

    function testCannotFinalizeBeforeDeadline() public {
        voting.createProposal("Test Proposal", "Description", 1 days);
        vm.expectRevert("Voting period not ended");
        voting.finalizeProposal(0);
    }

    function testProposalCreatedEvent() public {
        vm.expectEmit(true, true, true, true);
        emit Voting.ProposalCreated(0, "Test Proposal", address(this), block.timestamp + 1 days);
        voting.createProposal("Test Proposal", "Description", 1 days);
    }

    function testVotedEvent() public {
        voting.createProposal("Test Proposal", "Description", 1 days);
        vm.expectEmit(true, true, true, true);
        emit Voting.Voted(0, user1, true);
        vm.prank(user1);
        voting.vote(0, true);
    }
}
