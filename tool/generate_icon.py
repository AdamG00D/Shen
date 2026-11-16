#!/usr/bin/env python3
"""
يولّد أيقونة التطبيق: حلقة شِن (دايرة حبل فوق خط مستقيم) وجواها فتحة مفتاح.

    python3 tool/generate_icon.py

بيكتب:
  • android/app/src/main/res/drawable-*/ic_launcher_{background,foreground,monochrome}.png
  • android/app/src/main/res/mipmap-*/ic_launcher.png   (الأجهزة القديمة)
  • android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  • tool/icon_preview.png

لازم Pillow:  pip install pillow
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
S = 1024  # الرسم بدقة عالية وبعدين بنصغّر

TOP = (79, 70, 229)  # #4F46E5 (لون التطبيق الافتراضي)
BOTTOM = (124, 58, 237)  # #7C3AED

CX, CY = 512, 448  # مركز الحلقة
R_OUT, R_IN = 250, 172  # الحلقة
BAR = (512 - 300, 700, 512 + 300, 776)  # الخط اللي تحت


def background() -> Image.Image:
    """تدرّج قُطري."""
    ramp = Image.linear_gradient("L").resize((S, S)).rotate(45, expand=False, resample=Image.BICUBIC)
    ramp = ramp.resize((S * 2, S * 2)).crop((S // 2, S // 2, S // 2 + S, S // 2 + S))
    return Image.composite(Image.new("RGB", (S, S), BOTTOM), Image.new("RGB", (S, S), TOP), ramp)


def shen_mask() -> Image.Image:
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    d.ellipse((CX - R_OUT, CY - R_OUT, CX + R_OUT, CY + R_OUT), fill=255)
    d.ellipse((CX - R_IN, CY - R_IN, CX + R_IN, CY + R_IN), fill=0)
    d.rounded_rectangle(BAR, radius=38, fill=255)
    # الحبل بيتعقد: وصلة صغيرة بين الحلقة والخط
    d.rectangle((CX - 70, CY + R_OUT - 40, CX + 70, BAR[1] + 10), fill=255)
    return m


def keyhole_mask() -> Image.Image:
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    r = 58
    hy = CY - 30
    d.ellipse((CX - r, hy - r, CX + r, hy + r), fill=255)
    d.polygon([(CX - 34, hy + 20), (CX + 34, hy + 20), (CX + 54, hy + 132), (CX - 54, hy + 132)], fill=255)
    return m


def foreground() -> Image.Image:
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    white = Image.new("RGBA", (S, S), (255, 255, 255, 255))
    img.paste(white, mask=shen_mask())
    img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 235)), mask=keyhole_mask())
    return img


def monochrome() -> Image.Image:
    mask = ImageChops.lighter(shen_mask(), keyhole_mask())
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), mask=mask)
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
