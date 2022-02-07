// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.10;

import "./DLExpr.sol";
import "./DLSolver.sol";
import "./SymbEVMHandlers.sol";
import "./EVMOpcodes.sol";
import "./EVMSymbStack.sol";
import "./Term.sol";

error ConstantLT();

library SymbExec {
	event UnreachableBranch(uint pc);
}

function check(Expr[] memory constraints, uint pc) {
	if (dl_solve(constraints) == DLResult.UNSAT)
		emit SymbExec.UnreachableBranch(pc);
}

/// @notice Traverses the code symbolically looking for unreachable branches.
/// @dev `stack.values`, `path` and `constraints` would benefit a lot from being proper vectors.
function symb_run(bytes memory code) {
	EVMSymbStack memory stack;
	uint[] memory path;
	Expr[] memory constraints;
	// The symbolic variable 0 is reserved for the symbolic
	// representation of the constant 0 in the DL encoding.
	uint counter = 1;
	run_from(EVMContext(code, stack, 0, path, constraints, counter), symb_handlers());
}

function run_from(
	EVMContext memory context,
	Handler[256] memory handlers
) returns (uint) {
	while (context.pc < context.code.length) {
		uint opcode = uint8(context.code[context.pc]);

		// No loops pls.
		if (search_path(context.path, context.pc))
			return context.counter;

		context.path = extend_path(context.path);
		context.path[context.path.length - 1] = context.pc;

		Handler memory op_handler = handlers[opcode];
		Term[] memory symbArgs;
		Term[] memory symbOp;

		// We don't create symbolic values for push, dup, swap.

		if (PUSH1 <= opcode && opcode <= SWAP16) {
			uint n;
			if (PUSH1 <= opcode && opcode <= PUSH32)
				n = opcode - PUSH1 + 1;
			else if (DUP1 <= opcode && opcode <= DUP16)
				n = opcode - DUP1 + 1;
			else if (SWAP1 <= opcode && opcode <= SWAP16)
				n = opcode - SWAP1 + 1;
			op_handler.handler(context, uint8(n), op_handler.out_args, symbOp);
			continue;
		}

		// The other opcodes have either 0 or 1 output values.

		if (op_handler.in_args > 0) {
			symbArgs = new Term[](op_handler.in_args);
			for (uint i = 0; i < op_handler.in_args; ++i)
				symbArgs[i] = copy_term(context.stack.values[context.stack.free_top - i - 1]);
		}
		if (op_handler.out_args > 0) {
			assert(op_handler.out_args == 1);
			symbOp = new Term[](1);
			symbOp[0] = mk_symb_appl(opcode, symbArgs);
		}

		uint prev_pc = context.pc;
		op_handler.handler(context, op_handler.in_args, op_handler.out_args, symbOp);

		if (opcode == JUMPI) {
			Expr[] memory new_constraints;

			assert(symbArgs.length == 2);
			uint8 conditionOpcode = uint8(symbArgs[1].symb.value);

			if (is_relational(conditionOpcode) || conditionOpcode == ISZERO) {
				Expr[] memory exprs = term_to_expr(symbArgs[1]);
				if (exprs.length > 0) {
					new_constraints = extend_constraints(context.constraints, exprs);
					// Call DL solver.
					check(new_constraints, context.pc);
				} else {
					// TODO this branch will vanish once all relational opcodes
					// are supported.
					new_constraints = copy_constraints(context.constraints);
				}
			} else {
				new_constraints = copy_constraints(context.constraints);
			}

			// True branch, start new branch.
			context.counter = run_from(EVMContext(context.code, copy_stack(context.stack), context.pc, copy_path(context.path), new_constraints, context.counter), handlers);

			// Only one constraint was added, so it wasn't an EQ,
			// so we can safely negate it for the false branch,
			// otherwise solving it becomes NP-hard.
			if (new_constraints.length == context.constraints.length + 1) {
				context.constraints = extend_constraints(
					context.constraints,
					one_expr(new_constraints[new_constraints.length - 1])
				);
			}

			// False branch, continue this execution.
			context.pc = prev_pc + 1;
		} else if (opcode == RETURN || opcode == REVERT || opcode == STOP || opcode == SELFDESTRUCT) {
			// Terminate branch.
			return context.counter;
		}
	}

	return context.counter;
}

// Encode symbolic terms into DL expressions, when possible.
// For now handle only LT and GT.
function term_to_expr(Term memory term) returns (Expr[] memory) {
	uint8 opcode = uint8(term.symb.value);
	assert(is_relational(opcode) || opcode == ISZERO);

	Term[] memory args = term.args;

	// a < b ->	a <= b - 1	-> a - b <= -1
	// a < 4 ->	a <= 3		-> a - zero <= 3
	// 2 < a -> 3 <= a		-> 3 - a <= 0	-> zero - a <= -3
	if (opcode == LT) {
		assert(args.length == 2);
		if (is_symbolic(args[0]) && is_symbolic(args[1])) {
			return one_expr(Expr(
				mk_var(args[0].symb.value),
				mk_var(args[1].symb.value),
				mk_const(-1)
			));
		} else if (is_symbolic(args[0]) && is_concrete(args[1])) {
			return one_expr(Expr(
				mk_var(args[0].symb.value),
				mk_var(0),
				mk_const(int(args[1].symb.value) - 1)
			));
		} else if (is_symbolic(args[1]) && is_concrete(args[0])) {
			return one_expr(Expr(
				mk_var(0),
				mk_var(args[1].symb.value),
				mk_const(- (int(args[0].symb.value) + 1))
			));
		} else {
			revert ConstantLT();
		}
	}

	// a > b -> b < a
	if (opcode == GT) {
		assert(args.length == 2);
		Term[] memory swapped = new Term[](2);
		swapped[0] = args[1];
		swapped[1] = args[0];
		return term_to_expr(mk_symb_appl(LT, swapped));
	}

	// a = b -> a <= b && b <= a ->
	// 1) a - b <= 0 &&
	// 2) b - a <= 0
	if (opcode == EQ) {
		assert(args.length == 2);

		Expr memory e1 = Expr(
			mk_var(args[0].symb.value),
			mk_var(args[1].symb.value),
			mk_const(0)
		);

		Expr memory e2 = Expr(
			mk_var(args[1].symb.value),
			mk_var(args[0].symb.value),
			mk_const(0)
		);

		return two_exprs(e1, e2);
	}

	if (opcode == ISZERO) {
		assert(args.length == 1);
		if (is_symbolic(args[0])) {
			uint8 arg_op = uint8(args[0].symb.value);
			if (arg_op == LT || arg_op == GT) {
				// Negate child's expression.
				Expr[] memory child = term_to_expr(args[0]);
				assert(child.length == 1);
				return one_expr(negate(child[0]));
			}
		}
	}

	Expr[] memory exprs;
	return exprs;
}

function negate(Expr memory e) pure returns (Expr memory) {
	Expr memory neg = copy_expr(e);
	Var temp = neg.a;
	neg.a = neg.b;
	neg.b = temp;
	neg.k = mk_const((-Constant.unwrap(neg.k)) - 1);
	return neg;
}

function search_path(uint[] memory path, uint pc) pure returns (bool) {
	for (uint i = 0; i < path.length; ++i)
		if (path[i] == pc)
			return true;
	return false;
}

function copy_path(uint[] memory path) pure returns (uint[] memory copied) {
	copied = new uint[](path.length);
	for (uint i = 0; i < path.length; ++i)
		copied[i] = path[i];
}

function extend_path(uint[] memory path) pure returns (uint[] memory extended) {
	extended = new uint[](path.length + 1);
	for (uint i = 0; i < path.length; ++i)
		extended[i] = path[i];
}

function copy_constraints(Expr[] memory constraints) pure returns (Expr[] memory copy) {
	copy = new Expr[](constraints.length);
	for (uint i = 0; i < constraints.length; ++i)
		copy[i] = copy_expr(constraints[i]);
}

function extend_constraints(Expr[] memory constraints, Expr[] memory more) pure returns (Expr[] memory extended) {
	extended = new Expr[](constraints.length + more.length);
	for (uint i = 0; i < constraints.length; ++i)
		extended[i] = copy_expr(constraints[i]);
	for (uint i = constraints.length; i < extended.length; ++i)
		extended[i] = copy_expr(more[i - constraints.length]);
}

function one_expr(Expr memory expr) pure returns (Expr[] memory exprs) {
	exprs = new Expr[](1);
	exprs[0] = expr;
}

function two_exprs(Expr memory expr1, Expr memory expr2) pure returns (Expr[] memory exprs) {
	exprs = new Expr[](2);
	exprs[0] = expr1;
	exprs[1] = expr2;
}
