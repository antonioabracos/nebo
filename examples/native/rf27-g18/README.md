# RF27-G18 native Window examples

## F04 deterministic headless Window

`headless-window.asm` demonstrates the active bounded-native F04 ABI:
caller-owned runtime/record/event storage, one scoped event consumer,
deterministic `CREATED`/`SHOWN`/`CLOSED` ordering, bounded `wait`, direct close,
stream release and generational reclaim.

## F05 bounded direct-X11 Window

`x11-window.asm` demonstrates the active bounded-native F05 ABI over the
repository's direct AF_UNIX/X11 protocol adapter. It receives the resolved
local socket path and MIT-MAGIC-COOKIE-1 as arguments, then creates an unmapped
Window, binds one typed event stream, performs server-confirmed show, title,
resize, hide/show and redraw operations, leaves the mapped resource visible for
100 ms, closes it, drains `CREATED`/`SHOWN`/`HIDDEN`/`RESIZED`/`CLOSED`,
releases the stream, reclaims the generational handle and shuts down the
caller-owned runtime.

The live command is executed by the F05 validator only when the local DISPLAY,
AF_UNIX socket and Xauthority cookie are available. Without them the factual
classification is `LIVE_X11=NOT_EXECUTED_DISPLAY_UNAVAILABLE`; the mandatory
headless/protocol and existing X11 regressions still run.

## F06 bounded deterministic Canvas 2D

`canvas-2d.asm` composes the active bounded-native Canvas ABI with the F04
headless Window: caller-owned RGBA pixels and command records, clear, line,
filled rectangle, midpoint circle, built-in text, deterministic present, close
and exact Window cleanup. The optional F06 live test presents the same
SoftwareSurface through the F05 direct-X11 adapter when local display authority
exists.

These are native Assembly integration examples. F04–F06 do **not** activate a
new `.no` parser surface. F05 proves a server-mapped Window; F06 proves a
bounded direct pixel-transfer request without fabricating a screenshot or
human-observation claim. `canvas.image` remains deferred to RF27-G19.


## F07 bounded accessible widgets

`accessible-widgets.asm` composes exact integer Row layout, a bounded Label,
Button and TextInput, stable focus order, semantic accessibility metadata and
F06 Canvas rendering over caller-owned tree, node, event, text, pixel and
command storage. F07 accessibility is a bounded semantic snapshot; it does not
claim an AT-SPI or other operating-system accessibility bridge.

F07 keeps source-language widget syntax inactive. Charts remain in F08 and
`canvas.image` remains deferred to RF27-G19.

## F08 bounded Canvas charts

`charts.asm` composes line, scatter, bar and histogram series with title, X/Y
axes, grid lines and a bounded top-right legend over the F06 caller-owned
Canvas. Numeric values follow the G14 finite binary64 policy; the native ABI can
borrow existing G15 F64 Matrix storage without copying it. The example renders
deterministically, verifies the command count, then closes Chart and Canvas.

F08 keeps public `.no` Chart syntax inactive and adds no host plotting library,
host font, heap allocation or new Matrix/Dataset representation. Its normative
visual proof is the versioned headless command/pixel golden. F09 remains the
program closeout and `canvas.image` remains deferred to RF27-G19.

## F09 compact numeric/visual program closeout

`numeric-visual-app.asm` is the final bounded-native composition proof for the
G14–G18 program. One static ELF executes scalar `abs`/`sqrt`, validates a G15
F64 Matrix, constructs and queries a G16 Tensor, runs a G17 scalar add and
kernel plan, preserves the F02 Console document, creates an F04 headless Window,
renders F07 widgets and typed TextInput/accessibility metadata, renders F08
line/scatter/bar/histogram Charts through the F06 Canvas, presents a deterministic
headless frame, performs ordered cleanup, and writes a versioned pointer-free
160-byte summary to stdout.

The example is a public bounded-native ABI demonstration. It does not activate
or pretend to demonstrate public `.no` Window/Canvas/widget/Chart syntax.
`canvas.image` remains deferred to RF27-G19. Live X11 evidence is optional and
factual; headless summary/golden evidence is mandatory.
