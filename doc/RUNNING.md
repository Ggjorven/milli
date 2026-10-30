# Running

After building **milli** you can run it with QEMU. Make sure you have completed
the build instructions in [BUILDING.md](./BUILDING.md) first.

## Run with BIOS

The default `run` target starts **milli** using the BIOS configuration.

```sh
cmake --build --preset debug --target run
```

Use the `release` preset to run the release build:

```sh
cmake --build --preset release --target run
```

## Run with UEFI

The `run-uefi` target starts **milli** with the OVMF UEFI firmware.

```sh
cmake --build --preset debug --target run-uefi
```

The CMake configuration tries to find OVMF automatically. If it cannot be
found on your system, set the `OVMF` CMake cache variable to the path of the
firmware file while configuring the build:

```sh
cmake --preset debug -DOVMF=/path/to/OVMF.fd
```

## Debug with GDB

The `debug` target starts QEMU paused and opens a GDB server on port `1234`.

1. Start QEMU:
    ```sh
    cmake --build --preset debug --target debug
    ```

2. In another terminal, attach GDB to the built kernel:
    ```sh
    gdb build/debug/kernel
    ```

3. Connect GDB to QEMU:
    ```gdb
    target remote :1234
    ```

Continue with [TESTING.md](./TESTING.md) to learn about testing **milli**.