// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Mappings {
	struct Mapping {
		address[] _values;
	}

	function push(Mapping storage map, address addr) public {
		if (!_exist(map._values, addr)) {
			map._values.push(addr);
		}
	}

	function remove(Mapping storage map, address addr) public returns (address[] memory) {
		address[] memory memoryArray = new address[](map._values.length - 1);
		bool found = false;
		uint256 j = 0;
		for(uint256 i = 0; i < map._values.length; i++) {
			if (map._values[i] != addr) {
				if (i == map._values.length - 1 && found == false) {
					return map._values;
				}
				memoryArray[j++] = address(map._values[i]);
			} else {
				found = true;
	        }
        }
        if (!found) {
            return map._values;
        }
        map._values = memoryArray;
        return memoryArray;
    }

    
    function clear(Mapping storage map) public returns (address[] memory) {
        uint256 zeros = 0;
        for(uint256 i = 0; i < map._values.length; i++) {
            if (map._values[i] == address(0)) {
                zeros++;
            }
        }
        
        address[] memory memoryArray = new address[](map._values.length - zeros);
        uint256 j = 0;
        for(uint256 k = 0; k < map._values.length; k++) {
            if (map._values[k] != address(0)) {
                memoryArray[j++] = address(map._values[k]);
            }
        }
        map._values = memoryArray;
        return memoryArray;
    }
    
    function list(Mapping storage map) public view returns (address[] memory) {
        return map._values;
    }
    
    function length(Mapping storage map) public view returns (uint256) {
        return map._values.length;
    }
    
    function _exist(address[] storage map, address addr) internal view returns (bool) {
        for(uint256 i = 0; i < map.length; i++) {
            if (map[i] == addr) {
                return true;
            }
        }
        return false;
    }
}
