add_executable(kernel
    main.cpp
)

# The kernel is a freestanding ELF image: it has no C runtime, standard library
# or host-provided entry point.
target_compile_options(kernel PRIVATE
    -ffreestanding
    -fno-stack-protector
    -fno-pie
)

target_link_options(kernel PRIVATE
    -nostdlib
    -no-pie
    -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/arch/x86_64/linker.ld
    -Wl,--build-id=none
    -Wl,-e,kernel_main
)

set_target_properties(kernel PROPERTIES
    OUTPUT_NAME kernel
)
