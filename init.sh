#!/usr/bin/env bash

# Create SSH keys
ssh-keygen -f ssh/id_rsa -N ''
cat ssh/id_rsa.pub

# Generate the secret to encrypt/decrypt
dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev > decrypt_key.secret
git update-index --skip-worktree decrypt_key.secret

# Encrypt the SSH keys
tar cz ssh/id_rsa* | openssl enc -aes-256-cbc -iter 10000 -pass "pass:$(cat decrypt_key.secret)" -e > ssh/ssh.tar.gz.enc
