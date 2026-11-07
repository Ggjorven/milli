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

set(KERNEL_ELF_STAMP "${CMAKE_CURRENT_BINARY_DIR}/kernel_elf.stamp")
add_custom_command(TARGET ${KERNEL_TARGET} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E touch "${KERNEL_ELF_STAMP}"
    BYPRODUCTS "${KERNEL_ELF_STAMP}"
    VERBATIM
)
set(KERNEL_ELF_STAMP "${KERNEL_ELF_STAMP}" PARENT_SCOPE)

# ----------------------------------------------------------------
# General target
# ----------------------------------------------------------------
add_custom_target(kernel ALL DEPENDS kernel_elf)
