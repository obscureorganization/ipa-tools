#!/usr/bin/python

# Import /etc/passwd entries into IPA with a uid > 500. This preserves the
# existing uid/gid.

import pwd
from ipapython.ipautil import run

entries = pwd.getpwall()

# format is: login, password, uid, gid, gecos, homedir, shell

for e in entries:
    if e.pw_uid < 500:
        continue

    if e.pw_name == 'nfsnobody':
        continue

    if e.pw_gecos == '':
        print 'Need first and last name for user "%s". Skipped' % e.pw_name
        continue

    # Pull apart gecos and assume the first name is up to first space
    # and last name is everything else.
    name = e.pw_gecos.split(None)

    args = ['/usr/bin/ipa', 'user-add',
            '--first', name[0],
            '--last', ' '.join(name[1:]),
            '--homedir', e.pw_dir,
            '--shell', e.pw_shell,
            '--setattr', 'uidnumber=%d' % e.pw_uid,
            '--setattr', 'gidnumber=%d' % e.pw_gid,
            e.pw_name]

    (stdout, stderr, rc) = run(args, raiseonerr=False)
    if rc != 0:
        print 'Adding user "%s" failed: %s' % (e.pw_name, stderr)
    else:
        print 'Successfully added "%s"' % e.pw_name
