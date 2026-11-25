"""Read generated PNGs and record trim/surface metadata; never rewrite image pixels."""
from pathlib import Path
from statistics import median
import hashlib
import json
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT / "assets/Generated/Selarong"
FILES = {
    "telescope": "telescope-v1.png",
    "platform": "limestone-platform-v1.png",
    "lookout": "lookout-rock-v1.png",
    "shelter": "shelter-v1.png",
    "valley": "valley-depth-v1.png",
}
manifest = {}
for name, filename in FILES.items():
    path = DIRECTORY / filename
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    # Generation can leave very faint pixels well outside the visible silhouette.
    bounds = alpha.point(lambda value: 255 if value >= 64 else 0).getbbox()
    assert bounds, filename
    left, top, right, bottom = bounds
    item = {
        "path": "res://assets/Generated/Selarong/" + filename,
        "size": list(image.size),
        "region": [left, top, right-left, bottom-top],
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }
    if name in {"platform", "lookout"}:
        columns = range(left+(right-left)//4, left+3*(right-left)//4, 24)
        surfaces = [next(y for y in range(top, bottom) if alpha.getpixel((x,y))>=128) for x in columns]
        item["surface_from_top"] = median(surfaces)-top
    if name == "valley":
        assert alpha.getextrema() == (255,255), "Depth panorama must have no alpha holes"
    manifest[name] = item
output = json.dumps(manifest, indent=2)+"\n"
if "--stdout" in sys.argv:
    print(output, end="")
else:
    (ROOT / "data/selarong_art.json").write_text(output, encoding="utf-8")
    print(f"SELARONG_ASSETS: {len(manifest)} PNGs verified; alpha and platform surface metadata saved")
