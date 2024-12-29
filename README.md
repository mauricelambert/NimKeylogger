![NimKeylogger Logo](https://mauricelambert.github.io/info/nim/security/NimKeylogger_small.png "NimKeylogger logo")

# NimKeylogger

## Description

This nim script implements a keylogger and saves keyboard events in a Keyboard Catpure file.

## Keyboard Catpure

The Keyboard Capture is written with a file headers following by keyboard input data. The file format is defined with the following C structures:

```c
typedef struct {
    uint32_t state_seconds;      // First bit: is_pressed, 31 last bits: seconds since the header Unix timestamp
    uint8_t virtualKeyCode;      // Virtual key code
} KeyEntry;

typedef struct {
    char magicBytes[4];          // Magic bytes
    uint32_t timestamp;          // Unix timestamp
    uint32_t keyboardLayoutCode; // Keyboard layout code
    uint32_t numberOfEntries;    // Number of entries
    KeyEntry* entries;           // Pointer to dynamic array of KeyEntry
} KeyLog;
```

- The `KeyEntry` contains the *state* (1 bit) to know if key is pressed or released, the *time from the header timestamp* (31 bits) in seconds and the *virtual key code* (8 bits).
- The `Keylog` contains the *magic bytes* (`{'K', 'e', 'y', 'C'}`, 4 bytes), the *timestamp* when capture start (4 bytes, uint32, the number of seconds since 1970-01-01), the *keyboard layout* to identify the keyboard type and language (qwerty, azerty, ...), the *entries length* to know how many keyboard events you should parse
- *entries*, each keyboard events is a `KeyEntry` to define when/which key is pressed/released

### Parse

To parse the keyboard capture file format, i have written a python script, the `read` mode print the structure and the `replay` mode send keyboard events (you should open a notepad or another IDE and set the focus on the window) to see what is written, but becareful some keyboard shortcut can impact your system (multiples keyboard events are not authorized and print in the following format `<KEYNAME>` to protect your system), but `CTRL`, `SHIFT`, `TAB`, `ALT` is authorized to see upper case, numbers or special characters.

## Requirements

 - No requirements

## Download

 - https://github.com/mauricelambert/NimKeylogger/releases

## Compilation

```bash
nim --app:gui c --stackTrace:off  --lineTrace:off --checks:off --assertions:off -d:release --passl:"-s" Keylogger.nim
```

## Licence

Licensed under the [GPL, version 3](https://www.gnu.org/licenses/).
