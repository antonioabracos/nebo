%ifndef NEBOC_ARRAY_RANGE_INC
%define NEBOC_ARRAY_RANGE_INC 1

; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F03 allocation-free structural Array<T,N>/Range<Int> vertical.
%define NEBOC_AR_SOURCE_OFFSET 0
%define NEBOC_AR_SOURCE_LENGTH_OFFSET 8
%define NEBOC_AR_TOKENS_OFFSET 16
%define NEBOC_AR_TOKEN_COUNT_OFFSET 24
%define NEBOC_AR_BINDINGS_OFFSET 32
%define NEBOC_AR_BINDING_CAPACITY_OFFSET 40
%define NEBOC_AR_VALUES_OFFSET 48
%define NEBOC_AR_VALUE_CAPACITY_OFFSET 56
%define NEBOC_AR_FOUND_OFFSET 64
%define NEBOC_AR_DIAGNOSTIC_OFFSET 72
%define NEBOC_AR_ERROR_TOKEN_OFFSET 80
%define NEBOC_AR_CURSOR_OFFSET 88
%define NEBOC_AR_BINDING_COUNT_OFFSET 96
%define NEBOC_AR_VALUE_COUNT_OFFSET 104
%define NEBOC_AR_CONSTRUCT_COUNT_OFFSET 112
%define NEBOC_AR_ACCESS_COUNT_OFFSET 120
%define NEBOC_AR_RESULT_TYPE_OFFSET 128
%define NEBOC_AR_RESULT_VALUE_OFFSET 136
%define NEBOC_AR_LAYOUT_SIZE_OFFSET 144
%define NEBOC_AR_LAYOUT_ALIGN_OFFSET 152
%define NEBOC_AR_SEMANTIC_HASH_OFFSET 160
%define NEBOC_AR_ARRAY_COUNT_OFFSET 168
%define NEBOC_AR_RANGE_COUNT_OFFSET 176
%define NEBOC_AR_LOOPS_OFFSET 184
%define NEBOC_AR_LOOP_CAPACITY_OFFSET 192
%define NEBOC_AR_LOOP_COUNT_OFFSET 200
%define NEBOC_AR_ITERATION_COUNT_OFFSET 208
%define NEBOC_AR_FOR_DEPTH_OFFSET 216
%define NEBOC_AR_FOR_FLAGS_OFFSET 224
; NPT-LANG-18: token boundary of the current direct top-level declaration
; body.  It scopes the existing flat immutable binding pool without changing
; any public representation or runtime ABI.
%define NEBOC_AR_BODY_START_OFFSET 232
%define NEBOC_AR_REQUEST_SIZE 240
%define NEBOC_AR_REQUEST_QWORDS 30

; Failure-only bridge for the shared control-header parser. These aliases use
; result/layout fields that carry no publishable collection value after a
; rejected header; they preserve the authoritative diagnostic and insertions
; until the canonical CLI renderer runs.
%define NEBOC_AR_CONTROL_FIXIT_COUNT_OFFSET NEBOC_AR_RESULT_TYPE_OFFSET
%define NEBOC_AR_CONTROL_FIXIT0_START_OFFSET NEBOC_AR_RESULT_VALUE_OFFSET
%define NEBOC_AR_CONTROL_FIXIT0_KIND_OFFSET NEBOC_AR_LAYOUT_SIZE_OFFSET
%define NEBOC_AR_CONTROL_FIXIT1_START_OFFSET NEBOC_AR_LAYOUT_ALIGN_OFFSET

; C13-PRC-A3 private whole-program owner arena.  Public Array/Slice layouts,
; lengths and ABI remain unchanged; only compiler-internal simultaneous owner
; metadata grows to the selected bounded architecture capacity.
%define NEBOC_AR_MAX_BINDINGS 256
%define NEBOC_AR_MAX_VALUES 2048
%define NEBOC_AR_MAX_LENGTH 256
%define NEBOC_AR_MAX_LAYOUT 1048576
%define NEBOC_FOR_MAX_LOOPS 16
%define NEBOC_FOR_MAX_ITERATIONS 256

; Records contain token indices, scalar layout facts and a value-pool index.
%define NEBOC_AR_BIND_NAME_OFFSET 0
%define NEBOC_AR_BIND_KIND_OFFSET 8
%define NEBOC_AR_BIND_TYPE_OFFSET 16
%define NEBOC_AR_BIND_COUNT_OFFSET 24
%define NEBOC_AR_BIND_STRIDE_OFFSET 32
%define NEBOC_AR_BIND_SIZE_OFFSET 40
%define NEBOC_AR_BIND_DATA_INDEX_OFFSET 48
%define NEBOC_AR_BIND_START_OFFSET 56
%define NEBOC_AR_BIND_END_OFFSET 64
%define NEBOC_AR_BIND_STEP_OFFSET 72
%define NEBOC_AR_BIND_FLAGS_OFFSET 80
%define NEBOC_AR_BIND_HASH_OFFSET 88
; Original constructor byte offset and the half-open token interval of an
; authenticated pure map callback. These remain private compiler provenance.
%define NEBOC_AR_BIND_SOURCE_OFFSET 96
%define NEBOC_AR_BIND_CALLBACK_BEGIN_OFFSET 104
%define NEBOC_AR_BIND_CALLBACK_END_OFFSET 112
%define NEBOC_AR_BIND_SIZE 120
%define NEBOC_AR_BIND_QWORDS 15

; Slice-only provenance in otherwise unused record fields: semantic token
; indices plus one, zero meaning no explicit release. End-of-program cleanup
; must not erase the interval during which a view can be used by the AST owner.
%define NEBOC_AR_SLICE_CREATED_TOKEN_OFFSET NEBOC_AR_BIND_SOURCE_OFFSET
%define NEBOC_AR_SLICE_RELEASE_TOKEN_OFFSET NEBOC_AR_BIND_HASH_OFFSET

; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-F07 authenticated sequential-iterator records.  Collection values
; remain owned by the established option_result_null_externo_e_erros_tipados binding/value pools.
%define NEBOC_FOR_ID_OFFSET 0
%define NEBOC_FOR_DEPTH_OFFSET 8
%define NEBOC_FOR_KIND_OFFSET 16
%define NEBOC_FOR_COLLECTION_INDEX_OFFSET 24
%define NEBOC_FOR_ITEM_TOKEN_OFFSET 32
%define NEBOC_FOR_ACTION_OFFSET 40
%define NEBOC_FOR_CHILD_INDEX_OFFSET 48
%define NEBOC_FOR_START_OFFSET 56
%define NEBOC_FOR_STEP_OFFSET 64
%define NEBOC_FOR_COUNT_OFFSET 72
%define NEBOC_FOR_DATA_INDEX_OFFSET 80
%define NEBOC_FOR_FLAGS_OFFSET 88
%define NEBOC_FOR_INDEX_TOKEN_OFFSET 96
%define NEBOC_FOR_FILTER_LHS_TOKEN_OFFSET 104
%define NEBOC_FOR_FILTER_OPERATOR_OFFSET 112
%define NEBOC_FOR_FILTER_VALUE_OFFSET 120
%define NEBOC_FOR_RECORD_SIZE 128
%define NEBOC_FOR_RECORD_QWORDS 16

%define NEBOC_FOR_ACTION_EMPTY 0
%define NEBOC_FOR_ACTION_BREAK 1
%define NEBOC_FOR_ACTION_CONTINUE 2
%define NEBOC_FOR_ACTION_RETURN_ITEM 3
%define NEBOC_FOR_ACTION_NESTED 4
%define NEBOC_FOR_ACTION_GENERAL_BODY 5
%define NEBOC_FOR_ACTION_RETURN_INDEX 6

; NPT-LANG-16: the collection semantic owner has authenticated the immutable
; collection/iteration records, while the shared statement backend owns the
; body.  This is internal routing metadata, not a public language flag.
%define NEBOC_AR_FOR_FLAG_GENERAL_BODY 1
; NPT-LANG-24: at least one authenticated collection at() operand is a
; material non-literal Int expression owned by the shared AST backend.
%define NEBOC_AR_FOR_FLAG_DYNAMIC_AT 2
; NPT-LANG-27 compiler-only routing fact. Mutable Array payloads live in the
; per-invocation function frame; the public Array/Slice representation is
; unchanged.
%define NEBOC_AR_FOR_FLAG_MUTABLE_ARRAY 4
; NPT-LANG-29 exact routing fact: at least one owned Array is returned from a
; function and therefore needs a name-only placeholder in the filtered AST.
%define NEBOC_AR_FOR_FLAG_ARRAY_RETURN 16
; NPT-LANG-32 compiler-only routing fact: an authenticated S04 input or a
; constant subslice derived from that input is returned as a read-only Slice.
%define NEBOC_AR_FOR_FLAG_SLICE_RETURN 32
; Public Array.map transform was authenticated by the collection owner.
; The CLI uses this semantic fact to route map/callable composition before the
; older whole-source callable profile can claim the same Program.
%define NEBOC_AR_FOR_FLAG_MAP 64
%define NEBOC_AR_FOR_FLAG_RANGE_ITERATOR 128
; Explicit post-G204 compatibility admission, separate from general indexing.
%define NEBOC_AR_FOR_FLAG_LEGACY_INDEX 256

%define NEBOC_AR_CONTROL_FIXIT_INSERT_LPAREN 1
%define NEBOC_AR_CONTROL_FIXIT_INSERT_RPAREN 2

%define NEBOC_AR_KIND_ARRAY 1
%define NEBOC_AR_KIND_RANGE 2
%define NEBOC_AR_KIND_SLICE 3
%define NEBOC_AR_KIND_BYTES_OWNER 4
; NPT-LANG-21 compiler-only header record.  It carries exact element/name
; identity for a borrowed Slice parameter; runtime storage remains the
; caller-owned 40-byte descriptor reached through the function ABI pointer.
%define NEBOC_AR_KIND_SLICE_PARAMETER 5
%define NEBOC_AR_TYPE_INT 1
%define NEBOC_AR_TYPE_BOOL 2
%define NEBOC_AR_TYPE_CHAR 3
%define NEBOC_AR_TYPE_RANGE_INT 4

%define NEBOC_AR_RANGE_INCLUSIVE 1
%define NEBOC_AR_RANGE_ITERATOR 2
%define NEBOC_AR_RANGE_SYMBOLIC 4
%define NEBOC_AR_UNBOUND_NAME -1
%define NEBOC_AR_SLICE_LIVE 1
%define NEBOC_AR_SLICE_RELEASED 2
%define NEBOC_AR_ARRAY_MUTABLE 16
; NPT-LANG-29 compiler-only result-owner marker. The canonical logical Array
; representation is unchanged; this bit only says its payload/empty anchor is
; in caller frame storage rather than immutable module data.
%define NEBOC_AR_ARRAY_CALL_RESULT 32
; Exact callee-owned Array declaration used by a bare `.return`.  This avoids
; applying the private filtered-AST name anchor to unrelated Array bindings.
%define NEBOC_AR_ARRAY_RETURN_SOURCE 64
; NPT-LANG-32 provenance/result markers.  They are semantic/compiler state;
; the canonical five-qword public Slice descriptor remains unchanged.
%define NEBOC_AR_SLICE_S04_DERIVED 128
%define NEBOC_AR_SLICE_RETURN_SOURCE 256
%define NEBOC_AR_SLICE_CALL_RESULT 512
%define NEBOC_AR_SLICE_RESULT_LENGTH_KNOWN 1024
%define NEBOC_AR_ARRAY_FRAME_SHIFT 32

; A loop whose collection name is introduced by a direct B01 call-result
; binding is authenticated by the shared AST/codegen after signature
; resolution. The semantic scanner records the exact source token meanwhile.
; Loop records historically copy the collection representation flags, whose
; low bits include the canonical 1/4/8 strides. Keep deferred routing outside
; that value space so an ordinary Int Array loop can never look deferred.
%define NEBOC_FOR_FLAG_DEFERRED_RESULT (1 << 30)

; 004..006 were reserved by F01. F03 adds structural diagnostics 018..020.
%define NEBOC_AR_DIAG_NONE 0
%define NEBOC_AR_DIAG_CONST_LENGTH 4
%define NEBOC_AR_DIAG_BOUNDS 5
%define NEBOC_AR_DIAG_RANGE 6
%define NEBOC_AR_DIAG_SLICE_STALE 7
%define NEBOC_AR_DIAG_ARITY 18
%define NEBOC_AR_DIAG_TYPE 19
%define NEBOC_AR_DIAG_DYNAMIC_INDEX 20
%define NEBOC_AR_DIAG_SYNTAX 21
%define NEBOC_AR_DIAG_SLICE_MUTATION_CONFLICT 22
%define NEBOC_AR_DIAG_SLICE_ESCAPE 23
%define NEBOC_AR_DIAG_SLICE_UNAVAILABLE 24
%define NEBOC_AR_DIAG_RECORD_CAPACITY 33
%define NEBOC_AR_DIAG_VALUE_CAPACITY 34
%define NEBOC_AR_DIAG_FOR_TYPE 37
%define NEBOC_AR_DIAG_FOR_MUTATION 38
%define NEBOC_AR_DIAG_FOR_OVERFLOW 39
%define NEBOC_AR_DIAG_FOR_SYNTAX 40
%define NEBOC_AR_DIAG_FOR_NESTING 41
%define NEBOC_AR_DIAG_INTERNAL 99

%define NEBOC_ARRAY_RANGE_LAYOUT_ID 0x5246323747303642

%endif
