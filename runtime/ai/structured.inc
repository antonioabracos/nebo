%ifndef NEBO_STRUCTURED_INC
%define NEBO_STRUCTURED_INC 1
%define NEBO_STRUCT_OK 0
%define NEBO_STRUCT_E_ARGUMENT 1
%define NEBO_STRUCT_E_LIMIT 2
%define NEBO_STRUCT_E_SCHEMA 3
%define NEBO_STRUCT_E_REPAIR 4
%define NEBO_STRUCT_MAX_PROMPT 4096
%define NEBO_STRUCT_MAX_FIELDS 64
%ifndef NEBO_STRUCTURED_IMPLEMENTATION
extern nebo_prompt_validate
extern nebo_structured_schema_validate
extern nebo_structured_repair
extern nebo_provenance_copy
%endif
%endif
