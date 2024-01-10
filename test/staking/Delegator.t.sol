

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SumCalculator {

    function getBlockHashChunksAndNumber() external view returns (uint256) {
        // Get the current block hash
        bytes32 hash = blockhash(block.number - 1);

        // Ensure that the block hash is not zero
        require(hash != 0, "Block hash is zero");

        // Extract 4-byte chunks from bytes32 and convert to uint32
        uint32[5] memory chunks;
        assembly {
            mstore(chunks,         hash)
            mstore(add(chunks, 32), shr(32, hash))
            mstore(add(chunks, 64), shr(64, hash))
            mstore(add(chunks, 96), shr(96, hash))
            mstore(add(chunks, 128), shr(128, hash))
        }

        // Concatenate the chunks and interpret as uint256
        uint256 result = uint256(chunks[0]) + uint256(chunks[1]) + uint256(chunks[2]) + uint256(chunks[3]) + uint256(chunks[4]);

        return result;
    }
}