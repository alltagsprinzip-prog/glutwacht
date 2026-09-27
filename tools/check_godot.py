#!/usr/bin/env python3
"""Make Godot's logged failures fatal, including failures that otherwise return zero."""
import re, subprocess, sys
from pathlib import Path
if len(sys.argv)<3:
 raise SystemExit('usage: check_godot.py LOG COMMAND [ARGS...]')
log=Path(sys.argv[1]);log.parent.mkdir(parents=True,exist_ok=True)
result=subprocess.run(sys.argv[2:],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
log.write_text(result.stdout);print(result.stdout,end='')
pattern=r'SCRIPT ERROR|Parse Error|Failed to load script|Shader compilation failed|(^|\n)ERROR:|Export failed'
expected=next((marker for name,marker in [('hud_rules.gd','HUD_RULES'),('account_save_suite.gd','ACCOUNT_SAVE_TESTS'),('hud_layout_suite.gd','HUD_LAYOUT_TESTS'),('hud_review.gd','HUD_REVIEW_TESTS'),('release_suite.gd','RELEASE_TESTS'),('input_suite.gd','INPUT_TESTS'),('visual_release.gd','VISUAL_RELEASE_TESTS'),('release_gate.gd','RELEASE_GATE_OK')] if any(name in a for a in sys.argv[2:])),None)
if result.returncode or re.search(pattern,result.stdout,re.I) or (expected and expected not in result.stdout):
 print('RELEASE GATE FAILED: '+str(log),file=sys.stderr);raise SystemExit(result.returncode or 1)
print('RELEASE GATE PASSED: '+str(log))
