library StacketLibrary {
    struct DIPStacket {
        uint32 chainId;
        uint16 confirmations;
        address author;
        bytes transport;
        uint256 timestamp;
        ATTPStacket payload;
    }

    struct ATTPStacket {
        bytes inputs;
        address to;
    }

    function isReady(DIPStacket memory stacket) internal pure returns (bool) {
        // check if the stacket is ready to be executed      
        return true;
    }

    function execute(DIPStacket memory stacket) internal returns (bool) {
        // check if the stacket is ready to be executed
        isReady(stacket);
        // execute call to the smart contract
        (bool success, ) = stacket.payload.to.call(stacket.payload.inputs);
        return success;
    }
}