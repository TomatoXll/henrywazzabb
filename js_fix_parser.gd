extends RefCounted

const EXPECTED_METHOD := "getElementById"

const BUTTONS := [
	{"id": "respawn", "label": "Respawn"},
	{"id": "edit", "label": "Edit"},
	{"id": "folder", "label": "Code Folder"},
]

# =====================================================================
# โค้ดต้นฉบับที่ถูกต้อง (reference) — แต่ละปุ่มกิน 4 บรรทัด:
#   [0] icon      [1] onclick      [2] label      [3] </button>
# =====================================================================
static func get_reference_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append('<div id="respawn-screen">')
	lines.append('<h1>YOU DIED</h1>')

	for button in BUTTONS:
		var button_id: String = button["id"]
		lines.append('<img id="%s-icon" style="display: block;">' % button_id)
		lines.append('<button id="%s-btn" onclick="document.getElementById(\'%s\').disabled = false;">' % [button_id, button_id])
		lines.append(button["label"])
		lines.append('</button>')

	lines.append('</div>')
	return lines

static func _find_button_block_start(reference_lines: Array[String], target_element: String) -> int:
	for i in range(reference_lines.size()):
		if reference_lines[i].contains('id="%s-icon"' % target_element):
			return i
	return -1

static func _button_index(target_element: String) -> int:
	for i in range(BUTTONS.size()):
		if BUTTONS[i]["id"] == target_element:
			return i
	return 0

static func _scramble(text: String) -> String:
	var letters: Array = []
	for c in text:
		letters.append(c)
	letters.shuffle()
	return "".join(letters)

static func _other_element_id(target_element: String) -> String:
	var others: Array = []
	for button in BUTTONS:
		if button["id"] != target_element:
			others.append(button["id"])
	return others[randi() % others.size()]

static func _corrupt_onclick_line(correct_line: String, target_element: String) -> String:
	var variant: int = randi() % 3

	if variant == 0:
		return correct_line.replace("getElementById", "ERROR")
	elif variant == 1:
		var wrong_id: String = _other_element_id(target_element)
		return correct_line.replace("'%s'" % target_element, "'%s'" % wrong_id)
	else:
		return correct_line.replace("false;\">", "false\">")

# =====================================================================
# 30% (LOW TIER) — พังแค่ 1 บรรทัด สุ่มระหว่าง icon กับ label
# =====================================================================
static func _apply_low_tier_bug(lines: Array[String], block_start: int) -> void:
	var bug_on_icon: bool = randi() % 2 == 0

	if bug_on_icon:
		lines[block_start] = lines[block_start].replace("display: block;", "display: none;")
	else:
		var label_index: int = block_start + 2
		lines[label_index] = _scramble(lines[label_index])

# =====================================================================
# 0% (CRITICAL TIER) — พังทั้ง 3 บรรทัดพร้อมกัน: icon, onclick, label
# =====================================================================
static func _apply_critical_tier_bug(lines: Array[String], block_start: int, target_element: String) -> void:
	lines[block_start] = lines[block_start].replace("display: block;", "display: none;")
	lines[block_start + 1] = _corrupt_onclick_line(lines[block_start + 1], target_element)
	lines[block_start + 2] = _scramble(lines[block_start + 2])

# =====================================================================
# เรียกตอนเปิด Fix screen — สร้างโค้ดที่พังให้โชว์
# =====================================================================
static func get_display_lines(target_element: String, severity: String) -> Array[String]:
	var lines: Array[String] = get_reference_lines()
	var block_start: int = _find_button_block_start(lines, target_element)

	if block_start == -1:
		return lines

	if severity == "low":
		_apply_low_tier_bug(lines, block_start)
	else:
		_apply_critical_tier_bug(lines, block_start, target_element)

	return lines

# =====================================================================
# ตรวจ onclick โดยเฉพาะ — ครอบคลุมทั้ง 3 แบบบั๊กที่สุ่มได้
# =====================================================================
static func parse(code_line: String, target_element: String) -> Dictionary:
	var line: String = code_line.strip_edges()

	if line == "":
		return _fail("No code written yet.")

	if not line.begins_with("document."):
		return _fail("Line must start with 'document.'")

	var remainder: String = line.substr("document.".length())
	var shape_regex := RegEx.new()
	shape_regex.compile("^([A-Za-z_]+)\\((.*)\\)\\.disabled\\s*=\\s*false(;?)\\s*$")
	var shape_match := shape_regex.search(remainder)

	if not shape_match:
		return _fail("Line format invalid. Expected: document.%s('%s').disabled = false;" % [EXPECTED_METHOD, target_element])

	var method_name: String = shape_match.get_string(1)
	var arg_raw: String = shape_match.get_string(2).strip_edges()
	var semicolon: String = shape_match.get_string(3)

	if method_name != EXPECTED_METHOD:
		return _fail("Unknown method '%s'. Did you mean '%s'?" % [method_name, EXPECTED_METHOD])

	var quote_regex := RegEx.new()
	quote_regex.compile("^['\\\"](\\w+)['\\\"]$")
	var quote_match := quote_regex.search(arg_raw)

	if not quote_match:
		return _fail("Argument must be a quoted string, e.g. '%s'" % target_element)

	var arg_name: String = quote_match.get_string(1)

	if arg_name != target_element:
		return _fail("Wrong target. This code should target '%s', not '%s'." % [target_element, arg_name])

	if semicolon != ";":
		return _fail("Missing semicolon at the end of the line.")

	return {"is_fully_valid": true, "errors": []}

# =====================================================================
# ตรวจตอนกด Compile — ไม่ต้องรับ severity เลย (คำตอบที่ถูกคือ reference เสมอ)
# =====================================================================
static func parse_mock(code: String, target_element: String) -> Dictionary:
	var reference_lines: Array[String] = get_reference_lines()
	var player_lines: Array[String] = _significant_lines(code)

	if player_lines.size() != reference_lines.size():
		return _fail("Line count doesn't match. Expected %d lines, found %d. Don't add or remove lines." % [reference_lines.size(), player_lines.size()])

	var block_start: int = _find_button_block_start(reference_lines, target_element)
	if block_start == -1:
		return _fail("Internal error: unknown target element '%s'." % target_element)

	var icon_index: int = block_start
	var onclick_index: int = block_start + 1
	var label_index: int = block_start + 2

	for i in range(reference_lines.size()):
		if i == icon_index or i == onclick_index or i == label_index:
			continue
		if player_lines[i] != reference_lines[i]:
			return {"is_fully_valid": false, "errors": [{"line": i + 1, "message": "Line %d doesn't match the correct code." % (i + 1)}]}

	if player_lines[icon_index] != reference_lines[icon_index]:
		return {"is_fully_valid": false, "errors": [{"line": icon_index + 1, "message": "Icon is hidden. Change 'display: none;' back to 'display: block;'."}]}

	if player_lines[label_index] != reference_lines[label_index]:
		return {"is_fully_valid": false, "errors": [{"line": label_index + 1, "message": "Label text looks scrambled. It should say '%s'." % BUTTONS[_button_index(target_element)]["label"]}]}

	var onclick_regex := RegEx.new()
	onclick_regex.compile("onclick=\"([^\"]*)\"")
	var onclick_match := onclick_regex.search(player_lines[onclick_index])

	if not onclick_match:
		return _fail("Line %d: couldn't find an onclick=\"...\" attribute." % (onclick_index + 1))

	var result: Dictionary = parse(onclick_match.get_string(1), target_element)
	if not result["is_fully_valid"]:
		for error in result["errors"]:
			error["line"] = onclick_index + 1

	return result

static func _significant_lines(code: String) -> Array[String]:
	var result: Array[String] = []
	for raw_line in code.split("\n"):
		var trimmed: String = raw_line.strip_edges()
		if trimmed != "":
			result.append(trimmed)
	return result

static func _fail(message: String) -> Dictionary:
	return {"is_fully_valid": false, "errors": [{"line": 1, "message": message}]}
