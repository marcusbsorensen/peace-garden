#!/bin/zsh
# The launch moment, photographed: the two-second fiddlehead with the name and
# version on it, which no launch argument can hold still, so it is caught by
# timing — `simctl launch`, a pause, `simctl io screenshot` — at 1.2 s, where
# the nameplate is in and the moment not yet leaving.
#
#   zsh tools/masstest/app/launch.sh <udid> <out> <clock> "en/L fr/AX5 rtl/L ..."
#
# Each picture is written as a 900-pixel JPEG and the PNG deleted.
set -u
SIM=$1; OUT=$2; CLOCK=$3; CONFIGS=$4
mkdir -p "$OUT"
date > "$CLOCK"
xcrun simctl boot "$SIM" 2>/dev/null
for config in ${(z)CONFIGS}; do
  locale=${config%%/*}; size=${config#*/}
  extra=()
  language=$locale
  case $locale in
    pseudo) language=en; extra=(-NSDoubleLocalizedStrings YES) ;;
    rtl) language=en; extra=(-AppleTextDirection YES -NSForceRightToLeftWritingDirection YES) ;;
  esac
  case $size in
    L) category=UICTContentSizeCategoryL ;;
    XXXL) category=UICTContentSizeCategoryXXXL ;;
    AX3) category=UICTContentSizeCategoryAccessibilityXL ;;
    AX5) category=UICTContentSizeCategoryAccessibilityXXXL ;;
  esac
  xcrun simctl terminate "$SIM" app.peacegarden 2>/dev/null
  xcrun simctl launch "$SIM" app.peacegarden -loading.style.v1 fixed \
    -AppleLanguages "($language)" -UIPreferredContentSizeCategoryName "$category" \
    -stage.appearance.v1 dark "${extra[@]}" > /dev/null
  sleep 1.2
  xcrun simctl io "$SIM" screenshot "$OUT/launch-$locale-$size.png" > /dev/null 2>&1
  sips -s format jpeg -s formatOptions 70 -Z 900 "$OUT/launch-$locale-$size.png" --out "$OUT/launch-$locale-$size.jpg" > /dev/null 2>&1
  rm -f "$OUT/launch-$locale-$size.png"
  echo "$config $(date +%H:%M:%S)" >> "$CLOCK"
done
xcrun simctl terminate "$SIM" app.peacegarden 2>/dev/null
date >> "$CLOCK"
echo "rc=0" >> "$CLOCK"
echo DONE >> "$CLOCK"
