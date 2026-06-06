#!/usr/bin/env bash
set -e

GITHUB_DIR="/home/yanglong/work/github"
ZEN_DIR="$HOME/.config/zen"
PROFILES_INI="$ZEN_DIR/profiles.ini"

PROFILE_NAME=$(grep -B5 "^Default=1" "$PROFILES_INI" | grep "^Path=" | tail -1 | sed 's/^Path=//')
IS_RELATIVE=$(grep -B5 "^Default=1" "$PROFILES_INI" | grep "^IsRelative=" | tail -1 | sed 's/^IsRelative=//')
if [ "$IS_RELATIVE" = "1" ]; then
  ZEN_PROFILE="$ZEN_DIR/$PROFILE_NAME"
else
  ZEN_PROFILE="$PROFILE_NAME"
fi
EXT_DIR="$ZEN_PROFILE/extensions"

mkdir -p "$EXT_DIR"

echo "=== Building Dark Reader (Firefox MV2) ==="
cd "$GITHUB_DIR/darkreader"
npm install --legacy-peer-deps
npm run build:firefox
BUILD="$GITHUB_DIR/darkreader/build/release/firefox"
if [ -f "$BUILD/manifest.json" ]; then
    echo "$BUILD" > "$EXT_DIR/addon@darkreader.org"
    echo "✓ Dark Reader proxy file created"
fi

echo ""
echo "=== Building AdGuard AdBlocker (Firefox AMO dev) ==="
cd "$GITHUB_DIR/AdguardBrowserExtension"
# pnpm v9 requires explicit approval for packages that run build scripts
python3 -c "
import json
with open('package.json', 'r+') as f:
    pkg = json.load(f)
    pkg.setdefault('pnpm', {})['onlyBuiltDependencies'] = ['@swc/core', 'core-js', 'esbuild']
    f.seek(0); json.dump(pkg, f, indent=2); f.truncate()
"
pnpm install
BUILD_ENV=dev pnpm exec tsx tools/bundle.ts firefox-amo
BUILD="$GITHUB_DIR/AdguardBrowserExtension/build/dev/firefox-amo"
if [ -f "$BUILD/manifest.json" ]; then
    echo "$BUILD" > "$EXT_DIR/adguardadblockerdev@adguard.com"
    echo "✓ AdGuard proxy file created"
fi

echo ""
echo "=== Building Adblock Plus (Firefox devenv) ==="
cd "$GITHUB_DIR/adblockpluschrome"
npm install
npx gulp devenv -t firefox
BUILD="$GITHUB_DIR/adblockpluschrome/devenv.firefox"
if [ -f "$BUILD/manifest.json" ]; then
    echo "$BUILD" > "$EXT_DIR/devbuild@adblockplus.org"
    echo "✓ Adblock Plus proxy file created"
fi

echo ""
echo "=== Done! Restart Zen browser to load extensions ==="
echo "Note: Google Mail Checker and Save to Pinterest must be installed"
echo "      manually from Zen's add-ons page (about:addons)"
