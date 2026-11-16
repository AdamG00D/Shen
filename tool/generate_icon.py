#!/usr/bin/env python3
"""
يولّد أيقونة التطبيق: حلقة شِن نحاسية (حبل بخط داخلي رفيع، قرص الشمس في النص، عُقدة) فوق خط، على بازلت.
نفس رسمة ShenMark في lib/widgets/shen_mark.dart.

    python3 tool/generate_icon.py

بيكتب:
  • android/app/src/main/res/drawable-*/ic_launcher_{background,foreground,monochrome}.png
  • android/app/src/main/res/mipmap-*/ic_launcher.png   (الأجهزة القديمة)
  • android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  • tool/icon_preview.png و docs/images/icon.png

لازم Pillow:  pip install pillow
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
S = 1024  # الرسم بدقة عالية وبعدين بنصغّر
K = S / 160  # إحداثيات الرسمة في مساحة 160×160 زي ShenPainter

BASALT = (28, 27, 25)  # #1C1B19
BASALT_EDGE = (20, 19, 15)  # #14130F
BRASS = (201, 150, 59)  # #C9963B


def background() -> Image.Image:
    """بازلت مع تدرّج خفيف جداً من النص للأطراف (عشان ميبقاش مسطّح)."""
    ramp = Image.radial_gradient("L").resize((S, S))
    return Image.composite(Image.new("RGB", (S, S), BASALT_EDGE), Image.new("RGB", (S, S), BASALT), ramp)


def ring_mask() -> Image.Image:
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)

    def circle(cx, cy, r, width=None, fill=255):
        box = [(cx - r) * K, (cy - r) * K, (cx + r) * K, (cy + r) * K]
        if width is None:
            d.ellipse(box, fill=fill)
        else:
            d.ellipse(box, outline=fill, width=round(width * K))

    circle(80, 68, 38, width=10)  # الحلقة (نص قطرها 33 ± 5)
    circle(80, 68, 22.75, width=1.5, fill=150)  # خط الحبل الرفيع (أخف)
    circle(80, 68, 6)  # قرص الشمس
    d.rounded_rectangle([71 * K, 96 * K, 89 * K, 112 * K], radius=3 * K, fill=255)  # العُقدة
    d.rounded_rectangle([36 * K, 110 * K, 124 * K, 121 * K], radius=5.5 * K, fill=255)  # الخط
    return m


def foreground() -> Image.Image:
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    img.paste(Image.new("RGBA", (S, S), BRASS + (255,)), mask=ring_mask())
    return img


def monochrome() -> Image.Image:
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), mask=ring_mask())
    return img


def legacy(bg: Image.Image, fg: Image.Image) -> Image.Image:
    """أيقونة جاهزة (مربع بحواف دايرة) للأجهزة القديمة والمعاينة."""
    out = bg.convert("RGBA")
    inner = fg.resize((int(S * 0.78), int(S * 0.78)), Image.LANCZOS)
    off = (S - inner.width) // 2
    out.alpha_composite(inner, (off, off))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, S, S), radius=int(S * 0.24), fill=255)
    out.putalpha(mask)
    return out


ADAPTIVE = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@drawable/ic_launcher_background"/>
  <foreground>
      <inset
          android:drawable="@drawable/ic_launcher_foreground"
          android:inset="16%" />
  </foreground>
  <monochrome>
      <inset
          android:drawable="@drawable/ic_launcher_monochrome"
          android:inset="16%" />
  </monochrome>
</adaptive-icon>
"""


def main() -> None:
    bg, fg, mono = background(), foreground(), monochrome()
    sizes = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for density, size in sizes.items():
        d = RES / f"drawable-{density}"
        d.mkdir(parents=True, exist_ok=True)
        bg.resize((size, size), Image.LANCZOS).save(d / "ic_launcher_background.png")
        fg.resize((size, size), Image.LANCZOS).save(d / "ic_launcher_foreground.png")
        mono.resize((size, size), Image.LANCZOS).save(d / "ic_launcher_monochrome.png")
    full = legacy(bg, fg)
    for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        d = RES / f"mipmap-{density}"
        d.mkdir(parents=True, exist_ok=True)
        full.resize((size, size), Image.LANCZOS).save(d / "ic_launcher.png")
    any_dpi = RES / "mipmap-anydpi-v26"
    any_dpi.mkdir(parents=True, exist_ok=True)
    (any_dpi / "ic_launcher.xml").write_text(ADAPTIVE)
    full.resize((512, 512), Image.LANCZOS).save(ROOT / "tool/icon_preview.png")
    full.save(ROOT / "docs/images/icon.png")
    print("✅ الأيقونة اتولّدت")


if __name__ == "__main__":
    main()
