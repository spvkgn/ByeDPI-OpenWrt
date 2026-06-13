#!/bin/bash
# Assemble IPK and APK packages for a given set of OpenWrt architectures.
# Usage: build-byedpi.sh <version> <binary_path> <"ow_arch1 ow_arch2 ...">
#   version      - package version, e.g. 0.17.3
#   binary_path  - path to the compiled ciadpi binary
#   ow_arches    - space-separated list of OpenWrt arch strings

set -eo pipefail

PKG_VERSION="$1"
BINARY="$2"
OPENWRT_ARCHES="$3"

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
REPO_DIR="$SCRIPT_DIR/.."
OUT_DIR="$SCRIPT_DIR/out"
mkdir -p "$OUT_DIR"

INIT_FILE="$REPO_DIR/byedpi/files/byedpi.init"
CONFIG_FILE="$REPO_DIR/byedpi/files/byedpi.config"

for OW_ARCH in $OPENWRT_ARCHES; do
    echo "--- Building packages for $OW_ARCH ---"

    BASE_DIR="$(mktemp -d)"
    install -Dm755 "$BINARY"      "$BASE_DIR/usr/bin/ciadpi"
    install -Dm755 "$INIT_FILE"   "$BASE_DIR/etc/init.d/byedpi"
    install -Dm644 "$CONFIG_FILE" "$BASE_DIR/etc/config/byedpi"

    # --- IPK ---
    IPK_DIR="$(mktemp -d)"
    cp -a "$BASE_DIR/." "$IPK_DIR/"
    mkdir -p "$IPK_DIR/CONTROL"

    cat > "$IPK_DIR/CONTROL/control" <<EOF
Package: byedpi
Version: $PKG_VERSION
Architecture: $OW_ARCH
Depends: libc
Section: net
URL: https://github.com/hufrea/byedpi
Description: Local SOCKS proxy server to bypass DPI (Deep Packet Inspection)
EOF

    echo "/etc/config/byedpi" > "$IPK_DIR/CONTROL/conffiles"

    cat > "$IPK_DIR/CONTROL/postinst" <<'EOF'
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || /etc/init.d/byedpi enable
exit 0
EOF
    chmod 0755 "$IPK_DIR/CONTROL/postinst"

    cat > "$IPK_DIR/CONTROL/prerm" <<'EOF'
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || /etc/init.d/byedpi disable
exit 0
EOF
    chmod 0755 "$IPK_DIR/CONTROL/prerm"

    fakeroot ipkg-build -m "" "$IPK_DIR" "$OUT_DIR"
    rm -rf "$IPK_DIR"

    # --- APK ---
    APK_DIR="$(mktemp -d)"
    cp -a "$BASE_DIR/." "$APK_DIR/"
    mkdir -p "$APK_DIR/lib/apk/packages"

    find "$APK_DIR" -type f,l -printf '/%P\n' | sort \
        > "$APK_DIR/lib/apk/packages/byedpi.list"

    echo "/etc/config/byedpi" \
        > "$APK_DIR/lib/apk/packages/byedpi.conffiles"

    sha256sum "$APK_DIR/etc/config/byedpi" \
        | sed "s,$APK_DIR/,," \
        > "$APK_DIR/lib/apk/packages/byedpi.conffiles_static"

    APK_OUT="$OUT_DIR/byedpi_${PKG_VERSION}_${OW_ARCH}.apk"

    apk mkpkg \
        --info "name:byedpi" \
        --info "version:$PKG_VERSION" \
        --info "description:Local SOCKS proxy server to bypass DPI" \
        --info "arch:$OW_ARCH" \
        --info "origin:byedpi" \
        --info "url:https://github.com/hufrea/byedpi" \
        --info "depends:libc" \
        ${APK_SIGN_KEY:+--sign-key "$APK_SIGN_KEY"} \
        --files "$APK_DIR" \
        --output "$APK_OUT"

    rm -rf "$APK_DIR" "$BASE_DIR"
    echo "Done: $OW_ARCH"
done
