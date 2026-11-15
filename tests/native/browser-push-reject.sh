#!/bin/sh
# Set or clear a synthetic remote rejection in the owned appliance.
set -eu
hook=/tmp/fixture.git/hooks/pre-receive
case "$1" in
    reject)
        test ! -e "$hook"
        printf '#!/bin/sh\nexit 1\n' > "$hook"
        chmod 0700 "$hook"
        ;;
    accept)
        rm -f "$hook"
        ;;
    *) exit 64 ;;
esac
