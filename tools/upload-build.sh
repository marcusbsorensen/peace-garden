#!/bin/sh
# Uploads build N's archive to App Store Connect through the Apple account signed in to
# Xcode, as the Organizer's Distribute button does. No key file is read here.
#
#   tools/upload-build.sh 7
#
# It takes build/ExportOptions.plist (the one every build has been exported with) and
# changes only its destination, from export to upload.
set -eu
N=${1:?usage: tools/upload-build.sh BUILD_NUMBER}
HERE=$(cd "$(dirname "$0")/.." && pwd)
ARCHIVE="$HERE/build/PeaceGarden-1.0-$N.xcarchive"
[ -d "$ARCHIVE" ] || { echo "No archive at $ARCHIVE"; exit 1; }
OPTS="$(mktemp -d)/ExportOptions-upload.plist"
plutil -convert xml1 -o "$OPTS" "$HERE/build/ExportOptions.plist"
plutil -replace destination -string upload "$OPTS"
# Xcode's IPA step calls the first rsync on PATH, and Homebrew's rsync 3.5 rejects its
# arguments ("Copy failed"), so the system tools go first.
env PATH=/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin \
    xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$OPTS" \
    -exportPath "$HERE/build/upload-$N"
