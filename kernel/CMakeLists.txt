# ----------------------------------------------------------------
# Checks
# ----------------------------------------------------------------
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/arch/${ARCHITECTURE}/CMakeLists.txt")
    message(FATAL_ERROR "Kernel does not support ARCHITECTURE=${ARCHITECTURE}.")
endif()

# ----------------------------------------------------------------
# Shared Kernel Executable
# ----------------------------------------------------------------
set(KERNEL_TARGET kernel_elf)
add_executable(${KERNEL_TARGET}
    main.c
)

target_compile_options(${KERNEL_TARGET} PRIVATE
    -ffreestanding
    -fno-stack-protector
    -fno-pie
)

target_link_options(${KERNEL_TARGET} PRIVATE
    -nostdlib
    -no-pie
    -Wl,--build-id=none
    -Wl,-e,kernel_main
)

# ----------------------------------------------------------------
# General target
# ----------------------------------------------------------------
add_custom_target(kernel ALL DEPENDS kernel_elf)
