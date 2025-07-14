// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {SubscriptionManager} from "./SubscriptionManager.sol";

contract CrossChainManager is CCIPReceiver {
    IRouterClient private immutable i_router;
    IERC20 public i_token;
    SubscriptionManager private immutable i_subscriptionManager;

    event MessageSent(bytes32 indexed messageId, uint64 destinationChainSelector, address receiver);
    event MessageReceived(address sender, string message);

    error CrossChainManager__UnauthorizedSender(address sender);
    error CrossChainManager__InsufficientBalanceForFee();

    enum Action {
        PAY,
        CANCEL
    }

    struct SyncMessage {
        Action action;
        string companyName;
        address[] users;
    }

    constructor(address _router, address _token, address subscriptionManager) CCIPReceiver(_router) {
        i_router = IRouterClient(_router);
        i_token = IERC20(_token);
        i_subscriptionManager = SubscriptionManager(payable(subscriptionManager));
    }

    function _sendCCIPMessage(uint64 _destinationChainSelector, address _receiver, SyncMessage memory _message)
        public
    {
        // Encode the receiver and message data
        bytes memory encodedReceiver = abi.encode(_receiver);
        bytes memory encodedMessage = abi.encode(_message);

        // Prepare extraArgs
        Client.EVMExtraArgsV1 memory extraArgs = Client.EVMExtraArgsV1({gasLimit: 500_000});

        // Encode extraArgs
        bytes memory extraArgsEncoded = abi.encodeWithSelector(Client.EVM_EXTRA_ARGS_V1_TAG, extraArgs);

        // Construct the message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: encodedReceiver,
            data: encodedMessage,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: extraArgsEncoded,
            feeToken: address(i_token)
        });

        // Get the fee
        uint256 fee = i_router.getFee(_destinationChainSelector, message);
        if (i_token.balanceOf(address(this)) < fee) {
            revert CrossChainManager__InsufficientBalanceForFee();
        }

        // Approve LINK to Router
        i_token.approve(address(i_router), fee);

        // Send the message
        bytes32 messageId = i_router.ccipSend(_destinationChainSelector, message);
        emit MessageSent(messageId, _destinationChainSelector, _receiver);
    }

    function sendMessage(
        Action action,
        string memory companyName,
        address[] memory users,
        uint64 destinationChainSelector,
        address receiver
    ) public {
        // Create the sync message
        SyncMessage memory syncMessage = SyncMessage({action: action, companyName: companyName, users: users});

        // Encode the sync message
        // bytes memory encodedMessage = abi.encode(syncMessage);

        // Send the CCIP message
        _sendCCIPMessage(destinationChainSelector, receiver, syncMessage);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        // if (msg.sender != address(i_router)) {
        // revert CrossChainManager__UnauthorizedSender(msg.sender);
        // }

        SyncMessage memory sync = abi.decode(message.data, (SyncMessage));

        address sender = abi.decode(message.sender, (address));

        emit MessageReceived(
            sender, sync.action == Action.PAY ? "PAY" : sync.action == Action.CANCEL ? "Cancel" : "Unknown"
        );

        if (sync.action == Action.PAY) {
            for (uint256 i = 0; i < sync.users.length; i++) {
                // charge user, mint token, update timestamp, etc.
                i_subscriptionManager.paySubscriptionWhenReceived(
                    sync.companyName,
                    i_subscriptionManager.getCompanySubscription(sync.companyName).subscriptionAddress,
                    i_subscriptionManager.getCompanySubscription(sync.companyName).price
                );
            }
        } else if (sync.action == Action.CANCEL) {
            for (uint256 i = 0; i < sync.users.length; i++) {
                // remove user subscription mapping, etc.
                i_subscriptionManager.cancelSubscriptionWhenReceived(sync.companyName, sync.users[i]);
            }
        }
    }
}
