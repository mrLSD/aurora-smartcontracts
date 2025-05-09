// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

/// @title AURORA ENGINE Token
/// @author Aurora Engine team
contract AuroraEngineToken is ERC20 {
    uint8 constant _DECIMALS = 18;
    uint256 constant _TOTALCAP = 1000000;

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        uint256 _maxSupply = _TOTALCAP * (uint256(10) ** _DECIMALS);
        _mint(msg.sender, _maxSupply);
    }
}