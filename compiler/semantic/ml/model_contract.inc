%ifndef NEBO_MODEL_CONTRACT_INC
%define NEBO_MODEL_CONTRACT_INC 1
%define NEBO_MODEL_OK 0
%define NEBO_MODEL_E_ARGUMENT 1
%define NEBO_MODEL_E_LIMIT 2
%define NEBO_MODEL_E_IDENTITY 3
%define NEBO_MODEL_E_DTYPE 4
%define NEBO_MODEL_E_SHAPE 5
%define NEBO_MODEL_E_EDGE 6
%define NEBO_MODEL_E_CYCLE 7
%define NEBO_MODEL_DTYPE_F64 1
%define NEBO_MODEL_NODE_BYTES 32
%define NEBO_MODEL_EDGE_BYTES 8
%define NEBO_MODEL_GRAPH_BYTES 64
%ifndef NEBO_MODEL_CONTRACT_IMPLEMENTATION
extern nebo_model_validate
extern nebo_model_summary
extern nebo_model_eval_ready
%endif
%endif
