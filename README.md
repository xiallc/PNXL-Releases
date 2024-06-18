# Pixie-Net XL Software

This release contains all software and firmware to work with the Pixie-Net device. You
will need to compile the executables using the `make` command from the project root
directory. I.e. the same directory containing this README. These files are installed
into the `/var/www` directory on the Pixie-Net XL. You can either do that by copying
the contents of the release archive into `/var/www` or by cloning this repo into that
directory:

```
git clone https://github.com/xiallc/PNXL-Releases.git /var/www
```

## Compatibility Information

**Note:** Make sure that you have aligned your software release with the system's
boot files. The system will become unstable if these are not matched.

| SKU                  | Variant ID | FW     | SW   | Host     | Igor | ZT Boot | MZ Boot | SD Image |
|----------------------|------------|--------|------|----------|------|---------|---------|----------|
| Pixie-Net-8-14-125   | 1          | 0x3111 | 3.42 | 01232024 | 6.3E | 3.32    | 3.32    | 09112023 |
| Pixie-Net-16-14-250  | 4          | 0x4141 | 3.42 | 01232024 | 6.3E | 3.32    | 3.32    | 09112023 |
| Pixie-Net-16-14-250T | 4T         | 0x4141 | 3.42 | 01232024 | 6.3E | 3.32    | 3.32    | 09112023 |
| Pixie-Net-16-14-250W | 4W         | 0x3140 | 3.42 | 01232024 | 6.3E | N/A     | 3.25    | 09072022 |
| Pixie-Net-8-14-500   | 7          | 0x3F71 | 3.42 | 01232024 | 6.3E | 3.32    | 3.32    | 09112023 |
| Pixie-Net-8-14-250   | 8          | 0x3F41 | 3.42 | 01232024 | 6.3E | 3.32    | 3.32    | 09112023 |

## Versioning

The Pixie-Net XL project versions components
using [Binary Coded Decimal](https://en.wikipedia.org/wiki/Binary-coded_decimal).
BCD is a compact format well suited to store information in hardware registers.

In this implementation, the first byte corresponds to the major version. The second
byte to the minor version. For example, `0x033B` would be software version `3.3B`. The
version increments by incrementing the minor version's rightmost nibble. When reaching
`F`, the next nibble rolls up. Ex. `3.3F` -> `3.40`. Here's a bit more complete example.

```
# in hex representation
3.38 < 3.39 < 3.3A < 3.3B < 3.3C
# in decimal representation
3.56 < 3.57 < 3.58 < 3.59 < 3.60
```

`PixieNetDefs.h` contains the software version information in the `PS_CODE_VERSION`
variable. Please refer to the manual for information related to the firmware version.