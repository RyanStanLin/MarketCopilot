#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

release_app="${PWD}/build/Build/Products/Release/MarketCopilot.app"
installation_root="${1:-/Applications}"
installed_app="${installation_root}/MarketCopilot.app"
if [[ ! -x "${release_app}/Contents/MacOS/MarketCopilot" ]]; then
    print -u2 'Build the Release app first: zsh Scripts/build.sh Release'
    exit 1
fi
mkdir -p "$installation_root"
staging_directory="$(mktemp -d "${installation_root}/.MarketCopilot-install.XXXXXX")"
trap 'rm -rf -- "$staging_directory"' EXIT
ditto "$release_app" "${staging_directory}/MarketCopilot.app"

if pgrep -x MarketCopilot >/dev/null; then
    pkill -TERM -x MarketCopilot
    for attempt in {1..50}; do
        if ! pgrep -x MarketCopilot >/dev/null; then break; fi
        sleep 0.1
    done
    if pgrep -x MarketCopilot >/dev/null; then
        print -u2 'MarketCopilot did not exit. The installed app has not been replaced.'
        exit 1
    fi
fi

if [[ -e "$installed_app" ]]; then
    backup_root="$HOME/Library/Application Support/MarketCopilot/Previous Versions"
    mkdir -p "$backup_root"
    backup_directory="$(mktemp -d "${backup_root}/install.XXXXXX")"
    mv "$installed_app" "${backup_directory}/MarketCopilot.app"
    print "Previous app: ${backup_directory}/MarketCopilot.app"
fi
mv "${staging_directory}/MarketCopilot.app" "$installed_app"
open -n "$installed_app" --args --settings
print "Installed and launched: ${installed_app}"
