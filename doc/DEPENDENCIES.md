# Dependencies

Set up a cross-compiler before installing the remaining tools needed to build
and run **milli**. The project currently targets **x86_64**. Each architecture
needs its own cross-compiler.

## Cross-compiler

The cross-compiler script builds a freestanding toolchain named `<architecture>-elf-g++`.
For example, **x86_64** creates `x86_64-elf-g++`, a future **aarch64** target would create `aarch64-elf-g++`.

### Linux

Install GCC's build prerequisites for your distribution:

```sh
# Debian / Ubuntu
sudo apt install build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo curl

# Fedora
sudo dnf install gcc gcc-c++ make bison flex gmp-devel libmpc-devel mpfr-devel texinfo curl

# Arch Linux
sudo pacman -S base-devel bison flex gmp libmpc mpfr texinfo curl
```

### MacOS

Install GCC's build prerequisites with [Homebrew](https://brew.sh/):

```sh
brew install bison flex gmp libmpc mpfr make texinfo curl
```

The script uses Homebrew's GNU Make (`gmake`) on macOS.

### Build the compiler

After having installed the prerequisites for your OS we can start building the compiler.

1. First navigate to the cloned repository.

2. Now make the helper script executable:
    ```sh
    chmod +x scripts/build-cross-compiler.sh
    ```

3. We can almost start building the compiler, first we need to set some configuration variables:
    ```sh
    ARCH=x86_64
    SOURCE_DIR="$HOME/src/cross-compiler"
    INSTALL_LOCATION="$HOME/opt/cross-compilers"
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

### Add the compiler(s) to `.bashrc`

Use the installation location selected above. For example, if it is `$HOME/opt/cross-compilers`:

```sh
echo 'export PATH="$HOME/opt/cross-compilers/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

After restarting your shell you should be able to verify that your compiler exists.

```sh
x86_64-elf-g++ --version
```

## Build tools, QEMU & More...

After installing the cross-compiler, install the host-side tools used by CMake and the emulator.

### Linux

Install all the tools for your distribution:

```sh
# Debian / Ubuntu
sudo apt install cmake make qemu-system-x86 ovmf

# Fedora
sudo dnf install cmake make qemu-system-x86 edk2-ovmf

# Arch linux
sudo pacman -S cmake make qemu-desktop edk2-ovmf
```

### MacOS

Install all the tools with [Homebrew](https://brew.sh/):

```sh
brew install cmake make qemu
```

Homebrew's QEMU package provides the UEFI firmware detected by the CMake
configuration.

## Limine ISO builds

Building with `-DBUILD_WITH_LIMINE=ON` additionally requires `xorriso`.
CMake downloads Limine automatically unless `LIMINE_DIR` points to an existing Limine binary checkout.

### Linux

Install `xorriso` for your distribution:

```sh
# Debian / Ubuntu
sudo apt install xorriso

# Fedora
sudo dnf install xorriso

# Arch Linux
sudo pacman -S xorriso
```

### MacOS

Install `xorriso` with [Homebrew](https://brew.sh/):

```sh
brew install xorriso
```

## Check the full installation

To make sure you have all the prerequisites installed run the following commands:

```sh
x86_64-elf-g++ --version
cmake --version
make --version
qemu-system-x86_64 --version
```

Continue with [BUILDING.md](./BUILDING.md) to configure the project.