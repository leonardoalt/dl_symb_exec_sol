// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.10;

import "ds-test/test.sol";

import "../SymbExec.sol";

contract EmptyRuntime {}

contract Unreachable {
	function reach(uint x) public pure returns (bool) {
		require(x >= 1);
		if (x >= 0)
			return true;
		// This is unreachable.
		return false;
	}

	function reach2(uint x) public pure returns (bool) {
		require(x <= 10);
		if (x <= 50)
			return true;
		// This is unreachable.
		return false;
	}

	function reach3(uint x) public pure returns (bool) {
		require(x <= 10);
		if (x <= 5)
			return true;
		// This is reachable.
		return false;
	}

	function reach4(uint x) public pure returns (bool) {
		require(x <= 10);
		if (x <= 5)
			return true;
		if (x <= 50)
			return true;
		// This is unreachable.
		return false;
	}

	function reach5(uint x) public pure returns (bool) {
		if (x <= 50) {
		} else {
			require(x <= 10);
			// Unreachable.
		}
	}
}

contract SymbExecTest is DSTest {
	function test_symb_run_smoke() public {

		symb_run(type(EmptyRuntime).runtimeCode);
	}

	function test_symb_run_unreachable() public {

		symb_run(type(Unreachable).runtimeCode);
	}
}
