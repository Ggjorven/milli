# milli

**milli** is my attempt at writing a small bootloader, kernel and operating system from scratch. I am learning as I go with the help of resources like the OSDev wiki.

The goal isn't to compete with anything, but to understand how an OS actually works by building one: booting, memory management, interrupts, scheduling, and eventually a tiny userland. Keeping it small and readable is a design goal.

## Features

- [ ] Bootloader handoff
- [ ] Serial / text output
- [ ] GDT and IDT
- [ ] Physical and virtual memory management
- [ ] Interrupts and timer
- [ ] Scheduler
- [ ] Basic userland

## Supported architectures

The ultimate goal is having the OS be supported on the most common architectures, but for now these architectures are supported:

- **x86_64**

## Getting Started

### Prerequisites

Supported build platforms are:
- **Linux**
- **MacOS**\*

First you'll need to clone the repository:
```sh
git clone https://github.com/ggjorven/milli.git
```

To be able to build and run this OS we must have some tools installed.
Follow the instructions for your platform set in [DEPENDENCIES.md](./doc/build/DEPENDENCIES.md).

\*:
MacOS can only build the BIOS target because `parted` cannot be installed on macOS, see [#621579](https://superuser.com/questions/621579/install-gparted-on-a-mac-with-homebrew-or-macports).

### Building, testing & running

- [Build instructions](./doc/build/BUILDING.md)
- [Test instructions](./doc/build/TESTING.md)
- [Run instructions](./doc/build/RUNNING.md)

If you wish to get more insight into how the build proces builds the final `.img` file you can checkout [this architecture document](./doc/architecture/BUILD-ORDER.md).

## Notes

While researching for this project I took notes you can find under [`doc/research/`](./doc/research/). This includes:
- [From power on to the bootloader](./doc/research/POWER-ON-TO-BOOTLOADER.md)
- [From bootloader to the kernel](./doc/research/BOOTLOADER-TO-KERNEL.md)

## License

This project is licensed under the **MIT LICENSE**. See [LICENSE](./LICENSE.txt) for the full license text.

## Contributing

Contributions are highly appreciated, please follow the contributing guidelines stated in [CONTRIBUTING.md](./CONTRIBUTING.md) to make a quality contribution.
To get more insight into the file structure checkout [this architecture document](./doc/architecture/DIRECTORY-STRUCTURE.md).

## Acknowledgements

Thanks to the [OSDev wiki](https://wiki.osdev.org) and the OSDev community.
