%ifndef NEBO_STREAM_BRIDGE_INC
%define NEBO_STREAM_BRIDGE_INC 1
%include "compiler/semantic/data/data_contract.inc"
%include "runtime/concurrency/channel.inc"
%include "runtime/network/socket.inc"
%ifndef NEBO_STREAM_BRIDGE_IMPLEMENTATION
extern nebo_stream_to_channel
extern nebo_channel_to_sink
extern nebo_channel_to_socket
%endif
%endif
