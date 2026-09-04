extends RefCounted

const EFFECT_REGISTRY := {
	"fire": "burn",
	"ice": "freeze",
	"lightning": "shock",
	"life_steal": "life_steal",
	"gravity": "force",
}

const FUSION_RECIPES := {
	"burn|freeze": "freezeburn",
	"burn|shock": "overload",
}

static func parse(code: String) -> Dictionary:
	var lines: PackedStringArray = code.split("\n")
	var errors: Array = []
	var effects: Array[String] = []
	var line_index := 0

	while line_index < lines.size() and lines[line_index].strip_edges() == "":
		line_index += 1

	if line_index >= lines.size() or lines[line_index].strip_edges() != "import weapon_effect":
		errors.append({"line": line_index + 1, "message": "First line must be exactly: import weapon_effect"})
		return {
			"is_fully_valid": false,
			"effects": [],
			"errors": errors,
			"character_count": count_significant_characters(code),
		}

	line_index += 1
	var block_found := false

	while line_index < lines.size():
		var line: String = lines[line_index].strip_edges()

		if line == "":
			line_index += 1
			continue

		block_found = true

		if line.begins_with("if weapon_effect =="):
			var fusion_result := _parse_fusion_block(lines, line_index, effects)

			if fusion_result["error"] != "":
				errors.append({"line": fusion_result["error_line"], "message": fusion_result["error"]})
			elif fusion_result["fused_name"] != "":
				effects.erase(fusion_result["consumed_a"])
				effects.erase(fusion_result["consumed_b"])
				effects.append(fusion_result["fused_name"])

			line_index = fusion_result["next_index"]
		else:
			var block_result := _parse_effect_block(lines, line_index)

			if block_result["error"] != "":
				errors.append({"line": block_result["error_line"], "message": block_result["error"]})
			else:
				effects.append(block_result["status_effect"])

			line_index = block_result["next_index"]

	var is_fully_valid: bool = block_found and errors.is_empty()

	return {
		"is_fully_valid": is_fully_valid,
		"effects": effects if is_fully_valid else [],
		"errors": errors,
		"character_count": count_significant_characters(code),
	}

static func _parse_effect_block(lines: PackedStringArray, start_index: int) -> Dictionary:
	var result := {
		"error": "",
		"error_line": start_index + 1,
		"status_effect": "",
		"next_index": start_index + 1,
	}

	var assign_line: String = lines[start_index].strip_edges()
	var assign_regex := RegEx.new()
	assign_regex.compile("^weapon_effect\\s*=\\s*\"([a-zA-Z_]+)\"$")
	var assign_match := assign_regex.search(assign_line)

	if not assign_match:
		result["error"] = "Line must match: weapon_effect = \"effect_name\""
		result["error_line"] = start_index + 1
		result["next_index"] = start_index + 1
		return result

	var effect_name_raw: String = assign_match.get_string(1)
	var effect_name: String = effect_name_raw.to_lower()

	if not EFFECT_REGISTRY.has(effect_name):
		result["error"] = "Unknown effect '%s'. Known effects: %s" % [effect_name_raw, str(EFFECT_REGISTRY.keys())]
		result["error_line"] = start_index + 1
		result["next_index"] = start_index + 1
		return result

	if start_index + 1 >= lines.size():
		result["error"] = "Missing if condition line"
		result["error_line"] = start_index + 2
		result["next_index"] = start_index + 1
		return result

	var if_line: String = lines[start_index + 1].strip_edges()
	if if_line != "if sword.hit(enemy):":
		result["error"] = "Line must be exactly: if sword.hit(enemy):"
		result["error_line"] = start_index + 2
		result["next_index"] = start_index + 2
		return result

	if start_index + 2 >= lines.size():
		result["error"] = "Missing indented effect line after if statement"
		result["error_line"] = start_index + 3
		result["next_index"] = start_index + 2
		return result

	var effect_line: String = lines[start_index + 2]
	var expected_suffix: String = EFFECT_REGISTRY[effect_name]
	var effect_regex := RegEx.new()
	effect_regex.compile("^\\s+enemy\\.(\\w+)_effect\\s*=\\s*True$")
	var effect_match := effect_regex.search(effect_line)

	if not effect_match:
		result["error"] = "Indented line must match: enemy.<effect>_effect = True (with indentation)"
		result["error_line"] = start_index + 3
		result["next_index"] = start_index + 3
		return result

	var written_suffix: String = effect_match.get_string(1)
	if written_suffix != expected_suffix:
		result["error"] = "Effect '%s' should set 'enemy.%s_effect', not 'enemy.%s_effect'" % [effect_name, expected_suffix, written_suffix]
		result["error_line"] = start_index + 3
		result["next_index"] = start_index + 3
		return result

	result["status_effect"] = expected_suffix
	result["next_index"] = start_index + 3
	return result

static func _parse_fusion_block(lines: PackedStringArray, start_index: int, declared_effects: Array[String]) -> Dictionary:
	var result := {
		"error": "",
		"error_line": start_index + 1,
		"fused_name": "",
		"consumed_a": "",
		"consumed_b": "",
		"next_index": start_index + 1,
	}

	var if_line: String = lines[start_index].strip_edges()
	var if_regex := RegEx.new()
	if_regex.compile("^if weapon_effect == \"([a-zA-Z_]+)\" and weapon_effect == \"([a-zA-Z_]+)\":$")
	var if_match := if_regex.search(if_line)

	if not if_match:
		result["error"] = "Line must match: if weapon_effect == \"a\" and weapon_effect == \"b\":"
		result["error_line"] = start_index + 1
		result["next_index"] = start_index + 1
		return result

	var name_a: String = if_match.get_string(1).to_lower()
	var name_b: String = if_match.get_string(2).to_lower()

	if not EFFECT_REGISTRY.has(name_a) or not EFFECT_REGISTRY.has(name_b):
		result["error"] = "Unknown effect name in fusion condition"
		result["error_line"] = start_index + 1
		result["next_index"] = start_index + 1
		return result

	var suffix_a: String = EFFECT_REGISTRY[name_a]
	var suffix_b: String = EFFECT_REGISTRY[name_b]

	if not declared_effects.has(suffix_a) or not declared_effects.has(suffix_b):
		result["error"] = "Both '%s' and '%s' must be declared (with their own weapon_effect blocks) before this fusion condition" % [name_a, name_b]
		result["error_line"] = start_index + 1
		result["next_index"] = start_index + 1
		return result

	if start_index + 1 >= lines.size():
		result["error"] = "Missing indented weapon_effect assignment after fusion condition"
		result["error_line"] = start_index + 2
		result["next_index"] = start_index + 1
		return result

	var assign_line: String = lines[start_index + 1]
	var assign_regex := RegEx.new()
	assign_regex.compile("^\\s+weapon_effect\\s*=\\s*\"([a-zA-Z_]+)\"$")
	var assign_match := assign_regex.search(assign_line)

	if not assign_match:
		result["error"] = "Indented line must match: weapon_effect = \"fusion_name\" (with indentation)"
		result["error_line"] = start_index + 2
		result["next_index"] = start_index + 2
		return result

	var written_fusion_name: String = assign_match.get_string(1).to_lower()
	result["next_index"] = start_index + 2

	var recipe_key_1: String = "%s|%s" % [suffix_a, suffix_b]
	var recipe_key_2: String = "%s|%s" % [suffix_b, suffix_a]
	var correct_fusion: String = ""

	if FUSION_RECIPES.has(recipe_key_1):
		correct_fusion = FUSION_RECIPES[recipe_key_1]
	elif FUSION_RECIPES.has(recipe_key_2):
		correct_fusion = FUSION_RECIPES[recipe_key_2]

	if correct_fusion != "" and written_fusion_name == correct_fusion:
		result["fused_name"] = correct_fusion
		result["consumed_a"] = suffix_a
		result["consumed_b"] = suffix_b

	return result

static func count_significant_characters(text: String) -> int:
	var count := 0
	for character in text:
		if character != " " and character != "\n" and character != "\t" and character != "\r":
			count += 1
	return count
