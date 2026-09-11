#!/usr/bin/env python3
"""Relocatable offline lifecycle entry point."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from compiler.sdk.offline_lifecycle import main
if __name__ == '__main__':
    import signal
    def stop(*_): raise InterruptedError('NEBO_OFFLINE_INTERRUPTED')
    signal.signal(signal.SIGTERM,stop)
    raise SystemExit(main())
