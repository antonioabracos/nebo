#!/usr/bin/env python3
"""Resolve a local X11 AF_UNIX socket and MIT-MAGIC-COOKIE-1 without Xlib."""
from __future__ import annotations
import os, struct, sys
from pathlib import Path

AUTH_NAME=b'MIT-MAGIC-COOKIE-1'
FAMILY_LOCAL=256
FAMILY_WILD=65535

def fail(msg: str) -> None:
    raise SystemExit(f'MF051_X11_AUTH_RESOLVE_FAIL: {msg}')

def display_number(raw: str) -> str:
    value=raw.strip()
    for prefix in ('unix/', 'localhost'):
        if value.startswith(prefix): value=value[len(prefix):]
    if not value.startswith(':'): fail(f'only local DISPLAY is supported: {raw!r}')
    number=value[1:].split('.',1)[0]
    if not number.isdigit(): fail(f'invalid DISPLAY: {raw!r}')
    return number

def field(data: bytes, offset: int) -> tuple[bytes,int]:
    if offset+2>len(data): fail('truncated Xauthority length')
    size=struct.unpack_from('>H',data,offset)[0]; offset+=2
    if offset+size>len(data): fail('truncated Xauthority field')
    return data[offset:offset+size], offset+size

def records(data: bytes):
    off=0
    while off<len(data):
        if off+2>len(data): fail('truncated Xauthority family')
        fam=struct.unpack_from('>H',data,off)[0]; off+=2
        addr,off=field(data,off); number,off=field(data,off)
        name,off=field(data,off); auth,off=field(data,off)
        yield fam,addr,number,name,auth

def main() -> None:
    display=os.environ.get('DISPLAY','')
    if not display: fail('DISPLAY is empty')
    number=display_number(display)
    socket=Path('/tmp/.X11-unix')/f'X{number}'
    if not socket.exists(): fail(f'X11 socket not found: {socket}')
    auth_path=Path(os.environ.get('XAUTHORITY') or (Path.home()/'.Xauthority'))
    if not auth_path.is_file(): fail(f'Xauthority not found: {auth_path}')
    data=auth_path.read_bytes(); candidates=[]
    for fam,addr,num,name,auth in records(data):
        if name!=AUTH_NAME or num.decode('ascii','ignore')!=number or not auth: continue
        rank=0 if fam==FAMILY_LOCAL else 1 if fam==FAMILY_WILD else 2
        candidates.append((rank,fam,addr,auth))
    if not candidates: fail(f'no MIT-MAGIC-COOKIE-1 record for DISPLAY :{number}')
    candidates.sort(key=lambda x:x[0]); auth=candidates[0][3]
    if len(auth)>256: fail('authentication cookie exceeds adapter limit')
    print(f'SOCKET_PATH={socket}')
    print(f'COOKIE_HEX={auth.hex()}')
    print(f'DISPLAY_NUMBER={number}')
    print(f'XAUTHORITY_PATH={auth_path}')
if __name__=='__main__': main()
