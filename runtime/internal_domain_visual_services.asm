bits 64
default rel

%include "runtime/internal_domain_visual_services.inc"

section .text
global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_create_fromspec_layout_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_create_fromspec_layout_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_create_fromspec_layout_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_create_fromspec_layout_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_create_fromspec_layout_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_create_fromspec_layout_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_create_fromspec_layout_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_create_fromspec_layout_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_create_fromspec_layout_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addpanel_addtext_addchart_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addpanel_addtext_addchart_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addpanel_addtext_addchart_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addpanel_addtext_addchart_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addpanel_addtext_addchart_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addpanel_addtext_addchart_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addpanel_addtext_addchart_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addpanel_addtext_addchart_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addpanel_addtext_addchart_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addtable_addtimeline_show_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addtable_addtimeline_show_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addtable_addtimeline_show_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addtable_addtimeline_show_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addtable_addtimeline_show_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addtable_addtimeline_show_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addtable_addtimeline_show_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addtable_addtimeline_show_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_addtable_addtimeline_show_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_exporttext_exporthtml_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_exporttext_exporthtml_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_exporttext_exporthtml_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_exporttext_exporthtml_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_exporttext_exporthtml_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_exporttext_exporthtml_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_exporttext_exporthtml_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_exporttext_exporthtml_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_dashboard_exporttext_exporthtml_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_ml_trainingdashboard_result_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_ml_trainingdashboard_result_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_ml_trainingdashboard_result_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_ml_trainingdashboard_result_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_ml_trainingdashboard_result_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_ml_trainingdashboard_result_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_ml_trainingdashboard_result_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_ml_trainingdashboard_result_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_ml_trainingdashboard_result_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_loss_metric_confusion_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_loss_metric_confusion_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_loss_metric_confusion_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_loss_metric_confusion_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_loss_metric_confusion_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_loss_metric_confusion_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_loss_metric_confusion_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_loss_metric_confusion_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_loss_metric_confusion_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_predictions_checkpoint_model_summary_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_predictions_checkpoint_model_summary_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_predictions_checkpoint_model_summary_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_predictions_checkpoint_model_summary_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_predictions_checkpoint_model_summary_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_predictions_checkpoint_model_summary_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_predictions_checkpoint_model_summary_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_predictions_checkpoint_model_summary_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_predictions_checkpoint_model_summary_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_media_image_audio_video_frame_waveform_spectrogram_thumbnails_metadata_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_media_image_audio_video_frame_waveform_spectrogram_thumbnails_metadata_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_media_image_audio_video_frame_waveform_spectrogram_thumbnails_metadata_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_media_image_audio_video_frame_waveform_spectrogram_thumbnails_metadata_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_media_image_audio_video_frame_waveform_spectrogram_thumbnails_metadata_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_media_image_audio_video_frame_waveform_spectrogram_thumbnails_metadata_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_media_image_audio_video_frame_waveform_spectrogram_thumbnails_metadata_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_media_image_audio_video_frame_waveform_spectrogram_thumbnails_metadata_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_media_image_audio_video_frame_waveform_spectrogram_thumbnails_metadata_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_graph_tree_dependency_computational_layout_limits_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_graph_tree_dependency_computational_layout_limits_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_graph_tree_dependency_computational_layout_limits_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_graph_tree_dependency_computational_layout_limits_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_graph_tree_dependency_computational_layout_limits_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_graph_tree_dependency_computational_layout_limits_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_graph_tree_dependency_computational_layout_limits_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_graph_tree_dependency_computational_layout_limits_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_graph_tree_dependency_computational_layout_limits_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_contract_validate
nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_contract_validate:
    test rdx, rdx
    jz servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_.invalid_nebo_contract_validate
    cmp rdi, 100000
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret
