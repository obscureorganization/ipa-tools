#!/bin/bash
# Set up firewall for IPA
#

# Use the Unofficial Bash Strict Mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

DEBUG=${DEBUG:-false}

# Thanks https://stackoverflow.com/a/17805088
$DEBUG && export PS4='${LINENO}: '
$DEBUG && set -x

# Thanks https://stackoverflow.com/a/16496491
zone=
interface=
permanent=
op=

function usage {
    echo "Usage: $0 <-a|-r> [-h] [-z zone] [-i interface] <source-cidr> ..."
}

function choose_only_one {
    local choice
    choice=${1:-}
    if [[ -n "$choice" ]]; then
        echo "$0: Specify only one of add and remove"
        exit 1
    fi
}

set +u
while getopts "arpz:i:" args; do
    case "$args" in
        a) 
            choose_only_one "$op"
            op=--add
            ;;
        r) 
            choose_only_one "$op"
            op=--remove
            ;;
        p)
            permanent="--permanent"
            ;;
        z) 
            zone=${OPTARG}
            ;;
        i)
            interface=${OPTARG}
            ;;
        h)
            usage
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$op" ]]; then
    echo "$0: You must specify one of either -a (add) or -r (remove)"
    exit 1
fi
if [[ -z "$zone" ]]; then
    echo "$0: you must specify a zone"
    exit 1
fi
set -u

allowed=$*
# From https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/linux_domain_identity_authentication_and_policy_guide/installing-ipa
ports='80/tcp
443/tcp
389/tcp
636/tcp
88/tcp
88/udp
464/tcp
464/udp
123/udp'

echo "$0: config"
echo "allowed $allowed ports $ports interface $interface permanent $permanent"
echo "$0: running firewall-cmd:"
for source in $allowed; do
    echo firewall-cmd --zone="$zone" ${op}-source="$source" $permanent
    firewall-cmd --zone="$zone" ${op}-source="$source" $permanent
done
for port in $ports; do
    echo firewall-cmd --zone="$zone" ${op}-port="$port" $permanent
    firewall-cmd --zone="$zone" ${op}-port="$port" $permanent
done
if [[ -n "$interface" ]]; then
    echo firewall-cmd --zone="$zone" ${op}-interface="$interface" $permanent
    firewall-cmd --zone="$zone" ${op}-interface="$interface" $permanent
fi


