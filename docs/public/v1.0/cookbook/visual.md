# Headless Console rendering

RenderPlan renders the bold markup through .plain(), producing Local, then a typed format produces points=101. No display server is needed for the retained document.

Software, headless and live display profiles are distinct. This recipe promises the local retained text only. Opening a window is not proof of layout, pixels, lifecycle or event semantics; use the explicitly gated live profile when required.

Imports: the current implicit prelude. Required effects/capabilities: retained local Console rendering. No network, live display, external credentials or device capability is used.

```nebo
// Plain rendering is available without a display server.
start(){RenderPlan("/bold{Local}").render(.plain()).console();"points=%d".format(101).console();67.return;}
```

Expected context:
```json
{
  "expected_exit": 67,
  "kinds": [
    2,
    2
  ],
  "text": {
    "bytes_hex": "4c6f63616c706f696e74733d313031"
  }
}
```
