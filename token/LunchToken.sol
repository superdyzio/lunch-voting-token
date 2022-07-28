// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LunchToken is ERC20 {
    bool public voteOpen = false;
    string[] public optionNames;
    uint256[] public optionVotes;
    mapping(uint256 => address[]) public optionVoters;
    string public lastWinner;

    address private _owner;

    address[] private participants;
    mapping(address => string) private participantName;

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Only the contract owner can invoke this method."
        );
        _;
    }

    modifier votingAllowed() {
        require(voteOpen, "This operation is allowed only when vote is open.");
        _;
    }

    modifier votingClosed() {
        require(
            !voteOpen,
            "This operation is allowed only when vote is closed."
        );
        _;
    }

    modifier onlyParticipant() {
        require(
            isParticipant(_msgSender()),
            "This operation can be performed only by a participant."
        );
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _owner = _msgSender();
    }

    function destroyContract(address payable adr) public onlyOwner {
        selfdestruct(adr);
    }

    function registerParticipant(address addr, string calldata name)
        external
        onlyOwner
    {
        participants.push(addr);
        participantName[addr] = name;
    }

    function removeParticipant(address addr) external onlyOwner {
        if (isParticipant(addr)) {
            uint256 j;
            for (uint256 i = 0; i < participants.length; i++) {
                if (participants[i] == addr) {
                    j = i;
                    break;
                }
            }
            participants[j] = participants[participants.length - 1];
            participants.pop();
            participantName[addr] = "";
        }
    }

    function getAllParticipantNames() external view returns (string[] memory) {
        uint256 len = participants.length;
        string[] memory result = new string[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = participantName[participants[i]];
        }
        return result;
    }

    function startVoting(uint256 allocation) external onlyOwner votingClosed {
        voteOpen = true;
        for (uint256 i = 0; i < participants.length; i += 1) {
            _mint(participants[i], allocation);
        }
    }

    function addOption(string memory name_)
        external
        votingAllowed
        onlyParticipant
    {
        optionNames.push(name_);
        optionVotes.push(0);
    }

    function getOptions()
        external
        view
        onlyParticipant
        returns (string[] memory)
    {
        return optionNames;
    }

    function vote(uint256 position, uint256 votes)
        external
        votingAllowed
        onlyParticipant
    {
        approve(_owner, votes);
        optionVotes[position] += votes;
        optionVoters[position].push(_msgSender());
    }

    function endVoting() external onlyOwner votingAllowed {
        voteOpen = false;
        (uint256 winnerPosition, uint256 reward) = findWinner();
        distributeRewardsToVoters(winnerPosition, reward);
        resetPassiveParticipantsBalance();
        lastWinner = optionNames[winnerPosition];
    }

    function getLastWinner()
        external
        view
        votingClosed
        returns (string memory)
    {
        return lastWinner;
    }

    function isParticipant(address addr) public view returns (bool) {
        return bytes(participantName[addr]).length != 0;
    }

    function getParticipantName(address addr)
        external
        view
        onlyOwner
        returns (string memory)
    {
        return participantName[addr];
    }

    function findWinner()
        internal
        view
        returns (uint256 winnerPosition, uint256 reward)
    {
        uint256 maxVotes = 0;
        winnerPosition = 0;
        reward = 0;
        for (uint256 i = 0; i < optionVotes.length; i += 1) {
            if (optionVotes[i] > maxVotes) {
                maxVotes = optionVotes[i];
                winnerPosition = i;
            }
            reward += optionVotes[i];
        }
    }

    function distributeRewardsToVoters(uint256 position, uint256 reward)
        internal
    {
        address[] memory winningVoters = optionVoters[position];
        uint256 individualReward = reward / winningVoters.length;
        for (uint256 i = 0; i < participants.length; i += 1) {
            if (hasVoted(participants[i])) {
                transferFrom(
                    participants[i],
                    _owner,
                    allowance(participants[i], _owner)
                );
            }
        }
        for (uint256 i = 0; i < winningVoters.length; i += 1) {
            transfer(winningVoters[i], individualReward);
        }
    }

    function resetPassiveParticipantsBalance() internal {
        for (uint256 i = 0; i < participants.length; i += 1) {
            if (!hasVoted(participants[i])) {
                _burn(participants[i], balanceOf(participants[i]));
            }
        }
    }

    function hasVoted(address address_) internal view returns (bool) {
        for (uint256 i = 0; i < optionNames.length; i += 1) {
            for (uint256 j = 0; j < optionVoters[i].length; j += 1) {
                if (optionVoters[i][j] == address_) {
                    return true;
                }
            }
        }
        return false;
    }
}
