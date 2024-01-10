// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test {
    address PARTICIPANT = makeAddr("participant");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 lotteryDuration;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    /** Events */
    event EnteredRaffle(address indexed participant, uint256 amount);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /** Modifiers */
    modifier raffleEntered() {
        vm.prank(PARTICIPANT);
        raffle.enter{value: entranceFee}();
        _;
    }

    modifier timePassed() {
        vm.warp(block.timestamp + lotteryDuration + 1);
        vm.roll(block.number + 1);
        _;
    }

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            lotteryDuration,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit,
            link
        ) = helperConfig.s_activeNetworkConfig();
        vm.deal(PARTICIPANT, STARTING_USER_BALANCE);
    }

    function test_RaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /** Enter raffle tests */

    function test_RaffleRevertsWhenYouDontPayEnough() public {
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enter();
    }

    function test_RaffleRecordsParticipantsAccurately() public raffleEntered {
        address participant = raffle.getParticipant(0);
        assert(participant == PARTICIPANT);
    }

    function test_RaffleEmitsEventOnEntrance() public {
        vm.prank(PARTICIPANT);
        vm.expectEmit(true, true, false, false, address(raffle));
        emit EnteredRaffle(PARTICIPANT, entranceFee);
        raffle.enter{value: entranceFee}();
    }

    function test_RaffleCantBeEnteredWhenCalculatingWinner()
        public
        raffleEntered
        timePassed
    {
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PARTICIPANT);
        raffle.enter{value: entranceFee}();
    }

    /** Check up keep tests */

    function test_CheckUpKeepReturnsFalseWhenLotteryDurationHasntPassed()
        public
        raffleEntered
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function test_CheckUpKeepReturnsFalseWhenNotOpen()
        public
        raffleEntered
        timePassed
    {
        raffle.performUpkeep("");
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function test_CheckUpKeepReturnsFalseWhenNotEnoughEth() public timePassed {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function test_CheckUpKeepReturnsFalseWhenNoParticipants()
        public
        timePassed
    {
        vm.deal(address(raffle), 100 ether);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function test_CheckUpKeepReturnsTrueWhenAllConditionsAreMet()
        public
        raffleEntered
        timePassed
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    /** Perform up keep tests */

    function test_PerformUpKeepCanOnlyRunIfCheckUpKeepReturnsTrue()
        public
        raffleEntered
        timePassed
    {
        raffle.performUpkeep("");
    }

    function test_PerformUpKeepRevertsIfCheckUpKeepReturnsFalse() public {
        uint256 currentBalance = 0;
        uint256 numParticipants = 0;
        uint256 raffleState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                currentBalance,
                numParticipants,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function test_PerformUpKeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntered
        timePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING_WINNER);
    }
}
