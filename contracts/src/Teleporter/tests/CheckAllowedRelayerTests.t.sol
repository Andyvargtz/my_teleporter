// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import "./TeleporterMessengerTest.t.sol";

contract CheckIsAllowedRelayerTest is TeleporterMessengerTest {
    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment.
    function setUp() public virtual override {
        TeleporterMessengerTest.setUp();
    }

    function testIsSpecifiedAllowedRelayer() public {
        address relayerAddress = 0x6288dAdf62B57dd9A4ddcd02F88A98d0eb6c2598;
        address[] memory allowedRelayers = new address[](3);
        allowedRelayers[0] = relayerAddress;
        allowedRelayers[1] = 0xDeaDBeEf62B57DD9a4ddcD02F88a98d0eb6C2598;
        allowedRelayers[2] = 0xfFfFfFFffFB57Dd9A4ddcD02f88A98D0Eb6c2598;
        assertTrue(
            teleporterMessenger.checkIsAllowedRelayer(
                relayerAddress,
                allowedRelayers
            )
        );
    }

    function testAnyRelayerIsAllowed() public {
        address[] memory relayerAddresses = new address[](3);
        relayerAddresses[0] = 0x6288dAdf62B57dd9A4ddcd02F88A98d0eb6c2598;
        relayerAddresses[1] = 0xDeaDBeEf62B57DD9a4ddcD02F88a98d0eb6C2598;
        relayerAddresses[2] = 0xfFfFfFFffFB57Dd9A4ddcD02f88A98D0Eb6c2598;
        address[] memory allowedRelayers = new address[](0);

        for (uint256 i = 0; i < relayerAddresses.length; i++)
            assertTrue(
                teleporterMessenger.checkIsAllowedRelayer(
                    relayerAddresses[i],
                    allowedRelayers
                )
            );
    }

    function testUnauthorizedRelayer() public {
        address relayerAddress = 0x6288dAdf62B57dd9A4ddcd02F88A98d0eb6c2598;
        address[] memory allowedRelayers = new address[](3);
        allowedRelayers[0] = 0xCaFEbabE62B57DD9A4dDcD02F88A98d0Eb6c2598;
        allowedRelayers[1] = 0xDeaDBeEf62B57DD9a4ddcD02F88a98d0eb6C2598;
        allowedRelayers[2] = 0xfFfFfFFffFB57Dd9A4ddcD02f88A98D0Eb6c2598;

        assertFalse(
            teleporterMessenger.checkIsAllowedRelayer(
                relayerAddress,
                allowedRelayers
            )
        );
    }
}
