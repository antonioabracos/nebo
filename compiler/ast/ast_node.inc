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
%define NEBOC_AST_MAX_KIND NEBOC_AST_RANGE_FOR_STMT

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

%define NEBOC_AST_BUILDER_DATA_OFFSET 0
%define NEBOC_AST_BUILDER_COUNT_OFFSET 8
%define NEBOC_AST_BUILDER_CAPACITY_OFFSET 16
%define NEBOC_AST_BUILDER_FINALIZED_OFFSET 24
%define NEBOC_AST_BUILDER_SIZE 32

%endif
