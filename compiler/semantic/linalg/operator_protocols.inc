; PRODUTOS-LINEARES-COMPOSICAO-E-RELACOES-GEOMETRICAS-FECHAR-PROTOCOLOS-DE-PRODUCTS-COMPOSITION-E-GEOMETRIC-RELATIONS-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F01 — native linear-operator ABI contracts.
%ifndef OPERATOR_PROTOCOLS_INC
%define OPERATOR_PROTOCOLS_INC 1

%define LINALG_OK                 0
%define LINALG_ERR_SHAPE         -1
%define LINALG_ERR_CAPACITY      -2
%define LINALG_ERR_OVERFLOW      -3
%define LINALG_ERR_TYPE          -4
%define LINALG_ERR_SINGULAR      -5
%define LINALG_ERR_CONDITIONING  -6

; Dense descriptor (40 bytes), all storage caller-owned.
%define LINALG_DATA        0
%define LINALG_ROWS        8
%define LINALG_COLS       16
%define LINALG_STRIDE     24
%define LINALG_TYPE_TAG   32
%define LINALG_DESC_SIZE  40

; Type-directed product tags used by semantic planning only.
%define PRODUCT_DOT        1
%define PRODUCT_CROSS      2
%define PRODUCT_HADAMARD   3
%define PRODUCT_TENSOR     4
%define PRODUCT_DIRECT_SUM 5
%define PRODUCT_COMPOSE    6

%endif
