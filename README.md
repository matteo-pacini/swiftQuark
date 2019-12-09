# DEPRECATED

Currently rewriting this tool in C99 as dealing with pointers in Swift has been quite traumatic.
Long live C!

# swiftQuark

A [Goldleaf 0.7.3](https://github.com/XorTroll/Goldleaf) client written in Swift.

Under development.

## ToDo

- [X] Linux Support 
- [ ] Goldleaf USB protocol documentation

## Usage

Run `Goldleaf` on the Nintendo Switch, then run `swiftQuark`.

## Build

Built using **Xcode 11.1** (swift 5.1 toolchain).

Linux toolchains are available [here](https://swift.org/download/#releases).

Clone the repository, then run:
```bash
swift build
```

To run `swiftQuark` run: 
```
./.build/debug/swiftQuark
```

## Linux

Tested on `Ubuntu 18.04` with `Swift 5.1` toolchain.
