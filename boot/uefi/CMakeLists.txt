# ----------------------------------------------------------------
# Checks
# ----------------------------------------------------------------
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/arch/${ARCHITECTURE}/CMakeLists.txt")
    message(FATAL_ERROR "UEFI does not support ARCHITECTURE=${ARCHITECTURE}.")
endif()

# ----------------------------------------------------------------
# Shared UEFI executable
# ----------------------------------------------------------------
set(UEFI_TARGET bootloader_uefi_elf)

add_executable(${UEFI_TARGET}
    $<TARGET_OBJECTS:bootloader_common>
    common/file_loader.c
    common/memory_map.c
)

configure_bootloader_target(${UEFI_TARGET})
target_link_options(${UEFI_TARGET} PRIVATE
    -nostdlib
    -no-pie
    -Wl,--build-id=none
)

# ----------------------------------------------------------------
# Architecture-specific executable setup
# ----------------------------------------------------------------
set(UEFI_APPLICATION_TARGET uefi_application)
set(UEFI_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

add_subdirectory(arch/${ARCHITECTURE})

# ----------------------------------------------------------------
# Find ESP image tools
# ----------------------------------------------------------------
find_program(MKFS_FAT NAMES mkfs.fat mkfs.vfat)
find_program(MMD NAMES mmd)
find_program(MCOPY NAMES mcopy)
find_program(PARTED NAMES parted)
find_program(DD_TOOL NAMES dd REQUIRED)

# ----------------------------------------------------------------
# Create the UEFI ESP image
# ----------------------------------------------------------------
if(MKFS_FAT AND MMD AND MCOPY AND PARTED)
    set(UEFI_ESP_IMAGE ${CMAKE_CURRENT_BINARY_DIR}/milli-uefi.img)
    set(UEFI_ESP_OFFSET_BYTES 1048576)
    set(UEFI_ESP_OFFSET_SECTORS 2048)

    add_custom_command(
        OUTPUT ${UEFI_ESP_IMAGE}
        COMMAND ${CMAKE_COMMAND} -E rm -f ${UEFI_ESP_IMAGE}
        COMMAND ${DD_TOOL} if=/dev/zero of=${UEFI_ESP_IMAGE} bs=1M count=32
        COMMAND ${PARTED} -s ${UEFI_ESP_IMAGE}
                mklabel gpt mkpart EFI FAT32 1MiB 100% set 1 esp on
        COMMAND ${MKFS_FAT} -F 32 --offset=${UEFI_ESP_OFFSET_SECTORS} ${UEFI_ESP_IMAGE}
        COMMAND ${MMD} -i ${UEFI_ESP_IMAGE}@@${UEFI_ESP_OFFSET_BYTES} ::/EFI ::/EFI/BOOT
        COMMAND ${MCOPY} -i ${UEFI_ESP_IMAGE}@@${UEFI_ESP_OFFSET_BYTES}
                ${UEFI_APPLICATION} ::/${UEFI_BOOT_PATH}
        DEPENDS ${UEFI_APPLICATION_TARGET}
        VERBATIM
    )
    add_custom_target(uefi_image DEPENDS ${UEFI_ESP_IMAGE})

    set(MILLI_UEFI_ESP_IMAGE ${UEFI_ESP_IMAGE} CACHE INTERNAL "Path to the generated UEFI ESP image")
else()
    message(STATUS "UEFI ESP image disabled: install dosfstools, mtools, and parted for the uefi_image target")
endif()

# TODO: Add back run targets
