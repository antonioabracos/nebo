%ifndef NEBOC_AST_NODE_INC
%define NEBOC_AST_NODE_INC 1

%define NEBOC_AST_NODE_KIND_OFFSET 0
%define NEBOC_AST_NODE_FLAGS_OFFSET 8
%define NEBOC_AST_NODE_SOURCE_ID_OFFSET 16
%define NEBOC_AST_NODE_START_OFFSET 24
%define NEBOC_AST_NODE_END_OFFSET 32
%define NEBOC_AST_NODE_FIRST_CHILD_OFFSET 40
%define NEBOC_AST_NODE_NEXT_SIBLING_OFFSET 48
%define NEBOC_AST_NODE_CHILD_COUNT_OFFSET 56
%define NEBOC_AST_NODE_PAYLOAD0_OFFSET 64
%define NEBOC_AST_NODE_PAYLOAD1_OFFSET 72
%define NEBOC_AST_NODE_SIZE 80
%define NEBOC_AST_NODE_QWORDS 10

%define NEBOC_AST_INVALID 0
%define NEBOC_AST_PROGRAM 1
%define NEBOC_AST_START_DECL 2
%define NEBOC_AST_FUNCTION_DECL 3
%define NEBOC_AST_RECEIVER 4
%define NEBOC_AST_PARAMETER 5
%define NEBOC_AST_BLOCK 6
%define NEBOC_AST_IDENTIFIER_EXPR 7
%define NEBOC_AST_INTEGER_LITERAL 8
%define NEBOC_AST_TEXT_LITERAL 9
%define NEBOC_AST_BOOL_LITERAL 10
%define NEBOC_AST_UNARY_EXPR 11
%define NEBOC_AST_BINARY_EXPR 12
%define NEBOC_AST_CALL_EXPR 13
%define NEBOC_AST_BINDING_TERMINAL 14
%define NEBOC_AST_RETURN_TERMINAL 15
%define NEBOC_AST_EXPRESSION_STMT 16
%define NEBOC_AST_BINDING_STMT 17
%define NEBOC_AST_RETURN_STMT 18
%define NEBOC_AST_IF_STMT 19
%define NEBOC_AST_ERROR_NODE 20
%define NEBOC_AST_FLOAT_LITERAL 21
%define NEBOC_AST_CHAR_LITERAL 22
%define NEBOC_AST_ASSIGNMENT_STMT 23
%define NEBOC_AST_LOOP_STMT 24
%define NEBOC_AST_BREAK_STMT 25
%define NEBOC_AST_CONTINUE_STMT 26
%define NEBOC_AST_WHILE_STMT 27
%define NEBOC_AST_RANGE_FOR_STMT 28
%define NEBOC_AST_DO_WHILE_STMT 29
%define NEBOC_AST_DEFER_STMT 30
; G130 exact mathematical constants are typed leaf nodes.  Payload0 retains
; the source token kind and Payload1 the source token index.
%define NEBOC_AST_MATH_CONSTANT 31
; G133 typed empty Set literal.  The element type is supplied by the adjacent
; set expression or rejected by semantic inference when used alone.
%define NEBOC_AST_SET_EMPTY_LITERAL 32
; Ordered source elements for typed collection constructors. Each element
; remains an expression; the constructor's semantic owner supplies its type.
%define NEBOC_AST_ARRAY_LITERAL 33
; A lexical named argument retains its exact name token and one value child.
; Semantic owners decide whether a call accepts names; no argument is erased.
%define NEBOC_AST_NAMED_ARGUMENT 34
%define NEBOC_AST_INTERPOLATED_TEXT 35
%define NEBOC_AST_INTERPOLATION_VALUE 36
%define NEBOC_AST_STRUCT_DECL 37
%define NEBOC_AST_STRUCT_CONSTRUCTOR 38
%define NEBOC_AST_MAX_KIND NEBOC_AST_STRUCT_CONSTRUCTOR

%define NEBOC_AST_FLAG_NONE 0
%define NEBOC_AST_FLAG_BODY_OPAQUE 1
%define NEBOC_AST_FLAG_ELSE_IF 2
%define NEBOC_AST_FLAG_RECOVERED 4
%define NEBOC_AST_FLAG_TYPE_CONSTRUCTOR 8
%define NEBOC_AST_FLAG_MUTABLE_BINDING 16
; NPT-LANG-27 reuses the existing assignment node and `=` token while
; retaining the complete `.at(index)` target as its first child.
%define NEBOC_AST_FLAG_COLLECTION_ELEMENT_ASSIGNMENT 32
; NPT-LANG-21: the parameter spelling contains an authenticated bounded
; generic type constructor (`Slice<Int|Bool|Char>`).  Payload0 remains the
; outer type token and Payload1 remains the binding-name token; the element
; token is therefore recoverable at Payload0+2 without widening AstNode.
%define NEBOC_AST_FLAG_GENERIC_PARAMETER 32
; NPT-LANG-37: an existing receiver-first FunctionDecl parsed directly inside
; one outer function body.  The flag is compiler-private and never denotes a
; source-visible top-level function value.
%define NEBOC_AST_FLAG_NESTED_PRIVATE 64
; C13-PRC-A3 compiler-private bridge for the already-public two-statement
; typed binding spelling (`Type.name; value.name;`).  The marker is assigned
; only after exact adjacency, name and initializer-type validation.
%define NEBOC_AST_FLAG_TYPED_BINDING_DECLARATION 128
; C13-PRC-A3: a nominal vertical has already authenticated the public
; `Type.Variant` receiver.  The shared Pratt parser retains the two token IDs
; in one compiler-private receiver node so a following public method suffix can
; compose with FunctionTable codegen without introducing field-access syntax.
%define NEBOC_AST_FLAG_NOMINAL_VARIANT_RECEIVER 256
; C13-PRC-A3: the shared parser represents the already-public Tuple `.N`
; projection as a compiler-private call-shaped node.  Payload0 retains the
; exact integer token and Payload1 its constant position; no new source form
; or public runtime ABI is introduced.
%define NEBOC_AST_FLAG_TUPLE_POSITIONAL_PROJECTION 512
; G085: the compatibility spelling `const name: Type = value;` lowers to the
; same binding terminal as the preferred receiver-first form.  The private
; marker preserves syntax provenance for semantic type validation.
%define NEBOC_AST_FLAG_EXPLICIT_CONST_BINDING 1024
; A type application preserves its type-name token and ordered type children.
; It is a type receiver, never a value identifier or a comparison expression.
%define NEBOC_AST_FLAG_TYPE_APPLICATION 2048
; Typed associative borrow provenance: bits 16..31 lexical block id and
; bits 32..63 the resolved reference slot; low flags remain independently masked.
%define NEBOC_AST_FLAG_LEXICAL_BORROW 4096
; Generic method type children are semantic operands, not runtime arguments.
%define NEBOC_AST_FLAG_GENERIC_METHOD 8192
; Existing Node<T> value and Column<T> [values] spellings desugar to the
; same typed constructor,
; preserving the real type token instead of fabricating a new method token.
%define NEBOC_AST_FLAG_PREFIX_TYPED_CONSTRUCTOR 16384
; A receiver-relative .option(...) retains its own spelling and operands.
; Only a semantic owner with that contextual option contract may consume it.
%define NEBOC_AST_FLAG_CONTEXTUAL_OPTION 32768

%define NEBOC_AST_BUILDER_DATA_OFFSET 0
%define NEBOC_AST_BUILDER_COUNT_OFFSET 8
%define NEBOC_AST_BUILDER_CAPACITY_OFFSET 16
%define NEBOC_AST_BUILDER_FINALIZED_OFFSET 24
%define NEBOC_AST_BUILDER_SIZE 32

%endif
