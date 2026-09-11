%ifndef NEBO_TYPED_QUANTITY_CONTRACT_INC
%define NEBO_TYPED_QUANTITY_CONTRACT_INC 1

; Canonical core_operator_tokens_tokens quantity representation. Values are signed fixed-point
; integers; the scale and unit tag are explicit and never inferred from a path.
%define NEBO_QUANTITY_VALUE_OFFSET        0
%define NEBO_QUANTITY_SCALE_OFFSET        8
%define NEBO_QUANTITY_UNIT_OFFSET        16
%define NEBO_QUANTITY_FLAGS_OFFSET       20
%define NEBO_QUANTITY_SIZE               24

%define NEBO_UNIT_NONE                   0
%define NEBO_UNIT_PERCENT                1
%define NEBO_UNIT_PER_MILLE              2
%define NEBO_UNIT_BASIS_POINTS           3
%define NEBO_UNIT_MILLIDEGREE             4
%define NEBO_UNIT_MILLI_CELSIUS           5
%define NEBO_UNIT_MILLI_FAHRENHEIT        6

%define NEBO_QUANTITY_OK                 0
%define NEBO_QUANTITY_ERR_DOMAIN         1
%define NEBO_QUANTITY_ERR_UNIT           2
%define NEBO_QUANTITY_ERR_OVERFLOW       3
%define NEBO_QUANTITY_ERR_SYNTAX         4
%define NEBO_QUANTITY_ERR_PRECISION      5

; Parser context flags used to disambiguate postfix syntax.
%define NEBO_QCTX_HAS_COMPLETE_OPERAND   0x01
%define NEBO_QCTX_EXPECTS_INFIX           0x02
%define NEBO_QCTX_FORMAT_PLACEHOLDER      0x04
%define NEBO_QCTX_DOMAIN_ENABLED          0x08

; Locale-stable quantity FormatPlan. The value remains in its canonical unit;
; locale affects surrounding number formatting, never the Registry suffix.
%define NEBO_QUANTITY_LOCALE_INVARIANT    0
%define NEBO_QUANTITY_LOCALE_EN           1
%define NEBO_QUANTITY_LOCALE_FR           2
%define NEBO_QUANTITY_FORMAT_VALUE_OFFSET 0
%define NEBO_QUANTITY_FORMAT_UNIT_OFFSET  8
%define NEBO_QUANTITY_FORMAT_SUFFIX_OFFSET 16
%define NEBO_QUANTITY_FORMAT_SUFFIX_LENGTH_OFFSET 24
%define NEBO_QUANTITY_FORMAT_LOCALE_OFFSET 32
%define NEBO_QUANTITY_FORMAT_SIZE         40

%endif
