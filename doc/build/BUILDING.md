# Building

After following the instructions in [DEPENDENCIES.md](./DEPENDENCIES.md), you can start building **milli**.
The project uses CMake presets to configure the build for the currently supported architecture:
- **x86_64**

## Debug build

The debug build is the recommended build type while developing **milli**.
There are predefined debug targets for every architecture named `<architecture>-debug`.

1. First navigate to the cloned repository.

2. Configure the project (ex. **x86_64**):
    ```sh
    cmake --preset x86_64-debug
    ```

3. Build the project (e.g. **x86_64**):
    ```sh
    cmake --build --preset x86_64-debug
    ```

The build files and output are placed in `build/x86_64-debug`.

## Release build

To build an optimized release version, use the release presets instead.
Just like the debug targets there are release targets named `<architecture>-release`.

1. Configure the project (e.g. **x86_64**):
    ```sh
    cmake --preset x86_64-release
    ```

2. Build the project:
    ```sh
    cmake --build --preset x86_64-release
    ```

The build files and output are placed in `build/x86_64-release`.

## Changing build configuration

Run the configuration command again after changing CMake options.
For example, to select the UEFI loader for the release build on **x86_64**:

```sh
cmake --preset x86_64-release -DBOOTLOADER=uefi
cmake --build --preset x86_64-release
```

Continue with [RUNNING.md](./RUNNING.md) to run the built image in QEMU.
