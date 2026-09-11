#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import struct
import sys
from dataclasses import dataclass

MAX_AXIS = 2048
MAX_COMMANDS = 8192
COORD_MIN = -4096
COORD_MAX = 4095
FONT_W = 5
FONT_H = 7
FONT_ADV = 6
FONT_LINE = 8

PATTERNS = {
'0':["01110","10001","10011","10101","11001","10001","01110"],
'1':["00100","01100","00100","00100","00100","00100","01110"],
'2':["01110","10001","00001","00010","00100","01000","11111"],
'3':["11110","00001","00001","01110","00001","00001","11110"],
'4':["00010","00110","01010","10010","11111","00010","00010"],
'5':["11111","10000","10000","11110","00001","00001","11110"],
'6':["01110","10000","10000","11110","10001","10001","01110"],
'7':["11111","00001","00010","00100","01000","01000","01000"],
'8':["01110","10001","10001","01110","10001","10001","01110"],
'9':["01110","10001","10001","01111","00001","00001","01110"],
'A':["01110","10001","10001","11111","10001","10001","10001"],
'B':["11110","10001","10001","11110","10001","10001","11110"],
'C':["01110","10001","10000","10000","10000","10001","01110"],
'D':["11110","10001","10001","10001","10001","10001","11110"],
'E':["11111","10000","10000","11110","10000","10000","11111"],
'F':["11111","10000","10000","11110","10000","10000","10000"],
'G':["01110","10001","10000","10111","10001","10001","01110"],
'H':["10001","10001","10001","11111","10001","10001","10001"],
'I':["01110","00100","00100","00100","00100","00100","01110"],
'J':["00001","00001","00001","00001","10001","10001","01110"],
'K':["10001","10010","10100","11000","10100","10010","10001"],
'L':["10000","10000","10000","10000","10000","10000","11111"],
'M':["10001","11011","10101","10101","10001","10001","10001"],
'N':["10001","11001","10101","10011","10001","10001","10001"],
'O':["01110","10001","10001","10001","10001","10001","01110"],
'P':["11110","10001","10001","11110","10000","10000","10000"],
'Q':["01110","10001","10001","10001","10101","10010","01101"],
'R':["11110","10001","10001","11110","10100","10010","10001"],
'S':["01111","10000","10000","01110","00001","00001","11110"],
'T':["11111","00100","00100","00100","00100","00100","00100"],
'U':["10001","10001","10001","10001","10001","10001","01110"],
'V':["10001","10001","10001","10001","10001","01010","00100"],
'W':["10001","10001","10001","10101","10101","10101","01010"],
'X':["10001","10001","01010","00100","01010","10001","10001"],
'Y':["10001","10001","01010","00100","00100","00100","00100"],
'Z':["11111","00001","00010","00100","01000","10000","11111"],
}
REPLACEMENT = ["11111","10001","10101","10001","10101","10001","11111"]


def premul(c: int, a: int) -> int:
    if a == 0:
        return 0
    if a == 255:
        return c
    return (c * a + 127) // 255


def storage(color: int) -> tuple[int, int, int, int]:
    r = (color >> 24) & 0xFF
    g = (color >> 16) & 0xFF
    b = (color >> 8) & 0xFF
    a = color & 0xFF
    return premul(r, a), premul(g, a), premul(b, a), a


@dataclass
class Canvas:
    width: int
    height: int

    def __post_init__(self) -> None:
        if not (1 <= self.width <= MAX_AXIS and 1 <= self.height <= MAX_AXIS):
            raise ValueError("axis")
        self.pixels = bytearray(self.width * self.height * 4)
        self.commands = 0

    def _commit(self) -> None:
        if self.commands >= MAX_COMMANDS:
            raise OverflowError("command budget")
        self.commands += 1

    def pixel(self, x: int, y: int, color: int) -> None:
        if 0 <= x < self.width and 0 <= y < self.height:
            off = (y * self.width + x) * 4
            self.pixels[off:off+4] = bytes(storage(color))

    def clear(self, color: int) -> None:
        rgba = bytes(storage(color))
        self.pixels[:] = rgba * (self.width * self.height)
        self._commit()

    def line(self, x0: int, y0: int, x1: int, y1: int, color: int) -> None:
        if not all(COORD_MIN <= v <= COORD_MAX for v in (x0,y0,x1,y1)):
            raise ValueError("coordinate")
        if x0 == x1 and y0 == y1:
            return
        dx = abs(x1-x0)
        sx = 1 if x0 < x1 else -1
        dy = -abs(y1-y0)
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.pixel(x0,y0,color)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2*err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy
        self._commit()

    def hline(self, x0: int, x1: int, y: int, color: int) -> None:
        if y < 0 or y >= self.height:
            return
        if x0 > x1:
            x0,x1=x1,x0
        x0=max(x0,0); x1=min(x1,self.width-1)
        for x in range(x0,x1+1):
            self.pixel(x,y,color)

    def rectangle(self, x: int, y: int, w: int, h: int, color: int, fill: bool) -> None:
        if not (COORD_MIN <= x <= COORD_MAX and COORD_MIN <= y <= COORD_MAX):
            raise ValueError("coordinate")
        if not (0 <= w <= 8192 and 0 <= h <= 8192):
            raise ValueError("extent")
        if w == 0 or h == 0:
            return
        if fill:
            for row in range(h):
                self.hline(x,x+w-1,y+row,color)
        else:
            self.line(x,y,x+w-1,y,color)
            self.line(x,y+h-1,x+w-1,y+h-1,color)
            self.line(x,y,x,y+h-1,color)
            self.line(x+w-1,y,x+w-1,y+h-1,color)
            # Internal line calls are one public rectangle command.
            self.commands -= 4
        self._commit()

    def circle(self, cx: int, cy: int, radius: int, color: int, fill: bool) -> None:
        if not (COORD_MIN <= cx <= COORD_MAX and COORD_MIN <= cy <= COORD_MAX):
            raise ValueError("coordinate")
        if not 0 <= radius <= 4095:
            raise ValueError("radius")
        if radius == 0:
            return
        x=radius; y=0; err=1-radius
        while x >= y:
            if fill:
                self.hline(cx-x,cx+x,cy+y,color)
                self.hline(cx-x,cx+x,cy-y,color)
                self.hline(cx-y,cx+y,cy+x,color)
                self.hline(cx-y,cx+y,cy-x,color)
            else:
                for px,py in (
                    (cx+x,cy+y),(cx+y,cy+x),(cx-y,cy+x),(cx-x,cy+y),
                    (cx-x,cy-y),(cx-y,cy-x),(cx+y,cy-x),(cx+x,cy-y),
                ):
                    self.pixel(px,py,color)
            y += 1
            if err < 0:
                err += 2*y + 1
            else:
                x -= 1
                err += 2*(y-x) + 1
        self._commit()

    def text(self, text: str, x: int, y: int, color: int) -> None:
        data=text.encode('utf-8')
        if len(data) > 4096:
            raise ValueError("text limit")
        if not data:
            return
        if not (COORD_MIN <= x <= COORD_MAX and COORD_MIN <= y <= COORD_MAX):
            raise ValueError("coordinate")
        origin=x
        for ch in text:
            if ch == '\n':
                x=origin; y += FONT_LINE; continue
            key=ch.upper()
            rows=PATTERNS.get(key, REPLACEMENT)
            if ch == ' ':
                rows=["00000"]*7
            for row,bits in enumerate(rows):
                for col,bit in enumerate(bits):
                    if bit == '1':
                        self.pixel(x+col,y+row,color)
            x += FONT_ADV
        self._commit()


def golden_scene() -> Canvas:
    c=Canvas(32,24)
    c.clear(0x102030FF)
    c.line(-4,0,31,23,0xFFCC00FF)
    c.rectangle(2,3,10,6,0x2060FFFF,True)
    c.rectangle(18,2,13,9,0xFFFFFFFF,False)
    c.circle(8,17,5,0xE04080FF,True)
    c.circle(23,17,5,0x40FF80FF,False)
    c.text('NEBO',4,8,0xFFFFFFFF)
    if c.commands != 7:
        raise AssertionError(c.commands)
    return c


def property_run(seed: int, cases: int) -> dict[str, object]:
    rng=random.Random(seed)
    digest=hashlib.sha256()
    counters={"cases":cases,"clear":0,"line":0,"rectangle":0,"circle":0,"text":0,"noop":0}
    for _ in range(cases):
        w=rng.randint(1,64); h=rng.randint(1,64)
        c=Canvas(w,h)
        c.clear(rng.getrandbits(32)); counters["clear"]+=1
        kind=rng.randrange(4)
        color=rng.getrandbits(32)
        before=bytes(c.pixels)
        if kind==0:
            x0=rng.randint(-96,96); y0=rng.randint(-96,96)
            x1=rng.randint(-96,96); y1=rng.randint(-96,96)
            if x0==x1 and y0==y1: counters["noop"]+=1
            c.line(x0,y0,x1,y1,color); counters["line"]+=1
        elif kind==1:
            rw=rng.randrange(0,96); rh=rng.randrange(0,96)
            if rw==0 or rh==0: counters["noop"]+=1
            c.rectangle(rng.randint(-64,64),rng.randint(-64,64),rw,rh,color,bool(rng.getrandbits(1)))
            counters["rectangle"]+=1
        elif kind==2:
            radius=rng.randrange(0,48)
            if radius==0: counters["noop"]+=1
            c.circle(rng.randint(-64,64),rng.randint(-64,64),radius,color,bool(rng.getrandbits(1)))
            counters["circle"]+=1
        else:
            text=rng.choice(['NEBO','A2','x','', 'Z\n9','Ω'])
            if not text: counters["noop"]+=1
            c.text(text,rng.randint(-64,64),rng.randint(-64,64),color); counters["text"]+=1
        assert len(c.pixels)==w*h*4
        # No-op operations preserve bytes exactly.
        if counters["noop"] and c.commands == 1:
            assert c.pixels == before
        digest.update(struct.pack('<HHQ',w,h,c.commands))
        digest.update(c.pixels)
    return {"seed":seed,"cases":cases,"counters":counters,"sha256":digest.hexdigest()}


def exact_float(value: float) -> int:
    if not math.isfinite(value) or value != math.trunc(value):
        raise ValueError("non integer")
    out=int(value)
    if not COORD_MIN <= out <= COORD_MAX:
        raise OverflowError("coordinate")
    return out


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument('--golden',action='store_true')
    ap.add_argument('--properties',action='store_true')
    ap.add_argument('--seed',type=lambda x:int(x,0),default=0x271806)
    ap.add_argument('--cases',type=int,default=5000)
    args=ap.parse_args()
    if args.golden:
        sys.stdout.buffer.write(golden_scene().pixels)
        return 0
    if args.properties:
        result=property_run(args.seed,args.cases)
        print('RF27_G18_F06_RASTER_MODEL=PASS '
              f"seed=0x{args.seed:x} cases={args.cases} digest={result['sha256']} "
              + ' '.join(f'{k}={v}' for k,v in result['counters'].items()))
        print(json.dumps(result,sort_keys=True))
        return 0
    assert exact_float(0.0)==0
    assert exact_float(-0.0)==0
    assert exact_float(4095.0)==4095
    for value in (math.nan,math.inf,-math.inf,1.5,4096.0):
        try: exact_float(value)
        except (ValueError,OverflowError): pass
        else: raise AssertionError(value)
    print('RF27_G18_F06_ORACLE_SELFTEST=PASS')
    return 0

if __name__=='__main__':
    raise SystemExit(main())
