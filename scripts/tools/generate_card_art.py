from __future__ import annotations

import math
from pathlib import Path
from typing import Callable

from PIL import Image, ImageChops, ImageDraw, ImageFilter


WIDTH = 768
HEIGHT = 1024
ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = ROOT / "assets" / "card_art"


Color = tuple[int, int, int, int]


def rgba(hex_color: str, alpha: int = 255) -> Color:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c1: Color, c2: Color, t: float) -> Color:
    return (
        int(lerp(c1[0], c2[0], t)),
        int(lerp(c1[1], c2[1], t)),
        int(lerp(c1[2], c2[2], t)),
        int(lerp(c1[3], c2[3], t)),
    )


def gradient_background(size: tuple[int, int], top: Color, bottom: Color, accent: Color) -> Image.Image:
    width, height = size
    img = Image.new("RGBA", size, top)
    pixels = img.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        line = mix(top, bottom, t)
        for x in range(width):
            pixels[x, y] = line

    accent_layer = Image.new("RGBA", size, (0, 0, 0, 0))
    accent_draw = ImageDraw.Draw(accent_layer)
    accent_draw.polygon(
        [
            (int(width * 0.58), -30),
            (width + 50, 0),
            (width + 50, int(height * 0.42)),
            (int(width * 0.28), int(height * 0.12)),
        ],
        fill=accent,
    )
    accent_draw.polygon(
        [
            (-50, int(height * 0.64)),
            (int(width * 0.34), int(height * 0.36)),
            (int(width * 0.54), height + 50),
            (-50, height + 50),
        ],
        fill=(255, 255, 255, 18),
    )
    accent_layer = accent_layer.filter(ImageFilter.GaussianBlur(28))
    return Image.alpha_composite(img, accent_layer)


def apply_vignette(img: Image.Image, strength: int = 110) -> Image.Image:
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rectangle((0, 0, img.width, img.height), fill=(0, 0, 0, 0))
    draw.rounded_rectangle(
        (-40, -40, img.width + 40, img.height + 40),
        radius=48,
        outline=(0, 0, 0, strength),
        width=92,
    )
    overlay = overlay.filter(ImageFilter.GaussianBlur(32))
    return Image.alpha_composite(img, overlay)


def glow_line(layer: Image.Image, points: list[tuple[int, int]], width: int, color: Color, blur: int = 24) -> None:
    draw = ImageDraw.Draw(layer)
    draw.line(points, fill=color, width=width, joint="curve")
    if blur > 0:
        blurred = layer.filter(ImageFilter.GaussianBlur(blur))
        layer.alpha_composite(blurred)


def add_orb(img: Image.Image, center: tuple[int, int], radius: int, inner: Color, outer: Color) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=outer)
    layer = layer.filter(ImageFilter.GaussianBlur(max(radius // 3, 8)))
    img.alpha_composite(layer)
    draw = ImageDraw.Draw(img)
    draw.ellipse((x - radius // 2, y - radius // 2, x + radius // 2, y + radius // 2), fill=inner)


def add_shards(img: Image.Image, color: Color, count: int = 6, angle_shift: float = 0.0) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx = img.width // 2
    cy = img.height // 2
    for index in range(count):
        angle = angle_shift + (math.pi * 2.0 / count) * index
        dx = math.cos(angle)
        dy = math.sin(angle)
        inner = 120 + index * 12
        outer = 360 + index * 10
        spread = 18 + index * 2
        points = [
            (int(cx + dx * inner - dy * spread), int(cy + dy * inner + dx * spread)),
            (int(cx + dx * outer), int(cy + dy * outer)),
            (int(cx + dx * inner + dy * spread), int(cy + dy * inner - dx * spread)),
        ]
        draw.polygon(points, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(8))
    img.alpha_composite(layer)


def add_frame(img: Image.Image, border: Color) -> None:
    frame = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)
    draw.rounded_rectangle(
        (16, 16, img.width - 16, img.height - 16),
        radius=34,
        outline=border,
        width=8,
    )
    draw.rounded_rectangle(
        (34, 34, img.width - 34, img.height - 34),
        radius=28,
        outline=(255, 255, 255, 36),
        width=2,
    )
    frame = frame.filter(ImageFilter.GaussianBlur(1))
    img.alpha_composite(frame)


def add_support_grid(img: Image.Image, color: Color) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    nodes = [
        (186, 250),
        (562, 236),
        (220, 566),
        (540, 612),
        (382, 442),
    ]
    for start in range(len(nodes)):
        for end in range(start + 1, len(nodes)):
            draw.line((nodes[start], nodes[end]), fill=color, width=8)
    for x, y in nodes:
        draw.ellipse((x - 26, y - 26, x + 26, y + 26), fill=(255, 255, 255, 235))
        draw.ellipse((x - 12, y - 12, x + 12, y + 12), fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(4))
    img.alpha_composite(layer)


def add_scan_arc(img: Image.Image, box: tuple[int, int, int, int], color: Color, width: int) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.arc(box, start=210, end=320, fill=color, width=width)
    draw.arc((box[0] + 60, box[1] + 60, box[2] - 60, box[3] - 60), start=220, end=300, fill=(255, 255, 255, 130), width=max(width // 2, 4))
    layer = layer.filter(ImageFilter.GaussianBlur(3))
    img.alpha_composite(layer)


def add_slash(img: Image.Image, start: tuple[int, int], end: tuple[int, int], color: Color, glow: Color, width: int = 34) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.line((start, end), fill=glow, width=width + 22)
    layer = layer.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(layer)
    draw = ImageDraw.Draw(img)
    draw.line((start, end), fill=color, width=width)
    draw.line((start, end), fill=(255, 255, 255, 130), width=max(width // 5, 3))


def add_card_silhouettes(img: Image.Image, color: Color) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cards = [
        (240, 250, -16),
        (365, 210, 9),
        (470, 290, 18),
    ]
    for x, y, tilt in cards:
        draw.rounded_rectangle((x, y, x + 168, y + 238), radius=20, fill=color)
        draw.rounded_rectangle((x + 10, y + 12, x + 158, y + 226), radius=16, outline=(255, 255, 255, 120), width=3)
    layer = layer.rotate(-4, resample=Image.Resampling.BICUBIC, center=(384, 440))
    layer = layer.filter(ImageFilter.GaussianBlur(2))
    img.alpha_composite(layer)


def add_text_band(img: Image.Image, band_color: Color) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.polygon(
        [
            (-40, img.height - 214),
            (img.width, img.height - 304),
            (img.width + 50, img.height - 92),
            (-50, img.height),
        ],
        fill=band_color,
    )
    layer = layer.filter(ImageFilter.GaussianBlur(6))
    img.alpha_composite(layer)


def motif_arts_bolt(img: Image.Image) -> None:
    add_orb(img, (286, 664), 96, rgba("#f2fdff"), rgba("#45d5ff", 210))
    add_slash(img, (156, 760), (602, 296), rgba("#d5f7ff"), rgba("#2bd1ff", 180), 42)
    add_slash(img, (250, 860), (654, 420), rgba("#c8f8ff"), rgba("#6b67ff", 120), 18)


def motif_barrier_formula(img: Image.Image) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    hexagon = [(384, 190), (578, 318), (578, 568), (384, 694), (190, 568), (190, 318)]
    draw.polygon(hexagon, fill=rgba("#99ebff", 48), outline=rgba("#bff8ff"), width=12)
    draw.polygon([(384, 252), (516, 340), (516, 522), (384, 610), (252, 522), (252, 340)], fill=rgba("#f4feff", 148))
    for radius in (220, 290):
        draw.ellipse((384 - radius, 442 - radius, 384 + radius, 442 + radius), outline=rgba("#7fe0ff", 90), width=6)
    layer = layer.filter(ImageFilter.GaussianBlur(2))
    img.alpha_composite(layer)


def motif_blast_countdown(img: Image.Image) -> None:
    add_orb(img, (392, 448), 128, rgba("#fff7d9"), rgba("#ff9d34", 220))
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse((264, 326, 520, 582), fill=rgba("#ffb14e", 220), outline=rgba("#fff7d9"), width=8)
    draw.rectangle((372, 220, 412, 330), fill=rgba("#40211c"))
    draw.polygon([(372, 220), (414, 220), (430, 170), (356, 170)], fill=rgba("#fff2cf"))
    for offset in range(3):
        x0 = 286 + offset * 74
        draw.rounded_rectangle((x0, 670, x0 + 52, 788), radius=18, fill=rgba("#ff7043", 220))
    layer = layer.filter(ImageFilter.GaussianBlur(2))
    img.alpha_composite(layer)


def motif_burn_will(img: Image.Image) -> None:
    add_orb(img, (382, 508), 144, rgba("#fff9cf"), rgba("#ff6439", 220))
    add_shards(img, rgba("#ffbf4b", 190), count=7, angle_shift=0.2)
    add_text_band(img, rgba("#520000", 78))


def motif_command_sync(img: Image.Image) -> None:
    add_support_grid(img, rgba("#72f6ff", 220))
    add_slash(img, (154, 846), (644, 188), rgba("#f7feff"), rgba("#5ef8ff", 96), 12)


def motif_discipline_note(img: Image.Image) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle((220, 180, 548, 780), radius=34, fill=rgba("#f4ead6", 232))
    for y in range(248, 700, 72):
        draw.line((274, y, 500, y), fill=rgba("#4f5f6a", 110), width=5)
    draw.line((252, 340, 526, 636), fill=rgba("#ff7b53"), width=28)
    draw.line((526, 340, 252, 636), fill=rgba("#fff0b0"), width=16)
    layer = layer.filter(ImageFilter.GaussianBlur(2))
    img.alpha_composite(layer)


def motif_echo_conduit(img: Image.Image) -> None:
    add_orb(img, (282, 552), 118, rgba("#ecfcff"), rgba("#59ddff", 210))
    for radius in (146, 210, 282):
        add_scan_arc(img, (282 - radius, 552 - radius, 282 + radius, 552 + radius), rgba("#72e8ff", 180), 12)
    add_slash(img, (328, 560), (664, 468), rgba("#d8faff"), rgba("#7b79ff", 80), 24)


def motif_emergency_shield(img: Image.Image) -> None:
    motif_barrier_formula(img)
    add_slash(img, (112, 810), (292, 620), rgba("#d6fbff"), rgba("#57d3ff", 120), 20)
    add_slash(img, (656, 812), (476, 620), rgba("#d6fbff"), rgba("#57d3ff", 120), 20)


def motif_focus_pulse(img: Image.Image) -> None:
    add_orb(img, (228, 604), 74, rgba("#f8ffff"), rgba("#53d3ff", 192))
    add_slash(img, (188, 660), (690, 402), rgba("#ffffff"), rgba("#38deff", 170), 26)
    add_slash(img, (268, 692), (668, 506), rgba("#fff6c8"), rgba("#7b69ff", 88), 12)


def motif_guided_fire(img: Image.Image) -> None:
    add_orb(img, (246, 610), 78, rgba("#fcffff"), rgba("#67deff", 175))
    add_orb(img, (310, 744), 48, rgba("#f6ffff"), rgba("#6ca7ff", 140))
    add_slash(img, (222, 632), (650, 358), rgba("#fefefe"), rgba("#51dfff", 120), 22)
    add_slash(img, (314, 742), (680, 514), rgba("#ffffff"), rgba("#6d75ff", 100), 18)


def motif_hesitation(img: Image.Image) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    shadow = [(222, 238), (472, 238), (540, 412), (384, 756), (214, 566)]
    draw.polygon(shadow, fill=rgba("#1e1a3a", 190))
    draw.polygon([(316, 238), (580, 238), (646, 412), (474, 756), (304, 566)], fill=rgba("#8291ff", 88))
    for x in (262, 352, 442, 532):
        draw.line((x, 210, x - 58, 812), fill=rgba("#f8fbff", 150), width=8)
    layer = layer.filter(ImageFilter.GaussianBlur(8))
    img.alpha_composite(layer)


def motif_mind_alignment(img: Image.Image) -> None:
    for radius in (96, 166, 236, 320):
        add_scan_arc(img, (384 - radius, 440 - radius, 384 + radius, 440 + radius), rgba("#73ebff", 180), 10)
    add_orb(img, (384, 442), 80, rgba("#f8ffff"), rgba("#79deff", 210))
    add_text_band(img, rgba("#1d3d5d", 92))


def motif_overclock_arts(img: Image.Image) -> None:
    add_orb(img, (390, 446), 126, rgba("#fffad7"), rgba("#66ddff", 180))
    add_shards(img, rgba("#ff7648", 160), count=9, angle_shift=0.1)
    add_slash(img, (208, 812), (598, 282), rgba("#ffffff"), rgba("#5be3ff", 110), 26)


def motif_panic_static(img: Image.Image) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for row in range(11):
        y = 148 + row * 64
        draw.rectangle((94 + (row % 3) * 36, y, 694 - (row % 2) * 44, y + 30), fill=rgba("#b4b2ff", 58 + row * 10))
    for col in range(5):
        x = 122 + col * 118
        draw.rectangle((x, 180, x + 22, 842), fill=rgba("#ff52b0", 52 + col * 18))
    layer = layer.filter(ImageFilter.GaussianBlur(4))
    img.alpha_composite(layer)


def motif_pulse_scan(img: Image.Image) -> None:
    add_card_silhouettes(img, rgba("#7fe6ff", 74))
    add_scan_arc(img, (62, 206, 708, 852), rgba("#7ce8ff", 220), 18)
    add_slash(img, (232, 756), (574, 366), rgba("#fbffff"), rgba("#7ce8ff", 70), 10)


def motif_rescue_corridor(img: Image.Image) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.polygon(
        [(214, 164), (554, 164), (676, 862), (92, 862)],
        fill=rgba("#fff6d8", 210),
    )
    draw.polygon(
        [(286, 250), (484, 250), (558, 814), (210, 814)],
        fill=rgba("#83e1ff", 122),
    )
    draw.ellipse((244, 650, 314, 814), fill=rgba("#22304d", 200))
    draw.ellipse((454, 616, 530, 820), fill=rgba("#22304d", 200))
    layer = layer.filter(ImageFilter.GaussianBlur(3))
    img.alpha_composite(layer)


def motif_resonance_burst(img: Image.Image) -> None:
    add_orb(img, (384, 482), 120, rgba("#ffffff"), rgba("#76e2ff", 175))
    add_shards(img, rgba("#7ce8ff", 160), count=10, angle_shift=0.05)
    for radius in (170, 240):
        add_scan_arc(img, (384 - radius, 482 - radius, 384 + radius, 482 + radius), rgba("#d5fcff", 130), 10)


def motif_signal_relay(img: Image.Image) -> None:
    add_support_grid(img, rgba("#8fe9ff", 220))
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.polygon([(372, 242), (394, 242), (442, 684), (324, 684)], fill=rgba("#f3fcff", 214))
    layer = layer.filter(ImageFilter.GaussianBlur(3))
    img.alpha_composite(layer)


def motif_tactical_calm(img: Image.Image) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for y in (264, 374, 490, 608):
        draw.arc((154, y - 96, 614, y + 96), 180, 360, fill=rgba("#9eefff", 180), width=12)
    draw.polygon([(384, 198), (444, 324), (384, 450), (324, 324)], fill=rgba("#f0fdff", 180))
    layer = layer.filter(ImageFilter.GaussianBlur(6))
    img.alpha_composite(layer)


def motif_tactical_reorder(img: Image.Image) -> None:
    add_card_silhouettes(img, rgba("#9eeaff", 90))
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.arc((162, 382, 542, 772), 210, 322, fill=rgba("#ffe998", 220), width=24)
    draw.polygon([(514, 476), (610, 512), (548, 596)], fill=rgba("#ffe998", 220))
    layer = layer.filter(ImageFilter.GaussianBlur(2))
    img.alpha_composite(layer)


def motif_default_card(img: Image.Image) -> None:
    add_card_silhouettes(img, rgba("#a3ebff", 84))
    add_orb(img, (384, 438), 92, rgba("#f8ffff"), rgba("#7edfff", 176))
    add_scan_arc(img, (174, 230, 594, 650), rgba("#a9efff", 150), 12)


CARD_DEFS: dict[str, dict[str, object]] = {
    "default_card": {"colors": ("#12213a", "#21456d", "#4e8fbe"), "motif": motif_default_card, "frame": "#b7f4ff"},
    "arts_bolt": {"colors": ("#0c2038", "#1b4476", "#244f8e"), "motif": motif_arts_bolt, "frame": "#75efff"},
    "barrier_formula": {"colors": ("#09273b", "#1c5878", "#53a6cc"), "motif": motif_barrier_formula, "frame": "#abf2ff"},
    "blast_countdown": {"colors": ("#3b0f12", "#7d2918", "#c7511c"), "motif": motif_blast_countdown, "frame": "#ffc36e"},
    "burn_will": {"colors": ("#321010", "#7b2416", "#ff6d2c"), "motif": motif_burn_will, "frame": "#ffd38f"},
    "command_sync": {"colors": ("#101938", "#1e3f74", "#2e7eb9"), "motif": motif_command_sync, "frame": "#9aeeff"},
    "discipline_note": {"colors": ("#211314", "#603131", "#b15b43"), "motif": motif_discipline_note, "frame": "#ffe6c5"},
    "echo_conduit": {"colors": ("#16163a", "#284788", "#5cc4ff"), "motif": motif_echo_conduit, "frame": "#a4efff"},
    "emergency_shield": {"colors": ("#13243a", "#28586d", "#57b6d3"), "motif": motif_emergency_shield, "frame": "#c1f8ff"},
    "focus_pulse": {"colors": ("#111a40", "#283f84", "#3263c2"), "motif": motif_focus_pulse, "frame": "#97efff"},
    "guided_fire": {"colors": ("#112347", "#264c7c", "#4d7dc9"), "motif": motif_guided_fire, "frame": "#b2f4ff"},
    "hesitation": {"colors": ("#1b1831", "#35224a", "#574371"), "motif": motif_hesitation, "frame": "#c8dcff"},
    "mind_alignment": {"colors": ("#0f2340", "#214c7c", "#60c6e9"), "motif": motif_mind_alignment, "frame": "#a8f2ff"},
    "overclock_arts": {"colors": ("#291328", "#5a244e", "#ff7347"), "motif": motif_overclock_arts, "frame": "#ffe1a4"},
    "panic_static": {"colors": ("#120b1d", "#381441", "#7a2f8a"), "motif": motif_panic_static, "frame": "#efbbff"},
    "pulse_scan": {"colors": ("#0e2235", "#214067", "#2f7da7"), "motif": motif_pulse_scan, "frame": "#a7f0ff"},
    "rescue_corridor": {"colors": ("#1f1d34", "#4f4b75", "#b7a66e"), "motif": motif_rescue_corridor, "frame": "#fff1bc"},
    "resonance_burst": {"colors": ("#162043", "#234c81", "#4caed7"), "motif": motif_resonance_burst, "frame": "#b8f9ff"},
    "signal_relay": {"colors": ("#14224a", "#244577", "#3985bd"), "motif": motif_signal_relay, "frame": "#b4f6ff"},
    "tactical_calm": {"colors": ("#18313d", "#225969", "#6cc4b7"), "motif": motif_tactical_calm, "frame": "#cffdfd"},
    "tactical_reorder": {"colors": ("#16253d", "#284c76", "#f0bc5a"), "motif": motif_tactical_reorder, "frame": "#fff3c8"},
}


def render_card(card_id: str, drawer: Callable[[Image.Image], None], colors: tuple[str, str, str], frame_color: str) -> Image.Image:
    base = gradient_background((WIDTH, HEIGHT), rgba(colors[0]), rgba(colors[1]), rgba(colors[2], 118))
    drawer(base)
    add_frame(base, rgba(frame_color, 220))
    base = apply_vignette(base)
    return base


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for card_id, config in CARD_DEFS.items():
        image = render_card(
            card_id,
            config["motif"],  # type: ignore[arg-type]
            config["colors"],  # type: ignore[arg-type]
            config["frame"],  # type: ignore[arg-type]
        )
        image.save(OUTPUT_DIR / f"{card_id}.png")


if __name__ == "__main__":
    main()
