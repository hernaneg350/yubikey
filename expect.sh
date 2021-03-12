#!/usr/bin/env expect
#
# This Expect script was generated by autoexpect on Wed Aug  1 17:10:59 2018
# Expect and autoexpect were both written by Don Libes, NIST.
#
# Note that autoexpect does not guarantee a working script.  It
# necessarily has to guess about certain things.  Two reasons a script
# might fail are:
#
# 1) timing - A surprising number of programs (rn, ksh, zsh, telnet,
# etc.) and devices discard or ignore keystrokes that arrive "too
# quickly" after prompts.  If you find your new script hanging up at
# one spot, try adding a short sleep just before the previous send.
# Setting "force_conservative" to 1 (see below) makes Expect do this
# automatically - pausing briefly before sending each character.  This
# pacifies every program I know of.  The -c flag makes the script do
# this in the first place.  The -C flag allows you to define a
# character to toggle this mode off and on.

set force_conservative 1  ;# set to 1 to force conservative mode even if
			  ;# script was not run conservatively originally
if {$force_conservative} {
	set send_slow {1 .1}
	proc send {ignore arg} {
		sleep .1
		exp_send -s -- $arg
	}
}

#
# 2) differing output - Some programs produce different output each time
# they run.  The "date" command is an obvious example.  Another is
# ftp, if it produces throughput statistics at the end of a file
# transfer.  If this causes a problem, delete these patterns or replace
# them with wildcards.  An alternative is to use the -p flag (for
# "prompt") which makes Expect only look for the last line of output
# (i.e., the prompt).  The -P flag allows you to define a character to
# toggle this mode off and on.
#
# Read the man page for more info.
#
# -Don

set timeout -1
match_max 100000

# https://stackoverflow.com/a/17060172
set TOUCH_POLICY  [lindex $argv 0];
set ADMIN_PIN     [lindex $argv 1];
set GPG_HOMEDIR   [lindex $argv 2];
set USER_PIN      [lindex $argv 3];
set KEY_LENGTH    [lindex $argv 4];
set REALNAME      [lindex $argv 5];
set EMAIL         [lindex $argv 6];
set COMMENT       [lindex $argv 7];

# Turn off OTP.
send_user "Turning off YubiKey OTP:\n"
spawn ykman config mode "FIDO+CCID"
expect {
  "Mode is already FIDO+CCID, nothing to do..." {
    expect eof
  }

  ": " {
    send -- "y\r"
    expect eof
  }
}

# Set up User and Admin PINs, and then generate keys on card.

send_user "Now generating your GPG keys on the YubiKey itself.\n"
spawn gpg --homedir=$GPG_HOMEDIR --card-edit

expect -exact "gpg/card> "
send -- "admin\r"

# https://developers.yubico.com/PGP/Card_edit.html

expect -exact "gpg/card> "
send -- "passwd\r"

# Change User PIN
expect -exact "Your selection? "
send -- "1\r"

# Default User PIN
expect -exact "PIN: "
send -- "123456\r"

# New User PIN
expect -exact "PIN: "
send -- "$USER_PIN\r"

# Repeat new User PIN
expect -exact "PIN: "
send -- "$USER_PIN\r"

# Change Admin PIN
expect -exact "Your selection? "
send -- "3\r"

# Default Admin PIN
expect -exact "Admin PIN: "
send -- "12345678\r"

# New Admin PIN
expect -exact "Admin PIN: "
send -- "$ADMIN_PIN\r"

# Repeat new Admin PIN
expect -exact "Admin PIN: "
send -- "$ADMIN_PIN\r"

# Get out of passwd menu
expect -exact "Your selection? "
send -- "q\r"

# Set desired key attributes.

expect -exact "gpg/card> "
send -- "key-attr\r"

# Signature key.
expect -exact "Your selection? "
# RSA
send -- "1\r"

expect "What keysize do you want? (*) "
send -- "$KEY_LENGTH\r"

# Send new Admin PIN
expect -exact "Admin PIN: "
send -- "$ADMIN_PIN\r"

# Encryption key.
expect -exact "Your selection? "
# RSA
send -- "1\r"

expect "What keysize do you want? (*) "
send -- "$KEY_LENGTH\r"

# Send new Admin PIN
expect -exact "Admin PIN: "
send -- "$ADMIN_PIN\r"

# Authentication key.
expect -exact "Your selection? "
# RSA
send -- "1\r"

expect "What keysize do you want? (*) "
send -- "$KEY_LENGTH\r"

# Send new Admin PIN
expect -exact "Admin PIN: "
send -- "$ADMIN_PIN\r"

# Time to generate.

expect -exact "gpg/card> "
send -- "generate\r"

expect -exact "Make off-card backup of encryption key? (Y/n) "
send -- "n\r"

# Send new User PIN
expect -exact "PIN: "
send -- "$USER_PIN\r"

expect -exact "Key is valid for? (0) "
send -- "10y\r"

expect -exact "Is this correct? (y/N) "
send -- "y\r"

expect -exact "Real name: "
send -- "$REALNAME\r"

expect -exact "Email address: "
send -- "$EMAIL\r"

expect -exact "Comment: "
send -- "$COMMENT\r"

expect -exact "Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? "
send -- "O\r"

# Send new Admin PIN
expect -exact "Admin PIN: "
send -- "$ADMIN_PIN\r"

send_user "\nNow generating keys on card, lights will be flashing, this will take a few minutes, please wait...\n"

# Send new User PIN
expect {
    "PIN: " {
        send -- "$USER_PIN\r"
        expect -exact "gpg/card> "
        send -- "quit\r"
    }
    "gpg/card> " { send -- "quit\r" }
}

expect eof

# Turn on touch for SIGNATURES.

send_user "Now requiring you to touch your Yubikey to sign any message.\n"
spawn ykman openpgp keys set-touch sig $TOUCH_POLICY

expect -exact "Enter admin PIN: "
stty -echo
send -- "$ADMIN_PIN\r"

expect -exact "Set touch policy of signature key to $TOUCH_POLICY? \[y/N\]: "
send -- "y\r"
expect eof

# Turn on touch for AUTHENTICATION.

send_user "Now requiring you to touch your Yubikey to authenticate SSH.\n"
spawn ykman openpgp keys set-touch aut on

expect -exact "Enter admin PIN: "
stty -echo
send -- "$ADMIN_PIN\r"

expect -exact "Set touch policy of authentication key to on? \[y/N\]: "
send -- "y\r"
expect eof

# Turn on touch for ENCRYPTION.

send_user "Now requiring you to touch your Yubikey to encrypt any message.\n"
spawn ykman openpgp keys set-touch enc on

expect -exact "Enter admin PIN: "
stty -echo
send -- "$ADMIN_PIN\r"

expect -exact "Set touch policy of encryption key to on? \[y/N\]: "
send -- "y\r"
expect eof

# Touch for ATTESTATION works only for Yubico firmware >= 5.2.3.
# https://support.yubico.com/support/solutions/articles/15000027139-yubikey-5-2-3-enhancements-to-openpgp-3-4-support
