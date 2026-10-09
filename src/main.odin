package main

import "core:fmt"
import "core:os"
import "core:strings"

Todo :: struct {
	name:      string,
	content:   Maybe(string),
	completed: bool,
}

TODO_FILE: string : "TODOS"

WHITESPACE_RUNES: string : " \t\n"

ANSI_CLEAR_SCREEN: string : "\033[2J"
ANSI_MOVE_HOME: string : "\033[H"
ANSI_REVERSE_ON: string : "\033[7m"
ANSI_REVERSE_OFF: string : "\033[27m"

SERIALIZE_SEPARATER: string : "-----END TODO-----"


print_banner :: proc() {
	fmt.println("Welcome to the Todos® App™!")
}

print_controls_preview :: proc() {
	fmt.println("h: Print help text")
}

print_controls :: proc() {
	fmt.println("A: Append new todo to end")
	fmt.println("d: Delete current todo")
	fmt.println("s: Show content of current todo")
	fmt.println("j: Move cursor down")
	fmt.println("k: Move cursor up")
	fmt.println("c: Toggle completion of current todo")
	fmt.println("w: Write state to file")
	fmt.println("q: Quit the program")
	fmt.println("h: Print this text")
}

create_todo :: proc(buf: []byte) -> Maybe(Todo) {
	disable_raw_mode()
	defer enable_raw_mode()

	todo: Todo

	name: string
	for {
		fmt.println("What should the todo be called?")

		n := read_line_retry(buf)

		if n == 0 {
			// EOF
			return nil
		}
		name = strings.trim(string(buf[:n]), WHITESPACE_RUNES)
		if len(name) == 0 {
			continue
		}
		break
	}
	todo.name = strings.clone(name)

	fmt.println("What should the todo's content be? QQQ to finish")

	content_builder: strings.Builder
	defer strings.builder_destroy(&content_builder)
	for {
		n := read_line_retry(buf)
		if n == 0 {
			// EOF
			return nil
		}

		content := string(buf[:n])

		if strings.compare(strings.trim(content, WHITESPACE_RUNES), "QQQ") == 0 {
			break
		}
		if strings.compare(content, SERIALIZE_SEPARATER) == 0 {
			fmt.eprintfln("The line cannot be exactly %s", SERIALIZE_SEPARATER)
		} else {
			strings.write_string(&content_builder, content)
		}
	}
	content := strings.to_string(content_builder)
	content = strings.trim(content, WHITESPACE_RUNES)
	todo.content = strings.clone(content)

	todo.completed = false

	return todo
}


view_todo :: proc(todo: Todo) {
	if todo.completed {
		fmt.printfln("%s (completed)", todo.name)
	} else {
		fmt.printfln("%s (not completed)", todo.name)
	}

	fmt.println(todo.content)
}

print_list :: proc(todos: List(Todo), current: Node(Todo)) {
	if todos.len == 0 {
		fmt.println("No todos.")
	}

	for node := todos.head; node != nil; node = node.next {
		todo := node.value
		if node^ == current {
			fmt.print(ANSI_REVERSE_ON)
		}
		if todo.completed {
			fmt.print(" [X] ")
		} else {
			fmt.print(" [ ] ")
		}
		fmt.print(todo.name)
		if node^ == current {
			fmt.println(ANSI_REVERSE_OFF)
		} else {
			fmt.println()
		}
	}
}

save_todos :: proc(todos: ^List(Todo)) {
	if write_todos(TODO_FILE, todos) {
		fmt.printfln("Saved to %s", TODO_FILE)
	} else {
		fmt.printfln("Failed to save to %s", TODO_FILE)
	}
}

main :: proc() {
	enable_raw_mode()
	defer disable_raw_mode()

	todos: List(Todo)
	if tdo, ok := read_todos("TODOS").?; ok {
		todos = tdo
	} else {
		todos = list_init(Todo)
	}
	defer list_free(&todos)

	buf: [256]byte
	current := todos.head

	print_banner()
	program: for {
		clear_screen()
		print_controls_preview()
		print_list(todos, current^)
		n, err := os.read(os.stdin, buf[:])

		if err != nil {
			fmt.eprintln("Error reading from stdin:", err)
			continue
		}

		if n == 0 {
			fmt.eprintln("Nothing inputted!")
			continue
		}
		if buf[0] == 'A' {
			if todo, ok := create_todo(buf[:]).?; ok {
				current = list_push_back(&todos, todo)
			} else {
				fmt.eprintln("Error creating todo")
			}
		}
		if todos.len == 0 || current == nil {
			continue
		}
		switch option := buf[0]; option {
		case 'd':
			current = list_remove(&todos, current)
		case 'c':
			current.value.completed = !current.value.completed
		case 's':
			clear_screen()
			view_todo(current.value)
			wait_input(buf[:])
		case 'j':
			if current.next == nil {
				current = todos.head
			} else {
				current = current.next
			}
		case 'k':
			if current.prev == nil {
				current = todos.tail
			} else {
				current = current.prev
			}
		case 'w':
			clear_screen()
			save_todos(&todos)
			wait_input(buf[:])
		case 'q':
			break program
		case 'h':
			print_controls()
			wait_input(buf[:])
		case:
			fmt.println("Invalid option chosen")
			continue program
		}
	}
}
