#!/usr/bin/env sh
set -eu

echo "Creating or refreshing local demo users."
echo

for user in mario.rossi admin.lab; do
  if tctl users ls --format=json 2>/dev/null | grep -q "\"name\":\"$user\""; then
    tctl users rm "$user" >/dev/null 2>&1 || true
  fi
done

echo "Enrollment link for mario.rossi (role: lab-user):"
tctl users add mario.rossi --roles=lab-user --logins=labuser
echo
echo "Enrollment link for admin.lab (role: lab-admin):"
tctl users add admin.lab --roles=lab-admin --logins=root,admin,labuser
echo
echo "Open one of the links via https://localhost:3080 or https://localhost:3180."
echo "When MFA is prompted, register a passkey or YubiKey from the browser."
