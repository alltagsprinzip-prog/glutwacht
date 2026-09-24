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
if result.returncode or re.search(pattern,result.stdout,re.I):
 print('RELEASE GATE FAILED: '+str(log),file=sys.stderr);raise SystemExit(result.returncode or 1)
print('RELEASE GATE PASSED: '+str(log))
