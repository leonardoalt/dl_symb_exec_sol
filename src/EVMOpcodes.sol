// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.10;

// Helper functions.

function is_relational(uint8 opcode) pure returns (bool) {
	return opcode == LT || opcode == SLT || opcode == GT || opcode == SGT;
}

// Stop
uint8 constant STOP = 0x00;

// Arithmetic
uint8 constant ADD = 0x01;
uint8 constant MUL = 0x02;
uint8 constant SUB = 0x03;
uint8 constant DIV = 0x04;
uint8 constant SDIV = 0x05;
uint8 constant MOD = 0x06;
uint8 constant SMOD = 0x07;
uint8 constant ADDMOD = 0x08;
uint8 constant MULMOD = 0x09;
uint8 constant EXP = 0x0a;
uint8 constant SIGNEXTEND = 0x0b;

// Relational
uint8 constant LT = 0x10;
uint8 constant GT = 0x11;
uint8 constant SLT = 0x12;
uint8 constant SGT = 0x13;
uint8 constant EQ = 0x14;

// Bitwise
uint8 constant ISZERO = 0x15;
uint8 constant AND = 0x16;
uint8 constant OR = 0x17;
uint8 constant XOR = 0x18;
uint8 constant NOT = 0x19;
uint8 constant BYTE = 0x1a;
uint8 constant SHL = 0x1b;
uint8 constant SHR = 0x1c;
uint8 constant SAR = 0x1d;

// SHA3
uint8 constant SHA3 = 0x20;

// Env
uint8 constant ADDRESS = 0x30;
uint8 constant BALANCE = 0x31;
uint8 constant ORIGIN = 0x32;
uint8 constant CALLER = 0x33;
uint8 constant CALLVALUE = 0x34;
uint8 constant CALLDATALOAD = 0x35;
uint8 constant CALLDATASIZE = 0x36;
uint8 constant CALLDATACOPY = 0x37;
uint8 constant CODESIZE = 0x38;
uint8 constant CODECOPY = 0x39;
uint8 constant GASPRICE = 0x3a;
uint8 constant EXTCODESIZE = 0x3b;
uint8 constant EXTCODECOPY = 0x3c;
uint8 constant RETURNDATASIZE = 0x3d;
uint8 constant RETURNDATACOPY = 0x3e;
uint8 constant EXTCODEHASH = 0x3f;

// Block
uint8 constant BLOCKHASH = 0x40;
uint8 constant COINBASE = 0x41;
uint8 constant TIMESTAMP = 0x42;
uint8 constant NUMBER = 0x43;
uint8 constant DIFFICULTY = 0x44;
uint8 constant GASLIMIT = 0x45;
uint8 constant CHAINID = 0x46;
uint8 constant SELFBALANCE = 0x47;
uint8 constant BASEFEE = 0x48;

// Memory regionsStack, Memory, Storage and Flow Operations
uint8 constant POP = 0x50;
uint8 constant MLOAD = 0x51;
uint8 constant MSTORE = 0x52;
uint8 constant MSTORE8 = 0x53;
uint8 constant SLOAD = 0x54;
uint8 constant SSTORE = 0x55;
uint8 constant JUMP = 0x56;
uint8 constant JUMPI = 0x57;
uint8 constant PC = 0x58;
uint8 constant MSIZE = 0x59;
uint8 constant GAS = 0x5a;
uint8 constant JUMPDEST = 0x5b;

// Push operations
uint8 constant PUSH1 = 0x60;
uint8 constant PUSH2 = 0x61;
uint8 constant PUSH3 = 0x62;
uint8 constant PUSH4 = 0x63;
uint8 constant PUSH5 = 0x64;
uint8 constant PUSH6 = 0x65;
uint8 constant PUSH7 = 0x66;
uint8 constant PUSH8 = 0x67;
uint8 constant PUSH9 = 0x68;
uint8 constant PUSH10 = 0x69;
uint8 constant PUSH11 = 0x6a;
uint8 constant PUSH12 = 0x6b;
uint8 constant PUSH13 = 0x6c;
uint8 constant PUSH14 = 0x6d;
uint8 constant PUSH15 = 0x6e;
uint8 constant PUSH16 = 0x6f;
uint8 constant PUSH17 = 0x70;
uint8 constant PUSH18 = 0x71;
uint8 constant PUSH19 = 0x72;
uint8 constant PUSH20 = 0x73;
uint8 constant PUSH21 = 0x74;
uint8 constant PUSH22 = 0x75;
uint8 constant PUSH23 = 0x76;
uint8 constant PUSH24 = 0x77;
uint8 constant PUSH25 = 0x78;
uint8 constant PUSH26 = 0x79;
uint8 constant PUSH27 = 0x7a;
uint8 constant PUSH28 = 0x7b;
uint8 constant PUSH29 = 0x7c;
uint8 constant PUSH30 = 0x7d;
uint8 constant PUSH31 = 0x7e;
uint8 constant PUSH32 = 0x7f;

// DUPS
uint8 constant DUP1 = 0x80;
uint8 constant DUP2 = 0x81;
uint8 constant DUP3 = 0x82;
uint8 constant DUP4 = 0x83;
uint8 constant DUP5 = 0x84;
uint8 constant DUP6 = 0x85;
uint8 constant DUP7 = 0x86;
uint8 constant DUP8 = 0x87;
uint8 constant DUP9 = 0x88;
uint8 constant DUP10 = 0x89;
uint8 constant DUP11 = 0x8a;
uint8 constant DUP12 = 0x8b;
uint8 constant DUP13 = 0x8c;
uint8 constant DUP14 = 0x8d;
uint8 constant DUP15 = 0x8e;
uint8 constant DUP16 = 0x8f;

// SWAPS
uint8 constant SWAP1 = 0x90;
uint8 constant SWAP2 = 0x91;
uint8 constant SWAP3 = 0x92;
uint8 constant SWAP4 = 0x93;
uint8 constant SWAP5 = 0x94;
uint8 constant SWAP6 = 0x95;
uint8 constant SWAP7 = 0x96;
uint8 constant SWAP8 = 0x97;
uint8 constant SWAP9 = 0x98;
uint8 constant SWAP10 = 0x99;
uint8 constant SWAP11 = 0x9a;
uint8 constant SWAP12 = 0x9b;
uint8 constant SWAP13 = 0x9c;
uint8 constant SWAP14 = 0x9d;
uint8 constant SWAP15 = 0x9e;
uint8 constant SWAP16 = 0x9f;

// LOGS
uint8 constant LOG0 = 0xa0;
uint8 constant LOG1 = 0xa1;
uint8 constant LOG2 = 0xa2;
uint8 constant LOG3 = 0xa3;
uint8 constant LOG4 = 0xa4;

// External control-flow
uint8 constant CREATE = 0xf0;
uint8 constant CALL = 0xf1;
uint8 constant CALLCODE = 0xf2;
uint8 constant RETURN = 0xf3;
uint8 constant DELEGATECALL = 0xf4;
uint8 constant CREATE2 = 0xf5;
uint8 constant STATICCALL = 0xfa;
uint8 constant REVERT = 0xfd;
uint8 constant INVALID = 0xfe;
uint8 constant SELFDESTRUCT = 0xff;
