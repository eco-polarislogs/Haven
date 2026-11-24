"""Mağaza için tasarım tanıtım görseli: altı yeni tasarımın Bugün ekranı.

Önce ekran görüntülerini üret:  flutter test tool/design_screenshots_test.dart
Sonra:                          python store/make_design_showcase.py

Çıktı: store/screenshots/{tr,en}/6-tasarimlar.png (1080x1920, alfasız 24 bit PNG;
Play'in telefon ekran görüntüsü kurallarına uygun). Yazı tipi uygulamanın
kendi Inter'i (assets/fonts).
"""

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SHOTS = os.path.join(HERE, "screenshots", "designs")
FONT_BOLD = os.path.join(ROOT, "assets", "fonts", "Inter-700.ttf")
FONT_MEDIUM = os.path.join(ROOT, "assets", "fonts", "Inter-500.ttf")

DEEP = (59, 74, 122)  # simgenin zemini (#3B4A7A)
LIGHT = (244, 184, 96)  # kapıdan sızan ışık (#F4B860)

DESIGNS = ["sis", "gece", "bahce", "neseli", "defter", "net"]
TEXT = {
    "tr": {
        "title": "Görünümünü sen seç",
        "subtitle": "Klasik dahil 7 tasarım · Profil → Tasarım",
        "names": ["Sis", "Gece Limanı", "Bahçe", "Neşeli", "Defter", "Net"],
    },
    "en": {
        "title": "Choose your look",
        "subtitle": "7 designs, including Classic · Profile → Design",
        "names": ["Mist", "Night Harbor", "Garden", "Cheerful", "Notebook", "Clear"],
    },
}

W, H = 1080, 1920
COLS, CELL_W, GAP_X = 3, 316, 26
CELL_H = round(CELL_W * 16 / 9)
RADIUS = 28


def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0] - 1, im.size[1] - 1), radius, fill=255)
    out = Image.new("RGBA", im.size)
    out.paste(im, (0, 0), mask)
    return out


def make(lang):
    t = TEXT[lang]
    canvas = Image.new("RGB", (W, H), DEEP)
    draw = ImageDraw.Draw(canvas)
    title_font = ImageFont.truetype(FONT_BOLD, 76)
    sub_font = ImageFont.truetype(FONT_MEDIUM, 36)
    label_font = ImageFont.truetype(FONT_BOLD, 34)

    y = 160
    draw.text((W / 2, y), t["title"], font=title_font, fill="white", anchor="mt")
    y += 108
    draw.text((W / 2, y), t["subtitle"], font=sub_font, fill=LIGHT, anchor="mt")

    grid_w = COLS * CELL_W + (COLS - 1) * GAP_X
    x0 = (W - grid_w) // 2
    top = 420
    row_h = CELL_H + 92
    for i, design in enumerate(DESIGNS):
        col, row = i % COLS, i // COLS
        x = x0 + col * (CELL_W + GAP_X)
        yy = top + row * row_h
        shot = Image.open(os.path.join(SHOTS, design, "1-bugun.png")).convert("RGB")
        shot = shot.resize((CELL_W, CELL_H), Image.LANCZOS)
        # yumuşak gölge
        shadow = Image.new("RGBA", (CELL_W + 40, CELL_H + 40), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle((20, 26, CELL_W + 20, CELL_H + 26), RADIUS, fill=(0, 0, 0, 90))
        shadow = shadow.filter(ImageFilter.GaussianBlur(12))
        canvas.paste(shadow, (x - 20, yy - 20), shadow)
        card = rounded(shot, RADIUS)
        canvas.paste(card, (x, yy), card)
        draw.text((x + CELL_W / 2, yy + CELL_H + 24), t["names"][i], font=label_font, fill="white", anchor="mt")

    out = os.path.join(HERE, "screenshots", lang, "6-tasarimlar.png")
    canvas.convert("RGB").save(out, optimize=True)
    print(out)


if __name__ == "__main__":
    for lang in TEXT:
        make(lang)
