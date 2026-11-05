# Running

After building **milli** you can run it with QEMU. Make sure you have completed
the build instructions in [BUILDING.md](./BUILDING.md) first.

## Running

The default `run` target starts **milli** using the configuration selected during [BUILDING.md](./BUILDING.md).

```sh
cmake --build --preset debug --target run
```

Use the `release` preset to run the release build:

```sh
cmake --build --preset release --target run
```

## Debug with GDB

The `run-debug` target starts QEMU paused and opens a GDB server on port `1234`.

1. Start QEMU:
    ```sh
    cmake --build --preset debug --target -rundebug
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
