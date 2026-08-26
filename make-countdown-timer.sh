#!/usr/bin/env bash
set -e
set -u
set -o pipefail

# Make a tiny MP4 countdown timer
# Requires: ffmpeg built with libx264 and libfreetype
#
# Examples:
#   ./make-countdown-timer.sh 5m                     # 5:00 -> countdown-5m00s.mp4
#   ./make-countdown-timer.sh 90 --beep              # 1:30 with a beep at zero
#   ./make-countdown-timer.sh 3:00 --label "Pair up" -o exercise1.mp4
#   ./make-countdown-timer.sh 10m --size 1280x720    # fixed frame instead of a fitted one

set -euo pipefail

DUR_IN=""
OUT=""
SIZE="fit"      # "fit" sizes the frame to the digits; or give WxH
FPS=5
CRF=26
BEEP=0
HOLD=2          # seconds to hold on 0:00 after the countdown ends
LABEL=""
FONT=""
FG="black"
BG="white"
DIGITS=300      # digit height in pixels, fit mode only
PAD=8           # margin around the digits, percent of digit height, fit mode only
FILL=94         # percent of a fixed frame the digits should fill
FONT_FRAC=0     # if set, skip measuring: numeral size = this percent of frame height

die() { printf 'make-countdown-timer.sh: %s\n' "$1" >&2; exit 1; }

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  <duration>            required: 5m | 300 | 5:00 | 1:30:00
  -o, --out FILE        output path (default countdown-5m00s.mp4)
      --size fit|WxH    frame size (default fit, sized to the digits)
      --digits N        digit height in px, fit mode (default 300)
      --pad N           margin as percent of digit height, fit mode (default 8)
      --fill N          percent of a fixed WxH frame the digits fill (default 94)
      --fps N           frame rate (default 5; the digits only change once a second)
      --crf N           x264 quality, higher = smaller (default 26)
      --beep            add a short 880 Hz beep at zero (otherwise no audio track)
      --hold N          seconds to sit on 0:00 at the end (default 2)
      --label TEXT      small caption above the timer
      --font PATH       .ttf/.ttc to use (default: first system sans-serif found)
      --fg COLOR        numeral color (default black)
      --bg COLOR        background color (default white)
      --font-frac N     skip measuring; numeral size = N percent of frame height
  -h, --help            this
EOF
}

# ---------- argument parsing ----------
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -o|--out) OUT="${2:?}"; shift 2 ;;
    --size) SIZE="${2:?}"; shift 2 ;;
    --digits) DIGITS="${2:?}"; shift 2 ;;
    --pad) PAD="${2:?}"; shift 2 ;;
    --fill) FILL="${2:?}"; shift 2 ;;
    --fps) FPS="${2:?}"; shift 2 ;;
    --crf) CRF="${2:?}"; shift 2 ;;
    --beep) BEEP=1; shift ;;
    --no-beep) BEEP=0; shift ;;
    --hold) HOLD="${2:?}"; shift 2 ;;
    --label) LABEL="${2:?}"; shift 2 ;;
    --font) FONT="${2:?}"; shift 2 ;;
    --fg) FG="${2:?}"; shift 2 ;;
    --bg) BG="${2:?}"; shift 2 ;;
    --font-frac) FONT_FRAC="${2:?}"; shift 2 ;;
    -*) die "unknown option $1 (try --help)" ;;
    *) DUR_IN="$1"; shift ;;
  esac
done

if [ -z "$DUR_IN" ]; then usage >&2; exit 2; fi

command -v ffmpeg >/dev/null 2>&1 || die "ffmpeg not found on PATH. On a Mac: brew install ffmpeg"
FF_FILTERS="$(ffmpeg -hide_banner -filters 2>/dev/null || true)"
case "$FF_FILTERS" in
  *" drawtext "*) ;;
  *) die "this ffmpeg has no drawtext filter (needs libfreetype). Try Homebrew's ffmpeg." ;;
esac

# ---------- duration ----------
parse_dur() {
  local s="$1" total=0
  case "$s" in
    *:*)
      local IFS=:; local -a p=($s); local n=${#p[@]} i
      for ((i=0;i<n;i++)); do
        [[ ${p[i]} =~ ^[0-9]+$ ]] || die "bad duration: $1"
        total=$(( total*60 + 10#${p[i]} ))
      done
      ;;
    *[mM]) total=$(( 10#${s%[mM]} * 60 )) ;;
    *[sS]) total=$(( 10#${s%[sS]} )) ;;
    *) [[ $s =~ ^[0-9]+$ ]] || die "bad duration: $1"; total=$(( 10#$s )) ;;
  esac
  printf '%d' "$total"
}

D=$(parse_dur "$DUR_IN")
[ "$D" -gt 0 ] || die "duration must be greater than zero"
[[ "$HOLD" =~ ^[0-9]+$ ]] || die "--hold must be a whole number of seconds"
TOTAL=$(( D + HOLD ))

if [ "$D" -ge 3600 ]; then
  WIDEST=$(printf '%d:%02d:%02d' $((D/3600)) $((D%3600/60)) $((D%60)))
else
  WIDEST=$(printf '%d:%02d' $((D/60)) $((D%60)))
fi

if [ -z "$OUT" ]; then
  if [ "$D" -ge 3600 ]; then
    OUT=$(printf 'countdown-%dh%02dm%02ds.mp4' $((D/3600)) $((D%3600/60)) $((D%60)))
  else
    OUT=$(printf 'countdown-%dm%02ds.mp4' $((D/60)) $((D%60)))
  fi
fi

# ---------- font ----------
if [ -z "$FONT" ]; then
  for f in \
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf" \
    "/System/Library/Fonts/Supplemental/Helvetica.ttc" \
    "/Library/Fonts/Arial Bold.ttf" \
    "/System/Library/Fonts/HelveticaNeue.ttc" \
    "/System/Library/Fonts/Helvetica.ttc" \
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" \
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" \
    "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf" \
    "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf" \
    "C:/Windows/Fonts/arialbd.ttf"
  do
    [ -f "$f" ] && { FONT="$f"; break; }
  done
fi
[ -n "$FONT" ] && [ -f "$FONT" ] || die "no usable font found; pass --font /path/to/Font.ttf"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------- measure the inked box of a string at a reference size ----------
# Draws the string on an oversized canvas at a known origin, then lets cropdetect
# report where the ink actually lands. Sets MEAS_W MEAS_H MEAS_DX MEAS_DY, the
# last two being the offset of the ink from the drawtext origin.
REF=400
measure() {
  local str="$1" canvas_w canvas_h ox oy line
  printf '%s' "$str" > "$WORK/measure.txt"
  canvas_w=$(( REF * 3 + REF * ${#str} ))
  canvas_h=$(( REF * 3 ))
  ox=$REF; oy=$REF
  printf '%s\n' "[0:v]drawtext=fontfile='$FONT':textfile='$WORK/measure.txt':expansion=none:fontcolor=white:fontsize=$REF:x=$ox:y=$oy,format=gray,cropdetect=limit=0.005:round=2:reset=1[v]" > "$WORK/measure_filter.txt"
  line=$(ffmpeg -hide_banner -loglevel info -f lavfi \
      -i "color=c=black:s=${canvas_w}x${canvas_h}:r=10:d=0.5" \
      -filter_complex_script "$WORK/measure_filter.txt" -map "[v]" -frames:v 3 \
      -f null - 2>&1 | grep -o 'crop=[0-9]*:[0-9]*:[0-9]*:[0-9]*' | tail -1 || true)
  [ -n "$line" ] || return 1
  line=${line#crop=}
  MEAS_W=${line%%:*}; line=${line#*:}
  MEAS_H=${line%%:*}; line=${line#*:}
  MEAS_DX=$(( ${line%%:*} - ox )); line=${line#*:}
  MEAS_DY=$(( line - oy ))
  # cropdetect rounds inward, so give the box a pixel of slack on every side
  MEAS_W=$(( MEAS_W + 2 )); MEAS_H=$(( MEAS_H + 2 ))
  MEAS_DX=$(( MEAS_DX - 1 )); MEAS_DY=$(( MEAS_DY - 1 ))
  [ "$MEAS_W" -gt 0 ] && [ "$MEAS_H" -gt 0 ]
}

even() { awk -v v="$1" 'BEGIN{n=int(v+0.5); if(n%2)n++; if(n<2)n=2; print n}'; }
iround() { awk -v v="$1" 'BEGIN{printf "%d", (v<0? v-0.5 : v+0.5)}'; }

FIT=0
case "$SIZE" in
  fit|FIT|auto) FIT=1 ;;
  *x*)
    WIDTH="${SIZE%%x*}"; HEIGHT="${SIZE##*x}"
    [[ "$WIDTH" =~ ^[0-9]+$ && "$HEIGHT" =~ ^[0-9]+$ ]] || die "bad --size (use fit or e.g. 960x540)"
    WIDTH=$(( WIDTH / 2 * 2 )); HEIGHT=$(( HEIGHT / 2 * 2 ))
    ;;
  *) die "bad --size (use fit or e.g. 960x540)" ;;
esac

MEASURED=1
if [ "$FONT_FRAC" -gt 0 ] 2>/dev/null; then
  MEASURED=0
elif ! measure "$WIDEST"; then
  MEASURED=0
fi

if [ "$MEASURED" -eq 0 ]; then
  # measurement unavailable: fall back to a fixed fraction of frame height
  [ "$FIT" -eq 1 ] && { WIDTH=960; HEIGHT=540; }
  [ "$FONT_FRAC" -gt 0 ] 2>/dev/null || FONT_FRAC=45
  FS=$(( HEIGHT * FONT_FRAC / 100 ))
  LABEL_FS=$(( HEIGHT * 9 / 100 )); [ "$LABEL_FS" -lt 12 ] && LABEL_FS=12
  if [ -n "$LABEL" ]; then TIMER_Y="(h-text_h)/2+h*0.06"; else TIMER_Y="(h-text_h)/2"; fi
  TIMER_X="(w-text_w)/2"; LABEL_X="(w-text_w)/2"; LABEL_Y="h*0.14"
else
  T_W=$MEAS_W; T_H=$MEAS_H; T_DX=$MEAS_DX; T_DY=$MEAS_DY
  if [ -n "$LABEL" ]; then
    measure "$LABEL" || die "could not measure the label text"
    L_W=$MEAS_W; L_H=$MEAS_H; L_DX=$MEAS_DX; L_DY=$MEAS_DY
  fi

  if [ "$FIT" -eq 1 ]; then
    SCALE=$(awk -v d="$DIGITS" -v h="$T_H" 'BEGIN{print d/h}')
    MARGIN=$(awk -v d="$DIGITS" -v p="$PAD" 'BEGIN{print d*p/100}')
    INK_W=$(awk -v w="$T_W" -v s="$SCALE" 'BEGIN{print w*s}')
    HEIGHT_F=$(awk -v d="$DIGITS" -v m="$MARGIN" 'BEGIN{print d+2*m}')
    WIDTH_F=$(awk -v w="$INK_W" -v m="$MARGIN" 'BEGIN{print w+2*m}')
    LABEL_FS=0; BAND=0
    if [ -n "$LABEL" ]; then
      LABEL_FS=$(iround "$(awk -v d="$DIGITS" -v r="$REF" -v lh="$L_H" 'BEGIN{print r*(d*0.20)/lh}')")
      LBL_INK_H=$(awk -v d="$DIGITS" 'BEGIN{print d*0.20}')
      BAND=$(awk -v lh="$LBL_INK_H" -v m="$MARGIN" 'BEGIN{print lh+m}')
      HEIGHT_F=$(awk -v h="$HEIGHT_F" -v b="$BAND" 'BEGIN{print h+b}')
      LBL_W=$(awk -v w="$L_W" -v r="$REF" -v fs="$LABEL_FS" -v m="$MARGIN" 'BEGIN{print w*fs/r+2*m}')
      WIDTH_F=$(awk -v a="$WIDTH_F" -v b="$LBL_W" 'BEGIN{print (a>b)?a:b}')
      LABEL_Y=$(iround "$(awk -v m="$MARGIN" -v r="$REF" -v fs="$LABEL_FS" -v dy="$L_DY" 'BEGIN{print m-dy*fs/r}')")
    fi
    WIDTH=$(even "$WIDTH_F"); HEIGHT=$(even "$HEIGHT_F")
    FS=$(iround "$(awk -v r="$REF" -v s="$SCALE" 'BEGIN{print r*s}')")
    TIMER_X=$(iround "$(awk -v w="$WIDTH" -v iw="$INK_W" -v dx="$T_DX" -v s="$SCALE" 'BEGIN{print (w-iw)/2-dx*s}')")
    TIMER_Y=$(iround "$(awk -v m="$MARGIN" -v b="$BAND" -v dy="$T_DY" -v s="$SCALE" 'BEGIN{print m+b-dy*s}')")
    if [ -n "$LABEL" ]; then
      LABEL_X=$(iround "$(awk -v w="$WIDTH" -v lw="$L_W" -v dx="$L_DX" -v r="$REF" -v fs="$LABEL_FS" \
        'BEGIN{k=fs/r; print (w-lw*k)/2-dx*k}')")
    fi
  else
    BOX_TOP=0; BOX_H=$HEIGHT; LABEL_FS=0
    if [ -n "$LABEL" ]; then
      LABEL_FS=$(( HEIGHT * 9 / 100 )); [ "$LABEL_FS" -lt 12 ] && LABEL_FS=12
      # shrink the caption if it would run past the edges
      LABEL_FS=$(iround "$(awk -v fs="$LABEL_FS" -v lw="$L_W" -v r="$REF" -v w="$WIDTH" \
        'BEGIN{if (lw*fs/r > w*0.94) fs=w*0.94*r/lw; print fs}')")
      BOX_TOP=$(awk -v h="$HEIGHT" 'BEGIN{print h*0.20}')
      BOX_H=$(awk -v h="$HEIGHT" -v t="$BOX_TOP" 'BEGIN{print h-t}')
      LABEL_X=$(iround "$(awk -v w="$WIDTH" -v lw="$L_W" -v dx="$L_DX" -v r="$REF" -v fs="$LABEL_FS" \
        'BEGIN{k=fs/r; print (w-lw*k)/2-dx*k}')")
      LABEL_Y=$(iround "$(awk -v h="$HEIGHT" -v r="$REF" -v fs="$LABEL_FS" -v dy="$L_DY" 'BEGIN{print h*0.055-dy*fs/r}')")
    fi
    SCALE=$(awk -v w="$WIDTH" -v bh="$BOX_H" -v f="$FILL" -v tw="$T_W" -v th="$T_H" \
      'BEGIN{a=w*f/100/tw; b=bh*f/100/th; print (a<b)?a:b}')
    FS=$(iround "$(awk -v r="$REF" -v s="$SCALE" 'BEGIN{print r*s}')")
    TIMER_X=$(iround "$(awk -v w="$WIDTH" -v tw="$T_W" -v s="$SCALE" -v dx="$T_DX" \
      'BEGIN{print (w-tw*s)/2-dx*s}')")
    TIMER_Y=$(iround "$(awk -v t="$BOX_TOP" -v bh="$BOX_H" -v th="$T_H" -v s="$SCALE" -v dy="$T_DY" \
      'BEGIN{print t+(bh-th*s)/2-dy*s}')")
  fi
fi

# ---------- filtergraph ----------
# Remaining seconds, clamped at zero so the hold frames read 0:00.
# ceil() makes the first second read the full duration rather than one less.
REM="max(0,ceil($D-t))"
if [ "$D" -ge 3600 ]; then
  TIMETEXT='%{eif\:trunc('"$REM"'/3600)\:d}\:%{eif\:mod(trunc('"$REM"'/60)\,60)\:d\:2}\:%{eif\:mod('"$REM"'\,60)\:d\:2}'
else
  TIMETEXT='%{eif\:trunc('"$REM"'/60)\:d}\:%{eif\:mod('"$REM"'\,60)\:d\:2}'
fi

FILTER="[0:v]drawtext=fontfile='$FONT':text='$TIMETEXT':fontcolor=$FG:fontsize=$FS:x=$TIMER_X:y=$TIMER_Y"
if [ -n "$LABEL" ]; then
  # the label goes through a file so quotes, colons and percent signs stay literal
  printf '%s' "$LABEL" > "$WORK/label.txt"
  FILTER="$FILTER,drawtext=fontfile='$FONT':textfile='$WORK/label.txt':expansion=none:fontcolor=$FG:fontsize=$LABEL_FS:x=$LABEL_X:y=$LABEL_Y"
fi
FILTER="$FILTER[v]"
printf '%s\n' "$FILTER" > "$WORK/filter.txt"

# ---------- encode ----------
VIDEO_IN=( -f lavfi -i "color=c=$BG:s=${WIDTH}x${HEIGHT}:r=$FPS:d=$TOTAL" )
GOP=$(( FPS * 60 )); [ "$GOP" -lt 30 ] && GOP=30

if [ "$BEEP" -eq 1 ]; then
  # half-sine envelope so the beep fades in and out instead of clicking
  BEEP_EXPR="0.35*sin(2*PI*880*t)*sin(PI*max(0\,min(1\,(t-$D)/0.6)))"
  ffmpeg -hide_banner -loglevel error -y \
    "${VIDEO_IN[@]}" \
    -f lavfi -i "aevalsrc='$BEEP_EXPR':d=$TOTAL:s=44100:c=mono" \
    -filter_complex_script "$WORK/filter.txt" \
    -map "[v]" -map 1:a -t "$TOTAL" \
    -c:v libx264 -preset veryslow -crf "$CRF" -pix_fmt yuv420p -g "$GOP" \
    -c:a aac -q:a 0.2 -ac 1 \
    -movflags +faststart "$OUT"
else
  ffmpeg -hide_banner -loglevel error -y \
    "${VIDEO_IN[@]}" \
    -filter_complex_script "$WORK/filter.txt" \
    -map "[v]" -an -t "$TOTAL" \
    -c:v libx264 -preset veryslow -crf "$CRF" -pix_fmt yuv420p -g "$GOP" \
    -movflags +faststart "$OUT"
fi

SIZE_H=$(ls -lh "$OUT" | awk '{print $5}')
printf 'Wrote %s (%s, %dx%d, %ds countdown + %ds hold, %s fps)\n' \
  "$OUT" "$SIZE_H" "$WIDTH" "$HEIGHT" "$D" "$HOLD" "$FPS"
