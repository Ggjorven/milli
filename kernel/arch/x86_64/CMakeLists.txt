# ----------------------------------------------------------------
# Add x86_64 sources
# ----------------------------------------------------------------
target_sources(${UEFI_TARGET} PRIVATE
    empty.c
)

# ----------------------------------------------------------------
# x86_64 linker settings
# ----------------------------------------------------------------
target_link_options(${UEFI_TARGET} PRIVATE
    -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/linker.ld
)

# ----------------------------------------------------------------
# Architecture-specific executable setup
# ----------------------------------------------------------------
add_subdirectory(arch/${ARCHITECTURE})
