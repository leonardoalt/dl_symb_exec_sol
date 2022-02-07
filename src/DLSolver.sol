// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.10;

import "./DLExpr.sol";

enum DLResult { SAT, UNSAT }

/*
 * @title Difference Logic Solver.
 *
 * @param exprs A set of DL constraints a - b <= k
 * @notice a and b are integer variables, k is an integer constant.
 *
 * @return SAT if the constraints are feasible, UNSAT if infeasible.
 *
 * @dev Implements Bellman-Ford for negative cycle detection.
 */
function dl_solve(Expr[] memory exprs) pure returns (DLResult) {
	uint n_exprs = exprs.length;
	require(n_exprs > 0);

	// Figure out how many nodes we have.
	Var max_var = max(exprs[0].a, exprs[0].b);
	for (uint i = 1; i < n_exprs; ++i)
		max_var = max(max_var, max(exprs[i].a, exprs[i].b));

	uint n_nodes = Var.unwrap(max_var) + 1;

	// Allocate adjacency/weight matrix.
	int[][] memory adj = new int[][](n_nodes);
	for (uint i = 0; i < n_nodes; ++i)
		adj[i] = new int[](n_nodes);

	// Fill up adjacency/weight matrix.
	for (uint i = 0; i < n_exprs; ++i)
		adj[Var.unwrap(exprs[i].a)][Var.unwrap(exprs[i].b)] = Constant.unwrap(exprs[i].k);

	// ==== Bellman-Ford negative cycle detection ====

	// 1. Single source shortest path

	int[] memory dist = new int[](n_nodes);
	for (uint i = 0; i < n_nodes; ++i)
		dist[i] = 0;
	
	for (uint i = 1; i < n_nodes; ++i)
		for (uint j = 0; j < n_exprs; ++j) {
			uint u = Var.unwrap(exprs[j].a);
			uint v = Var.unwrap(exprs[j].b);
			dist[v] = min(dist[v], dist[u] + adj[u][v]);
		}

	// 2. Negative cycle detection

	bool neg = false;
	for (uint i = 0; i < n_exprs; ++i) {
		uint u = Var.unwrap(exprs[i].a);
		uint v = Var.unwrap(exprs[i].b);
		if (dist[v] > dist[u] + adj[u][v])
			neg = true;
	}

	return neg ? DLResult.UNSAT : DLResult.SAT;
}

function max(Var v1, Var v2) pure returns (Var) {
	return Var.unwrap(v1) > Var.unwrap(v2) ? v1 : v2;
}

function min(int x, int y) pure returns (int) {
	return x < y ? x : y;
}

/*
library Debug {
	event EXPR(uint a, uint b, int k);
}

function print_expr(Expr memory expr) {
	emit E.EXPR(Var.unwrap(expr.a), Var.unwrap(expr.b), Constant.unwrap(expr.k));
}
*/
