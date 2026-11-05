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

# ----------------------------------------------------------------
# Subdirs
# ----------------------------------------------------------------
if(BOOTLOADER STREQUAL "bios")
    add_subdirectory(bios)

    set(BIOS_STAGE1_BIN "${BIOS_STAGE1_BIN}" PARENT_SCOPE)
    set(BIOS_STAGE2_BIN "${BIOS_STAGE2_BIN}" PARENT_SCOPE)
elseif(BOOTLOADER STREQUAL "uefi")
    add_subdirectory(uefi)

    set(UEFI_EFI_FILE "${UEFI_EFI_FILE}" PARENT_SCOPE)
endif()
