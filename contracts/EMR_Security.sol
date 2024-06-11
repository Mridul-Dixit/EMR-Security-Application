// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract EMR_Security {
    struct EMR {
        uint256 emrId;
        uint256[] shares;
        uint256 emrLength;
        uint256 totalSharesLength;
        string[] changeHistory;
        uint256[] changeTimestamps;
        uint256[] changeBlocks;
    }

    uint256 private emrCounter;
    mapping(uint256 => EMR) public emrs;

    event EMRUploaded(uint256 emrID, uint256 blockNumber);
    event EMRUpdated(uint256 emrID, uint256 blockNumber);

    function stringToAscii(string memory str) private pure returns (uint8[] memory) {
        uint8[] memory asciiValues = new uint8[](bytes(str).length);
        for (uint256 i = 0; i < bytes(str).length; i++) {
            asciiValues[i] = uint8(bytes(str)[i]);
        }
        return asciiValues;
    }

    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    function bitsToDecimal(uint256[] memory bits, uint256 t) private pure returns (uint256[] memory) {
        uint256[] memory decimalNumbers = new uint256[](t);
        uint256 bitsPerGroup = bits.length / t;

        for (uint256 i = 0; i < t; i++) {
            uint256 result = 0;
            for (uint256 j = 0; j < bitsPerGroup; j++) {
                uint256 index = i * bitsPerGroup + j;
                require(bits[index] == 0 || bits[index] == 1, "Invalid bit value");
                result = result * 2 + bits[index];
            }
            decimalNumbers[i] = result;
        }
        return decimalNumbers;
    }

    function StrToBits(string memory s) private pure returns (uint256[] memory) {
        uint256[] memory bits = new uint256[](bytes(s).length * 8);
        uint256 index = 0;
        uint8[] memory b = stringToAscii(s);
        for (uint256 i = 0; i < b.length; i++) {
            uint8 a = b[i];
            for (uint256 j = 0; j < 8; j++) {
                bits[index] = (a >> (7 - j)) & 1;
                index++;
            }
        }
        return bits;
    }

    function InterleavingEncoder(string memory r, uint256 t) private pure returns (uint256[] memory, uint256) {
        uint256[] memory temp = StrToBits(r);
        uint256 bitsLength = temp.length;

        uint256 paddedBitsLength = bitsLength;
        if (bitsLength % t != 0) {
            paddedBitsLength += t - (bitsLength % t);
        }
        uint256[] memory bits = new uint256[](paddedBitsLength);
        for (uint256 i = 0; i < bitsLength; i++) {
            bits[i] = temp[i];
        }

        for (uint256 i = bitsLength; i < paddedBitsLength; i++) {
            bits[i] = 0;
        }

        uint256[] memory sub_mess_bits = new uint256[](paddedBitsLength);
        for (uint256 i = 0; i < paddedBitsLength; i++) {
            sub_mess_bits[((i % t) * (paddedBitsLength / t)) + (i / t)] = bits[i];
        }

        uint256[] memory sub_mess = bitsToDecimal(sub_mess_bits, t);
        return (sub_mess, paddedBitsLength);
    }

    function DecimalToBits(uint256[] memory nums, uint256 totalBitsLength) private pure returns (uint256[] memory) {
        uint256[] memory bits = new uint256[](totalBitsLength);
        uint256 bitsPerNum = totalBitsLength / nums.length;
        uint256 index = 0;

        for (uint256 i = 0; i < nums.length; i++) {
            uint256 num = nums[i];
            for (uint256 j = 0; j < bitsPerNum; j++) {
                uint256 bitValue = (num >> (bitsPerNum - j - 1)) & 1;
                bits[index] = bitValue;
                index++;
            }
        }

        return bits;
    }

    function InterleavingDecoder(uint256[] memory subMessages, uint256 t, uint256 totalBitsLength, uint256 emrLength) public pure returns (string memory) {
        uint256[] memory bits = DecimalToBits(subMessages, totalBitsLength);
        uint256[] memory rearrangedBits = new uint256[](totalBitsLength);
        for (uint256 i = 0; i < totalBitsLength; i++) {
            rearrangedBits[i] = bits[((i % t) * (totalBitsLength / t)) + (i / t)];
        }
        
        uint256[] memory charInt = bitsToDecimal(rearrangedBits, emrLength / 8);
        uint8[] memory EMR = new uint8[](charInt.length);
        for (uint256 i = 0; i < charInt.length; i++) {
            EMR[i] = uint8(charInt[i]);
        }
        return convertToChars(EMR);
    }

    function convertToChars(uint8[] memory _asciiNumbers) private pure returns (string memory) {
        require(_asciiNumbers.length > 0, "Input array cannot be empty");
        
        bytes memory result = new bytes(_asciiNumbers.length);
        for (uint256 i = 0; i < _asciiNumbers.length; i++) {
            result[i] = bytes1(_asciiNumbers[i]);
        }
        
        return string(result);
    }

    function uploadEMR(string memory emr, uint t) public returns (uint256 emrID,uint256 blockNumber) {
        emrCounter++;
        emrID = emrCounter;
        (uint256[] memory shares, uint256 totalSharesLength) = InterleavingEncoder(emr, t);
        uint256 emrLength = strlen(emr) * 8;

        emrs[emrID].emrId = emrID;
        emrs[emrID].shares = shares;
        emrs[emrID].emrLength = emrLength;
        emrs[emrID].totalSharesLength = totalSharesLength;
        emrs[emrID].changeHistory.push("Uploaded");
        emrs[emrID].changeTimestamps.push(block.timestamp);

        uint256 blockNumber = block.number;
        emrs[emrID].changeBlocks.push(blockNumber);

        emit EMRUploaded(emrID, blockNumber);
        return (emrID,blockNumber);
    }

    function getEMRData(uint256[] memory shares,uint256 EMR_id) public view returns (string memory) {
        return InterleavingDecoder(shares, shares.length,emrs[EMR_id].totalSharesLength, emrs[EMR_id].emrLength);
    }

    function getSharesByBlockNumber(uint256 emrID, uint256 blockNumber) public view returns (uint256[] memory) {
        require(emrs[emrID].shares.length > 0, "EMR not found");

        for (uint256 i = 0; i < emrs[emrID].changeBlocks.length; i++) {
            if (emrs[emrID].changeBlocks[i] == blockNumber) {
                return emrs[emrID].shares;
            }
        }
        revert("Block number not found for this EMR ID");
    }
    
    function updateEMR(uint256 emrID, uint256[] memory shares, string memory changeData, string memory changeMessage) public returns (uint256 updatedEmrID, uint256 blockNumber) {
        require(emrs[emrID].shares.length > 0, "EMR not found");

        string memory originalData = InterleavingDecoder(shares, shares.length,emrs[emrID].totalSharesLength, emrs[emrID].emrLength);
        string memory newData = string.concat(originalData, changeData);
        (uint256[] memory newShares,uint256 sharesLength) = InterleavingEncoder(newData, shares.length);

        emrs[emrID].shares = newShares;
        emrs[emrID].changeHistory.push(changeMessage);
        emrs[emrID].emrLength = strlen(newData) * 8;
        emrs[emrID].changeTimestamps.push(block.timestamp);
        emrs[emrID].totalSharesLength = sharesLength;
        blockNumber = block.number;
        emrs[emrID].changeBlocks.push(blockNumber);

        emit EMRUpdated(emrID, blockNumber);
        return (emrID, blockNumber);
    }

    function getEMRHistory(uint256 emrID) public view returns (string[] memory history, uint256[] memory timestamps, uint256[] memory blocks) {
        EMR storage emr = emrs[emrID];
        return (emr.changeHistory, emr.changeTimestamps, emr.changeBlocks);
    }
}
