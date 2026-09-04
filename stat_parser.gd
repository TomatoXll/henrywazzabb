extends RefCounted

const STAT_CONFIG := {
	"speed": {"required_value": 0.1, "required_type": "float", "per_line": 2.5},
	"speed_atk": {"required_value": 10.0, "required_type": "int", "per_line": 1.0},
	"dexterity": {"required_value": 2.0, "required_type": "int", "per_line": 2.0},
}

static func parse(code: String) -> Dictionary:
	var lines: PackedStringArray = code.split("\n")
	var errors: Array = []
	var gains: Dictionary = {}
	var line_index := 0

	while line_index < lines.size() and lines[line_index].strip_edges() == "":
		line_index += 1

	if line_index >= lines.size() or lines[line_index].strip_edges() != "import stat":
		errors.append({"line": line_index + 1, "message": "First line must be exactly: import stat"})
		return {
			"is_fully_valid": false,
			"gains": {},
			"errors": errors,
			"character_count": count_significant_characters(code),
		}

	line_index += 1
	var current_stat: String = ""

	var assign_regex := RegEx.new()
	assign_regex.compile("^(\\w+)\\s*=\\s*(float|int)\\(([^)]+)\\)$")
	var improve_regex := RegEx.new()
	improve_regex.compile("^henry\\.improve\\s*\\+=\\s*(\\w+)$")

	while line_index < lines.size():
		var line: String = lines[line_index].strip_edges()

		if line == "":
			line_index += 1
			continue

		var assign_match := assign_regex.search(line)
		if assign_match:
			var stat_name: String = assign_match.get_string(1)
			var used_type: String = assign_match.get_string(2)
			var value: float = assign_match.get_string(3).strip_edges().to_float()

			if not STAT_CONFIG.has(stat_name):
				errors.append({"line": line_index + 1, "message": "Unknown stat '%s'" % stat_name})
				current_stat = ""
				line_index += 1
				continue

			var config: Dictionary = STAT_CONFIG[stat_name]

			if used_type != config["required_type"]:
				errors.append({"line": line_index + 1, "message": "nice try kid — %s must use %s(), not %s()" % [stat_name, config["required_type"], used_type]})
				current_stat = ""
				line_index += 1
				continue

			if abs(value - config["required_value"]) > 0.0001:
				errors.append({"line": line_index + 1, "message": "nice try kid — %s must be %s(%s)" % [stat_name, config["required_type"], str(config["required_value"])]})
				current_stat = ""
				line_index += 1
				continue

			current_stat = stat_name
			line_index += 1
			continue

		var improve_match := improve_regex.search(line)
		if improve_match:
			var referenced_stat: String = improve_match.get_string(1)

			if current_stat == "" or referenced_stat != current_stat:
				errors.append({"line": line_index + 1, "message": "'%s' not defined before use" % referenced_stat})
				line_index += 1
				continue

			var per_line: float = STAT_CONFIG[current_stat]["per_line"]
			gains[current_stat] = gains.get(current_stat, 0.0) + per_line
			line_index += 1
			continue

		errors.append({"line": line_index + 1, "message": "Unrecognized line: '%s'" % line})
		line_index += 1

	return {
		"is_fully_valid": errors.is_empty(),
		"gains": gains if errors.is_empty() else {},
		"errors": errors,
		"character_count": count_significant_characters(code),
	}

static func count_significant_characters(text: String) -> int:
	var count := 0
	for character in text:
		if character != " " and character != "\n" and character != "\t" and character != "\r":
			count += 1
	return count
