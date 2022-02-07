// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.10;

enum Kind { Concrete, Symbolic }

struct SymbValue {
	uint value;
	Kind kind;
}

struct Term {
	SymbValue symb;
	Term[] args;
}

function mk_conc_var(uint x) pure returns (Term memory t) {
	t.symb = SymbValue(x, Kind.Concrete);
}

function mk_symb_appl(uint f, Term[] memory args) pure returns (Term memory t) {
	t.symb = SymbValue(f, Kind.Symbolic);
	t.args = args;
}

function is_concrete(Term memory term) pure returns (bool) {
	return term.symb.kind == Kind.Concrete;
}

function is_symbolic(Term memory term) pure returns (bool) {
	return term.symb.kind == Kind.Symbolic;
}

function copy_term(Term memory term) pure returns (Term memory) {
	Term memory copy;
	copy.symb = term.symb;
	copy.args = new Term[](term.args.length);
	for (uint i = 0; i < copy.args.length; ++i)
		copy.args[i] = copy_term(term.args[i]);
	return copy;
}
