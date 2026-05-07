# My yubikey setups

## opengpg

the default yubikey opengpg key is:

- PIN: `123456`
- Admin PIN: `12345678`
- Reset Code: Null

use `gpg --card-edit` manage yubikey opengpg settings

use `gpg --card-status` view yubikey opengpg status

## PIV

## Passkeys with ssh

Change FIDO default pin `ykman fido access change-pin`

Generate a new ssh key on yubikey:
`ssh-keygen -t ed25519-sk -N "" -C "{{your_name}}@{{yubikey_label}}" -f ~/.ssh/id_{{yubikey_label}}`

Touch and enter PIN when prompted

## sudo by yubikey

add yubikey to sudoers: `pamu2fcfg -u <username> > ~/u2f_keys` append: `pamu2fcfg -n >> ~/u2f_keys`

## luks2 by yubikey

`sudo systemd-cryptenroll --fido2-device=auto /dev/nvme1n1p1`

## `agenix-rekey` by yubikey

### make master key

`age-plugin-yubikey --generate`

### generate master.key

`age-plugin-yubikey -i --serial <serial> > yubikey.txt`
