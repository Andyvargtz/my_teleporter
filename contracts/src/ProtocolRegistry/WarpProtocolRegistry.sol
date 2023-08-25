// (c) 2022-2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./IWarpProtocolRegistry.sol";
import "@subnet-evm-contracts/IWarpMessenger.sol";
import "@openzeppelin/contracts/utils/Address.sol";

struct ProtocolRegistryInput {
    uint256 nonce;
    bytes32 protocol;
    address protocolAddress;
}

/**
 * @dev Implementation of the {IWarpProtocolRegistry} interface.
 */
contract WarpProtocolRegistry is IWarpProtocolRegistry {
    // Address of the warp precompile.
    address public constant WARP_PRECOMPILE_ADDRESS =
        0x0200000000000000000000000000000000000005;

    // Address that the out-of-band warp message sets as the "source" address.
    // The address is obviously not owned by any EOA or smart contract account, so it
    // can not possibly be the source address of any other warp message emitted by the VM.
    bytes32 public constant VALIDATORS_SOURCE_ADDRESS =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    WarpMessenger public constant WARP_MESSENGER =
        WarpMessenger(WARP_PRECOMPILE_ADDRESS);

    mapping(bytes32 => address) public protocolAddresses;

    bytes32 private immutable _chainID;

    uint256 private _nonce;

    /**
     * @dev Sets the initial values for {_nonce} and {_chainID}.
     *
     * {_chainID} is an immutable value we get from the warp precompile.
     */
    constructor() {
        _nonce = 0;
        _chainID = WARP_MESSENGER.getBlockchainID();
    }

    /**
     * @dev See {IWarpProtocolRegistry-registerProtocolAddresses}.
     *
     * Requirements:
     * - valid warp out of band message for registry.
     * - input protocol has not previously been registered.
     */
    function registerProtocolAddress() external {
        ProtocolRegistryInput memory input = _getVerifiedProtocolInput();

        require(
            protocolAddresses[input.protocol] == address(0),
            "Protocol already registered."
        );

        protocolAddresses[input.protocol] = input.protocolAddress;
        _nonce++;
        emit RegisterProtocol(input.protocol, input.protocolAddress);
    }

    /**
     * @dev See {IWarpProtocolRegistry-updateProtocolAddress}.
     *
     * Requirements:
     * - valid warp out of band message for registry.
     * - input protocol has previously been registered.
     */
    function updateProtocolAddress() external {
        ProtocolRegistryInput memory input = _getVerifiedProtocolInput();

        require(
            protocolAddresses[input.protocol] != address(0),
            "Protocol is not registered."
        );

        emit UpdateProtocolAddress(
            input.protocol,
            protocolAddresses[input.protocol],
            input.protocolAddress
        );

        protocolAddresses[input.protocol] = input.protocolAddress;
        _nonce++;
    }

    /**
     * @dev See {IWarpProtocolRegistry-getProtocolAddress}.
     *
     * Requirements:
     * - input protocol has previously been registered.
     */
    function getProtocolAddress(
        bytes32 protocol
    ) external view returns (address) {
        address result = protocolAddresses[protocol];
        require(result != address(0), "Unregistered protocol.");
        return result;
    }

    /**
     * @dev Checks for a valid warp out of band message and returns the {ProtocolRegistryInput}.
     *
     * Requirements:
     * - valid warp message is returned from warp messenger.
     * - warp message origin and destination chain ids are same as `_chainID`.
     * - warp message origin sender is `VALIDATORS_SOURCE_ADDRESS`
     * - warp message destination address is this registry contract's address.
     * - input {ProtocolRegistryInput} has correct nonce value.
     * - input {ProtocolRegistryInput} `protocolAddress` is a contract.
     */
    function _getVerifiedProtocolInput()
        private
        view
        returns (ProtocolRegistryInput memory)
    {
        (WarpMessage memory warpMessage, bool exists) = WARP_MESSENGER
            .getVerifiedWarpMessage();

        require(exists, "No valid warp message.");
        require(
            warpMessage.originChainID == _chainID,
            "Invalid origin chain ID."
        );
        require(
            warpMessage.originSenderAddress == VALIDATORS_SOURCE_ADDRESS,
            "Invalid origin sender address."
        );
        require(
            warpMessage.destinationChainID == _chainID,
            "Invalid destination chain ID."
        );
        require(
            warpMessage.destinationAddress ==
                bytes32(uint256(uint160(address(this)))),
            "Invalid destination address."
        );

        ProtocolRegistryInput memory input = abi.decode(
            warpMessage.payload,
            (ProtocolRegistryInput)
        );

        require(input.nonce == _nonce + 1, "Invalid nonce.");

        // Check that the input protocol address is a contract, which would revert if address(0) was passed in.
        require(
            Address.isContract(input.protocolAddress),
            "Invalid protocol address."
        );

        return input;
    }
}
