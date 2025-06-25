// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle Contract
 * @author Ebenezer Igbinoba
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
    */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeepNotNeed(uint256 walletBalance, uint256 numberOfPlayers, uint256 raffleState);

    /** Type declarations */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    /** State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    address payable[] private s_players; // using storage cos the players would keep changing
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_interval; // period between one raffle draw and the next one
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**
     * Event
     */
    event WinnerPicked(address indexed recentWinner);
    event RaffleEntered(address indexed player); // indexed is a keyword in Solidity, and it's used in event declarations to make up to three parameters searchable/filterable in the blockchain logs

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        // call the vrf library contract constructor
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp; // block represents the most recent block on the blockchain
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender)); // using payable cos the players would be paid
        emit RaffleEntered(msg.sender);
    }
    
    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     * @return upkeepNeeded - true if it is time to restart the lottery
    */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool hasTimePassed = (block.timestamp - s_lastTimeStamp) < i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = hasTimePassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        // check to see if the time has passed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) {
            revert Raffle__UpKeepNotNeed(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, // maximum gas price you are willing to pay for a request in wei
            subId: i_subscriptionId, // The subscription ID that this contract uses for funding requests.
            requestConfirmations: REQUEST_CONFIRMATIONS, // How many confirmations the Chainlink node should wait before responding. confirmations means mined blocks added to the blockchain
            callbackGasLimit: i_callbackGasLimit, // the limit for how much gas to use for the callback request to your contract's fulfillRandomWords function
            numWords: NUM_WORDS, // How many random values to request.
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 /** requestId */, uint256[] calldata randomWords) internal override {
        /** Checks */
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];

        /** Effects */
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        /** Interactions */
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if(!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(s_recentWinner);
    }

    /**
     * Getters
    */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 playerIndex) external view returns (address) {
        return s_players[playerIndex];
    }
}

/**
 * Always try to follow the CEI patterns (Checks (conditionals at the begining of functions)
 * Effects - side effects and state variable modifications
 * Interactions - interaction with external contracts (e.g transfer of eth to external contracts)
*/