package main

import "core:fmt"
import "core:os"
import "core:strings"

DeserializeError :: enum {
	None,
	UnknownVersion,
	BadField,
	Malformed,
}

deserialize_error_to_string :: proc(err: DeserializeError) -> string {
	switch err {
	case .None:
		return "No error"
	case .UnknownVersion:
		return "Unknown version"
	case .BadField:
		return "Bad field"
	case .Malformed:
		return "Malformed"
	case:
		return "Unknown error"
	}
}

deserialize_todo :: proc(str: string) -> (Maybe(Todo), DeserializeError) {
	todo: Todo
	lines := strings.split_lines(str)
	if len(lines) == 0 {
		return nil, .Malformed
	}
	switch lines[0] {
	case "0.0.0":
		if len(lines) < 3 {
			return nil, .Malformed
		}
		todo.name = strings.clone(lines[1])
		if lines[2] == "FINISHED" {
			todo.completed = true
		} else if lines[2] == "ACTIVE" {
			todo.completed = false
		} else {
			return nil, .BadField
		}
		if len(lines) > 3 {
			if strings.compare(lines[len(lines) - 1], SERIALIZE_SEPARATER) == 0 {
				// The todo itself cannot contain the seperator
				return nil, .Malformed
			} else {
				todo.content = strings.join(lines[3:], "\n")
			}
		} else {
			todo.content = nil
		}
		return todo, .None
	case:
		return nil, .UnknownVersion
	}
}

serialize_todo :: proc(todo: Todo) -> string {
	builder: strings.Builder
	defer strings.builder_destroy(&builder)

	strings.write_string(&builder, "0.0.0\n")

	strings.write_string(&builder, todo.name)
	strings.write_string(&builder, "\n")

	if todo.completed {
		strings.write_string(&builder, "FINISHED\n")
	} else {
		strings.write_string(&builder, "ACTIVE\n")
	}
	if content, ok := todo.content.?; ok {
		strings.write_string(&builder, content)
		strings.write_string(&builder, "\n")
	}

	str := strings.clone(strings.to_string(builder))
	return str
}

read_todos :: proc(path: string) -> Maybe(List(Todo)) {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil {
		fmt.eprintln("Error reading file:", err)
		return nil
	}
	defer delete(data)

	todos := list_init(Todo)

	it := string(data)
	for todo_raw in strings.split_iterator(&it, SERIALIZE_SEPARATER) {
		fmt.printfln("Loading todo:\n%s\n", todo_raw)
		todo_maybe, err := deserialize_todo(todo_raw)
		if todo, ok := todo_maybe.?; ok {
			list_push_back(&todos, todo)
		} else {
			fmt.eprintln("Error deserializing:", deserialize_error_to_string(err))
			continue
		}
	}
	return todos
}

write_todos :: proc(path: string, todos: ^List(Todo)) -> bool {
	builder: strings.Builder
	defer strings.builder_destroy(&builder)

	for node := todos.head; node != nil; node = node.next {
		todo := node.value

		serialized := serialize_todo(todo)
		strings.write_string(&builder, serialized)
		strings.write_string(&builder, "\n")
		strings.write_string(&builder, SERIALIZE_SEPARATER)
		strings.write_string(&builder, "\n")
	}
	str := strings.to_string(builder)

	err := os.write_entire_file(path, str)
	if err != nil {
		fmt.eprintf("Error writing to path %s:", path)
		fmt.eprintln(err)
		return false
	}
	return true
}
