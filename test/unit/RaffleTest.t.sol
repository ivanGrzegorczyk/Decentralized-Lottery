// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";

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

    function test_RaffleRevertsWhenYouDontPayEnough() public {
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enter();
    }

    function test_RaffleRecordsParticipantsAccurately() public {
        vm.prank(PARTICIPANT);
        raffle.enter{value: entranceFee}();
        address participant = raffle.getParticipant(0);
        assert(participant == PARTICIPANT);
    }

    function test_RaffleEmitsEventOnEntrance() public {
        vm.prank(PARTICIPANT);
        vm.expectEmit(true, true, false, false, address(raffle));
        emit EnteredRaffle(PARTICIPANT, entranceFee);
        raffle.enter{value: entranceFee}();
    }

    function test_RaffleCantBeEnteredWhenCalculatingWinner() public {
        vm.prank(PARTICIPANT);
        raffle.enter{value: entranceFee}();
        vm.warp(block.timestamp + lotteryDuration + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PARTICIPANT);
        raffle.enter{value: entranceFee}();
    }
}
