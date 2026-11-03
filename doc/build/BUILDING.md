# Building

After following the instructions in [DEPENDENCIES.md](./DEPENDENCIES.md), you
can start building **milli**. The project uses CMake presets to configure the
build for the currently supported **x86_64** architecture.

## Debug build

The debug build is the recommended build type while developing **milli**.

1. First navigate to the cloned repository.

2. Configure the project:
    ```sh
    cmake --preset debug
    ```

3. Build the project:
    ```sh
    cmake --build --preset debug
    ```

The build files and output are placed in `build/debug`.

## Release build

To build an optimized release version, use the `release` preset instead.

1. Configure the project:
    ```sh
    cmake --preset release
    ```

2. Build the project:
    ```sh
    cmake --build --preset release
    ```

The build files and output are placed in `build/release`.

## Limine ISO build

By default **milli** is configured for the custom bootloader. To build a
bootable ISO using Limine, first make sure `xorriso` is installed as described
in [DEPENDENCIES.md](./DEPENDENCIES.md).

1. Configure a build with Limine enabled:
    ```sh
    cmake --preset debug -DBOOTLOADER=limine
    ```

2. Build the ISO image:
    ```sh
    cmake --build --preset debug --target iso
    ```

The ISO image is placed at `build/debug/image.iso`.

## Changing build configuration

Run the configuration command again after changing CMake options.
For example,to select the UEFI loader for the release build:

```sh
cmake --preset release -DBOOTLOADER=uefi
cmake --build --preset release
```

Continue with [RUNNING.md](./RUNNING.md) to run the built image in QEMU.
