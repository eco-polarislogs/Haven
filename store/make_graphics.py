"""Google Play mağaza görsellerini üretir: 512x512 simge ve 1024x500 tanıtım görseli (tr, en).

Çizim uygulamanın gerçek simgesinden (android/.../ic_launcher_foreground.xml) ve
Android'in yazı tipi Roboto'dan (Flutter SDK içindeki kopya) yapılır; görüntüyü
Microsoft Edge'in başsız modu alır, PNG'yi Windows'un System.Drawing'i Play'in
istediği biçime çevirir (simge 32 bit, tanıtım görseli alfasız 24 bit).

Çalıştır:  python -I store/make_graphics.py
"""

import base64
import os
import shutil
import struct
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

DEEP = "#3B4A7A"  # ic_launcher_background
LIGHT = "#F4B860"  # kapıdan sızan ışık
SAND = "#F5F2EC"

# Simgenin kendisi (108x108 tuval, ic_launcher_foreground.xml ile aynı yollar).
SHIELD = f"""
  <path fill="#FFFFFF" d="M54,27 C61,31.5 68.5,33.5 76,33.5 C77,52 71,69 54,81 C37,69 31,52 32,33.5 C39.5,33.5 47,31.5 54,27 Z"/>
  <path fill="{DEEP}" d="M45.5,69 L45.5,54 A8.5,8.5 0 0 1 62.5,54 L62.5,69 Z"/>
  <path fill="{LIGHT}" d="M49,69 L49,54.5 A5,5 0 0 1 59,54.5 L59,69 Z"/>"""

TEXT = {
    "tr": {
        "tagline": "Zor günlerde güvenli bir liman.",
        "chips": ["Yargısız takip", "Nazik hatırlatmalar", "Güvenli topluluk"],
    },
    "en": {
        "tagline": "A safe harbor for hard days.",
        "chips": ["Judgment-free tracking", "Gentle reminders", "Safe community"],
    },
}


def fonts_css():
    flutter = shutil.which("flutter") or r"C:\src\flutter\bin\flutter"
    root = os.path.join(os.path.dirname(os.path.realpath(flutter)), "cache", "artifacts", "material_fonts")
    css = []
    for weight, name in [(400, "roboto-regular.ttf"), (500, "roboto-medium.ttf"), (700, "roboto-bold.ttf")]:
        with open(os.path.join(root, name), "rb") as f:
            data = base64.b64encode(f.read()).decode()
        css.append(
            "@font-face{font-family:Roboto;font-weight:%d;src:url(data:font/ttf;base64,%s) format('truetype');}"
            % (weight, data)
        )
    return "".join(css)


def icon_html():
    # Tam kare, köşesiz: Play köşe yuvarlamasını ve gölgeyi kendisi uygular.
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
html,body{{margin:0;width:512px;height:512px;overflow:hidden;background:{DEEP}}}
svg{{display:block}}</style></head><body>
<svg width="512" height="512" viewBox="16 16 76 76" xmlns="http://www.w3.org/2000/svg">
  <defs><radialGradient id="g" cx="50%" cy="42%" r="62%">
    <stop offset="0" stop-color="#4A5C93"/><stop offset="1" stop-color="{DEEP}"/></radialGradient></defs>
  <rect x="0" y="0" width="108" height="108" fill="url(#g)"/>{SHIELD}
</svg></body></html>"""


def feature_html(lang, fonts):
    t = TEXT[lang]
    chips = "".join(f"<span>{c}</span>" for c in t["chips"])
    return f"""<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>
{fonts}
html,body{{margin:0;width:1024px;height:500px;overflow:hidden}}
body{{font-family:Roboto,sans-serif;color:#fff;
  background:
    radial-gradient(circle at 84% 16%, rgba(132,160,220,.42), rgba(132,160,220,0) 38%),
    radial-gradient(circle at 8% 100%, rgba(91,125,177,.45), rgba(91,125,177,0) 42%),
    linear-gradient(135deg, #2A3660 0%, {DEEP} 52%, #4A5C93 100%);}}
.ring{{position:absolute;border:2px solid rgba(255,255,255,.06);border-radius:50%}}
.wrap{{position:absolute;inset:0;display:flex;align-items:center;gap:56px;padding:0 84px}}
.tile{{flex:none;width:208px;height:208px;border-radius:52px;background:{DEEP};
  box-shadow:0 24px 60px rgba(10,16,40,.45), inset 0 0 0 2px rgba(255,255,255,.10);overflow:hidden}}
.tile svg{{display:block}}
h1{{margin:0;font-size:104px;font-weight:700;letter-spacing:-1px;line-height:1}}
p{{margin:18px 0 0;font-size:38px;font-weight:500;color:{SAND};line-height:1.2}}
.chips{{margin-top:30px;display:flex;gap:12px;flex-wrap:wrap}}
.chips span{{font-size:21px;font-weight:500;color:#FFE7BF;padding:9px 18px;border-radius:999px;
  background:rgba(244,184,96,.16);box-shadow:inset 0 0 0 1.5px rgba(244,184,96,.38)}}
</style></head><body>
<div class="ring" style="width:620px;height:620px;right:-210px;top:-260px"></div>
<div class="ring" style="width:420px;height:420px;right:-110px;top:-160px"></div>
<div class="wrap">
  <div class="tile"><svg width="208" height="208" viewBox="16 16 76 76" xmlns="http://www.w3.org/2000/svg">
    <rect x="0" y="0" width="108" height="108" fill="{DEEP}"/>{SHIELD}</svg></div>
  <div><h1>Haven</h1><p>{t["tagline"]}</p><div class="chips">{chips}</div></div>
</div></body></html>"""


def shoot(html, width, height, out_png, work):
    page = os.path.join(work, os.path.basename(out_png) + ".html")
    with open(page, "w", encoding="utf-8") as f:
        f.write(html)
    raw = os.path.join(work, os.path.basename(out_png))
    subprocess.run(
        [
            EDGE, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
            "--force-device-scale-factor=1", f"--user-data-dir={os.path.join(work, 'edge')}",
            f"--window-size={width},{height}", f"--screenshot={raw}", "file:///" + page.replace("\\", "/"),
        ],
        check=True, capture_output=True, timeout=120,
    )
    return raw


def convert(src, dst, alpha):
    """PNG'yi Play'in istediği piksel biçimiyle yeniden kaydeder."""
    fmt = "Format32bppArgb" if alpha else "Format24bppRgb"
    ps = (
        "Add-Type -AssemblyName System.Drawing;"
        f"$s=[System.Drawing.Image]::FromFile('{src}');"
        f"$b=New-Object System.Drawing.Bitmap($s.Width,$s.Height,[System.Drawing.Imaging.PixelFormat]::{fmt});"
        "$g=[System.Drawing.Graphics]::FromImage($b);$g.DrawImage($s,0,0,$s.Width,$s.Height);$g.Dispose();"
        f"$b.Save('{dst}',[System.Drawing.Imaging.ImageFormat]::Png);$b.Dispose();$s.Dispose()"
    )
    subprocess.run(["powershell", "-NoProfile", "-NonInteractive", "-Command", ps], check=True, timeout=120)


def png_info(path):
    with open(path, "rb") as f:
        head = f.read(33)
    w, h, depth, color = struct.unpack(">IIBB", head[16:26])
    kind = {2: "RGB (alfasız)", 6: "RGBA"}.get(color, f"renk tipi {color}")
    return f"{w}x{h}, {kind}, {os.path.getsize(path) // 1024} KB"


def main():
    fonts = fonts_css()
    work = tempfile.mkdtemp(prefix="haven_store_")
    try:
        jobs = [(icon_html(), 512, 512, "icon-512.png", True)]
        for lang in TEXT:
            jobs.append((feature_html(lang, fonts), 1024, 500, f"feature-graphic-{lang}.png", False))
        for html, w, h, name, alpha in jobs:
            raw = shoot(html, w, h, os.path.join(HERE, name), work)
            out = os.path.join(HERE, name)
            convert(raw, out, alpha)
            print(f"{name}: {png_info(out)}")
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
