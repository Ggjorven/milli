#!/usr/bin/env bash
set -euo pipefail

# NOTE: This file was created with the help of an LLM.

BINUTILS_VERSION="2.45"
GCC_VERSION="15.2.0"

log()
{
    printf '[cross-compiler] %s\n' "$*"
}

die()
{
    printf '[cross-compiler] error: %s\n' "$*" >&2
    exit 1
}

usage()
{
    cat <<'EOF'
Usage:
  build-cross-compiler.sh --arch <architecture> --install-location <directory> --source-dir <directory>

The same values may be supplied through ARCH, INSTALL_LOCATION, and SOURCE_DIR.
Arguments take precedence over environment variables.

Examples:
  ARCH=x86_64 INSTALL_LOCATION=/opt/cross-compilers SOURCE_DIR=$HOME/src/cross-compilers \
      ./scripts/build-cross-compiler.sh

  ./scripts/build-cross-compiler.sh --arch x86_64 \
      --install-location "$HOME/opt/cross-compilers" --source-dir "$HOME/src/cross-compilers"
EOF
}

ARCH="${ARCH:-}"
INSTALL_LOCATION="${INSTALL_LOCATION:-}"
SOURCE_DIR="${SOURCE_DIR:-}"
HOST_CXXFLAGS="${HOST_CXXFLAGS:--std=gnu++14}"

while (( $# > 0 )); do
    case "$1" in
        --arch)
            ARCH="${2:-}"
            shift 2
            ;;
        --install-location)
            INSTALL_LOCATION="${2:-}"
            shift 2
            ;;
        --source-dir)
            SOURCE_DIR="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
done

[[ -n "$ARCH" ]] || die "set ARCH or pass --arch"
[[ -n "$INSTALL_LOCATION" ]] || die "set INSTALL_LOCATION or pass --install-location"
[[ -n "$SOURCE_DIR" ]] || die "set SOURCE_DIR or pass --source-dir"

[[ ! -e "$INSTALL_LOCATION" || -d "$INSTALL_LOCATION" ]] || die "installation location is not a directory: $INSTALL_LOCATION"

INSTALL_OWNER_PATH="$INSTALL_LOCATION"
while [[ ! -e "$INSTALL_OWNER_PATH" ]]; do
    NEXT_PATH="$(dirname "$INSTALL_OWNER_PATH")"
    [[ "$NEXT_PATH" != "$INSTALL_OWNER_PATH" ]] || die "cannot find a parent directory for: $INSTALL_LOCATION"
    INSTALL_OWNER_PATH="$NEXT_PATH"
done

INSTALL_REQUIRES_SUDO=false
SUDO_AUTHENTICATED=false
if [[ ! -O "$INSTALL_OWNER_PATH" ]]; then
    command -v sudo >/dev/null 2>&1 || die "sudo is required to install into: $INSTALL_LOCATION"
    INSTALL_REQUIRES_SUDO=true
fi

install()
{
    if "$INSTALL_REQUIRES_SUDO"; then
        if ! "$SUDO_AUTHENTICATED"; then
            log "installation location is not owned by the current user; sudo is required for installation"
            sudo -v
            SUDO_AUTHENTICATED=true
        fi
        sudo "$@"
    else
        "$@"
    fi
}

case "$OSTYPE" in
    darwin*)
        MAKE="${MAKE:-gmake}"
        JOBS="${JOBS:-$(sysctl -n hw.ncpu)}"
        command -v brew >/dev/null 2>&1 || die "Homebrew is required on macOS"
        export PATH="$(brew --prefix bison)/bin:$(brew --prefix flex)/bin:$(brew --prefix texinfo)/bin:${PATH}"
        GCC_DEPENDENCY_OPTIONS=(
            "--with-gmp=$(brew --prefix gmp)"
            "--with-mpfr=$(brew --prefix mpfr)"
            "--with-mpc=$(brew --prefix libmpc)"
        )
        ;;
    *)
        MAKE="${MAKE:-make}"
        JOBS="${JOBS:-$(nproc)}"
        GCC_DEPENDENCY_OPTIONS=()
        ;;
esac

for command in curl tar "$MAKE"; do
    command -v "$command" >/dev/null 2>&1 || die "required command not found: $command"
done

TARGET="${ARCH}-elf"
BINUTILS_ARCHIVE="binutils-${BINUTILS_VERSION}.tar.xz"
GCC_ARCHIVE="gcc-${GCC_VERSION}.tar.xz"
BINUTILS_SOURCE="${SOURCE_DIR}/binutils-${BINUTILS_VERSION}"
GCC_SOURCE="${SOURCE_DIR}/gcc-${GCC_VERSION}"

mkdir -p "$SOURCE_DIR"

download()
{
    local url="$1"
    local destination="$2"

    if [[ ! -f "$destination" ]]; then
        log "downloading $(basename "$destination")"
        curl --fail --location --output "$destination" "$url"
    fi
}

extract()
{
    local archive="$1"
    local directory="$2"

    if [[ ! -d "$directory" ]]; then
        log "extracting $(basename "$archive")"
        tar -xf "$archive" -C "$SOURCE_DIR"
    fi
}

patch_libcody_configure()
{
    local configure_script="${GCC_SOURCE}/libcody/configure"
    local temporary_script="${configure_script}.tmp"

    if grep -q '#if __cplusplus != 201103' "$configure_script"; then
        log "patching libcody's obsolete C++11-only check"
        sed 's/#if __cplusplus != 201103/#if __cplusplus < 201103/' "$configure_script" > "$temporary_script"
        mv "$temporary_script" "$configure_script"
        chmod +x "$configure_script"
    fi
}

log "target: $TARGET"
log "installation location: $INSTALL_LOCATION"
log "source location: $SOURCE_DIR"
log "host C++ flags: $HOST_CXXFLAGS"

download "https://ftp.gnu.org/gnu/binutils/${BINUTILS_ARCHIVE}" "${SOURCE_DIR}/${BINUTILS_ARCHIVE}"
download "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${GCC_ARCHIVE}" "${SOURCE_DIR}/${GCC_ARCHIVE}"
extract "${SOURCE_DIR}/${BINUTILS_ARCHIVE}" "$BINUTILS_SOURCE"
extract "${SOURCE_DIR}/${GCC_ARCHIVE}" "$GCC_SOURCE"
patch_libcody_configure

BINUTILS_BUILD="${SOURCE_DIR}/build-binutils-${TARGET}"
GCC_BUILD="${SOURCE_DIR}/build-gcc-${TARGET}"

log "configuring Binutils"
mkdir -p "$BINUTILS_BUILD"
(
    cd "$BINUTILS_BUILD"
    "$BINUTILS_SOURCE/configure" --target="$TARGET" --prefix="$INSTALL_LOCATION" --with-sysroot \
        --disable-nls --disable-werror
)

log "building Binutils"
"$MAKE" -C "$BINUTILS_BUILD" -j"$JOBS"
log "installing Binutils"
install "$MAKE" -C "$BINUTILS_BUILD" install

export PATH="${INSTALL_LOCATION}/bin:${PATH}"

log "configuring GCC"
mkdir -p "$GCC_BUILD"
(
    cd "$GCC_BUILD"
    CXXFLAGS="$HOST_CXXFLAGS" "$GCC_SOURCE/configure" --target="$TARGET" --prefix="$INSTALL_LOCATION" --disable-nls \
        --enable-languages=c,c++ --without-headers "${GCC_DEPENDENCY_OPTIONS[@]}"
)

log "building GCC"
"$MAKE" -C "$GCC_BUILD" -j"$JOBS" all-gcc all-target-libgcc
log "installing GCC"
install "$MAKE" -C "$GCC_BUILD" install-gcc install-target-libgcc

log "complete: ${INSTALL_LOCATION}/bin/${TARGET}-g++"
