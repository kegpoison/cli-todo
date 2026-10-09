package main

import "core:fmt"
import "core:os"

clear_screen :: proc() {
	fmt.printf("%s%s", ANSI_CLEAR_SCREEN, ANSI_MOVE_HOME)
}
wait_input :: proc(buf: []byte) {
	fmt.println("==============================")
	fmt.println("Press enter to continue.")
	read_line(buf)
}
read_line_retry :: proc(buf: []byte) -> int {
	retry: for {
		switch n := read_line(buf); n {
		case -1:
			continue retry
		case:
			return n
		}
	}
}

read_line :: proc(buf: []byte) -> int {
	n, err := os.read(os.stdin, buf[:])
	if n == 0 {
		return 0
	}

	if err == nil {
		return n
	}

	fmt.eprintln("Error reading from stdin:", err)
	return -1
}
