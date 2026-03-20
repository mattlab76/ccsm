#!/bin/bash
# ccsm SessionEnd Hook
# Speichert Session-Daten in eine Temp-Datei für den ccsm Wrapper
# Input kommt via stdin als JSON von Claude Code
# Verwendet Session-ID im Dateinamen um parallele Sessions zu unterstützen

TMPDIR="/tmp/ccsm"
mkdir -p "$TMPDIR"

# JSON von stdin lesen und relevante Felder extrahieren
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

[ -z "$SESSION_ID" ] && exit 0

TMPFILE="${TMPDIR}/session-${SESSION_ID}.json"

# Ersten User-Prompt aus dem Transcript als Auto-Betreff extrahieren
BETREFF=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    BETREFF=$(python3 - "$TRANSCRIPT" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f:
        for line in f:
            try:
                obj = json.loads(line)
                if obj.get('type') == 'user' and 'message' in obj:
                    msg = obj['message']
                    if isinstance(msg, dict) and msg.get('role') == 'user':
                        for c in msg.get('content', []):
                            if isinstance(c, dict) and c.get('type') == 'text':
                                text = c['text'].strip().replace('\n', ' ').replace('\t', ' ')[:120]
                                print(text)
                                sys.exit(0)
            except json.JSONDecodeError:
                pass
except Exception:
    pass
PYEOF
    )
fi

# Tabs im Betreff durch Leerzeichen ersetzen (TSV-Sicherheit)
BETREFF=$(echo "$BETREFF" | tr '\t' ' ')

# In Temp-Datei schreiben (mit Session-ID im Namen)
jq -n \
    --arg sid "$SESSION_ID" \
    --arg cwd "$CWD" \
    --arg betreff "$BETREFF" \
    --arg transcript "$TRANSCRIPT" \
    '{"session_id": $sid, "cwd": $cwd, "betreff": $betreff, "transcript": $transcript}' > "$TMPFILE"

# Alte Temp-Dateien aufräumen (älter als 1 Tag)
find "$TMPDIR" -name "session-*.json" -mtime +1 -delete 2>/dev/null
