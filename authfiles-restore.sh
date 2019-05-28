#!/bin/bash
# 
# Restore system auth files after import scripts have
# done their thing

set -euo pipefail

archive_latest=${1:-/root/authfiles.tar.gz}

cd /
tar xvfz "$archive_latest" etc/passwd etc/group etc/shadow
