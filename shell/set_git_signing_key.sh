gpg --list-secret-keys --keyid-format LONG
# note ! prevents gpg from expanding and pickup up all subkeys
git config --global --unset gpg.format && git config --global user.signingkey ACD1234567890XXX!
