# ----------------------------------------------------------------
# Variables
# ----------------------------------------------------------------
if(NOT DEFINED ARCHITECTURE)
	set(ARCHITECTURE x86_64 CACHE STRING "Target architecture")
endif()

# ----------------------------------------------------------------
# Checks
# ----------------------------------------------------------------
if(NOT ARCHITECTURE STREQUAL "x86_64")
    message(FATAL_ERROR "This toolchain only supports ARCHITECTURE=x86_64.")
endif()

# ----------------------------------------------------------------
# Set defaults
# ----------------------------------------------------------------
# Bare metal: no OS, no default libs/startfiles, compile x86_64 for architecture
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Look for cross compiler (x86_64-elf-gcc), fall back to the host gcc.
if(NOT CMAKE_C_COMPILER)
    find_program(_kernel_cc NAMES x86_64-elf-gcc gcc)
    if(_kernel_cc)
        set(CMAKE_C_COMPILER ${_kernel_cc})
    endif()
endif()

# By default CMake tries to compile a test binary, but this uses libc
# to avoid CMake complaining that it can't compile with the current compiler
# we test by creating a STATIC_LIBARRY which doesn't need libc.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# The (target) root path is the place where all the tools and files for the compiled
# binary end up, we only want our binary to use it's own libraries and includes not from
# the host. But for programs it should use our host for like qemu
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
