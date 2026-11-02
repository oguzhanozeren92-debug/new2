#!/usr/bin/env python3
"""Validate the Swift and browser chess academy curricula.

Usage:
  python3 -m pip install python-chess
  python3 satranc-akademisi-ios/Tools/validate_lessons.py

Uses python-chess solely as a developer validation tool. It is not bundled into
the mobile application. No chess lessons are published by this script.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SWIFT = ROOT / "satranc-akademisi-ios/Sources/LearningContent.swift"
WEB = ROOT / "satranc-akademisi-web/index.html"

try:
    import chess
except ImportError:
    print("Missing developer dependency. Run: python3 -m pip install python-chess", file=sys.stderr)
    sys.exit(2)

swift = SWIFT.read_text(encoding="utf-8")
web = WEB.read_text(encoding="utf-8")
starting = re.search(r'static let initial = "([^"]+)"', swift)
assert starting, "Swift starting FEN not found"
INITIAL = starting.group(1)

swift_pattern = re.compile(
    r'TrainingLesson\("([^"]+)",\s*"([^"]+)",\s*"[^"]*",\s*"[^"]*",\s*'
    r'(initial|"[^"]+"),\s*\[(.*?)\]\)',
    re.DOTALL,
)
swift_lessons = {}
for found in swift_pattern.finditer(swift):
    lesson_id, title, fen, steps = found.groups()
    assert lesson_id not in swift_lessons, f"Duplicate Swift lesson ID: {lesson_id}"
    uci = re.findall(r'\("([a-h][1-8][a-h][1-8][qrbn]?)",\s*"[^"]*"\)', steps)
    assert uci, f"Missing move(s): {lesson_id}"
    assert steps.count('("') == len(uci), f"Invalid tuple(s) in {lesson_id}"
    swift_lessons[lesson_id] = (title, INITIAL if fen == "initial" else fen.strip('"'), uci)

def browser_rows(name, next_name):
    pattern = re.compile(r"const " + name + r"=\[(.*?)\];\s*const " + next_name, re.DOTALL)
    found = pattern.search(web)
    assert found, f"Web {name} data not found"
    data = re.sub(r'(?<=,)start(?=,)', json.dumps(INITIAL), found.group(1))
    return json.loads("[" + data + "]")

web_lessons = {}
for row in browser_rows("course", "puzzles"):
    category, lesson_id, title, description, goal, fen, moves = row
    assert lesson_id not in web_lessons, f"Duplicate web ID: {lesson_id}"
    web_lessons[lesson_id] = (title, fen, moves)

puzzle_regex = re.compile(r"const puzzles=\[(.*?)\];\s*const glyph=", re.DOTALL)
pm = puzzle_regex.search(web)
assert pm, "Web puzzle data not found"
for row in json.loads("[" + pm.group(1) + "]"):
    lesson_id, title, fen, move, clue = row
    assert lesson_id not in web_lessons, f"Duplicate web puzzle: {lesson_id}"
    web_lessons[lesson_id] = (title, fen, [move])

assert set(swift_lessons) == set(web_lessons), (
    "iOS and web lessons differ: " + str(set(swift_lessons) ^ set(web_lessons))
)

for lesson_id, (title, fen, sequence) in swift_lessons.items():
    _, web_fen, web_moves = web_lessons[lesson_id]
    assert fen == web_fen, f"Different FEN for {lesson_id}"
    assert sequence == web_moves, f"Different moves for {lesson_id}"
    try:
        board = chess.Board(fen)
    except ValueError as exc:
        raise AssertionError(f"Invalid FEN in {lesson_id}: {exc}") from exc
    assert board.is_valid(), f"Unreachable/invalid chess position in {lesson_id}: {fen}"
    for uci in sequence:
        move = chess.Move.from_uci(uci)
        assert move in board.legal_moves, (
            f"Illegal {uci} in {lesson_id} ({title}) at {board.fen()}"
        )
        board.push(move)
    if lesson_id in {"mat", "puzzle-mat", "arka-sira", "puzzle-arka"}:
        assert board.is_checkmate(), f"Expected checkmate in {lesson_id}"

print("PASS: ", len(swift_lessons), "validated iOS/web lessons and puzzles.")
print("Validated full FEN positions, every UCI move and checkmate exercises.")
