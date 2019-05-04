#!/bin/bash
# 
# Back up system auth files in preparation for using other
# scripts to import users.

set -euo pipefail

timestamp=$(date --iso-8601=seconds)

umask=0077
archive="/root/authfiles-$timestamp.tar.gz"
archive_latest="/root/authfiles.tar.gz"

rm -f "$archive_latest"

cd /
tar cvfz "$archive" etc/passwd etc/group etc/shadow
ln "$archive" "$archive_latest"
echo "Auth files backed up:"
ls -l /root/authfiles*
