# Token model v0

`Token` is 48 bytes: kind, flags, SourceId, byte start, byte end and payload.
Spans are half-open byte ranges. EOF is explicit. Trivia is not preserved.
Deferred keywords and reserved punctuation have dedicated kinds and flags.
