#!/bin/bash
# 
# Back up system auth files in preparation for using other
# scripts to import users.

set -euo pipefail

timestamp=$(date --iso-8601=seconds)

umask 0077
archive="$HOME/authfiles-$timestamp.tar.gz"
archive_latest="$HOME/authfiles.tar.gz"

rm -f "$archive_latest"

umask 0117
cd /
tar cvfz "$archive" etc/passwd etc/group etc/shadow
ln "$archive" "$archive_latest"
cat <<EOF
Auth files backed up to:
  $archive
  $archive_latest
All auth files stored so far:
EOF
ls -l "$HOME/authfiles"*
