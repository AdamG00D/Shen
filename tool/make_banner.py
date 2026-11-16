#!/usr/bin/env python3
"""
يولّد بانر الـ README: docs/images/banner.ar.png و docs/images/banner.en.png

    python3 tool/generate_icon.py && python3 tool/make_banner.py

لازم Pillow مع libraqm (عشان الحروف العربي تتوصل صح).
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets/fonts"
W, H = 1600, 560
TOP, BOTTOM = (28, 27, 25), (20, 19, 15)  # بازلت

TEXT = {
    "ar": ("شِن", "مفاتيح PGP بتاعتك في الحفظ والصون", ["من غير إنترنت", "بروفايلات منفصلة", "OpenPGP قياسي", "مفتوح المصدر"]),
    "en": ("Shen", "Your PGP keys, kept safe", ["Offline", "Separate profiles", "Standard OpenPGP", "Open source"]),
}


def font(weight: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"IBMPlexSansArabic-{weight}.ttf"), size, layout_engine=ImageFont.Layout.RAQM)


def make(lang: str) -> None:
    title, tagline, chips = TEXT[lang]
    rtl = lang == "ar"
    ramp = Image.linear_gradient("L").rotate(90).resize((W, H))
    img = Image.composite(Image.new("RGB", (W, H), BOTTOM), Image.new("RGB", (W, H), TOP), ramp).convert("RGBA")
    # الحاجات الشفافة بتترسم في طبقة لوحدها وبعدين تتدمج (ImageDraw مبيخلطش الشفافية)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    # دواير خفيفة في الخلفية (حلقات شِن)
    for x, y, r in [(1350, 90, 220), (180, 520, 260), (900, -60, 160)]:
        ld.ellipse((x - r, y - r, x + r, y + r), outline=(201, 150, 59, 22), width=22)

    img.alpha_composite(layer)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    icon = Image.open(ROOT / "docs/images/icon.png").convert("RGBA").resize((300, 300), Image.LANCZOS)
    margin = 110
    icon_x = W - margin - icon.width if rtl else margin
    img.alpha_composite(icon, (icon_x, (H - icon.height) // 2))

    direction = "rtl" if rtl else "ltr"
    anchor = "ra" if rtl else "la"
    tx = icon_x - 60 if rtl else icon_x + icon.width + 60

    f = font("SemiBold", 30)
    x = tx
    oy = (H - 560) // 2  # النص في النص لو البانر أطول
    y = 385 + oy
    boxes = []
    for c in chips:
        w = ld.textlength(c, font=f, direction=direction) + 48
        x0, x1 = (x - w, x) if rtl else (x, x + w)
        ld.rounded_rectangle((x0, y, x1, y + 58), radius=29, outline=(243, 239, 231, 90), width=2)
        boxes.append((c, (x0 + x1) / 2))
        x = x0 - 14 if rtl else x1 + 14
    img.alpha_composite(layer)
    d = ImageDraw.Draw(img)
    for c, cx in boxes:
        d.text((cx, y + 29), c, font=f, fill=(237, 231, 218), anchor="mm", direction=direction)
    d.text((tx, 120 + oy), title, font=font("Bold", 120), fill=(243, 239, 231), anchor=anchor, direction=direction)
    d.text((tx, 285 + oy), tagline, font=font("Medium", 46), fill=(201, 150, 59), anchor=anchor, direction=direction)
    out = ROOT / f"docs/images/banner.{lang}.png"
    img.convert("RGB").save(out, optimize=True)
    print("✅", out.relative_to(ROOT))


if __name__ == "__main__":
    for lang in TEXT:
        make(lang)
