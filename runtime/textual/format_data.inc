; RF84 O5 bounded formats/data/tooling ABI (internal, not public source syntax)
%ifndef FORMAT_DATA_INC
%define FORMAT_DATA_INC 1

%define FMT_OK             0
%define FMT_INVALID        1
%define FMT_LIMIT          2
%define FMT_CAPACITY       3
%define FMT_SYNTAX         4
%define FMT_NOT_FOUND      5
%define FMT_UNSUPPORTED    6
%define FMT_CONFLICT       7

%define FMT_STATE_CONTRACT 1
%define FMT_STATE_INTERNAL 2
%define FMT_STATE_EXTERNAL 3

%define FMT_UNKNOWN        0
%define FMT_CSV            1
%define FMT_TSV            2
%define FMT_JSON           3
%define FMT_JSONL          4
%define FMT_MARKDOWN       5
%define FMT_TOML           6
%define FMT_LOG            7
%define FMT_FEED           8
%define FMT_XML            9
%define FMT_HTML          10
%define FMT_YAML          11
%define FMT_INI           12
%define FMT_PARQUET       13
%define FMT_ARROW         14
%define FMT_AVRO          15
%define FMT_SQLITE        16
%define FMT_GRAPHML       17
%define FMT_DOT           18
%define FMT_MERMAID       19
%define FMT_BINARY        20

%define FMT_MAX_BYTES       4096
%define FMT_MAX_RECORDS      256
%define FMT_MAX_FIELDS        64
%define FMT_MAX_DEPTH         32
%define FMT_MAX_PATTERN       256
%define FMT_MAX_STEPS       65536
%define FMT_MAX_CAPTURES       32

extern format_front_state
extern format_validate_kind
extern format_check_limits
extern format_detect
extern delimited_scan
extern json_validate
extern ascii_upper_vector
extern pattern_find
extern format_normalize
extern lint_text

%endif
