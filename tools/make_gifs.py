#!/usr/bin/env python3
"""Record actual Godot gameplay and create the README GIFs (requires FFmpeg)."""
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "artifacts/recordings"
MEDIA = ROOT / "docs/media"


def run(command, timeout):
    result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=timeout)
    if result.returncode or re.search(r"SCRIPT ERROR|ERROR:", result.stdout):
        print(result.stdout)
        sys.exit("Capture/conversion failed")
    return result.stdout


if not shutil.which("ffmpeg"):
    sys.exit("FFmpeg is required to make GIFs; it is not needed to play.")
MEDIA.mkdir(parents=True, exist_ok=True)
for clip in ("atendimento", "reposicao"):
    directory = RAW / clip
    directory.mkdir(parents=True, exist_ok=True)
    for frame in directory.glob("[0-9][0-9][0-9][0-9].png"):
        frame.unlink()

print("Recording gameplay in Godot...", flush=True)
output = run(["sh", "tools/godot.sh", "--fixed-fps", "60", "--log-file",
              str(ROOT / "artifacts/record-demo.log"), "--script",
              "res://tools/record_demo.gd"], 240)
print(output)
if "DEMO VERIFIED" not in output:
    sys.exit("Recording did not verify sales and restocking")

filters = (
    "[0:v]scale=896:-1:flags=lanczos,split[a][b];"
    "[a]palettegen=max_colors=128:stats_mode=diff[p];"
    "[b][p]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle"
)
for clip in ("atendimento", "reposicao"):
    frames = list((RAW / clip).glob("*.png"))
    if len(frames) < 30:
        sys.exit(f"Too few frames for {clip}")
    destination = MEDIA / f"{clip}.gif"
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-framerate", "15",
         "-i", str(RAW / clip / "%04d.png"), "-filter_complex", filters,
         "-loop", "0", str(destination)], 120)
    print(f"{clip}: {len(frames)} frames, {destination.stat().st_size / 1048576:.2f} MiB")
print("GIFs ready in docs/media/")
