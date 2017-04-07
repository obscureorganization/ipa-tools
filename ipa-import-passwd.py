#!/usr/bin/python
#
# Import /etc/passwd entries into IPA with a uid > 500. This preserves the
# existing uid/gid.

# Adapted from a script by Rob Crittenden <rcritten@redhat.com>
# https://www.redhat.com/archives/freeipa-users/2010-September/msg00105.html
# (Used and adapted with permission)
#
# Copyright (C) 2010 Red Hat, Inc.
# Copyright (C) 2017 The Obscure Organization.
#
# MIT Licensed, see the LICENSE file for details.

import pwd
import grp
import spwd
from ipapython.ipautil import run

# Versions of Red Hat Enterprise Linux before 7 had 500 as the first
# available uid above the range of system users, and 100 as the first
# avaialble gid.
MIN_UID = 500
MIN_GID = 100

# Use the UID offset to re-number the UIDs of imported users.
# This is optional but often desirable
# This may vary from installation to installation of IPA.
# Set this to 0 to avoid renumbering users and groups.
UID_OFFSET = 1634000000

# Use the GID offset to create group IDs that are in the same
# number range as the UIDs, but higher, and distinct. This gets
# added to UID_OFFSET.
# That way you will not stomp on any new UIDs that IPA assigns.
# Set this higher than the highest legacy uid you have.
GID_OFFSET = 1000

# On RHEL 7.x+ these system users have UIDs above 500 and may need
# to be blacklisted if you are importing a passwd file that contains
# UIDs that are in the range 500-1000.
USER_BLACKLIST = ["systemd-bus-proxy",
                  "polkitd",
                  "libstoragemgmt",
                  "pcp",
                  "chrony",
                  "sssd",
                  "saslauth",
                  "nfsnobody"]

# If there are some groups you prefer not to add that are above
# the MIN_GID range list those here.
GROUP_BLACKLIST = ["fberferd",
                   "blacklistedgroup"]

# do not put root into IPA groups - that should be saved for local configs
GROUP_MEMBER_BLACKLIST = ["root"]

# Should we skip unnamed users or import them?
SKIP_UNNAMED_USERS = False


# format is: login, password, uid, gid, gecos, homedir, shell
def extract_gecos(e):
    (firstname, lastname,
        building, office, home, other) = ["Someone", "Anonymous",
                                          "", "", "", ""]
    # Pull apart gecos and assume the first name is up to first space
    # and last name is everything else.
    gecos = e.pw_gecos.split(",")
    name = gecos[0].split(None)
    # print(name)

    if len(name) > 0:
        firstname = name[0]
    if len(name) > 1:
        lastname = " ".join(name[1:])
    if len(gecos) > 1:
        building = gecos[1]
    if len(gecos) > 2:
        office = gecos[2]
    if len(gecos) > 3:
        home = gecos[3]
    if len(gecos) > 4:
        other = gecos[4]
    return (firstname, lastname, building, office, home, other)


def valid_user(e):
    if e.pw_uid < MIN_UID:
        print('Skipped: user "%s" has uid %s < %s' %
             (e.pw_name, e.pw_uid, MIN_UID))
        return False
    if e.pw_name in USER_BLACKLIST:
        print('Skipped: user "%s" is in blacklist' % e.pw_name)
        return False
    if SKIP_UNNAMED_USERS and e.pw_gecos == '':
        print('Skipped: Need first and last name for user "%s"' % e.pw_name)
        return False
    return True


def add_users():
    entries = pwd.getpwall()
    for e in entries:
        if not valid_user(e):
            continue
            #raise SystemExit("Not valid_user, exiting")

        (firstname, lastname, building, office, home, other) = extract_gecos(e)

        uid = e.pw_uid + UID_OFFSET
        gid = e.pw_gid + UID_OFFSET
        shadow = spwd.getspnam(e.pw_name)
        crypt = "{crypt}%s" % shadow.sp_pwd

        args = ['/usr/bin/ipa', 'user-add',
                '--first', firstname,
                '--last', lastname,
                '--homedir', e.pw_dir,
                '--shell', e.pw_shell, '--setattr', 'userpassword=%s' % crypt,
                '--setattr', 'uidnumber=%d' % uid,
                '--setattr', 'gidnumber=%d' % gid,
                e.pw_name]

        print(" ".join(args))

        (stdout, stderr, rc) = run(args, raiseonerr=False)
        #(stdout, stderr, rc) = [0,0,0]
        if rc != 0:
            print 'Adding user "%s" failed: %s' % (e.pw_name, stderr)
        else:
            print 'Successfully added user "%s"' % e.pw_name


def valid_group(e):
    if e.gr_gid < MIN_GID:
        print('Skipped: group "%s" has gid %s < %s'
              % (e.gr_name, e.gr_gid, MIN_GID))
        return False
    if e.gr_name in GROUP_BLACKLIST:
        print('Skipped: group "%s" is in blacklist' % e.gr_name)
        return False
    if len(e.gr_mem) == 0:
        print('Skipped: group "%s" is empty' % e.gr_name)
        return False
    if len(e.gr_mem) == 1 and e.gr_name == e.gr_mem[0]:
        print('Skipped: group "%s" contains only itself' % e.gr_name)
        return False
    # Originally this script skipped unnamed users but we have
    # users that are intentionally unnamed, so lets not do that.
    #if e.pw_gecos == '':
    #    print('Skipped: Need first and last name for user "%s"' % e.pw_name)
    #    return False
    return True


def group_add_member(group, members):
    #member_list = ",".join(members)

    for member in members:
        args = ['/usr/bin/ipa',
                'group-add-member',
                group,
                '--users=%s' % member]

        print(" ".join(args))

        (stdout, stderr, rc) = run(args, raiseonerr=False)
        #(stdout, stderr, rc) = [0,0,0]
        if rc != 0:
            print('Adding group members "%s" failed: %s' %
                 (group, stderr))
        else:
            print('Successfully added group "%s" member "%s"' %
                 (group, member))


def add_groups():
    users = [user.pw_name for user in pwd.getpwall()]
    entries = grp.getgrall()
    for e in entries:
        if not valid_group(e):
            continue
            #raise SystemExit("Not valid_user, exiting")
        gid = e.gr_gid + UID_OFFSET + GID_OFFSET

        args = ['/usr/bin/ipa',
                'group-add', e.gr_name,
                '--gid', str(gid)]

        print(" ".join(args))

        (stdout, stderr, rc) = run(args, raiseonerr=False)
        #(stdout, stderr, rc) = [0,0,0]
        if rc != 0:
            print('Adding group "%s" failed: %s' % (e.gr_name, stderr))
        else:
            print('Successfully added group "%s"' % e.gr_name)

        members = [member for member in e.gr_mem
                   if member not in GROUP_MEMBER_BLACKLIST
                   and member in users]
        if (len(members) > 0):
            group_add_member(e.gr_name, members)


add_users()
add_groups()