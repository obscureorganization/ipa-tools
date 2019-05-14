#!/bin/bash
# Unlock IPA account through ldap. Defaults to admin account.
#
# Nornally you would use `ipa user-unlock` to achieve this,
# but if your admin account itself is locked you might need
# to fall back to unlocking that through LDAP.
#
# Thanks Simon Bonsor for the idea and the seed of the command:
# https://wiki.ceh.ac.uk/display/ER/FreeIPA+-+Unlock+admin+account


set -euo pipefail

account=${1:-admin}
manager=${2:-Directory Manager}

domain=$(domainname)
d=$(tr '.' ' '<<<"$domain")
dc=$(for x in $d; do echo -n ",dc=$x"; done)
host=$(dig +short "_kerberos._tcp.$domain" SRV |
    cut -d\  -f 4 |
    sed -e 's/\.$//')

echo "Unlocking account $account for domain $domain"
echo -n "$manager - " 
ldapmodify -h "$host" -D "cn=$manager" -ZZ -x -W <<EOF
dn: uid=$account,cn=users,cn=accounts$dc
changetype: modify
replace: nsaccountlock
nsaccountlock: false
EOF

