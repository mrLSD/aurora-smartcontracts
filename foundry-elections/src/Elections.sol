// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// Elections
contract Election {
    // Voter data
    struct Voter {
        bool voted;
        bool active;
    }
    
    // Proposals
    struct Proposal {
        bytes32 name;
        uint256 votes;
    }

    enum Status {
        NotStarted,
        Started,
        Ended
    }

    enum WinnerStatus {
        NotVoted,
        SingleWin,
        DeadHeat
    }

    address public chairman;
    Proposal[] public proposals;
    Status public status;
    uint256 public votersCount;
    uint256 public votedVoters;

    mapping(address => Voter) public voters;
    WinnerStatus winnerStatus;
    uint256 winnerVotes;
    uint256 winnerProposalId;

    event ElectionStarted();
    event ElectionEnded();
    event ChangedWinner(Proposal proposal);

    error EmptyProposals();
    error UnauthorizedAction();
    error ProposalNotFound(uint256 proposal_id);
    error VoterAlreadyAdded(address voter);
    error VoterNotAdded(address voter);
    error VoterVoted(address voter);
    error ElectionStartedOrEnded(Status status);
    error ElectionNotStartedOrEnded(Status status);
    error NotVoted();

    constructor(bytes32[] memory proposals_list) {
        require(proposals_list.length > 0, EmptyProposals());
        chairman = msg.sender;
        for (uint256 i = 0; i < proposals_list.length; i++) {
            proposals.push(Proposal({name: proposals_list[i], votes: 0}));
        }
    }

    function addVoter(address voter) external {
        require(msg.sender == chairman, UnauthorizedAction());
        require(!voters[voter].active, VoterAlreadyAdded(voter));
        voters[voter].active = true;
        votersCount++;
    }

    function start() external {
        require(msg.sender == chairman, UnauthorizedAction());
        require(status == Status.NotStarted, ElectionStartedOrEnded(status));
        status = Status.Started;
        emit ElectionStarted();
    }

    function end() external {
        require(msg.sender == chairman, UnauthorizedAction());
        require(status == Status.Started, ElectionNotStartedOrEnded(status));
        status = Status.Ended;
        emit ElectionEnded();
    }

    function vote(uint256 proposal_id) external {
        require(status == Status.Started, ElectionNotStartedOrEnded(status));
        require(proposal_id < proposals.length, ProposalNotFound(proposal_id));

        Voter storage sender = voters[msg.sender];
        require(sender.active, VoterNotAdded(msg.sender));
        require(!sender.voted, VoterVoted(msg.sender));
        sender.voted = true;
        votedVoters++;

        Proposal storage proposal = proposals[proposal_id];
        proposal.votes++;
        if (winnerVotes < proposal.votes) {
            winnerStatus = WinnerStatus.SingleWin;
            winnerVotes = proposal.votes;
                winnerProposalId = proposal_id;
            emit ChangedWinner(proposal);
        } else if (winnerVotes == proposal.votes) {
            winnerStatus = WinnerStatus.DeadHeat;
        }
    }

    function getWinners() external view returns (Proposal[] memory winners) {
        require(status == Status.Ended, ElectionNotStartedOrEnded(status));
        require(winnerStatus != WinnerStatus.NotVoted, NotVoted());
        if (winnerStatus == WinnerStatus.SingleWin) {
            winners = new Proposal[](1);
            winners[0] = proposals[winnerProposalId];
            return winners;
        }
        uint256 count = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].votes == winnerVotes) {
                count++;
            }
        }
        winners = new Proposal[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].votes == winnerVotes) {
                winners[index] = proposals[i];
                index++;
            }
        }
    }

    function getWinnerStatus() external view returns (WinnerStatus) {
        require(status == Status.Ended, ElectionNotStartedOrEnded(status));
        return winnerStatus;
    }

    function getProposalName(uint256 proposal_id) external view returns (bytes32) {
        require(proposal_id < proposals.length, ProposalNotFound(proposal_id));
        return proposals[proposal_id].name;
    }
}
