// (c) 2022-2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.16;

/**
 * @dev Interface for a registry that keeps track of warp protocol addresses.
 */
interface IWarpProtocolRegistry {
    /**
     * @dev Emitted when a new `protocol` is registered in the registry with its `protocolAddress.
     */
    event RegisterProtocol(
        bytes32 indexed protocol,
        address indexed protocolAddress
    );

    /**
     * @dev Emitted when a registered `protocol` updates its address.
     */
    event UpdateProtocolAddress(
        bytes32 indexed protocol,
        address indexed oldProtocolAddress,
        address indexed newProtocolAddress
    );

    /**
     * @dev Registers a new protocol to the warp registry.
     *
     * Emits a {RegisterProtocol} event.
     */
    function registerProtocolAddress() external;

    /**
     * @dev Updates a registered protocol's address in the warp registry.
     *
     * Emits an {UpdateProtocolAddress} event.
     */
    function updateProtocolAddress() external;

    /**
     * @dev Gets the protocol's address recorded in the warp registry.
     */
    function getProtocolAddress(
        bytes32 protocol
    ) external view returns (address);
}
