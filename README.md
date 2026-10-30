# milli

**milli** is my attempt at writing a small kernel and operating system from scratch, learning as I go with the help of resources like the OSDev wiki.

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
- **MacOS**

First you'll need to clone the repository:
```sh
git clone https://github.com/ggjorven/milli.git
```

To be able to build and run this OS we must have some tools installed.
Follow the instructions for your platform set in [DEPENDENCIES.md](./doc/DEPENDENCIES.md).

### Building

Build instructions for this project can be found in the [BUILDING.md](./doc/BUILDING.md) file.

### Testing

Test instructions for this project can be found in the [TESTING.md](./doc/TESTING.md) file.

### Running

Run instructions for this project can be found in the [RUNNING.md](./doc/RUNNING.md) file.

## License

This project is licensed under the **MIT LICENSE**. See [LICENSE](./LICENSE.txt) for the full license text.

## Contributing

Contributions are highly appreciated, please follow the contributing guidelines stated in [CONTRIBUTING.md](./CONTRIBUTING.md) to make a quality contribution.

## Acknowledgements

Thanks to the [OSDev wiki](https://wiki.osdev.org) and the OSDev community.