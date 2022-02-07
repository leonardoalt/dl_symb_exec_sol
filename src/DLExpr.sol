// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.10;

/// @dev An actual integer constant.
type Constant is int;
/// @dev A variable is represented by its id.
type Var is uint;

/// @dev A Difference Logic constraint has the form a - b <= k.
struct Expr {
	Var a;
	Var b;
	Constant k;
}

function mk_const(int x) pure returns (Constant) {
	return Constant.wrap(x);
}

function mk_var(uint x) pure returns (Var) {
	return Var.wrap(x);
}

function copy_expr(Expr memory expr) pure returns (Expr memory) {
	return Expr(expr.a, expr.b, expr.k);
}
