#!/bin/bash
# AI Social Credit — FICO display formula.
#
# Single source of truth. Edit constants here to retune scoring.
#
# Internal model: total_score is a signed integer accumulated from
# per-session deltas. Stored in social-credit.local.md.
#
# Display: map internal total to a FICO-shaped score in [300, 850].
# Positives are logarithmic (diminishing returns); negatives are linear
# and steeper. Gaining is hard, slows down further the higher you go.
# Losing is fast and stays fast.

FICO_BASE=700
FICO_MIN=300
FICO_MAX=850
POSITIVE_LOG_SCALE=22   # FICO = base + ln(total + 1) * scale  (when total >= 0)
NEGATIVE_PER_POINT=10   # FICO = base + total * 10             (when total <  0)

# internal_to_fico <int_total> -> echoes FICO score
internal_to_fico() {
    local total="$1"
    local fico
    if [ "$total" -ge 0 ] 2>/dev/null; then
        fico=$(awk -v t="$total" -v s="$POSITIVE_LOG_SCALE" -v b="$FICO_BASE" \
            'BEGIN { printf "%d", b + log(t + 1) * s }')
    else
        fico=$(( FICO_BASE + total * NEGATIVE_PER_POINT ))
    fi
    [ -z "$fico" ] && fico=$FICO_BASE
    [ "$fico" -lt "$FICO_MIN" ] && fico=$FICO_MIN
    [ "$fico" -gt "$FICO_MAX" ] && fico=$FICO_MAX
    echo "$fico"
}

# fico_to_tier <fico> -> echoes tier label
fico_to_tier() {
    local fico="$1"
    if   [ "$fico" -ge 800 ]; then echo "Exceptional"
    elif [ "$fico" -ge 740 ]; then echo "Very Good"
    elif [ "$fico" -ge 670 ]; then echo "Good"
    elif [ "$fico" -ge 580 ]; then echo "Fair"
    else                            echo "Poor"
    fi
}
