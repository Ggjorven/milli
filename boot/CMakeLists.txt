# ----------------------------------------------------------------
# Common
# ----------------------------------------------------------------
add_library(bootloader_common OBJECT
    common/config.c
    common/elf_loader.c
    common/handoff.c
)

# ----------------------------------------------------------------
# Helper function
# ----------------------------------------------------------------
function(configure_bootloader_target target)
    target_compile_features(${target} PRIVATE c_std_23)
    target_include_directories(${target} PRIVATE ${PROJECT_SOURCE_DIR})
    target_compile_options(${target} PRIVATE
        $<$<COMPILE_LANGUAGE:C>:-ffreestanding>
        $<$<COMPILE_LANGUAGE:C>:-fno-stack-protector>
        $<$<COMPILE_LANGUAGE:C>:-fno-pie>
    )
endfunction()

configure_bootloader_target(bootloader_common)

# ----------------------------------------------------------------
# Common tools
# ----------------------------------------------------------------
find_program(QEMU qemu-system-${ARCHITECTURE} DOC "Path to the QEMU ${ARCHITECTURE} emulator")

# Cross-platform OVMF UEFI firmware auto-discovery
set(OVMF "" CACHE FILEPATH "Path to UEFI firmware image (OVMF.fd)")
if(NOT OVMF)
    if(EXISTS "/usr/share/ovmf/OVMF.fd")
        set(OVMF "/usr/share/ovmf/OVMF.fd")                         # Ubuntu/Debian
    elseif(EXISTS "/usr/share/edk2/ovmf/OVMF_CODE.fd")
        set(OVMF "/usr/share/edk2/ovmf/OVMF_CODE.fd")               # Fedora
    elseif(EXISTS "/usr/share/edk2/x64/OVMF_CODE.fd")
        set(OVMF "/usr/share/edk2/x64/OVMF_CODE.fd")                # Arch
    elseif(EXISTS "/opt/homebrew/share/qemu/edk2-x86_64-code.fd")
        set(OVMF "/opt/homebrew/share/qemu/edk2-x86_64-code.fd")    # MacOS Homebrew
    else()
        set(OVMF "OVMF.fd" CACHE FILEPATH "Path to UEFI firmware image")
    endif()
endif()

# ----------------------------------------------------------------
# Subdirs
# ----------------------------------------------------------------
if(BOOTLOADER STREQUAL "bios")
    add_subdirectory(bios)
elseif(BOOTLOADER STREQUAL "uefi")
    add_subdirectory(uefi)
endif()
