#+build !windows
package main

import psx "core:sys/posix"

@(private = "file")
orig_mode: psx.termios

enable_raw_mode :: proc() {
	res := psx.tcgetattr(psx.STDIN_FILENO, &orig_mode)
	assert(res == .OK)

	raw := orig_mode
	raw.c_lflag -= {.ECHO, .ICANON}
	res = psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &raw)
	assert(res == .OK)
}

disable_raw_mode :: proc "c" () {
	psx.tcsetattr(psx.STDIN_FILENO, .TCSANOW, &orig_mode)
}
