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

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            lotteryDuration,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit
        ) = helperConfig.s_activeNetworkConfig();
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}
