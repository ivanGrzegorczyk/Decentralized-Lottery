// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title Raffle contract
 * @author Iván Grzegorczyk
 * @notice This contract is for creating a sample raffle
 */
contract Raffle is VRFConsumerBaseV2 {
    /** Errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleNotOpen();
    error Raffle__TransferFailed();
    error Raffle__UpKeepNotNeeded(
        uint256 balance,
        uint256 participantsLength,
        uint256 raffleState
    );

    /** Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING_WINNER
    }

    /** Constants */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /** Immutable variables */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_lotteryDuration;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    /** Storage variables */
    address payable[] private s_participants;
    uint256 private s_lastTimeStamp;
    address private s_lastWinner;
    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle(address indexed participant, uint256 amount);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 lotteryDuration,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_lotteryDuration = lotteryDuration;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    /** External functions */

    function enter() external payable {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_participants.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender, msg.value);
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_participants.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING_WINNER;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId); // this is redundant because the VRF Coordinator emits the same event
    }

    /** Public functions */

    /**
     * @dev This is a function that the Chainlink Automation nodes call to see if
     * it's time to perform an upkeep.
     * @return upkeepNeeded It will return true if the following conditions are met:
     * 1. The time interval between two raffles has passed
     * 2. The raffle is in OPEN state
     * 3. The contract has ETH
     * 4. The contract has participants
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = block.timestamp - s_lastTimeStamp >=
            i_lotteryDuration;
        bool raffleIsOpen = s_raffleState == RaffleState.OPEN;
        bool hasEnoughEth = address(this).balance >= 0;
        bool hasParticipants = s_participants.length > 0;
        upkeepNeeded =
            timeHasPassed &&
            raffleIsOpen &&
            hasEnoughEth &&
            hasParticipants;
        return (upkeepNeeded, "0x0");
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getParticipant(uint256 index) external view returns (address) {
        return s_participants[index];
    }

    /** Internal functions */

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory _randomWords
    ) internal override {
        uint256 winnerIndex = _randomWords[0] % s_participants.length;
        address payable winner = s_participants[winnerIndex];
        s_lastWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_participants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        (bool success, ) = s_lastWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }
}
