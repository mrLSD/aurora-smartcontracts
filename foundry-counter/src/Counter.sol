// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "@openzeppelin-contracts/access/AccessControl.sol";
import {
AuroraSdk,
IERC20,
Codec,
NEAR,
PromiseCreateArgs,
PromiseResultStatus,
PromiseWithCallback
} from "@aurora-sdk/AuroraSdk.sol";

// NEAR gas constants (TGas)
uint64 constant CONTRACT_CALL_NEAR_GAS = 35_000_000_000_000;
uint64 constant CONTRACT_CALLBACK_NEAR_GAS = 10_000_000_000_000;
uint64 constant APPROVE_NEAR_GAS = 20_000_000_000_000;

contract Counter is AccessControl {
    using AuroraSdk for NEAR;
    using AuroraSdk for PromiseCreateArgs;
    using AuroraSdk for PromiseWithCallback;
    using Codec for bytes;

    bytes32 public constant CALLBACK_ROLE = keccak256("CALLBACK_ROLE");

    uint256 public number;
    string public nearAccountId;
    NEAR public near;
    IERC20 public wNEAR;

    constructor(string memory _nearAccountId, IERC20 _wNEAR, uint256 _number) {
        number = _number;
        nearAccountId = _nearAccountId;
        near = AuroraSdk.initNear(_wNEAR);
        wNEAR = _wNEAR;
        _grantRole(CALLBACK_ROLE, AuroraSdk.nearRepresentitiveImplicitAddress(address(this)));
    }

    function approveWNEAR() public {
        uint256 amount = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        PromiseCreateArgs memory approveCall = near.auroraCall(
            address(this.wNEAR()),
            abi.encodeWithSelector(
                0x095ea7b3, // approve method selector
                address(this),
                amount
            ),
            0,
            APPROVE_NEAR_GAS
        );
        approveCall.transact();
    }

    function setNumber(uint256 _number) public {
        number = _number;
        _grantRole(CALLBACK_ROLE, AuroraSdk.nearRepresentitiveImplicitAddress(address(this)));
    }

    function increment() public {
        number++;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }

    function nearIncCall() public {
        bytes memory data = "";
        PromiseCreateArgs memory callInc = near.call(nearAccountId, "inc", data, 0, CONTRACT_CALL_NEAR_GAS);
        PromiseCreateArgs memory callback = near.auroraCall(address(this), abi.encodePacked(this.setCallback.selector), 0, CONTRACT_CALLBACK_NEAR_GAS);

        callInc.then(callback).transact();
    }

    function setCallback() public onlyRole(CALLBACK_ROLE) {
        if (AuroraSdk.promiseResult(0).status != PromiseResultStatus.Successful) {
            revert("Call to set failed");
        }
    }
}
