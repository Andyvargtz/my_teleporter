// (c) 2022-2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../ProtocolRegistry/IWarpProtocolRegistry.sol";
import "./ITeleporterMessenger.sol";

/**
 * @dev Collection of functions that get a warp registry's teleporter address, and makes {ITeleporterMessenger} function calls
 */
library TeleporterCaller {
    bytes32 public constant PROTOCOL = bytes32("teleporter");

    /**
     * @dev See {ITeleporterMessenger-sendCrossChainMessage}
     */
    function sendCrossChainMessage(
        IWarpProtocolRegistry registry,
        TeleporterMessageInput memory messageInput
    ) internal returns (uint256) {
        return
            ITeleporterMessenger(getTeleporterAddress(registry))
                .sendCrossChainMessage(messageInput);
    }

    /**
     * @dev See {ITeleporterMessenger-retrySendCrossChainMessage}
     */
    function retrySendCrossChainMessage(
        IWarpProtocolRegistry registry,
        bytes32 destinationChainID,
        TeleporterMessage memory message
    ) internal {
        ITeleporterMessenger(getTeleporterAddress(registry))
            .retrySendCrossChainMessage(destinationChainID, message);
    }

    /**
     * @dev See {ITeleporterMessenger-getMessageHash}
     */
    function getMessageHash(
        IWarpProtocolRegistry registry,
        bytes32 destinationChainID,
        uint256 messageID
    ) internal view returns (bytes32 messageHash) {
        return
            ITeleporterMessenger(getTeleporterAddress(registry)).getMessageHash(
                destinationChainID,
                messageID
            );
    }

    /**
     * @dev See {ITeleporterMessenger-addFeeAmount}
     */
    function addFeeAmount(
        IWarpProtocolRegistry registry,
        bytes32 destinationChainID,
        uint256 messageID,
        address feeContractAddress,
        uint256 additionalFeeAmount
    ) internal {
        ITeleporterMessenger(getTeleporterAddress(registry)).addFeeAmount(
            destinationChainID,
            messageID,
            feeContractAddress,
            additionalFeeAmount
        );
    }

    /**
     * @dev See {ITeleporterMessenger-getFeeInfo}
     */
    function getFeeInfo(
        IWarpProtocolRegistry registry,
        bytes32 destinationChainID,
        uint256 messageID
    ) internal view returns (address feeAsset, uint256 feeAmount) {
        return
            ITeleporterMessenger(getTeleporterAddress(registry)).getFeeInfo(
                destinationChainID,
                messageID
            );
    }

    /**
     * @dev See {ITeleporterMessenger-receiveCrossChainMessage}
     */
    function receiveCrossChainMessage(
        IWarpProtocolRegistry registry,
        address relayerRewardAddress
    ) internal {
        ITeleporterMessenger(getTeleporterAddress(registry))
            .receiveCrossChainMessage(relayerRewardAddress);
    }

    /**
     * @dev See {ITeleporterMessenger-retryMessageExecution}
     */
    function retryMessageExecution(
        IWarpProtocolRegistry registry,
        bytes32 originChainID,
        TeleporterMessage calldata message
    ) internal {
        ITeleporterMessenger(getTeleporterAddress(registry))
            .retryMessageExecution(originChainID, message);
    }

    /**
     * @dev See {ITeleporterMessenger-messageReceived}
     */
    function messageReceived(
        IWarpProtocolRegistry registry,
        bytes32 originChainID,
        uint256 messageID
    ) internal view returns (bool delivered) {
        return
            ITeleporterMessenger(getTeleporterAddress(registry))
                .messageReceived(originChainID, messageID);
    }

    /**
     * @dev See {ITeleporter-getRelayerRewardAddress}
     */
    function getRelayerRewardAddress(
        IWarpProtocolRegistry registry,
        bytes32 originChainID,
        uint256 messageID
    ) internal view returns (address relayerRewardAddress) {
        return
            ITeleporterMessenger(getTeleporterAddress(registry))
                .getRelayerRewardAddress(originChainID, messageID);
    }

    /**
     * @dev See {ITeleporterMessenger-retryReceipts}
     */
    function retryReceipts(
        IWarpProtocolRegistry registry,
        bytes32 originChainID,
        uint256[] calldata messageIDs,
        TeleporterFeeInfo calldata feeInfo,
        address[] calldata allowedRelayerAddresses
    ) internal returns (uint256 messageID) {
        return
            ITeleporterMessenger(getTeleporterAddress(registry)).retryReceipts(
                originChainID,
                messageIDs,
                feeInfo,
                allowedRelayerAddresses
            );
    }

    /**
     * @dev See {ITeleporterMessenger-checkRelayerRewardAmount}
     */
    function checkRelayerRewardAmount(
        IWarpProtocolRegistry registry,
        address relayer,
        address feeAsset
    ) internal returns (uint256) {
        return
            ITeleporterMessenger(getTeleporterAddress(registry))
                .checkRelayerRewardAmount(relayer, feeAsset);
    }

    /**
     * @dev See {ITeleporterMessenger-redeemRelayerRewards}
     */
    function redeemRelayerRewards(
        IWarpProtocolRegistry registry,
        address feeAsset
    ) internal {
        ITeleporterMessenger(getTeleporterAddress(registry))
            .redeemRelayerRewards(feeAsset);
    }

    /**
     * @dev Returns the teleporter protocol address recorded in registry.
     */
    function getTeleporterAddress(
        IWarpProtocolRegistry registry
    ) internal view returns (address) {
        return registry.getProtocolAddress(PROTOCOL);
    }
}
