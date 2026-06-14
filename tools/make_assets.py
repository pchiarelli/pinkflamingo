# -*- coding: utf-8 -*-
import json, os
from PIL import Image

SRC = "/Users/pietro/Downloads/pink flamingo"
APP = "/Users/pietro/Projetos/pinkflamingo"
ICONSET = f"{APP}/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ASSETS = f"{APP}/assets/images"
os.makedirs(ASSETS, exist_ok=True)

def make_transparent(path):
    """Drop the near-white/grey studio background to alpha, keeping the art."""
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if min(r, g, b) >= 235 and (max(r, g, b) - min(r, g, b)) <= 12:
                px[x, y] = (r, g, b, 0)
    return im

def autocrop(im):
    bbox = im.getbbox()
    return im.crop(bbox) if bbox else im

# ---- Transparent assets for the splash ------------------------------------
flam = autocrop(make_transparent(f"{SRC}/img2.jpeg"))
flam.save(f"{ASSETS}/flamingo.png")
logo = autocrop(make_transparent(f"{SRC}/img1.jpeg"))
logo.save(f"{ASSETS}/logo.png")
print("flamingo.png", flam.size, "| logo.png", logo.size)

# ---- App icon master: flamingo centered on white, 1024x1024 ----------------
master = Image.new("RGBA", (1024, 1024), (255, 255, 255, 255))
fl = flam.copy()
target_h = int(1024 * 0.74)
ratio = target_h / fl.height
fl = fl.resize((int(fl.width * ratio), target_h), Image.LANCZOS)
master.paste(fl, ((1024 - fl.width) // 2, (1024 - fl.height) // 2), fl)
master_rgb = master.convert("RGB")  # iOS icons must not have alpha

# ---- Generate every size referenced by Contents.json -----------------------
with open(f"{ICONSET}/Contents.json") as f:
    contents = json.load(f)

done = {}
for entry in contents["images"]:
    fn = entry["filename"]
    base = float(entry["size"].split("x")[0])
    scale = int(entry["scale"].replace("x", ""))
    px = round(base * scale)
    if fn not in done:
        master_rgb.resize((px, px), Image.LANCZOS).save(f"{ICONSET}/{fn}")
        done[fn] = px
print(f"Wrote {len(done)} icon files, sizes {sorted(set(done.values()))}")
