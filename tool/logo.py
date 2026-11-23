"""Usage: python3 tool/logo.py  (needs rsvg-convert; then run `dart run flutter_launcher_icons`).

The LifeMeter mark, "One-Hand Life Clock": a paper-white dial on a riso-cobalt
tile with one short cobalt hand set to 10:54 (the app's hero example, "It's
10:54 AM in your life") and a fluoro-pink heart on the rim where the hand
points, cut free by a cobalt gap. The heart is "now": the time you have, spent on
what you love. Pink means "now", as on the progress bar.

Writes:
  assets/images/logo.svg / logo.png                    full-bleed cobalt tile, 1024
  assets/images/logo_foreground.svg / .png             transparent adaptive foreground
                                                       (flutter_launcher_icons adds its own 16% inset)
  assets/images/logo_monochrome.svg / .png             themed-icon silhouette (hand and gap cut out)
  site/img/logo.png (1024) and site/img/favicon.png (64)
  android/app/src/main/res/drawable/ic_widget_mark.xml widget header glyph (cropped to the glyph)

The geometry constants below are mirrored in lib/widgets/logo_mark.dart (LogoPainter).
"""
import math
import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COBALT, PINK, WHITE = "#2340F5", "#FF48B0", "#FFFFFF"
S = 1024.0

# Geometry, as fractions of the tile side.
DIAL_R = 0.272     # paper dial radius
HAND_W = 0.092     # hand thickness (round caps)
KNOB_R = 0.105     # pink now-knob radius
GAP = 0.029        # cobalt ring around the knob
KNOB_AT = 1.07     # knob centre, in dial radii from the dial centre
OVERLAP = 0.020    # the hand's round cap runs this far into the knob's gap ring
ANGLE = (10 + 54 / 60) / 12 * 360   # 10:54 -> 327 deg clockwise from 12
HAND_L = DIAL_R * KNOB_AT - KNOB_R - GAP - HAND_W / 2 + OVERLAP   # pivot -> end-cap centre
# The heart replaces the round knob. It is drawn from a unit outline (x -1..1,
# y -0.95..0.9, centred near the knob centre) scaled by HEART; the gap is the
# same outline stroked in cobalt.
HEART = KNOB_R * 1.16
HEART_PATH = [  # (command, points) in unit space; mirrored in LogoPainter
    ("M", [(0.0, 0.9)]),
    ("C", [(-0.6, 0.45), (-1.0, 0.1), (-1.0, -0.3)]),
    ("C", [(-1.0, -0.7), (-0.65, -0.95), (-0.35, -0.95)]),
    ("C", [(-0.15, -0.95), (-0.03, -0.82), (0.0, -0.65)]),
    ("C", [(0.03, -0.82), (0.15, -0.95), (0.35, -0.95)]),
    ("C", [(0.65, -0.95), (1.0, -0.7), (1.0, -0.3)]),
    ("C", [(1.0, 0.1), (0.6, 0.45), (0.0, 0.9)]),
]


def heart_d(cx, cy, scale, turn=math.radians(ANGLE)):
    """The heart, tilted so its point aims along the hand at the dial centre."""
    c, s_ = math.cos(turn), math.sin(turn)
    out = []
    for cmd, pts in HEART_PATH:
        out.append(cmd + " ".join(
            f"{cx + (x * c - y * s_) * scale:.3f},{cy + (x * s_ + y * c) * scale:.3f}" for x, y in pts))
    return " ".join(out) + " Z"
# Knob centre on a pixel centre at 16 and 48 px, so it rasterises as a solid block.
KNOB_X, KNOB_Y = 5.5 / 16, 4.5 / 16
_a = math.radians(ANGLE)
DIAL_X = KNOB_X - DIAL_R * KNOB_AT * math.sin(_a)
DIAL_Y = KNOB_Y + DIAL_R * KNOB_AT * math.cos(_a)
# Square crop around the visible glyph (dial + knob), for tile-less uses.
CROP = (196.4, 180.4, 636.0)   # x, y, side on the 1024 grid


def pol(r, deg=ANGLE):
    a = math.radians(deg)
    return DIAL_X * S + r * math.sin(a), DIAL_Y * S - r * math.cos(a)


def shapes(cut=COBALT, dial=WHITE, knob=PINK):
    cx, cy = DIAL_X * S, DIAL_Y * S
    hx, hy = pol(HAND_L * S)
    kx, ky = pol(KNOB_AT * DIAL_R * S)
    return [
        f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="{DIAL_R * S:.2f}" fill="{dial}"/>',
        f'<line x1="{cx:.2f}" y1="{cy:.2f}" x2="{hx:.2f}" y2="{hy:.2f}" stroke="{cut}" '
        f'stroke-width="{HAND_W * S:.2f}" stroke-linecap="round"/>',
        f'<path d="{heart_d(kx, ky, HEART * S)}" fill="{cut}" stroke="{cut}" '
        f'stroke-width="{2 * GAP * S:.2f}" stroke-linejoin="round"/>',
        f'<path d="{heart_d(kx, ky, HEART * S)}" fill="{knob}"/>',
    ]


def svg(body, bg=None):
    rect = f'<rect width="1024" height="1024" fill="{bg}"/>' if bg else ""
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'
            f'{rect}{"".join(body)}</svg>\n')


def mono_svg():
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'
            '<mask id="m" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">'
            '<rect width="1024" height="1024" fill="black"/>'
            f'{"".join(shapes(cut="black", dial="white", knob="white"))}</mask>'
            '<rect width="1024" height="1024" fill="white" mask="url(#m)"/></svg>\n')


def circle_path(x, y, r):
    return (f"M{x - r:.3f},{y:.3f} a{r:.3f},{r:.3f} 0 1,0 {2 * r:.3f},0 "
            f"a{r:.3f},{r:.3f} 0 1,0 {-2 * r:.3f},0 Z")


def widget_vector():
    """The glyph in the CROP box, scaled to a 24-unit viewport, coloured by widget tokens."""
    ox, oy, side = CROP
    k = 24 / side

    def p(x, y):
        return (x - ox) * k, (y - oy) * k

    cx, cy = p(DIAL_X * S, DIAL_Y * S)
    hx, hy = p(*pol(HAND_L * S))
    kx, ky = p(*pol(KNOB_AT * DIAL_R * S))
    dial, heart = DIAL_R * S * k, HEART * S * k
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!-- The LifeMeter mark (one-hand Life Clock) for the widget header. Generated by tool/logo.py. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="12dp" android:height="12dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="@color/lm_widget_text"
        android:pathData="{circle_path(cx, cy, dial)}" />
    <path android:strokeColor="@color/lm_widget_bg" android:strokeWidth="{HAND_W * S * k:.3f}"
        android:strokeLineCap="round"
        android:pathData="M{cx:.3f},{cy:.3f} L{hx:.3f},{hy:.3f}" />
    <path android:fillColor="@color/lm_widget_bg" android:strokeColor="@color/lm_widget_bg"
        android:strokeWidth="{2 * GAP * S * k:.3f}" android:strokeLineJoin="round"
        android:pathData="{heart_d(kx, ky, heart)}" />
    <path android:fillColor="@color/lm_widget_now"
        android:pathData="{heart_d(kx, ky, heart)}" />
</vector>
"""


def write(rel, text):
    path = os.path.join(ROOT, rel)
    with open(path, "w") as f:
        f.write(text)
    return path


def render(src, rel, px):
    subprocess.run(["rsvg-convert", "-w", str(px), "-h", str(px), src,
                    "-o", os.path.join(ROOT, rel)], check=True)


def main():
    tile = write("assets/images/logo.svg", svg(shapes(), bg=COBALT))
    fg = write("assets/images/logo_foreground.svg", svg(shapes()))
    mono = write("assets/images/logo_monochrome.svg", mono_svg())
    render(tile, "assets/images/logo.png", 1024)
    render(fg, "assets/images/logo_foreground.png", 1024)
    render(mono, "assets/images/logo_monochrome.png", 1024)
    render(tile, "site/img/logo.png", 1024)
    render(tile, "site/img/favicon.png", 64)
    write("android/app/src/main/res/drawable/ic_widget_mark.xml", widget_vector())
    print(f"HAND_L={HAND_L:.4f} dial=({DIAL_X:.4f}, {DIAL_Y:.4f}) angle={ANGLE:.1f}")


if __name__ == "__main__":
    main()
