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
  ARCH=x86_64 INSTALL_LOCATION=/opt/cross SOURCE_DIR=$HOME/src/cross \
      ./scripts/build-cross-compiler.sh

  ./scripts/build-cross-compiler.sh --arch x86_64 \
      --install-location "$HOME/opt/cross" --source-dir "$HOME/src/cross"
EOF
}

ARCH="${ARCH:-}"
INSTALL_LOCATION="${INSTALL_LOCATION:-}"
SOURCE_DIR="${SOURCE_DIR:-}"

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

log "target: $TARGET"
log "installation location: $INSTALL_LOCATION"
log "source location: $SOURCE_DIR"

download "https://ftp.gnu.org/gnu/binutils/${BINUTILS_ARCHIVE}" "${SOURCE_DIR}/${BINUTILS_ARCHIVE}"
download "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${GCC_ARCHIVE}" "${SOURCE_DIR}/${GCC_ARCHIVE}"
extract "${SOURCE_DIR}/${BINUTILS_ARCHIVE}" "$BINUTILS_SOURCE"
extract "${SOURCE_DIR}/${GCC_ARCHIVE}" "$GCC_SOURCE"

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
"$MAKE" -C "$BINUTILS_BUILD" install

export PATH="${INSTALL_LOCATION}/bin:${PATH}"

log "configuring GCC"
mkdir -p "$GCC_BUILD"
(
    cd "$GCC_BUILD"
    "$GCC_SOURCE/configure" --target="$TARGET" --prefix="$INSTALL_LOCATION" --disable-nls \
        --enable-languages=c,c++ --without-headers "${GCC_DEPENDENCY_OPTIONS[@]}"
)

log "building GCC"
"$MAKE" -C "$GCC_BUILD" -j"$JOBS" all-gcc all-target-libgcc
log "installing GCC"
"$MAKE" -C "$GCC_BUILD" install-gcc install-target-libgcc

log "complete: ${INSTALL_LOCATION}/bin/${TARGET}-g++"