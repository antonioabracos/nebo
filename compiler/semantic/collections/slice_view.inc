%ifndef NEBOC_SLICE_VIEW_INC
%define NEBOC_SLICE_VIEW_INC 1

; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F04 internal borrowed Slice A0
; semantic/lowering identity. C13-PRC-A3 keeps every public Slice layout and
; lifetime rule unchanged while sizing the compiler-private whole-program view
; plan to the same bounded 256-owner composition contract as Array/Range.
%define NEBOC_SLICE_LAYOUT_ID 0x5246323747303643
%define NEBOC_SLICE_MAX_VIEWS 256

%endif
