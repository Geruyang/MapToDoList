#!/usr/bin/env python3
"""Report system memory while running this task; no memory threshold or kill.

The user explicitly revoked the previous memory limit. This wrapper preserves
observational evidence and serial execution without retaining the old guard.
"""
import importlib.util
from pathlib import Path
import signal
import subprocess
import sys
import os
import time

spec = importlib.util.spec_from_file_location("waypoint_memory_measure", Path(__file__).resolve().parents[2] / "scripts" / "memory_guard.py")
measure = importlib.util.module_from_spec(spec)
spec.loader.exec_module(measure)
command = sys.argv[1:]
if command and command[0] == "--":
    command = command[1:]
if not command:
    raise SystemExit("Command required")
peak = measure.used_percent()
print("Memory sampling only; previous thresholds revoked by user.", flush=True)
print(f"Baseline sampled memory: {peak:.2f}%", flush=True)
child = subprocess.Popen(command, start_new_session=True)
try:
    while child.poll() is None:
        time.sleep(0.5)
        peak = max(peak, measure.used_percent())
except KeyboardInterrupt:
    if child.poll() is None:
        os.killpg(child.pid, signal.SIGINT)
    child.wait()
    raise
print(f"Highest sampled memory: {peak:.2f}%", flush=True)
print(f"Child exit: {child.returncode}", flush=True)
raise SystemExit(child.returncode)
