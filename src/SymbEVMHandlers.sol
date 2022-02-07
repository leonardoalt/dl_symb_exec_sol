// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.10;

import "./DLExpr.sol";
import "./EVMSymbStack.sol";

struct EVMContext {
	bytes code;
	EVMSymbStack stack;
	uint pc;
	uint[] path;
	Expr[] constraints;
	uint counter;
}

struct Handler {
	function (EVMContext memory, uint8, uint8, Term[] memory) internal handler;
	uint8 in_args;
	uint8 out_args;
}

error SymbolicJump();

function handleBase(EVMContext memory context, uint8 in_args, uint8 out_args, Term[] memory symbValues) pure {
	for (uint i = 0; i < in_args; ++i)
		symb_pop(context.stack);
	require(out_args == symbValues.length);
	for (uint i = 0; i < out_args; ++i)
		symb_push(context.stack, symbValues[i]);
}

function handleUnimplemented(EVMContext memory context, uint8 in_args, uint8 out_args, Term[] memory symbValues) pure {
	handleBase(context, in_args, out_args, symbValues);

	++context.pc;
}

function handlePUSH(EVMContext memory context, uint8 in_args, uint8 /*out_args*/, Term[] memory /*symbValues*/) pure {
	uint word = 0;
	for (uint i = 0; i < in_args; ++i) {
		word |= uint8(context.code[context.pc + i + 1]);
		if (i < in_args - 1)
			word <<= 8;
	}
	symb_push(context.stack, mk_conc_var(word));
	context.pc += in_args + 1;
}

function handleDUP(EVMContext memory context, uint8 in_args, uint8 /*out_args*/, Term[] memory /*symbValues*/) pure {
	symb_dup(context.stack, in_args);
	++context.pc;
}

function handleSWAP(EVMContext memory context, uint8 in_args, uint8 /*out_args*/, Term[] memory /*symbValues*/) pure {
	symb_swap(context.stack, in_args);
	++context.pc;
}

function handleJUMP(EVMContext memory context, uint8 in_args, uint8 out_args, Term[] memory symbValues) pure {
	Term memory top = symb_top(context.stack);
	if (top.symb.kind == Kind.Symbolic)
		revert SymbolicJump();

	handleBase(context, in_args, out_args, symbValues);

	context.pc = top.symb.value;
}

function handleJUMPI(EVMContext memory context, uint8 in_args, uint8 out_args, Term[] memory symbValues) pure {
	Term memory top = symb_top(context.stack);
	if (top.symb.kind == Kind.Symbolic)
		revert SymbolicJump();

	handleBase(context, in_args, out_args, symbValues);

	context.pc = top.symb.value;
}

function handleTerminatingOpcode(EVMContext memory context, uint8 in_args, uint8 out_args, Term[] memory symbValues) pure {
	handleBase(context, in_args, out_args, symbValues);
}

function symb_handlers() pure returns (Handler[256] memory) {
	Handler memory inv = Handler(handleUnimplemented, 0, 0);
	Handler memory push = Handler(handlePUSH, 0, 1);
	Handler memory dup= Handler(handleDUP, 0, 1);
	Handler memory swap= Handler(handleSWAP, 0, 0);

	return [
		// 0x0X
		Handler(handleTerminatingOpcode, 0, 0),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 3, 1),
		Handler(handleUnimplemented, 3, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 0, 0),
		inv,
		inv,
		inv,
		inv,
		// 0x1X
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 1, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 1, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		Handler(handleUnimplemented, 2, 1),
		inv,
		inv,
		// 0x2X
		Handler(handleUnimplemented, 2, 1),
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		// 0x3X
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 1, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 1, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 3, 0),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 3, 0),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 1, 1),
		Handler(handleUnimplemented, 4, 0),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 3, 0),
		Handler(handleUnimplemented, 1, 1),
		// 0x4X
		Handler(handleUnimplemented, 1, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		// 0x5X
		Handler(handleUnimplemented, 1, 0),
		Handler(handleUnimplemented, 1, 1),
		Handler(handleUnimplemented, 2, 0),
		Handler(handleUnimplemented, 2, 0),
		Handler(handleUnimplemented, 1, 1),
		Handler(handleUnimplemented, 2, 0),
		Handler(handleJUMP, 1, 0),
		Handler(handleJUMPI, 2, 0),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 1),
		Handler(handleUnimplemented, 0, 0),
		inv,
		inv,
		inv,
		inv,
		// 0x6X
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		// 0x7X
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		push,
		// 0x8X
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		dup,
		// 0x9X
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		swap,
		// 0xaX
		Handler(handleUnimplemented, 2, 0),
		Handler(handleUnimplemented, 3, 0),
		Handler(handleUnimplemented, 4, 0),
		Handler(handleUnimplemented, 5, 0),
		Handler(handleUnimplemented, 6, 0),
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		// 0xbX
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		// 0xcX
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		// 0xdX
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		// 0xeX
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		inv,
		// 0xfX
		Handler(handleUnimplemented, 3, 1),
		Handler(handleUnimplemented, 7, 1),
		Handler(handleUnimplemented, 7, 1),
		Handler(handleTerminatingOpcode, 2, 0),
		Handler(handleUnimplemented, 6, 1),
		Handler(handleUnimplemented, 4, 1),
		inv,
		inv,
		inv,
		inv,
		Handler(handleUnimplemented, 6, 1),
		inv,
		inv,
		Handler(handleTerminatingOpcode, 2, 0),
		inv,
		Handler(handleTerminatingOpcode, 1, 0)
	];
}
