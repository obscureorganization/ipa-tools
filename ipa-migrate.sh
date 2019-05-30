#!/bin/bash
#
# ipa-migrate.sh
#
# Transfer authentication files from origin server to destination server
# used for ipa credential import
#

# Use the Unofficial Bash Strict Mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

DEBUG=${DEBUG:-false}

# Thanks https://stackoverflow.com/a/246128
DIR=$(dirname "$(readlink -f "$0")")


# Thanks https://stackoverflow.com/a/16496491
function usage {
    echo "Usage: $0 [-h] [-s] user@server.example.com"
}

sudo=''
limit=''
verbose=''

set +u
while getopts ":hl:sv" args; do
    case "${args}" in
        h)
            usage
            ;;
        l)
            limit="-l $OPTARG"
            ;;
        s)
            sudo='sudo'
            ;;
        v)
            DEBUG='true'
            verbose='-v'
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

set -u

# Thanks https://stackoverflow.com/a/17805088
$DEBUG && export PS4='${LINENO}: '
$DEBUG && set -x

$DEBUG && echo "args: limit $limit / sudo $sudo / verbose $verbose"

dest=${1-}
if [[ -z "$dest" ]]; then
    echo "ERROR: You must specify a destination host (and optionally, a user)"
    usage
    exit 1
fi


filename="authfiles.tar.gz"
archive="$HOME/$filename"
backup="$DIR/authfiles-backup.sh"
import="$DIR/ipa-import-passwd.py"

if ! ssh "$dest" klist; then
    echo "WARNINGARROR: the user on the remote of $dest is not authorized with krb5."
    ssh -t "$dest" kinit admin
fi

$sudo "$DIR/authfiles-backup.sh"
$sudo "$DIR/authfiles-backup.sh"
remote_dir=$($sudo ssh "$dest" mktemp -d)
dest_dir="$dest":"$remote_dir"
dest_file="$dest_dir/$filename"
echo "Using $dest_dir for import"
$sudo scp "$archive" "$backup" "$import" "$dest_dir"
ssh "$dest" /bin/bash <<EOF
#!/bin/bash

set -euo pipefail

# Thanks http://redsymbol.net/articles/bash-exit-traps/
finish() {
    retcode=\$?
    cd /
    tar xvfz "/root/$filename"
    rm -rf "$remote_dir"
    ipa config-mod --enable-migration=FALSE
    return \$retcode
}
trap finish EXIT
trap finish INT
trap finish HUP

ipa config-mod --enable-migration=TRUE || true
ls -la "$remote_dir"
cd "$remote_dir"
tar xvf "$filename"
ls -lR "$remote_dir"
bash ./authfiles-backup.sh
tar xvf "$filename"
for auth in passwd group shadow; do
    cat "etc/\$auth" >> "/etc/\$auth"
done
set -x
python ./ipa-import-passwd.py $limit $verbose
EOF

