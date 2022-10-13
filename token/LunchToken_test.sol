// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol";
import "remix_accounts.sol";
import ".\LunchToken.sol";

contract testSuite {
    LunchToken public lunchToken;

    function beforeAll() public {
        lunchToken = new LunchToken("Lunch Token Test", "LVTT");
    }

    function checkStartVotingTokensAllocation() public {
        // arrange
        lunchToken.registerParticipant(0xAA86C4eFcB63dE40d16729734B474Fe68AA570D1, "Dawid");
        lunchToken.registerParticipant(0x9558C48F1c1Cb68393ffD278C863D8d05a1C47B9, "Iwona");

        // act
        lunchToken.startVoting(1000);

        // assert
        Assert.equal(
            lunchToken.balanceOf(0xAA86C4eFcB63dE40d16729734B474Fe68AA570D1),
            1000,
            "first participant should have 1000 tokens"
        );
        Assert.equal(
            lunchToken.balanceOf(0x9558C48F1c1Cb68393ffD278C863D8d05a1C47B9),
            1000,
            "second participant should have 1000 tokens"
        );
    }

    function afterEach() public {
        lunchToken.removeParticipant(0xAA86C4eFcB63dE40d16729734B474Fe68AA570D1);
        lunchToken.removeParticipant(0x9558C48F1c1Cb68393ffD278C863D8d05a1C47B9);
    }

    function returnFalseWhenNotParticipating() public {
        lunchToken.registerParticipant(0xAA86C4eFcB63dE40d16729734B474Fe68AA570D1, "Dawid");

        (bool _isParticipant, uint256 i) = lunchToken.isParticipant(0x9558C48F1c1Cb68393ffD278C863D8d05a1C47B9);

        Assert.equal(
            _isParticipant,
            false,
            "this address is not a participant"
        );
    }

    function returnTrueWhenParticipating() public {
        lunchToken.registerParticipant(0xAA86C4eFcB63dE40d16729734B474Fe68AA570D1, "Dawid");

        (bool _isParticipant, uint256 i) = lunchToken.isParticipant(0xAA86C4eFcB63dE40d16729734B474Fe68AA570D1);

        Assert.equal(
            _isParticipant,
            true,
            "this address is a participant"
        );
    }
}
