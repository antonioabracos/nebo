%ifndef NEBO_CANVAS_X11_INC
%define NEBO_CANVAS_X11_INC 1

%include "runtime/canvas/canvas.inc"
%include "runtime/window/x11/x11_window.inc"

%ifndef NEBO_CANVAS_X11_IMPLEMENTATION
extern nebo_canvas_present_x11
%endif

%endif
