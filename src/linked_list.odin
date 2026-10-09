package main

import "base:runtime"

Node :: struct($T: typeid) {
	value: T,
	prev:  ^Node(T),
	next:  ^Node(T),
}

List :: struct($T: typeid) {
	head:      ^Node(T),
	tail:      ^Node(T),
	len:       int,
	allocator: runtime.Allocator,
}

list_init :: proc($T: typeid, allocator := context.allocator) -> List(T) {
	l: List(T)
	l.allocator = allocator
	return l
}

list_push_back :: proc(list: ^List($T), value: T) -> ^Node(T) {
	node := new_clone(Node(T){value = value}, list.allocator)

	if list.tail == nil {
		list.head = node
		list.tail = node
	} else {
		node.prev = list.tail
		list.tail.next = node
		list.tail = node
	}
	list.len += 1
	return node
}

list_insert_after :: proc(list: ^List($T), curr: ^Node(T), value: T) {
	node := new_clone(Node(T){value = value, prev = curr, next = curr.next}, list.allocator)
	if curr.next == nil {
		list.tail = node
	} else {
		curr.next.prev = node
	}

	curr.next = node
	list.len += 1
}

list_remove :: proc(list: ^List($T), node: ^Node(T)) -> ^Node(T) {
	ret := node.prev
	if node.prev == nil {
		ret = node.next
		list.head = node.next
	} else {
		node.prev.next = node.next
	}

	if node.next == nil {
		list.tail = node.prev
	} else {
		node.next.prev = node.prev
	}

	free(node, list.allocator)
	list.len -= 1
	return ret
}

list_free :: proc(list: ^List($T)) {
	node := list.head

	for node != nil {
		next := node.next
		free(node, list.allocator)
		node = next
	}
	list.head = nil
	list.tail = nil
	list.len = 0
}
