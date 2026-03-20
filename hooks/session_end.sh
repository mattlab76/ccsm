#!/bin/bash
# ccsm SessionEnd Hook
# Saves session metadata to a temp file for the ccsm wrapper
# Input comes via stdin as JSON from Claude Code
# Uses session ID in filename to support parallel sessions

TMPDIR="/tmp/ccsm"
mkdir -p "$TMPDIR"

# Read JSON input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

[ -z "$SESSION_ID" ] && exit 0

TMPFILE="${TMPDIR}/session-${SESSION_ID}.json"

# Extract first user prompt and token usage from transcript
BETREFF=""
TOKENS="0/0"
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    local_output=$(python3 - "$TRANSCRIPT" <<'PYEOF'
import json, sys

transcript_path = sys.argv[1]
betreff = ""
input_tokens = 0
output_tokens = 0
cache_read = 0
cache_create = 0

try:
    with open(transcript_path) as f:
        for line in f:
            try:
                obj = json.loads(line)

                # Extract first user message as subject
                if not betreff and obj.get('type') == 'user' and 'message' in obj:
                    msg = obj['message']
                    if isinstance(msg, dict) and msg.get('role') == 'user':
                        for c in msg.get('content', []):
                            if isinstance(c, dict) and c.get('type') == 'text':
                                betreff = c['text'].strip().replace('\n', ' ').replace('\t', ' ')[:120]
                                break

                # Sum token usage from assistant messages
                msg = obj.get('message', {})
                if isinstance(msg, dict) and 'usage' in msg:
                    u = msg['usage']
                    input_tokens += u.get('input_tokens', 0)
                    output_tokens += u.get('output_tokens', 0)
                    cache_read += u.get('cache_read_input_tokens', 0)
                    cache_create += u.get('cache_creation_input_tokens', 0)

            except (json.JSONDecodeError, KeyError):
                pass
except Exception:
    pass

total_in = input_tokens + cache_read + cache_create
print(f"{betreff}\t{total_in}/{output_tokens}")
PYEOF
    )
    # Parse tab-separated output: betreff<TAB>tokens
    BETREFF=$(echo "$local_output" | cut -f1)
    TOKENS=$(echo "$local_output" | cut -f2)
fi

# Sanitize for TSV
BETREFF=$(echo "$BETREFF" | tr '\t' ' ')
[ -z "$TOKENS" ] && TOKENS="0/0"

# Write temp file
jq -n \
    --arg sid "$SESSION_ID" \
    --arg cwd "$CWD" \
    --arg betreff "$BETREFF" \
    --arg transcript "$TRANSCRIPT" \
    --arg tokens "$TOKENS" \
    '{"session_id": $sid, "cwd": $cwd, "betreff": $betreff, "transcript": $transcript, "tokens": $tokens}' > "$TMPFILE"

# Cleanup old temp files (older than 1 day)
find "$TMPDIR" -name "session-*.json" -mtime +1 -delete 2>/dev/null
