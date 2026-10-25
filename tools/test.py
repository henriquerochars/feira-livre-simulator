#!/usr/bin/env python3
"""Bounded Godot validation. Fails on runtime errors even if Godot exits zero."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
ARTIFACTS = ROOT / "artifacts"
ARTIFACTS.mkdir(exist_ok=True)
launcher = ["sh", str(ROOT / "tools/godot.sh")]
stages = [
    ("import", ["--headless", "--editor", "--quit"], 90),
    ("tests", ["--headless", "--script", "res://tests/test_game.gd"], 90),
    ("smoke-menu", ["--headless", "--quit-after", "120"], 30),
    ("smoke-game", ["--headless", "--quit-after", "600", "--", "--smoke"], 40),
]
for name, args, timeout in stages:
    command = launcher + ["--log-file", str(ARTIFACTS / f"{name}-engine.log")] + args
    print(f"Running {name}...", flush=True)
    try:
        result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=timeout)
    except subprocess.TimeoutExpired:
        sys.exit(f"FAIL: {name} exceeded {timeout}s")
    (ARTIFACTS / f"{name}.log").write_text(result.stdout)
    print(result.stdout)
    if result.returncode or re.search(r"SCRIPT ERROR|ERROR:|FAIL:|WARNING:.*leaked", result.stdout):
        sys.exit(f"FAIL: {name}; see artifacts/{name}.log")
print("PASS: editor import, gameplay tests, menu smoke, and active game smoke")
