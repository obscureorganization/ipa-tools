# ipa-tools
Tools to help support [FreeIPA](https://www.freeipa.org) and [Red Hat Identity Management](https://access.redhat.com/products/identity-management) migration and operations.

# Prerequisites

You will need a functioning IPA server and a separate functioning IPA client in order to use these tools.

Installing the IPA tools and clients is beyond the scope of the tools listed here. Please see the [FreeIPA documentation](https://www.freeipa.org/page/Documentation) for more information on setting up the clients and the server. You might also want to consider using Ansible to set up your clients and servers, see [freeipa/ansible-freeipa](https://github.com/freeipa/ansible-freeipa) for the playbook that we have used.

# Using ipa-tools
The tools here are meant to ease in migration and maintenance of a traditional UNIX password system using `/etc/passwd`, `/etc/group`, and `/etc/shadow` to an IPA-based system. They contemplate using at least three different servers to make this happen:

1. An IPA server that is freshly installed without hand-created user accounts
2. An IPA client that is freshly installed without ordinary user accounts
3. An origin server that has current user accounts

## Migrate a UNIX-domain authentication system to IPA

To migrate from `passwd` and friends to IPA you need to run the `ipa-migrate` script. It uses these steps to migrate the information:

1. It archives the current authentication files, 
2. copies them to the destination host, which should already be configured as an IPA client, 
3. archives the current authentication files on the destination
4. temporarily appends the current files to those on the destination
5. imports all the users with the `ipa-import-users.py` script
6. restores the authentication files that were on the destination

The script has some constants in it you may want to adjust for blacklisting users that may vary for your environment.

Run this script on the host that has the authentication files you wish to migrate, for example::

```
./ipa-migrate -s -d root@ipaclient.example.com
```

# Acknowledgements
Many thanks go to Robert Crittenden <rcritten@redhat.com> (@rcritten) who both wrote the original script that `ipa-import-users.py` was based on and gave permission to extend and re-publish that work under the [MIT License](LICENSE).

Thanks go to Scott Hanselman for the [suggestion and instructions on switching the git default branch from master to main](https://www.hanselman.com/blog/EasilyRenameYourGitDefaultBranchFromMasterToMain.aspx). This repository transitioned to using `main` as its branch on 2020-06-14.

# Legal
Copyright (C) 2010 Red Hat, Inc.

Copyright (C) 2017 The Obscure Organization

This work is [MIT Licensed](LICENSE).
