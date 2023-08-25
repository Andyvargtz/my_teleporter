// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "./IWarpProtocolRegistry.sol";
import "./WarpProtocolRegistry.sol";
import "../Teleporter/ITeleporterMessenger.sol";
import "../Teleporter/TeleporterMessenger.sol";
import "../Teleporter/TeleporterCaller.sol";

contract WarpProtocolRegistryTest is Test {
    address constant WARP_PRECOMPILE_ADDRESS =
        address(0x0200000000000000000000000000000000000005);

    WarpMessenger public constant WARP_MESSENGER =
        WarpMessenger(WARP_PRECOMPILE_ADDRESS);

    bytes32 public constant VALIDATORS_SOURCE_ADDRESS =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public mockBlockchainID = bytes32(uint256(123456));

    ITeleporterMessenger public teleporterMessenger;
    IWarpProtocolRegistry public warpRegistry;

    event RegisterProtocol(
        bytes32 indexed protocol,
        address indexed protocolAddress
    );

    event UpdateProtocolAddress(
        bytes32 indexed protocol,
        address indexed oldProtocolAddress,
        address indexed newProtocolAddress
    );

    function setUp() public virtual {
        vm.mockCall(
            WARP_PRECOMPILE_ADDRESS,
            abi.encodeWithSelector(WarpMessenger.getBlockchainID.selector),
            abi.encode(mockBlockchainID)
        );

        // Create a new teleporter messenger contract and set the test used state variable.
        TeleporterMessenger teleporter = new TeleporterMessenger();
        teleporterMessenger = ITeleporterMessenger(address(teleporter));

        // Create initial instance of warp protocol registry.
        WarpProtocolRegistry registry = new WarpProtocolRegistry();
        warpRegistry = IWarpProtocolRegistry(address(registry));
    }

    function testRegisterProtocolSuccess() public {
        ProtocolRegistryInput memory input = _createInitialRegistryInput();

        WarpMessage memory warpMsg = _createWarpMessage(input);
        _setUpSuccessGetVerifiedWarpMessageMock(warpMsg);

        vm.expectEmit(true, true, false, true, address(warpRegistry));
        emit RegisterProtocol(
            TeleporterCaller.PROTOCOL,
            address(input.protocolAddress)
        );
        warpRegistry.registerProtocolAddress();

        // Now that we've registered, teleporter address should be updated
        address teleporterAddress = warpRegistry.getProtocolAddress(
            TeleporterCaller.PROTOCOL
        );
        assertEq(teleporterAddress, address(teleporterMessenger));
    }

    function testUpdateProtocolAddressSuccess() public {
        ProtocolRegistryInput memory input = _createInitialRegistryInput();

        WarpMessage memory warpMsg = _createWarpMessage(input);
        _setUpSuccessGetVerifiedWarpMessageMock(warpMsg);

        warpRegistry.registerProtocolAddress();
        address currentAddress = warpRegistry.getProtocolAddress(
            TeleporterCaller.PROTOCOL
        );
        assertEq(address(teleporterMessenger), currentAddress);

        // Deploy a new teleporter contract address
        TeleporterMessenger newTeleporter = new TeleporterMessenger();
        input.protocolAddress = address(newTeleporter);
        input.nonce++;

        warpMsg = _createWarpMessage(input);
        _setUpSuccessGetVerifiedWarpMessageMock(warpMsg);

        // Expect an event for updating teleporter protocol address to new address.
        vm.expectEmit(true, true, true, true, address(warpRegistry));
        emit UpdateProtocolAddress(
            TeleporterCaller.PROTOCOL,
            address(teleporterMessenger),
            address(newTeleporter)
        );
        warpRegistry.updateProtocolAddress();

        // Check that the teleporter address is updated to new address value.
        currentAddress = warpRegistry.getProtocolAddress(
            TeleporterCaller.PROTOCOL
        );
        assertEq(address(newTeleporter), currentAddress);
    }

    function testInvalidNonce() public {
        ProtocolRegistryInput memory input = _createInitialRegistryInput();

        // Since we have not sent any messages to registry yet,
        // incrementing nonce should make an invalid register and update.
        input.nonce++;

        WarpMessage memory warpMsg = _createWarpMessage(input);
        _setUpSuccessGetVerifiedWarpMessageMock(warpMsg);

        vm.expectRevert("Invalid nonce.");
        warpRegistry.registerProtocolAddress();

        vm.expectRevert("Invalid nonce.");
        warpRegistry.updateProtocolAddress();
    }

    function testInvalidInputAddress() public {
        ProtocolRegistryInput memory input = _createInitialRegistryInput();

        // In register and update we require Address.isContract(protocolAddress),
        // and this should fail for address(0).
        input.protocolAddress = address(0);

        WarpMessage memory warpMsg = _createWarpMessage(input);
        _setUpSuccessGetVerifiedWarpMessageMock(warpMsg);

        vm.expectRevert("Invalid protocol address.");
        warpRegistry.registerProtocolAddress();

        vm.expectRevert("Invalid protocol address.");
        warpRegistry.updateProtocolAddress();
    }

    function testRegisterDuplicate() public {
        ProtocolRegistryInput memory input = _createInitialRegistryInput();

        WarpMessage memory warpMsg = _createWarpMessage(input);
        _setUpSuccessGetVerifiedWarpMessageMock(warpMsg);

        // Register teleporter once and try to register again, which should fail.
        warpRegistry.registerProtocolAddress();

        input.nonce++;
        warpMsg = _createWarpMessage(input);
        _setUpSuccessGetVerifiedWarpMessageMock(warpMsg);

        vm.expectRevert("Protocol already registered.");
        warpRegistry.registerProtocolAddress();
    }

    function testUpdatingNonRegisteredProtocol() public {
        ProtocolRegistryInput memory input = _createInitialRegistryInput();
        WarpMessage memory warpMsg = _createWarpMessage(input);
        _setUpSuccessGetVerifiedWarpMessageMock(warpMsg);

        vm.expectRevert("Protocol is not registered.");
        warpRegistry.updateProtocolAddress();
    }

    function testGetInvalidProtocolAddress() public {
        // No protocol has been registered yet, so getting teleporter address fails.
        vm.expectRevert("Unregistered protocol.");
        warpRegistry.getProtocolAddress(TeleporterCaller.PROTOCOL);
    }

    function _createWarpMessage(
        ProtocolRegistryInput memory input
    ) internal view returns (WarpMessage memory) {
        return
            WarpMessage({
                originChainID: mockBlockchainID,
                originSenderAddress: VALIDATORS_SOURCE_ADDRESS,
                destinationChainID: mockBlockchainID,
                destinationAddress: _addressToBytes32(address(warpRegistry)),
                payload: abi.encode(input)
            });
    }

    function _createInitialRegistryInput()
        internal
        view
        returns (ProtocolRegistryInput memory)
    {
        return
            ProtocolRegistryInput({
                nonce: 1,
                protocol: TeleporterCaller.PROTOCOL,
                protocolAddress: address(teleporterMessenger)
            });
    }

    function _setUpSuccessGetVerifiedWarpMessageMock(
        WarpMessage memory warpMessage
    ) internal {
        vm.mockCall(
            WARP_PRECOMPILE_ADDRESS,
            abi.encodeCall(WarpMessenger.getVerifiedWarpMessage, ()),
            abi.encode(warpMessage, true)
        );
        vm.expectCall(
            WARP_PRECOMPILE_ADDRESS,
            abi.encodeCall(WarpMessenger.getVerifiedWarpMessage, ())
        );
    }

    function _addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }
}
