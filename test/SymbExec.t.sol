// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.17;

import "forge-std/Test.sol";

import "../src/SymbExec.sol";

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
        return true;
	}
}

contract SymbExecTest is Test {
	function test_symb_run_smoke() public {

		symb_run(type(EmptyRuntime).runtimeCode);
	}

	function test_symb_run_unreachable() public {

		symb_run(type(Unreachable).runtimeCode);
	}

	function test_symb_run_simple() public {
		symb_run(hex"600035600a8110600b57005b80603210601457005b600080fd");
/*
This is a simple test to check whether the symbolic execution really finds a
branch crafted to be unreachable.

In the Yul code below, the inner `if` can never be entered due to the outer
`if`.

```yul
{
	let x := calldataload(0)
	if lt(x, 10) {
		if lt(50, x) {
			revert(0, 0)
		}
	}
}
```

In the Symbolic Execution library, we propagate true branch conditions into the
block. We actually cannot propagate the negation of the branch condition into
the continuation of the bytecode (no jump case), since the block may be entered
from different blocks in the general case. We can only propagate if we know
that the true branch is terminating.

The Yul compiler seems to prefer negating the `if` condition and jumping to the
false branch, leaving the `if`'s block, i.e., the true branch, as the
continuation of the bytecode. This doesn't really work for us.

This test was compiled manually to force the bytecode to jump to the true case,
by using the `if` condition as given. This means that the branch conditions are
accumulated, and we can prove that the inner `if` is indeed unreachable.

Running `forge test --match symb_run -vvvv` shows that the branch starting at
program counter 0x14 (tag_2) is unreachable.

```asm
  push1 0x00
  calldataload
  push1 0x0a
  dup2
  lt
  push1 tag_1 (0x0b)
  jumpi
  stop
tag_1:
  jumpdest
  dup1
  push1 0x32
  lt
  push1 tag_2 (0x14)
  jumpi
  stop
tag_2:
  jumpdest
  push1 0x00
  dup1
  revert
```

```evm
600035600a8110600b57005b80603210601457005b600080fd
```

*/
	}
}
