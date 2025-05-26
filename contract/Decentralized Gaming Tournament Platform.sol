// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    address public owner;
    uint256 public tournamentIdCounter = 0;

    enum TournamentStatus { Open, InProgress, Completed }

    struct Tournament {
        uint256 id;
        string name;
        uint256 entryFee;
        address[] participants;
        TournamentStatus status;
        address winner;
    }

    mapping(uint256 => Tournament) public tournaments;
    mapping(uint256 => mapping(address => bool)) public isParticipant;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier tournamentExists(uint256 _id) {
        require(tournaments[_id].id != 0, "Tournament does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTournament(string memory _name, uint256 _entryFee) external onlyOwner returns (uint256) {
        tournamentIdCounter++;
        tournaments[tournamentIdCounter] = Tournament({
            id: tournamentIdCounter,
            name: _name,
            entryFee: _entryFee,
            participants: new address[](0),
            status: TournamentStatus.Open,
            winner: address(0)
        });
        return tournamentIdCounter;
    }

    function register(uint256 _tournamentId) external payable tournamentExists(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.status == TournamentStatus.Open, "Tournament is not open");
        require(msg.value == tournament.entryFee, "Incorrect entry fee");
        require(!isParticipant[_tournamentId][msg.sender], "Already registered");

        tournament.participants.push(msg.sender);
        isParticipant[_tournamentId][msg.sender] = true;
    }

    function completeTournament(uint256 _tournamentId, address _winner) external onlyOwner tournamentExists(_tournamentId) {
        Tournament storage tournament = tournaments[_tournamentId];
        require(tournament.status == TournamentStatus.Open || tournament.status == TournamentStatus.InProgress, "Cannot complete tournament");
        require(isParticipant[_tournamentId][_winner], "Winner not a participant");

        tournament.status = TournamentStatus.Completed;
        tournament.winner = _winner;

        payable(_winner).transfer(tournament.entryFee * tournament.participants.length);
    }

    function getParticipants(uint256 _tournamentId) external view tournamentExists(_tournamentId) returns (address[] memory) {
        return tournaments[_tournamentId].participants;
    }
}
