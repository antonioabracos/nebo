%ifndef NEBOC_TARGET_REGISTRY_INC
%define NEBOC_TARGET_REGISTRY_INC 1

%include "compiler/parser/target_manifest.inc"

; Exact selector: explicit selector, then declared default, then sole target.
; neboc_target_registry_select(manifest*, selector*, selector_len) -> status.
; On success selected_index is written; on failure it remains -1.

%endif
