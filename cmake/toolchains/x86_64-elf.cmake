# cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=cmake/x86_64-elf.cmake
# Override the compiler with -DCMAKE_CXX_COMPILER=... if you like.

# Bare metal: no OS, no default libs/startfiles, compile x86_64 for architecture
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Look for cross compiler (x86_64-elf-g++), fall back to the host g++,
if(NOT CMAKE_CXX_COMPILER)
    find_program(_kernel_cxx NAMES x86_64-elf-g++ g++)
    if(_kernel_cxx)
        set(CMAKE_CXX_COMPILER ${_kernel_cxx})
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