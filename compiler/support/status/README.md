# Internal StatusCode v0

| Value | Name |
|---:|---|
| `0` | `NEBOC_STATUS_OK` |
| `1` | `NEBOC_STATUS_INVALID_ARGUMENT` |
| `2` | `NEBOC_STATUS_OUT_OF_MEMORY` |
| `3` | `NEBOC_STATUS_IO_ERROR` |
| `4` | `NEBOC_STATUS_INVALID_SOURCE` |
| `5` | `NEBOC_STATUS_INTERNAL_ERROR` |
| `6` | `NEBOC_STATUS_UNSUPPORTED_TARGET` |
| `7` | `NEBOC_STATUS_TOOLCHAIN_ERROR` |
| `8` | `NEBOC_STATUS_LIMIT_EXCEEDED` |

A StatusCode controls internal execution. A Diagnostic explains a failure to
the user. The two concepts must not be collapsed.
