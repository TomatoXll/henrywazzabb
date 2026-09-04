extends RefCounted

static func parse(code: String) -> Dictionary:
	var raw_lines: PackedStringArray = code.split("\n")
	var lines: Array = []

	for raw_line in raw_lines:
		if raw_line.strip_edges() != "":
			lines.append(raw_line)

	var errors: Array = []
	var i := 0

	i = _expect_line(lines, i, "import henry_ability", -1, errors)
	i = _expect_line(lines, i, "stamina = int(100)", -1, errors)
	i = _expect_line(lines, i, "henry.stamina = stamina", -1, errors)

	var shift_if_index := i
	i = _expect_line(lines, i, "if henry.press_shift:", -1, errors)
	var shift_indent := _get_indent(lines, shift_if_index)

	i = _expect_line(lines, i, "henry.stamina -= 5", shift_indent, errors)

	var shift_inner_if_index := i
	i = _expect_line(lines, i, "if henry.stamina > 0:", shift_indent, errors)
	var shift_inner_indent := _get_indent(lines, shift_inner_if_index)

	i = _expect_line(lines, i, "henry.run = True", shift_inner_indent, errors)
	i = _expect_line(lines, i, "else:", shift_indent, errors)
	i = _expect_line(lines, i, "henry.run = False", shift_inner_indent, errors)

	var space_if_index := i
	i = _expect_line(lines, i, "if henry.press_space_bar:", -1, errors)
	var space_indent := _get_indent(lines, space_if_index)

	i = _expect_line(lines, i, "henry.stamina -= 15", space_indent, errors)

	var space_inner_if_index := i
	i = _expect_line(lines, i, "if henry.stamina > 0:", space_indent, errors)
	var space_inner_indent := _get_indent(lines, space_inner_if_index)

	i = _expect_line(lines, i, "henry.dodge = True", space_inner_indent, errors)
	i = _expect_line(lines, i, "else:", space_indent, errors)
	i = _expect_line(lines, i, "henry.dodge = False", space_inner_indent, errors)

	var regen_if_index := i
	i = _expect_line(lines, i, "if not henry.use_ability and henry.stamina < 100:", -1, errors)
	var regen_indent := _get_indent(lines, regen_if_index)

	i = _expect_line(lines, i, "henry.stamina += 5", regen_indent, errors)

	return {
		"is_fully_valid": errors.is_empty(),
		"errors": errors,
		"character_count": count_significant_characters(code),
	}

static func _get_indent(lines: Array, index: int) -> int:
	if index >= lines.size():
		return 0
	var line: String = lines[index]
	var count := 0
	for character in line:
		if character == " " or character == "\t":
			count += 1
		else:
			break
	return count

static func _expect_line(lines: Array, index: int, expected_content: String, parent_indent: int, errors: Array) -> int:
	if index >= lines.size():
		errors.append({"line": index + 1, "message": "Missing expected line: '%s'" % expected_content})
		return index + 1

	var actual_line: String = lines[index]
	var actual_content: String = actual_line.strip_edges()
	var actual_indent: int = _get_indent(lines, index)

	if actual_content != expected_content:
		errors.append({"line": index + 1, "message": "Expected '%s', got '%s'" % [expected_content, actual_content]})
	elif parent_indent == -1:
		if actual_indent != 0:
			errors.append({"line": index + 1, "message": "'%s' must not be indented" % expected_content})
	else:
		if actual_indent <= parent_indent:
			errors.append({"line": index + 1, "message": "'%s' must be indented more than the line above it" % expected_content})

	return index + 1

static func count_significant_characters(text: String) -> int:
	var count := 0
	for character in text:
		if character != " " and character != "\n" and character != "\t" and character != "\r":
			count += 1
	return count
