// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../ReentrancyGuards.sol";

// Errors
error ReceiveFailed();
error SendFailed();

contract ReentrancyGuardsTests is Test {
    SampleMessenger internal _sampleMessenger;

    function setUp() public virtual {
        _sampleMessenger = new SampleMessenger();
    }

    function testConsecutiveSendSuccess() public {
        _sampleMessenger.sendAndCall(new bytes(0));
        _sampleMessenger.sendMessage();
        _sampleMessenger.sendAndCall(new bytes(0));
        assertEq(_sampleMessenger.nonce(), 3);
    }

    function testConsecutiveReceiveSuccess() public {
        _sampleMessenger.receiveAndCall(new bytes(0));
        _sampleMessenger.receiveMessage();
        _sampleMessenger.receiveAndCall(new bytes(0));
        assertEq(_sampleMessenger.nonce(), 3);
    }

    function testRecursiveSendFails() public {
        // First we check when a send function calls another send function, which should fail.
        bytes memory sendMsg = abi.encodeCall(SampleMessenger.sendMessage, ());
        vm.expectRevert(SendFailed.selector);
        _sampleMessenger.sendAndCall(sendMsg);

        // We also need to check that we fail if a send function calls a receive function,
        // and then calls send function again
        bytes memory receiveMsg = abi.encodeCall(
            SampleMessenger.receiveAndCall,
            (sendMsg)
        );
        vm.expectRevert(SendFailed.selector);
        _sampleMessenger.sendAndCall(receiveMsg);
    }

    function testRecursiveReceiveFails() public {
        // First we check when a receive function calls another receive function, which should fail.
        bytes memory receiveMsg = abi.encodeCall(
            SampleMessenger.receiveMessage,
            ()
        );
        vm.expectRevert(ReceiveFailed.selector);
        _sampleMessenger.receiveAndCall(receiveMsg);

        // We also need to check that we fail if a receive function calls a send function,
        // and then calls receive function again
        bytes memory sendMsg = abi.encodeCall(
            SampleMessenger.sendAndCall,
            (receiveMsg)
        );
        vm.expectRevert(ReceiveFailed.selector);
        _sampleMessenger.receiveAndCall(sendMsg);
    }

    function testSendCallsReceiveSuccess() public {
        bytes memory message = abi.encodeCall(
            SampleMessenger.receiveMessage,
            ()
        );
        _sampleMessenger.sendAndCall(message);
        assertEq(_sampleMessenger.nonce(), 2);
    }

    function testReceiveCallsSendSuccess() public {
        bytes memory message = abi.encodeCall(SampleMessenger.sendMessage, ());
        _sampleMessenger.receiveAndCall(message);
        assertEq(_sampleMessenger.nonce(), 2);
    }

    function testRecursiveDirectSendFails() public {
        // We want to check sending recursively by directly making a function call and not low level call also fails.
        vm.expectRevert(ReentrancyGuards.SenderReentrancy.selector);
        _sampleMessenger.sendRecursive();

        assertEq(_sampleMessenger.nonce(), 0);
    }

    function testRecursiveDirectReceiveFails() public {
        // We want to check receiving recursively by directly making a function call and not low level call also fails.
        vm.expectRevert(ReentrancyGuards.ReceiverReentrancy.selector);
        _sampleMessenger.receiveRecursive();

        assertEq(_sampleMessenger.nonce(), 0);
    }
}

contract SampleMessenger is ReentrancyGuards {
    uint256 public nonce;

    constructor() {
        nonce = 0;
    }

    function sendAndCall(bytes memory message) public senderNonReentrant {
        nonce++;
        if (message.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(message);
            if (!success) {
                revert SendFailed();
            }
        }
    }

    function sendMessage() public senderNonReentrant {
        nonce++;
    }

    function sendRecursive() public senderNonReentrant {
        nonce++;
        sendMessage();
    }

    function receiveAndCall(bytes memory message) public receiverNonReentrant {
        nonce++;
        if (message.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(message);
            if (!success) {
                revert ReceiveFailed();
            }
        }
    }

    function receiveMessage() public receiverNonReentrant {
        nonce++;
    }

    function receiveRecursive() public receiverNonReentrant {
        nonce++;
        receiveMessage();
    }
}
