# Formatting a local documentation result

Open index.html in the restored documentation root. Search uses the same complete document index in the browser and neboc docs search. Results show maturity and target and point to local pages. No analytics, CDN, fetch or external font is required.

Use Tab to reach navigation, search and results; Enter opens the selected link. A visible focus outline and skip link are provided. Without JavaScript, use the complete reference indexes with Browser Find. The manual and editor help metadata use the same identities; documentation identities are not language SymbolIds.

```nebo
// A composed value is rendered through the public format sink.
start(){"pages=%d".format(79).console();59.return;}
```

Expected context:
```json
{
  "expected_exit": 59,
  "kinds": [
    2
  ],
  "text": {
    "bytes_hex": "70616765733d3739"
  }
}
```
neboc docs portal build docs/public/v1.0 -o ./site --archive ./nebo-docs-v1.0.tar
neboc docs portal verify ./site
neboc docs search "Scan" --index ./site/search-index.json --report json
