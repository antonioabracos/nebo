# Bounded tasks and channels

A noncapturing callback runs through the bounded native task profile and returns 73. A separate capacity-two channel returns 89 and is then closed.

The current material concurrency profile is bounded and is not promoted to stable by this recipe. Futures have consumption rules and channels distinguish full, empty and closed states. No claim of parallel scaling, unbounded tasks or real-time scheduling is made.

Imports: the current implicit prelude. Required effects/capabilities: bounded local task/channel runtime state. No network, live display, external credentials or device capability is used.

```nebo
// A noncapturing task and channel use separate lifetimes.
(Int.index)work(){(index+73).return;}start(){Task.spawn(work).f;Channel<Int>.bounded(2).c;c.trySend(89).get();f.await().get().console();c.tryReceive().get().console();c.close();61.return;}
```

Expected context:
```json
{
  "expected_exit": 61,
  "kinds": [
    4,
    4
  ],
  "text": {
    "bytes_hex": "37333839"
  }
}
```
