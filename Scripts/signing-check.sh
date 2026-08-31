#!/usr/bin/env bash
# Reports exactly what is still missing before a signed, notarized release,
# and prints the commands to finish. Reads nothing secret.
set -uo pipefail

PROFILE="${NOTARY_PROFILE:-notchii}"
READY=1

echo "Notchii signing check"
echo

# 1. Developer ID Application certificate
IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | grep "Developer ID Application" \
    | head -1 \
    | sed -E 's/.*"(.*)".*/\1/')"

if [[ -n "$IDENTITY" ]]; then
    TEAM_ID="$(printf '%s' "$IDENTITY" | sed -E 's/.*\(([A-Z0-9]+)\)$/\1/')"
    echo "  [ok]  certificate: $IDENTITY"
    echo "        team id:     $TEAM_ID"
else
    READY=0
    echo "  [--]  No Developer ID Application certificate."
    echo "        Xcode -> Settings -> Accounts -> your team -> Manage Certificates"
    echo "        -> + -> Developer ID Application"
    echo "        (not 'Apple Development' and not 'Apple Distribution')"
fi
echo

# 2. notarytool credentials
if xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    echo "  [ok]  notary profile: $PROFILE"
else
    READY=0
    echo "  [--]  No working notary profile named '$PROFILE'."
    echo "        Get an app-specific password at appleid.apple.com"
    echo "        (Sign-In and Security -> App-Specific Passwords), then run:"
    echo
    echo "        xcrun notarytool store-credentials \"$PROFILE\" \\"
    echo "            --apple-id \"<your apple id>\" \\"
    echo "            --team-id \"${TEAM_ID:-<team id>}\" \\"
    echo "            --password \"<app-specific password>\""
fi
echo

if [[ "$READY" == 1 ]]; then
    echo "Ready. Release with:"
    echo
    echo "  DEVELOPER_ID=\"$IDENTITY\" NOTARY_PROFILE=\"$PROFILE\" make release VERSION=0.1.0"
else
    echo "Finish the steps above, then run 'make signing-check' again."
    exit 1
fi
