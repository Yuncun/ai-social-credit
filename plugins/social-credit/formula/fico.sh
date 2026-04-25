#!/bin/bash
# AI Social Credit — FICO display formula.
#
# Single source of truth. Edit constants here to retune scoring.
#
# Internal model (unchanged): total_score is a signed integer accumulated
# from per-session deltas in [-3, +3]. Stored in social-credit.local.md.
#
# Display: map internal total to a FICO-shaped score in [300, 850].

FICO_BASE=700
FICO_PER_POSITIVE=3   # gaining is harder
FICO_PER_NEGATIVE=7   # losing is faster
FICO_MIN=300
FICO_MAX=850

# internal_to_fico <int_total> -> echoes FICO score
internal_to_fico() {
    local total="$1"
    local fico
    if [ "$total" -ge 0 ] 2>/dev/null; then
        fico=$(( FICO_BASE + total * FICO_PER_POSITIVE ))
    else
        fico=$(( FICO_BASE + total * FICO_PER_NEGATIVE ))
    fi
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
