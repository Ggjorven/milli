# Dependencies

Install the host build tools and set up a cross-compiler to build and run
**milli**. The project currently targets:
- **x86_64**.

Each architecture needs its own cross-compiler.

## Build tools

Install these once for your host operating system. They provide CMake, GNU Make
and the prerequisites for building the cross-compiler. All are used regardless of the target architecture.

### Linux

```sh
# Debian / Ubuntu
sudo apt install cmake make build-essential bison flex libgmp3-dev libisl-dev libmpc-dev libmpfr-dev texinfo curl

# Fedora
sudo dnf install cmake make gcc gcc-c++ libstdc++-devel bison flex gmp-devel isl-devel libmpc-devel mpfr-devel texinfo curl

# Arch Linux
sudo pacman -S cmake make base-devel bison flex gmp isl libmpc mpfr texinfo curl
```

### MacOS

```sh
brew install cmake make bison flex gmp isl libmpc mpfr texinfo curl
```

The cross-compiler script uses Homebrew's GNU Make (`gmake`) on MacOS.

## Cross-compiler

The cross-compiler script builds a freestanding toolchain named `<architecture>-elf-g++`.
For example, **x86_64** creates `x86_64-elf-g++`, a future **aarch64** target would create `aarch64-elf-g++`.

1. First navigate to the cloned repository.

2. Now make the helper script executable:
    ```sh
    chmod +x scripts/build-cross-compiler.sh
    ```

3. We can almost start building the compiler, first we need to set some configuration variables:
    ```sh
    export ARCH=x86_64
    export SOURCE_DIR="$HOME/src/cross-compiler"
    export INSTALL_LOCATION="$HOME/opt/cross-compilers"
    ```
    Replace `ARCH` with your desired outcome architecture (ex. **x86_64**).
    Set `SOURCE_DIR` to the location where all source can be cloned and built.
    Finally set the `INSTALL_LOCATION` to the location where the binary will end up.

4. Now run the script:
    ```sh
    ./scripts/build-cross-compiler.sh
    ```

The script logs each download, configuration, build, and installation step.
Set `JOBS` to choose a different number of parallel build jobs, or `MAKE` to use a specific GNU Make executable.

### Add the compiler(s) to your shell

Use the installation location selected above.
For example, if it is `$HOME/opt/cross-compilers`:

```sh
echo 'export PATH="$HOME/opt/cross-compilers/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

After restarting your shell you should be able to verify that your compiler exists.

```sh
x86_64-elf-g++ --version
```

Or whatever cross-compiler you built.

## QEMU, UEFI tools & firmware

After installing the cross-compiler, install the emulator and UEFI firmware
for the target architecture you want to run. Add a new target as another
subsection here when support for it is added.

### Linux

Install all the tools need for your wanted architecture.

#### x86_64 target

```sh
# Debian / Ubuntu
sudo apt install qemu-system-x86 ovmf dosfstools mtools parted

# Fedora
sudo dnf install qemu-system-x86 edk2-ovmf dosfstools mtools parted

# Arch Linux
sudo pacman -S qemu-desktop edk2-ovmf dosfstools mtools parted
```

### MacOS

Install all the tools need for your wanted architecture with [Homebrew](https://brew.sh/).

> [!IMPORTANT]
> The UEFI image target cannot be built on MacOS at this moment because `parted` cannot be installed, see: [#621579](https://superuser.com/questions/621579/install-gparted-on-a-mac-with-homebrew-or-macports).

#### x86_64 target

```sh
brew install qemu dosfstools mtools
```

Homebrew's QEMU package provides the UEFI firmware detected by the CMake configuration.

## Check the full installation

To make sure you have all the prerequisites installed run the following commands:

```sh
x86_64-elf-g++ --version
cmake --version
make --version
qemu-system-x86_64 --version
```

Continue with [BUILDING.md](./BUILDING.md) to configure the project.
