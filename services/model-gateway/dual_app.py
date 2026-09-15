from __future__ import annotations

# Backward-compatible import target for older Docker/Render commands.
# All routes, including bounded dual-Kc shadow, are registered in app.py.
from app import app, run_pyfao56_dual_kc_shadow

__all__ = ["app", "run_pyfao56_dual_kc_shadow"]
