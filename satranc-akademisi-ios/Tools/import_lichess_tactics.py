#!/usr/bin/env python3
"""Select high-quality, beginner-friendly CC0 Lichess puzzles into a reviewable JSON set.

Usage:
  pip install python-chess zstandard
  python3 satranc-akademisi-ios/Tools/import_lichess_tactics.py \
      --input lichess_db_puzzle.csv.zst --output beginner_tactics.json

Source: https://database.lichess.org/#puzzles (CC0-1.0).
This intentionally does NOT auto-publish: selected puzzles must pass review
of motif relevance, ambiguity and didactic Turkish explanations first.

Important: Lichess CSV FEN is BEFORE the opponent's first move. The
opponent's UCI move must be applied to get the position to show the user.
"""
import argparse
import csv
import io
import json
import sys
from collections import Counter
from pathlib import Path

THEMES = {
    "fork": ("Çatal", "Tek taşla en az iki hedefe saldır."),
    "pin": ("Açmaz", "Öndeki taşın arkasındaki değerli hedefi gör."),
    "skewer": ("Şiş", "Öndeki değerli taş kaçınca arkasındaki hedefe ulaş."),
    "discoveredAttack": ("Keşif saldırısı", "Bir taşını çekerek arkasındaki saldırı hattını aç."),
    "doubleCheck": ("Çifte şah", "İki ayrı taşla aynı anda şah çek."),
    "hangingPiece": ("Korunmayan taş", "Rakibin savunmasız taşını fark et."),
    "backRankMate": ("Arka sıra matı", "Rakip şahın kaçış karelerinin kapalı olduğunu gör."),
    "mateIn1": ("Tek hamlede mat", "Rakip şahın hiçbir kaçış veya savunma hamlesi kalmasın.")
}

def read_csv(path):
    if path.suffix == ".zst":
        try:
            import zstandard
        except ImportError as error:
            raise SystemExit("Install zstandard: python3 -m pip install zstandard") from error
        with path.open("rb") as raw:
            with zstandard.ZstdDecompressor().stream_reader(raw) as decoded:
                with io.TextIOWrapper(decoded, encoding="utf-8", newline="") as text:
                    yield from csv.DictReader(text)
    else:
        with path.open("r", encoding="utf-8", newline="") as stream:
            yield from csv.DictReader(stream)

def prepare(row, chess, minimum, maximum, popularity):
    try:
        rating = int(row["Rating"])
        votes = int(row["Popularity"])
        plays = int(row.get("NbPlays", "0"))
        if not minimum <= rating <= maximum or votes < popularity or plays < 20:
            return None
        tags = set(row["Themes"].split())
        themes = [key for key in THEMES if key in tags]
        if not themes:
            return None
        moves = row["Moves"].split()
        if len(moves) < 2 or len(moves) > 8:
            return None
        board = chess.Board(row["FEN"])
        if not board.is_valid():
            return None
        # In the original dataset the first move is the opponent's setup move.
        first = chess.Move.from_uci(moves[0])
        if first not in board.legal_moves:
            return None
        board.push(first)
        # Current iOS training board is White-at-bottom with learner as White.
        if board.turn != chess.WHITE:
            return None
        playable_fen = board.fen()
        normalized, san_moves = [], []
        for move_string in moves[1:]:
            move = chess.Move.from_uci(move_string)
            if move not in board.legal_moves:
                return None
            san_moves.append(board.san(move))
            board.push(move)
            normalized.append(move_string)
        if "mateIn1" in themes and not board.is_checkmate():
            return None
        theme = themes[0]
        return {
            "id": row["PuzzleId"],
            "theme": theme,
            "turkishTheme": THEMES[theme][0],
            "teachingQuestion": THEMES[theme][1],
            "fen": playable_fen,
            "uciMoves": normalized,
            "standardSAN": san_moves,
            "rating": rating,
            "popularity": votes,
            "plays": plays,
            "allTags": sorted(tags),
            "source": row.get("GameUrl", ""),
            "license": "CC0-1.0",
            "requiresHumanReview": True,
        }
    except (KeyError, ValueError, IndexError):
        return None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--min-rating", type=int, default=600)
    parser.add_argument("--max-rating", type=int, default=1200)
    parser.add_argument("--min-popularity", type=int, default=80)
    parser.add_argument("--per-theme", type=int, default=30)
    args = parser.parse_args()

    try:
        import chess
    except ImportError as error:
        raise SystemExit("Install python-chess: python3 -m pip install chess") from error

    found, counts, seen = [], Counter(), set()
    for row in read_csv(args.input):
        item = prepare(row, chess, args.min_rating, args.max_rating, args.min_popularity)
        if not item or item["id"] in seen or counts[item["theme"]] >= args.per_theme:
            continue
        seen.add(item["id"])
        counts[item["theme"]] += 1
        found.append(item)
        if all(counts[k] >= args.per_theme for k in THEMES):
            break

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps({
        "source": "Lichess Open Database chess puzzles",
        "license": "CC0-1.0",
        "status": "draft_requires_review_not_live",
        "warning": "Only reviewed puzzles with Turkish explanations should be published.",
        "count": len(found),
        "themes": dict(counts),
        "puzzles": found
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Saved", len(found), "review-pending puzzles to", args.output)
    print("Per motif:", dict(counts))

if __name__ == "__main__":
    main()
