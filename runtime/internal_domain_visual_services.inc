%ifndef NEBO_INTERNAL_DOMAIN_VISUAL_SERVICES_INC
%define NEBO_INTERNAL_DOMAIN_VISUAL_SERVICES_INC 1

; G113 is an internal host-service layer. Nebo programs continue to use the
; receiver-first RenderPlan surface; these entry points do not create a public
; visual.* namespace.
%define NEBO_G113_SPEC_VERSION 1
%define NEBO_G113_MATURITY_INTERNAL_DOMAIN_VISUAL_SERVICES_GREEN 2

%define NEBO_G113_OK 0
%define NEBO_G113_ERROR_INVALID -1
%define NEBO_G113_ERROR_BOUNDS -2
%define NEBO_G113_ERROR_VERSION -3
%define NEBO_G113_ERROR_TARGET -4
%define NEBO_G113_ERROR_POLICY -5
%define NEBO_G113_ERROR_LIFETIME -6
%define NEBO_G113_ERROR_CORE -7
%define NEBO_G113_ERROR_LAYOUT -8
%define NEBO_G113_ERROR_CAPABILITY -9

%define NEBO_G113_TARGET_HEADLESS 1
%define NEBO_G113_TARGET_LIVE 2
%define NEBO_G113_PRIVACY_PUBLIC 1
%define NEBO_G113_PRIVACY_REDACTED 2
%define NEBO_G113_CAPABILITY_SEMANTIC_PREVIEW 1
%define NEBO_G113_LAYOUT_GRID 1
%define NEBO_G113_LAYOUT_STACK 2
%define NEBO_G113_LAYOUT_SPLIT 3
%define NEBO_G113_LAYOUT_LAYERED 4

%define NEBO_G113_DOMAIN_DASHBOARD 1
%define NEBO_G113_DOMAIN_ML 2
%define NEBO_G113_DOMAIN_MEDIA 3
%define NEBO_G113_DOMAIN_GRAPH 4

%define NEBO_G113_DASHBOARD_CREATE 1
%define NEBO_G113_DASHBOARD_FROM_SPEC 2
%define NEBO_G113_DASHBOARD_LAYOUT 3
%define NEBO_G113_DASHBOARD_ADD_PANEL 4
%define NEBO_G113_DASHBOARD_ADD_TEXT 5
%define NEBO_G113_DASHBOARD_ADD_CHART 6
%define NEBO_G113_DASHBOARD_ADD_TABLE 7
%define NEBO_G113_DASHBOARD_ADD_TIMELINE 8
%define NEBO_G113_DASHBOARD_SHOW 9
%define NEBO_G113_DASHBOARD_EXPORT_TEXT 10
%define NEBO_G113_DASHBOARD_EXPORT_HTML 11
%define NEBO_G113_ML_TRAINING_DASHBOARD 12
%define NEBO_G113_ML_TRAINING_RESULT 13
%define NEBO_G113_ML_LOSS_CHART 14
%define NEBO_G113_ML_METRIC_CHART 15
%define NEBO_G113_ML_CONFUSION_MATRIX 16
%define NEBO_G113_ML_PREDICTIONS 17
%define NEBO_G113_ML_CHECKPOINT_TIMELINE 18
%define NEBO_G113_ML_MODEL_SUMMARY 19
%define NEBO_G113_MEDIA_IMAGE 20
%define NEBO_G113_MEDIA_AUDIO 21
%define NEBO_G113_MEDIA_VIDEO 22
%define NEBO_G113_MEDIA_FRAME 23
%define NEBO_G113_MEDIA_WAVEFORM 24
%define NEBO_G113_MEDIA_SPECTROGRAM 25
%define NEBO_G113_MEDIA_THUMBNAILS 26
%define NEBO_G113_MEDIA_METADATA 27
%define NEBO_G113_GRAPH_GRAPH 28
%define NEBO_G113_GRAPH_TREE 29
%define NEBO_G113_GRAPH_DEPENDENCY 30
%define NEBO_G113_GRAPH_COMPUTATIONAL 31
%define NEBO_G113_GRAPH_LAYOUT 32
%define NEBO_G113_GRAPH_LIMIT_NODES 33
%define NEBO_G113_GRAPH_LIMIT_EDGES 34
%define NEBO_G113_OPERATION_COUNT 34

%define NEBO_G113_MAX_DASHBOARD_PANELS 64
%define NEBO_G113_MAX_DASHBOARD_ITEMS 256
%define NEBO_G113_MAX_ML_VALUES 65536
%define NEBO_G113_MAX_MEDIA_UNITS 65536
%define NEBO_G113_MAX_GRAPH_NODES 4096
%define NEBO_G113_MAX_GRAPH_EDGES 16384

; Borrowed, pointer-free service specification (104 bytes).
%define NEBO_G113_SPEC_VERSION_OFFSET 0
%define NEBO_G113_SPEC_TARGET_OFFSET 8
%define NEBO_G113_SPEC_PRIMARY_OFFSET 16
%define NEBO_G113_SPEC_SECONDARY_OFFSET 24
%define NEBO_G113_SPEC_AUX_OFFSET 32
%define NEBO_G113_SPEC_GENERATION_OFFSET 40
%define NEBO_G113_SPEC_CORE_DIGEST_OFFSET 48
%define NEBO_G113_SPEC_PRIVACY_OFFSET 56
%define NEBO_G113_SPEC_CAPABILITY_OFFSET 64
%define NEBO_G113_SPEC_OWNER_GENERATION_OFFSET 72
%define NEBO_G113_SPEC_VIEW_GENERATION_OFFSET 80
%define NEBO_G113_SPEC_LAYOUT_OFFSET 88
%define NEBO_G113_SPEC_FLAGS_OFFSET 96
%define NEBO_G113_SPEC_SIZE 104

; Pointer-free, versioned, target-neutral semantic receipt (104 bytes).
%define NEBO_G113_RECEIPT_OPERATION_OFFSET 0
%define NEBO_G113_RECEIPT_DOMAIN_OFFSET 8
%define NEBO_G113_RECEIPT_TARGET_OFFSET 16
%define NEBO_G113_RECEIPT_PRIMARY_OFFSET 24
%define NEBO_G113_RECEIPT_SECONDARY_OFFSET 32
%define NEBO_G113_RECEIPT_AUX_OFFSET 40
%define NEBO_G113_RECEIPT_CORE_DIGEST_OFFSET 48
%define NEBO_G113_RECEIPT_SERVICE_DIGEST_OFFSET 56
%define NEBO_G113_RECEIPT_GENERATION_OFFSET 64
%define NEBO_G113_RECEIPT_PRIVACY_OFFSET 72
%define NEBO_G113_RECEIPT_CAPABILITY_OFFSET 80
%define NEBO_G113_RECEIPT_LAYOUT_OFFSET 88
%define NEBO_G113_RECEIPT_MATURITY_OFFSET 96
%define NEBO_G113_RECEIPT_SIZE 104

%ifndef NEBO_G113_DOMAIN_VISUAL_IMPLEMENTATION
extern nebo_g113_dashboard_create
extern nebo_g113_dashboard_from_spec
extern nebo_g113_dashboard_layout
extern nebo_g113_dashboard_add_panel
extern nebo_g113_dashboard_add_text
extern nebo_g113_dashboard_add_chart
extern nebo_g113_dashboard_add_table
extern nebo_g113_dashboard_add_timeline
extern nebo_g113_dashboard_show
extern nebo_g113_dashboard_export_text
extern nebo_g113_dashboard_export_html
extern nebo_g113_ml_training_dashboard
extern nebo_g113_ml_training_result
extern nebo_g113_ml_loss_chart
extern nebo_g113_ml_metric_chart
extern nebo_g113_ml_confusion_matrix
extern nebo_g113_ml_predictions
extern nebo_g113_ml_checkpoint_timeline
extern nebo_g113_ml_model_summary
extern nebo_g113_media_image
extern nebo_g113_media_audio
extern nebo_g113_media_video
extern nebo_g113_media_frame
extern nebo_g113_media_waveform
extern nebo_g113_media_spectrogram
extern nebo_g113_media_thumbnails
extern nebo_g113_media_metadata
extern nebo_g113_graph_graph
extern nebo_g113_graph_tree
extern nebo_g113_graph_dependency_graph
extern nebo_g113_graph_computational_graph
extern nebo_g113_graph_layout
extern nebo_g113_graph_limit_nodes
extern nebo_g113_graph_limit_edges
%endif

%endif
