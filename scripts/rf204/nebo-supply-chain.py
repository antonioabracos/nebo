#!/usr/bin/env python3
"""Explicit offline entry point for the supply-chain inventory owner."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from compiler.sdk.supply_chain import main
if __name__=='__main__':main()
