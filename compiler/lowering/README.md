# Function Lowering Plan

MF030 creates a target-independent logical `FunctionPlan` from validated semantic,
routing and dependency metadata. It records the stable Console/scan runtime
operation sequence, continuation registrations, cancellation policy and exit paths.

The plan is not a universal IR and contains no target DataLayout, physical stack
slots, instruction selection, ABI lowering or emitted Assembly. Those decisions
remain in TR07.
