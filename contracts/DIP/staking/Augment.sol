// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

interface IAugment {
    function symbol() external view returns (string memory);
}

contract Augment is ERC20PresetMinterPauser {
    constructor(string memory name, string memory symbol, address augmentor) ERC20PresetMinterPauser(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, augmentor);
        _setupRole(MINTER_ROLE, augmentor);
        _setupRole(PAUSER_ROLE, augmentor);
    }
}