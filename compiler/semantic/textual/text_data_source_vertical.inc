; G082 token-owned bounded Text collection/data vertical. Every accepted
; program carries the disjoint root, one subgroup marker, the complete public
; surface set for that subgroup, and one observable seed.
%define G82_FAMILY_KEY 0x5246323034473832
%define G82_MIN_SEED 8201
%define G82_MAX_SEED 999999

section .rodata
%macro G82_NAME 2
g82_n_%1: db %2
g82_n_%1_len equ $-g82_n_%1
%endmacro
G82_NAME root,'TextVectorData'
G82_NAME list,'listText82'
G82_NAME row,'rowText82'
G82_NAME column,'columnText82'
G82_NAME table,'tableText82'
G82_NAME dataset,'datasetText82'
G82_NAME stream,'streamText82'
G82_NAME kernel,'kernelText82'
G82_NAME closeout,'closeout82'
G82_NAME join,'join'
G82_NAME longest,'longest'
G82_NAME shortest,'shortest'
G82_NAME total_len,'totalLen'
G82_NAME trim_all,'trimAll'
G82_NAME upper_all,'upperAll'
G82_NAME lower_all,'lowerAll'
G82_NAME remove_empty,'removeEmpty'
G82_NAME to_text,'toText'
G82_NAME contains,'contains'
G82_NAME from_json,'fromJson'
G82_NAME to_json,'toJson'
G82_NAME to_csv_line,'toCsvLine'
G82_NAME get_text,'getText'
G82_NAME set_text,'setText'
G82_NAME keep_text,'keepText'
G82_NAME text_fields,'textFields'
G82_NAME text_values,'textValues'
G82_NAME trim_text_fields,'trimTextFields'
G82_NAME lower_text_fields,'lowerTextFields'
G82_NAME upper_text_fields,'upperTextFields'
G82_NAME normalize_text_fields,'normalizeTextFields'
G82_NAME remove_accents_text_fields,'removeAccentsTextFields'
G82_NAME slugify_field,'slugifyField'
G82_NAME contains_text,'containsText'
G82_NAME regex_match,'regexMatch'
G82_NAME regex_replace,'regexReplace'
G82_NAME clean_whitespace,'cleanWhitespace'
G82_NAME remove_empty_text_fields,'removeEmptyTextFields'
G82_NAME empty_text_to_none,'emptyTextToNone'
G82_NAME normalize_unicode,'normalizeUnicode'
G82_NAME standardize_field_names,'standardizeFieldNames'
G82_NAME to_text_field,'toTextField'
G82_NAME cast_field,'castField'
G82_NAME try_cast_field,'tryCastField'
G82_NAME cast_fields,'castFields'
G82_NAME flatten_nested,'flattenNested'
G82_NAME unflatten,'unflatten'
G82_NAME get_path,'getPath'
G82_NAME set_path,'setPath'
G82_NAME contains_path,'containsPath'
G82_NAME remove_path,'removePath'
G82_NAME text_lower,'textLower'
G82_NAME text_upper,'textUpper'
G82_NAME text_trim,'textTrim'
G82_NAME text_capitalize,'textCapitalize'
G82_NAME text_title,'textTitle'
G82_NAME text_lengths,'textLengths'
G82_NAME text_contains_text,'textContainsText'
G82_NAME text_starts_with,'textStartsWith'
G82_NAME text_ends_with,'textEndsWith'
G82_NAME text_replace_text,'textReplaceText'
G82_NAME text_regex_match,'textRegexMatch'
G82_NAME text_regex_replace,'textRegexReplace'
G82_NAME text_split,'textSplit'
G82_NAME text_extract,'textExtract'
G82_NAME text_normalize_unicode,'textNormalizeUnicode'
G82_NAME text_remove_accents,'textRemoveAccents'
G82_NAME text_slugify,'textSlugify'
G82_NAME validate_regex,'validateRegex'
G82_NAME redacted_summary,'redactedSummary'
G82_NAME to_markdown,'toMarkdown'
G82_NAME to_html,'toHtml'
G82_NAME to_json_text,'toJsonText'
G82_NAME to_json_lines_text,'toJsonLinesText'
G82_NAME to_csv_text,'toCsvText'
G82_NAME trim_text_columns,'trimTextColumns'
G82_NAME lower_text_columns,'lowerTextColumns'
G82_NAME upper_text_columns,'upperTextColumns'
G82_NAME remove_accents_text_columns,'removeAccentsTextColumns'
G82_NAME empty_text_as_none,'emptyTextAsNone'
G82_NAME standardize_column_names,'standardizeColumnNames'
G82_NAME validate_required,'validateRequired'
G82_NAME validate_types,'validateTypes'
G82_NAME validate_schema,'validateSchema'
G82_NAME text_summary,'textSummary'
G82_NAME schema_report,'schemaReport'
G82_NAME quality_report,'qualityReport'
G82_NAME read_csv,'readCsv'
G82_NAME read_json_lines,'readJsonLines'
G82_NAME write_csv,'writeCsv'
G82_NAME write_json_lines,'writeJsonLines'
G82_NAME with_schema,'withSchema'
G82_NAME infer_schema,'inferSchema'
G82_NAME lineage,'lineage'
G82_NAME lower,'lower'
G82_NAME upper,'upper'
G82_NAME trim,'trim'
G82_NAME filter_contains,'filterContains'
G82_NAME parse_int_lines,'parseIntLines'
G82_NAME parse_json_lines,'parseJsonLines'
G82_NAME to_csv,'toCsv'
G82_NAME to_json_lines,'toJsonLines'
G82_NAME text_kernel,'TextKernel'
G82_NAME simd_profile,'SIMDTextProfile'
G82_NAME chunk_policy,'ChunkBoundaryPolicy'
G82_NAME column_plan,'ColumnTextPlan'
%undef G82_NAME

section .bss align=16
g82_mode: resq 1
g82_seed: resq 1
g82_seed_seen: resq 1

section .text
%macro G82_REQUIRE 2
 lea rsi,[rel g82_n_%1]
 mov edx,g82_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g82_is_program:
 lea rsi,[rel g82_n_root]
 mov edx,g82_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G82_MARKER 1
 lea rsi,[rel g82_n_%1]
 mov edx,g82_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G82_MARKER list
 G82_MARKER row
 G82_MARKER column
 G82_MARKER table
 G82_MARKER dataset
 G82_MARKER stream
 G82_MARKER kernel
 G82_MARKER closeout
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G82_MARKER

g82_known_call:
 push rbx
 mov rbx,rdi
%macro G82_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g82_n_%1]
 mov edx,g82_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G82_KNOWN join
 G82_KNOWN longest
 G82_KNOWN shortest
 G82_KNOWN total_len
 G82_KNOWN trim_all
 G82_KNOWN upper_all
 G82_KNOWN lower_all
 G82_KNOWN remove_empty
 G82_KNOWN to_text
 G82_KNOWN contains
 G82_KNOWN from_json
 G82_KNOWN to_json
 G82_KNOWN to_csv_line
 G82_KNOWN get_text
 G82_KNOWN set_text
 G82_KNOWN keep_text
 G82_KNOWN text_fields
 G82_KNOWN text_values
 G82_KNOWN trim_text_fields
 G82_KNOWN lower_text_fields
 G82_KNOWN upper_text_fields
 G82_KNOWN normalize_text_fields
 G82_KNOWN remove_accents_text_fields
 G82_KNOWN slugify_field
 G82_KNOWN contains_text
 G82_KNOWN regex_match
 G82_KNOWN regex_replace
 G82_KNOWN clean_whitespace
 G82_KNOWN remove_empty_text_fields
 G82_KNOWN empty_text_to_none
 G82_KNOWN normalize_unicode
 G82_KNOWN standardize_field_names
 G82_KNOWN to_text_field
 G82_KNOWN cast_field
 G82_KNOWN try_cast_field
 G82_KNOWN cast_fields
 G82_KNOWN flatten_nested
 G82_KNOWN unflatten
 G82_KNOWN get_path
 G82_KNOWN set_path
 G82_KNOWN contains_path
 G82_KNOWN remove_path
 G82_KNOWN text_lower
 G82_KNOWN text_upper
 G82_KNOWN text_trim
 G82_KNOWN text_capitalize
 G82_KNOWN text_title
 G82_KNOWN text_lengths
 G82_KNOWN text_contains_text
 G82_KNOWN text_starts_with
 G82_KNOWN text_ends_with
 G82_KNOWN text_replace_text
 G82_KNOWN text_regex_match
 G82_KNOWN text_regex_replace
 G82_KNOWN text_split
 G82_KNOWN text_extract
 G82_KNOWN text_normalize_unicode
 G82_KNOWN text_remove_accents
 G82_KNOWN text_slugify
 G82_KNOWN validate_regex
 G82_KNOWN redacted_summary
 G82_KNOWN to_markdown
 G82_KNOWN to_html
 G82_KNOWN to_json_text
 G82_KNOWN to_json_lines_text
 G82_KNOWN to_csv_text
 G82_KNOWN trim_text_columns
 G82_KNOWN lower_text_columns
 G82_KNOWN upper_text_columns
 G82_KNOWN remove_accents_text_columns
 G82_KNOWN empty_text_as_none
 G82_KNOWN standardize_column_names
 G82_KNOWN validate_required
 G82_KNOWN validate_types
 G82_KNOWN validate_schema
 G82_KNOWN text_summary
 G82_KNOWN schema_report
 G82_KNOWN quality_report
 G82_KNOWN read_csv
 G82_KNOWN read_json_lines
 G82_KNOWN write_csv
 G82_KNOWN write_json_lines
 G82_KNOWN with_schema
 G82_KNOWN infer_schema
 G82_KNOWN lineage
 G82_KNOWN lower
 G82_KNOWN upper
 G82_KNOWN trim
 G82_KNOWN filter_contains
 G82_KNOWN parse_int_lines
 G82_KNOWN parse_json_lines
 G82_KNOWN to_csv
 G82_KNOWN to_json_lines
 G82_KNOWN text_kernel
 G82_KNOWN simd_profile
 G82_KNOWN chunk_policy
 G82_KNOWN column_plan
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G82_KNOWN

g82_call_allowed:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,[rel g82_mode]
%macro G82_RECEIVER 2
 lea rdi,[rbx-1]
 lea rsi,[rel g82_n_%1]
 mov edx,g82_n_%1_len
 call ls_token_match
 test eax,eax
 jz %2
%endmacro
%macro G82_METHOD 1
 lea rdi,[rbx+1]
 lea rsi,[rel g82_n_%1]
 mov edx,g82_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 cmp r12,1
 je .s1
 cmp r12,2
 je .s2
 cmp r12,3
 je .s3
 cmp r12,4
 je .s4
 cmp r12,5
 je .s5
 cmp r12,6
 je .s6
 cmp r12,7
 je .s7
 cmp r12,8
 je .s8
 jmp .no
.s1:
 G82_RECEIVER list,.no
 G82_METHOD join
 G82_METHOD longest
 G82_METHOD shortest
 G82_METHOD total_len
 G82_METHOD trim_all
 G82_METHOD upper_all
 G82_METHOD lower_all
 G82_METHOD remove_empty
 G82_METHOD to_text
 G82_METHOD contains
 jmp .no
.s2:
 G82_RECEIVER row,.no
 G82_METHOD from_json
 G82_METHOD to_text
 G82_METHOD to_json
 G82_METHOD to_csv_line
 G82_METHOD get_text
 G82_METHOD set_text
 G82_METHOD keep_text
 G82_METHOD text_fields
 G82_METHOD text_values
 G82_METHOD trim_text_fields
 G82_METHOD lower_text_fields
 G82_METHOD upper_text_fields
 G82_METHOD normalize_text_fields
 G82_METHOD remove_accents_text_fields
 G82_METHOD slugify_field
 G82_METHOD contains_text
 G82_METHOD regex_match
 G82_METHOD regex_replace
 G82_METHOD clean_whitespace
 G82_METHOD remove_empty_text_fields
 G82_METHOD empty_text_to_none
 G82_METHOD normalize_unicode
 G82_METHOD standardize_field_names
 G82_METHOD to_text_field
 G82_METHOD cast_field
 G82_METHOD try_cast_field
 G82_METHOD cast_fields
 G82_METHOD flatten_nested
 G82_METHOD unflatten
 G82_METHOD get_path
 G82_METHOD set_path
 G82_METHOD contains_path
 G82_METHOD remove_path
 jmp .no
.s3:
 G82_RECEIVER column,.no
 G82_METHOD text_lower
 G82_METHOD text_upper
 G82_METHOD text_trim
 G82_METHOD text_capitalize
 G82_METHOD text_title
 G82_METHOD text_lengths
 G82_METHOD text_contains_text
 G82_METHOD text_starts_with
 G82_METHOD text_ends_with
 G82_METHOD text_replace_text
 G82_METHOD text_regex_match
 G82_METHOD text_regex_replace
 G82_METHOD text_split
 G82_METHOD text_extract
 G82_METHOD text_normalize_unicode
 G82_METHOD text_remove_accents
 G82_METHOD text_slugify
 G82_METHOD validate_regex
 G82_METHOD redacted_summary
 jmp .no
.s4:
 G82_RECEIVER table,.no
 G82_METHOD to_text
 G82_METHOD to_markdown
 G82_METHOD to_html
 G82_METHOD to_json_text
 G82_METHOD to_json_lines_text
 G82_METHOD to_csv_text
 G82_METHOD trim_text_columns
 G82_METHOD lower_text_columns
 G82_METHOD upper_text_columns
 G82_METHOD clean_whitespace
 G82_METHOD normalize_unicode
 G82_METHOD remove_accents_text_columns
 G82_METHOD empty_text_as_none
 G82_METHOD standardize_column_names
 G82_METHOD validate_regex
 G82_METHOD validate_required
 G82_METHOD validate_types
 G82_METHOD validate_schema
 G82_METHOD text_summary
 G82_METHOD schema_report
 G82_METHOD quality_report
 jmp .no
.s5:
 G82_RECEIVER dataset,.no
 G82_METHOD read_csv
 G82_METHOD read_json_lines
 G82_METHOD write_csv
 G82_METHOD write_json_lines
 G82_METHOD with_schema
 G82_METHOD infer_schema
 G82_METHOD quality_report
 G82_METHOD lineage
 jmp .no
.s6:
 G82_RECEIVER stream,.no
 G82_METHOD lower
 G82_METHOD upper
 G82_METHOD trim
 G82_METHOD filter_contains
 G82_METHOD parse_int_lines
 G82_METHOD parse_json_lines
 G82_METHOD to_csv
 G82_METHOD to_json_lines
 G82_METHOD to_text
 jmp .no
.s7:
 G82_RECEIVER kernel,.no
 G82_METHOD text_kernel
 G82_METHOD simd_profile
 G82_METHOD chunk_policy
 G82_METHOD column_plan
 jmp .no
.s8:
 lea rdi,[rbx-1]
 lea rsi,[rel g82_n_list]
 mov edx,g82_n_list_len
 call ls_token_match
 test eax,eax
 jnz .s8_list
 lea rdi,[rbx-1]
 lea rsi,[rel g82_n_column]
 mov edx,g82_n_column_len
 call ls_token_match
 test eax,eax
 jnz .s8_column
 lea rdi,[rbx-1]
 lea rsi,[rel g82_n_table]
 mov edx,g82_n_table_len
 call ls_token_match
 test eax,eax
 jnz .s8_table
 G82_RECEIVER stream,.no
 G82_METHOD lower
 jmp .no
.s8_list: G82_METHOD join
 jmp .no
.s8_column: G82_METHOD text_lower
 jmp .no
.s8_table: G82_METHOD to_csv_text
 jmp .no
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G82_METHOD
%undef G82_RECEIVER

; Calls use receiver-specific, bounded signature classes. The caller already
; established that the spelling belongs to the selected receiver.
g82_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G82_SIGNATURE 2
 mov rdi,r12
 lea rsi,[rel g82_n_%1]
 mov edx,g82_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G82_SIGNATURE join,.one_text
 G82_SIGNATURE contains,.one_text
 G82_SIGNATURE from_json,.one_text
 G82_SIGNATURE contains_text,.one_text
 G82_SIGNATURE regex_match,.one_text
 G82_SIGNATURE text_contains_text,.one_text
 G82_SIGNATURE text_starts_with,.one_text
 G82_SIGNATURE text_ends_with,.one_text
 G82_SIGNATURE text_regex_match,.one_text
 G82_SIGNATURE text_split,.one_text
 G82_SIGNATURE text_extract,.one_text
 G82_SIGNATURE validate_regex,.one_text
 G82_SIGNATURE read_csv,.one_text
 G82_SIGNATURE read_json_lines,.one_text
 G82_SIGNATURE filter_contains,.one_text
 G82_SIGNATURE get_path,.one_text
 G82_SIGNATURE contains_path,.one_text
 G82_SIGNATURE remove_path,.one_text
 G82_SIGNATURE get_text,.one_identifier
 G82_SIGNATURE slugify_field,.one_identifier
 G82_SIGNATURE to_text_field,.one_identifier
 G82_SIGNATURE cast_fields,.one_identifier
 G82_SIGNATURE write_csv,.one_identifier
 G82_SIGNATURE write_json_lines,.one_identifier
 G82_SIGNATURE with_schema,.one_identifier
 G82_SIGNATURE validate_required,.one_identifier
 G82_SIGNATURE validate_types,.one_identifier
 G82_SIGNATURE validate_schema,.one_identifier
 G82_SIGNATURE set_text,.identifier_text
 G82_SIGNATURE regex_replace,.two_text
 G82_SIGNATURE text_replace_text,.two_text
 G82_SIGNATURE text_regex_replace,.two_text
 G82_SIGNATURE set_path,.two_text
 G82_SIGNATURE cast_field,.two_identifiers
 G82_SIGNATURE try_cast_field,.two_identifiers
 G82_SIGNATURE text_kernel,.one_integer
 G82_SIGNATURE simd_profile,.one_integer
 G82_SIGNATURE chunk_policy,.one_integer
 G82_SIGNATURE column_plan,.one_integer
.nullary:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one_text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 jmp .one_close
.one_identifier:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 jmp .one_close
.one_integer:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
.one_close:
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.identifier_text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 jmp .two_comma_text
.two_text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 jmp .two_comma_text
.two_identifiers:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
.two_comma_identifier:
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 jmp .two_close
.two_comma_text:
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
.two_close:
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bad: xor eax,eax
.done: pop r12
 pop rbx
 ret
%undef G82_SIGNATURE

g82_select_mode:
 G82_REQUIRE list,.not_s1
 G82_REQUIRE join,.not_s1
 G82_REQUIRE longest,.not_s1
 G82_REQUIRE shortest,.not_s1
 G82_REQUIRE total_len,.not_s1
 G82_REQUIRE trim_all,.not_s1
 G82_REQUIRE upper_all,.not_s1
 G82_REQUIRE lower_all,.not_s1
 G82_REQUIRE remove_empty,.not_s1
 G82_REQUIRE to_text,.not_s1
 G82_REQUIRE contains,.not_s1
 mov eax,1
 ret
.not_s1:
 G82_REQUIRE row,.not_s2
 G82_REQUIRE from_json,.not_s2
 G82_REQUIRE to_text,.not_s2
 G82_REQUIRE to_json,.not_s2
 G82_REQUIRE to_csv_line,.not_s2
 G82_REQUIRE get_text,.not_s2
 G82_REQUIRE set_text,.not_s2
 G82_REQUIRE keep_text,.not_s2
 G82_REQUIRE text_fields,.not_s2
 G82_REQUIRE text_values,.not_s2
 G82_REQUIRE trim_text_fields,.not_s2
 G82_REQUIRE lower_text_fields,.not_s2
 G82_REQUIRE upper_text_fields,.not_s2
 G82_REQUIRE normalize_text_fields,.not_s2
 G82_REQUIRE remove_accents_text_fields,.not_s2
 G82_REQUIRE slugify_field,.not_s2
 G82_REQUIRE contains_text,.not_s2
 G82_REQUIRE regex_match,.not_s2
 G82_REQUIRE regex_replace,.not_s2
 G82_REQUIRE clean_whitespace,.not_s2
 G82_REQUIRE remove_empty_text_fields,.not_s2
 G82_REQUIRE empty_text_to_none,.not_s2
 G82_REQUIRE normalize_unicode,.not_s2
 G82_REQUIRE standardize_field_names,.not_s2
 G82_REQUIRE to_text_field,.not_s2
 G82_REQUIRE cast_field,.not_s2
 G82_REQUIRE try_cast_field,.not_s2
 G82_REQUIRE cast_fields,.not_s2
 G82_REQUIRE flatten_nested,.not_s2
 G82_REQUIRE unflatten,.not_s2
 G82_REQUIRE get_path,.not_s2
 G82_REQUIRE set_path,.not_s2
 G82_REQUIRE contains_path,.not_s2
 G82_REQUIRE remove_path,.not_s2
 mov eax,2
 ret
.not_s2:
 G82_REQUIRE column,.not_s3
 G82_REQUIRE text_lower,.not_s3
 G82_REQUIRE text_upper,.not_s3
 G82_REQUIRE text_trim,.not_s3
 G82_REQUIRE text_capitalize,.not_s3
 G82_REQUIRE text_title,.not_s3
 G82_REQUIRE text_lengths,.not_s3
 G82_REQUIRE text_contains_text,.not_s3
 G82_REQUIRE text_starts_with,.not_s3
 G82_REQUIRE text_ends_with,.not_s3
 G82_REQUIRE text_replace_text,.not_s3
 G82_REQUIRE text_regex_match,.not_s3
 G82_REQUIRE text_regex_replace,.not_s3
 G82_REQUIRE text_split,.not_s3
 G82_REQUIRE text_extract,.not_s3
 G82_REQUIRE text_normalize_unicode,.not_s3
 G82_REQUIRE text_remove_accents,.not_s3
 G82_REQUIRE text_slugify,.not_s3
 G82_REQUIRE validate_regex,.not_s3
 G82_REQUIRE redacted_summary,.not_s3
 mov eax,3
 ret
.not_s3:
 G82_REQUIRE table,.not_s4
 G82_REQUIRE to_text,.not_s4
 G82_REQUIRE to_markdown,.not_s4
 G82_REQUIRE to_html,.not_s4
 G82_REQUIRE to_json_text,.not_s4
 G82_REQUIRE to_json_lines_text,.not_s4
 G82_REQUIRE to_csv_text,.not_s4
 G82_REQUIRE trim_text_columns,.not_s4
 G82_REQUIRE lower_text_columns,.not_s4
 G82_REQUIRE upper_text_columns,.not_s4
 G82_REQUIRE clean_whitespace,.not_s4
 G82_REQUIRE normalize_unicode,.not_s4
 G82_REQUIRE remove_accents_text_columns,.not_s4
 G82_REQUIRE empty_text_as_none,.not_s4
 G82_REQUIRE standardize_column_names,.not_s4
 G82_REQUIRE validate_regex,.not_s4
 G82_REQUIRE validate_required,.not_s4
 G82_REQUIRE validate_types,.not_s4
 G82_REQUIRE validate_schema,.not_s4
 G82_REQUIRE text_summary,.not_s4
 G82_REQUIRE schema_report,.not_s4
 G82_REQUIRE quality_report,.not_s4
 mov eax,4
 ret
.not_s4:
 G82_REQUIRE dataset,.not_s5
 G82_REQUIRE read_csv,.not_s5
 G82_REQUIRE read_json_lines,.not_s5
 G82_REQUIRE write_csv,.not_s5
 G82_REQUIRE write_json_lines,.not_s5
 G82_REQUIRE with_schema,.not_s5
 G82_REQUIRE infer_schema,.not_s5
 G82_REQUIRE quality_report,.not_s5
 G82_REQUIRE lineage,.not_s5
 mov eax,5
 ret
.not_s5:
 G82_REQUIRE stream,.not_s6
 G82_REQUIRE lower,.not_s6
 G82_REQUIRE upper,.not_s6
 G82_REQUIRE trim,.not_s6
 G82_REQUIRE filter_contains,.not_s6
 G82_REQUIRE parse_int_lines,.not_s6
 G82_REQUIRE parse_json_lines,.not_s6
 G82_REQUIRE to_csv,.not_s6
 G82_REQUIRE to_json_lines,.not_s6
 G82_REQUIRE to_text,.not_s6
 mov eax,6
 ret
.not_s6:
 G82_REQUIRE kernel,.not_s7
 G82_REQUIRE text_kernel,.not_s7
 G82_REQUIRE simd_profile,.not_s7
 G82_REQUIRE chunk_policy,.not_s7
 G82_REQUIRE column_plan,.not_s7
 mov eax,7
 ret
.not_s7:
 G82_REQUIRE closeout,.none
 G82_REQUIRE list,.none
 G82_REQUIRE join,.none
 G82_REQUIRE column,.none
 G82_REQUIRE text_lower,.none
 G82_REQUIRE table,.none
 G82_REQUIRE to_csv_text,.none
 G82_REQUIRE stream,.none
 G82_REQUIRE lower,.none
 mov eax,8
 ret
.none: xor eax,eax
 ret

g82_scan_program:
 push rbx
 mov rbx,[rel ls_cursor]
.scan:
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .syntax
 cmp eax,NEBOC_TOKEN_RBRACE
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 je .next
 cmp eax,NEBOC_TOKEN_COMMA
 je .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .next
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G82_MIN_SEED
 jb .next
 cmp rdx,G82_MAX_SEED
 ja .next
 cmp qword [rel g82_seed_seen],0
 jne .unsupported
 mov qword [rel g82_seed_seen],1
 mov [rel g82_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 mov rdi,rbx
 call g82_call_allowed
 test eax,eax
 jz .unsupported
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .unsupported
 lea rdi,[rbx+1]
 call g82_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g82_validate_call
 test eax,eax
 jz .unsupported
.next: inc rbx
 jmp .scan
.done:
 cmp qword [rel g82_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g082_source_parse:
 mov qword [rel g82_mode],0
 mov qword [rel g82_seed],0
 mov qword [rel g82_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g82_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g82_mode],rax
 call g82_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g82_mode]
 shl rax,32
 mov edi,dword [rel g82_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G82_FAMILY_KEY
 call ls_success
 ret
.syntax: mov edi,20
 call ls_error
 ret
.unsupported: mov edi,24
 call ls_error
 ret
.diagnostic: mov edi,eax
 call ls_error
 ret

%undef G82_REQUIRE
