// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.17;

import "./Term.sol";

uint constant STACK_SIZE = 1024;

struct EVMSymbStack {
	Term[STACK_SIZE] values;
	uint16 free_top;
}

error StackUnderflow();
error StackOverflow();
error InvalidArgument();

function symb_top(EVMSymbStack memory stack) pure returns (Term memory) {
	if (stack.free_top == 0)
		revert StackUnderflow();

	return copy_term(stack.values[stack.free_top - 1]);
}

function symb_push(EVMSymbStack memory stack, Term memory term) pure {
	if (stack.free_top >= STACK_SIZE)
		revert StackOverflow();

	stack.values[stack.free_top++] = term;
}

function symb_pop(EVMSymbStack memory stack) pure {
	if (stack.free_top == 0)
		revert StackUnderflow();

	stack.free_top--;
}

function symb_dup(EVMSymbStack memory stack, uint n) pure {
	if (stack.free_top >= STACK_SIZE)
		revert StackOverflow();

	if (!(n >= 1 && n <= 16))
		revert InvalidArgument();

	if (stack.free_top < n)
		revert StackUnderflow();

	stack.values[stack.free_top++] = copy_term(stack.values[stack.free_top - n]);
}

function symb_swap(EVMSymbStack memory stack, uint n) pure {
	if (!(n >= 1 && n <= 16))
		revert InvalidArgument();

	if (stack.free_top <= n)
		revert StackUnderflow();

	Term memory temp = stack.values[stack.free_top - 1];
	stack.values[stack.free_top - 1] = stack.values[stack.free_top - 1 - n];
	stack.values[stack.free_top - 1 - n] = temp;
}

function copy_stack(EVMSymbStack memory stack) pure returns (EVMSymbStack memory) {
	EVMSymbStack memory copy;
	copy.free_top = stack.free_top;
	for (uint i = 0; i < stack.free_top; ++i)
		copy.values[i] = copy_term(stack.values[i]);
	return copy;
}
