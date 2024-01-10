pragma solidity ^0.8.17;

library DelegatorLibrary {
    struct State {
        /// delegator ids
        mapping(address => uint32) dIds;
        /// delegators
        mapping(uint32 => address) delegators;
        /// delegator points
        mapping(uint32 => uint256) staked;
        /// delegated total points
        uint256 total;
        /// delegator list in random order to shuffle relay author
        mapping(uint32 => uint32) list;
        /// queue head
        uint32 lHead;
        /// delegator count
        uint32 dCount;
    }

    // errors
    error InvalidDelegator(address delegateTo);

    function register(State storage self) internal {
        self.dCount += 1;
        self.dIds[msg.sender] = self.dCount;
        self.list[self.dCount] = self.lHead;
        self.lHead = self.dCount;
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

        self.staked[id] += amount;
        self.total += amount;

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

        self.staked[id] -= amount;
        self.total -= amount;

        return true;
    }

    function authorize(
        State storage self
    ) internal returns (address author, address[] memory validators) {
        // Get the current block hash
        bytes32 hash = blockhash(block.number - 1);

        // Ensure that the block hash is not zero
        require(hash != 0, "Block hash is zero");

        // Extract 4-byte chunks from bytes32 and convert to uint32
        uint32[3] memory chunks;
        assembly {
            mstore(chunks, hash)
            mstore(add(chunks, 32), shr(32, hash))
            mstore(add(chunks, 64), shr(64, hash))
            //mstore(add(chunks, 96), shr(96, hash))
            //mstore(add(chunks, 128), shr(128, hash))
        }

        // get author
        author = self.delegators[chunks[0] % self.dCount];
        // initialize the validators array with a length of 2
        uint32[] memory dIdQ = new uint32[](2);
        validators = new address[](2);

        // push validators into the array
        for (uint32 i = 0; i < 2; i++) {
            uint32 id = self.lHead;
            uint32 last = 0;
            // reuse chunks[0] for storing index
            chunks[0] = chunks[i + 1] % self.dCount;

            // traverse to the given index then get delegator id
            for (uint32 j = 0; j < chunks[0] - 1; j++) {
                last = id;
                id = self.list[id];
            }
            // take out picked id from list
            self.list[last] = self.list[id];
            self.list[id] = 0;
            dIdQ[i] = id;
            validators[i] = self.delegators[id];
        }

        // shuffle picked indices by pushing front to the list
        for (uint32 i = 0; i < dIdQ.length; i++) {
            self.list[dIdQ[i]] = self.lHead;
            self.lHead = dIdQ[i];
        }

        return (author, validators);
    }

    function confisticate() internal {
        // slash points on validator
    }
}
