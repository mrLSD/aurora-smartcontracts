// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "@openzeppelin-contracts/access/AccessControl.sol";
import "@openzeppelin-contracts/utils/Strings.sol";
import {
    AuroraSdk,
    IERC20,
    Codec,
    NEAR,
PromiseResult,
    PromiseCreateArgs,
    PromiseResultStatus,
    PromiseWithCallback
} from "@aurora-sdk/AuroraSdk.sol";

// NEAR gas constants (TGas)
uint64 constant CONTRACT_CALL_NEAR_GAS = 100_000_000_000;
uint64 constant CONTRACT_CALLBACK_NEAR_GAS = 6_000_000_000_000;

contract Counter is AccessControl {
    using AuroraSdk for NEAR;
    using AuroraSdk for PromiseCreateArgs;
    using AuroraSdk for PromiseWithCallback;
    using Codec for bytes;

    bytes32 public constant CALLBACK_ROLE = keccak256("CALLBACK_ROLE");

    uint256 public number;
    uint128 public numberFromNEAR;
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
        PromiseCreateArgs memory callback =
            near.auroraCall(address(this), abi.encodePacked(this.incCallback.selector), 0, CONTRACT_CALLBACK_NEAR_GAS);

        callInc.then(callback).transact();
    }

    function incCallback() public onlyRole(CALLBACK_ROLE) {
        if (AuroraSdk.promiseResult(0).status != PromiseResultStatus.Successful) {
            revert("Call to set failed");
        }
    }

    function nearIncByValueCall(uint256 _number) public {
        bytes memory data = abi.encodePacked('{"value": "', Strings.toString(_number), '"}');
        PromiseCreateArgs memory callInc = near.call(nearAccountId, "inc_by_value", data, 0, CONTRACT_CALL_NEAR_GAS);
        PromiseCreateArgs memory callback =
            near.auroraCall(address(this), abi.encodePacked(this.incCallback.selector), 0, CONTRACT_CALLBACK_NEAR_GAS);

        callInc.then(callback).transact();
    }

    function nearGetCounterCall() public {
        bytes memory data = "";
        PromiseCreateArgs memory callInc = near.call(nearAccountId, "get_counter", data, 0, CONTRACT_CALL_NEAR_GAS);
        PromiseCreateArgs memory callback = near.auroraCall(
            address(this), abi.encodePacked(this.getCounterCallback.selector), 0, CONTRACT_CALLBACK_NEAR_GAS
        );

        callInc.then(callback).transact();
    }

    function getCounterCallback() public onlyRole(CALLBACK_ROLE) {
        PromiseResult memory promiseResult = AuroraSdk.promiseResult(0);
        if (promiseResult.status != PromiseResultStatus.Successful) {
            revert("Call to set failed");
        }
        numberFromNEAR = _stringToUint(string(promiseResult.output));
    }

    function _stringToUint(
        string memory s
    ) private pure returns (uint128 result) {
        bytes memory b = bytes(s);
        uint128 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint128 c = uint128(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

}
