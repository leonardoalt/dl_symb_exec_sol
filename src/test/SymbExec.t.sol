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
}

contract SymbExecTest is DSTest {
	function test_symb_run_smoke() public {

		symb_run(type(EmptyRuntime).runtimeCode);
	}

	function test_symb_run_unreachable() public {

		symb_run(type(Unreachable).runtimeCode);
	}
}
