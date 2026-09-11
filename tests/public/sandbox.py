"""Kernel rules for SDK file access; directory traversal grants no file reads."""
import ctypes,os
from pathlib import Path
class Rule(ctypes.Structure):
    _pack_=1
    _fields_=[('access',ctypes.c_uint64),('parent',ctypes.c_int32)]

def restrict(roots):
    libc=ctypes.CDLL(None,use_errno=True)
    abi=libc.syscall(444,0,0,1)
    if abi<1:raise OSError(ctypes.get_errno(),'LANDLOCK_UNAVAILABLE')
    handled=(1<<min(12+abi,15))-1
    mask=ctypes.c_uint64(handled)
    fd=libc.syscall(444,ctypes.byref(mask),8,0)
    if fd<0:raise OSError(ctypes.get_errno(),'LANDLOCK_RULESET')
    def allow(path,access):
        if not Path(path).exists():return
        parent=os.open(path,os.O_PATH|os.O_CLOEXEC)
        try:
            rule=Rule(access,parent)
            if libc.syscall(445,fd,1,ctypes.byref(rule),0):
                raise OSError(ctypes.get_errno(),'LANDLOCK_PATH')
        finally:os.close(parent)
    try:
        allow('/',8)
        for root in roots:allow(str(root),handled)
        for directory in ('/usr','/lib','/lib64','/bin'):allow(directory,1|4|8)
        for file in ('/etc/ld.so.cache','/dev/urandom'):allow(file,4)
        allow('/dev/null',2|4)
        if libc.prctl(38,1,0,0,0) or libc.syscall(446,fd,0):
            raise OSError(ctypes.get_errno(),'LANDLOCK_RESTRICT')
    finally:os.close(fd)
