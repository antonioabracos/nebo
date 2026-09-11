# Convert an explicit duration

Duration.fromMillis(17).asNanos() returns 17000000. Conversion has no dependency on local clock values or scheduling.

This deterministic recipe uses the bounded public Duration profile. OS/environment/monotonic APIs have individual limits and capability requirements in the Standard Library reference. It promises neither real-time scheduling nor a measured elapsed duration.

Imports: the current implicit prelude. Required effects/capabilities: retained local Console rendering. No network, live display, external credentials or device capability is used.

```nebo
// Duration conversion is deterministic and has no wall-clock assumption.
start(){Duration.fromMillis(17).asNanos().console();59.return;}
```

Expected context:
```json
{
  "expected_exit": 59,
  "kinds": [
    4
  ],
  "text": {
    "bytes_hex": "3137303030303030"
  }
}
```
