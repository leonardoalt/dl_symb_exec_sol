**This code base is not meant to be used seriously, it's only a study.**
========================================================================

EVM Symbolic Execution in Solidity
==================================

This repo contains an experimental symbolic execution engine implemented in
Solidity.
If you write smart contracts in Solidity and write your tests also in Solidity,
the analysis runs simply as part of the test suite, itself being a test
library.
Therefore, any framework that allows tests in Solidity should be able to run
this symbolic execution, without any extra tooling.
Since that code is not going to be deployed anyway we don't care about gas.

The VM opcode handling part was inspired by
https://github.com/Ohalo-Ltd/solevm.

Analysis
--------

During the symbolic run, path constraints are collected and for every `JUMPI`
opcode the analysis asks a Difference Logic solver (`DLSolver.sol`) whether the
condition can ever be true.
If the condition can never be true, the event `UnreachableBranch(pc)` is
emitted, giving the program counter of that branch.
If the condition can be true, the generated constraints are added into the list
of constraints, and the new `true` branch is executed.
The negation of the generated constraints is added into the constraint list for
the `false` branch.

Usage
-----

This repo uses `forge` from [Foundry](https://github.com/gakonst/foundry/).
To run all the tests:

```
$ forge test
```

The tests in this repo include unit tests for the DL solver, and examples of
how to use the symbolic engine.
To run the latter:

```
$ forge test --match symb_run -vvvv
```

The first test, `SymbExecTest::test_symb_run_simple`, shows us that the branch
starting at program counter 0x14 is unreachable! It can therefore be removed.
That branch is `tag_2`, which represents the inner `if` in the sample Yul code.
See the test for a detailed explanation.

In the last test, you should see

```
[PASS] test_symb_run_unreachable() (gas: 687208634)
Traces:

  [687208634] SymbExecTest::test_symb_run_unreachable()
    ├─ emit UnreachableBranch(pc: 382)
    ├─ emit UnreachableBranch(pc: 425)
    ├─ emit UnreachableBranch(pc: 468)
    ├─ emit UnreachableBranch(pc: 550)
    └─ ← ()
```

This shows that the analysis found 4 useless branches in the bytecode!
Check `src/test/SymbExec.t.sol` to understand why/where.

The analysis for a contract Analyzed can be invoked by calling
`symb_run(type(Analyzed).runtimeCode)`, as seen in the tests.

Note that the settings in this repo are **not** using the Solidity compiler's
optimizer on purpose.
The optimizer itself already removes some of these branches from the bytecode.
It is likely that many of the cases that this engine could optimize are already
covered by the compiler.
You will likely notice test result differences if you enable/disable the
optimizer settings in`foundry.toml`.
Need to run more tests.

Difference Logic (DL)
---------------------

DL is a nice little logic that accepts expressions of the form `a - b <= k`,
where `a` and `b` are variables, and `k` is a constant.
The domain may be the Integers or the Reals.
A DL solver is similar to an LP solver, but a lot simpler.
It takes a set of constraints in the form above (instead of more general linear
constraints), and answers whether it is feasible for all the constraints to be
true at the same time.

The algorithm for solving sets of DL constraints is to represent the
constraints as a weighted graph, such that every constraint `a - b <= k` is an
edge `a -> b` with weight `k`, and check whether the graph has a negative
cycle.
The latter can be solved, for example, with the Bellman-Ford single source
shortest path algorithm with the negative cycle detection extension.

The proofs of the statements above are left as exercises to the reader.

Encoding
--------

For every `JUMPI` we collect constraints from the condition and convert them to
DL expressions.
For example, if the `JUMPI` condition is `stack_slot_1 < 2`, this becomes
`stack_slot_1 - zero <= 1`, where `zero` is a symbolic variable that always
represents the constant 0 in the DL graph.
The encoding for `GT` is similar.
The encoding for `ISZERO` simply negates the encoding of its argument.
Equalities (`EQ`) `x = y` become two constraints: `x - y <= 0` and `y - x <=
0`.
In the case of disequalities, that is, the `iszero(eq(...))` constraint for the
true branch of a `JUMPI`, or the negation of an `eq(...)` for the false branch,
we actually do not generate new constraints.
This is because the encoding of a disequality is actually a disjunction: `a !=
b <=> !(a <= b && b <= a) <=> a > b || b > a`.
If the domain is the Integers (which it is in our case), the DL satisfiability
problem becomes NP-hard.

Code base issues
----------------

All the VM data structures, such as stack, path and constraints, are memory arrays.
There is a lot of copying of those arrays.
Some of them are intended, since we need to make a new VM when starting a new
`JUMPI` branch, and continue the other branch with the current VM.
However, at times we simply want to extend an array without copying it
entirely.
Since we can't extend memory arrays natively, we just create a new larger array
from scratch with the previous content copied, plus the desired extension.
The code base would definitely benefit from a memory vector, either natively
or from a library.
