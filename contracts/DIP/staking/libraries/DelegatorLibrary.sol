pragma solidity ^0.8.17;


import {TransferHelper} from "../../libraries/TransferHelper.sol";

library DelegatorLibrary {
    struct State {
        /// delegator ids
        mapping(address => uint32) dIds;
        /// delegators
        mapping(uint32 => address) delegators;
        /// delegator points
        mapping(uint32 => uint256) delegated;
        /// delegated total points
        uint256 total;
        /// delegator array
        uint32[20] dArr;
        uint32 dCount;
        /// confisticated until
        mapping(uint32 => uint64) confiscated;
        address LUM;
    }

    // errors
    error InvalidDelegator(address delegateTo);
    error AlreadyOccupied(address delegator, uint32 dId);

    function register(State storage self) internal {
        // check occupation
        if(self.dIds[msg.sender] != 0) {
            revert AlreadyOccupied(msg.sender, self.dIds[msg.sender]);
        }

        // Transfer required LUMs to register as validator
        // TODO: set point decimals
        TransferHelper.safeTransferFrom(self.LUM, msg.sender, address(this), 32e18);

        // Add delegator in the list
        self.dCount += 1;
        self.dIds[msg.sender] = self.dCount;
        self.delegated[self.dCount] += 32e18;
        _reorder(self, self.dCount);
    }

    function _reorder(State storage self, uint32 newId) internal {
        for (uint256 i = 19; i > 0; i--) {
            if(self.delegated[self.dArr[i]] >= self.delegated[newId]) {
                if(i==19) {
                    return;
                } else {
                    self.dArr[i+1] = newId;
                    return;
                }
            }
            if(self.delegated[self.dArr[i]] < self.delegated[newId]) {
                if(i==19) {
                    self.dArr[i] = newId;
                } else {
                    self.dArr[i+1] = self.dArr[i];
                    self.dArr[i] = newId;
                }
            }
        }
    }

    function delegate(
        State storage self,
        address delegateTo,
        uint256 amount
    ) internal returns (bool) {
        // check if delegator exists
        uint32 id = self.dIds[delegateTo];
        if (id == 0) {
            revert InvalidDelegator(delegateTo);
        }

        self.delegated[id] += amount;
        self.total += amount;
        _reorder(self, id);
        return true;
    }

    function undelegate(
        State storage self,
        address delegateTo,
        uint256 amount
    ) external returns (bool) {
        // check if delegator exists
        uint32 id = self.dIds[delegateTo];
        if (id == 0) {
            revert InvalidDelegator(delegateTo);
        }

        self.delegated[id] -= amount;
        self.total -= amount;
        _reorder(self, id);
        return true;
    }

    function authorize(
        State storage self
    ) internal view returns (address author, address validator1, address validator2) {
        // Get the current block hash
        bytes32 hash = blockhash(block.number - 1);

        // Ensure that the block hash is not zero
        require(hash != 0, "Block hash is zero");

        // Extract 4-byte chunks from bytes32 and convert to uint32
        uint32[3] memory chunks;
        address[] memory validators;
        assembly {
            mstore(chunks, hash)
            mstore(add(chunks, 32), shr(32, hash))
            mstore(add(chunks, 64), shr(64, hash))
            //mstore(add(chunks, 96), shr(96, hash))
            //mstore(add(chunks, 128), shr(128, hash))
        }
       
        validators = new address[](3);

        // get validators in the array
        for (uint32 i = 0; i < 3; i++) {
            validators[i] = self.delegators[chunks[i] % 20];
        }

        return (validators[0], validators[1], validators[2]);
    }

    function slash(State storage self, address delegator) internal {
        // slash points on delegator
        self.delegated[self.dIds[delegator]] = 0;

        // distribute slashed LUM to reporter


        // confiscate delegator for 3 months

    }
}
