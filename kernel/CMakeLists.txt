# ----------------------------------------------------------------
# Kernel ELF Executable
# ----------------------------------------------------------------
add_executable(kernel
    main.c
)

target_compile_options(kernel PRIVATE
    -ffreestanding
    -fno-stack-protector
    -fno-pie
)

target_link_options(kernel PRIVATE
    -nostdlib
    -no-pie
    -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/arch/${ARCHITECTURE}/linker.ld
    -Wl,--build-id=none
    -Wl,-e,kernel_main
)

set_target_properties(kernel PROPERTIES OUTPUT_NAME kernel)
