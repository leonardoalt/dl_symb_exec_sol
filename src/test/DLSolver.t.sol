// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.10;

import "ds-test/test.sol";

import "../DLExpr.sol";
import "../DLSolver.sol";

contract DLSolverTest is DSTest {
	function setUp() public {}

	function expect_result(Expr[] memory problem, DLResult result) internal {
		assertEq(uint(dl_solve(problem)), uint(result));
	}

	function testDLSolver_unsat() public {
		Expr[] memory problem = new Expr[](3);

		problem[0] = Expr(mk_var(0), mk_var(1), mk_const(2));
		problem[1] = Expr(mk_var(1), mk_var(2), mk_const(3));
		problem[2] = Expr(mk_var(2), mk_var(0), mk_const(-7));

		expect_result(problem, DLResult.UNSAT);
	}

	function testDLSolver_sat() public {
		Expr[] memory problem = new Expr[](3);

		problem[0] = Expr(mk_var(0), mk_var(1), mk_const(2));
		problem[1] = Expr(mk_var(1), mk_var(2), mk_const(3));
		problem[2] = Expr(mk_var(2), mk_var(0), mk_const(-4));

		expect_result(problem, DLResult.SAT);
	}
}
