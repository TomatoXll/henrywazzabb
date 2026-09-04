extends Node

const CORRUPTIBLE_ELEMENTS: Array[String] = ["respawn", "edit", "folder"]
const HITS_BEFORE_CORRUPTION_START := 5
const HITS_BEFORE_GAME_OVER := 10
const MAX_DURABILITY := 100.0
const MIN_DAMAGE_PER_EVENT := 5.0
const MAX_DAMAGE_PER_EVENT := 15.0
const SAVE_PATH := "user://corruption_data.json"
const LOW_DURABILITY_THRESHOLD := 30.0

signal element_corrupted(element_name: String)
signal game_over_triggered

var hit_count: int = 0
var durability: Dictionary = {}
var broken_elements: Array[String] = []

func _ready() -> void:
	_init_durability()
	_load_data()

func _init_durability() -> void:
	for element_name in CORRUPTIBLE_ELEMENTS:
		durability[element_name] = MAX_DURABILITY

func register_hit() -> void:
	hit_count += 1
	print("Hit count: ", hit_count)

	if hit_count >= HITS_BEFORE_GAME_OVER:
		game_over_triggered.emit()
		return

	if hit_count >= HITS_BEFORE_CORRUPTION_START:
		_try_damage_random_element()

func _try_damage_random_element() -> void:
	var chance_percent: float = (hit_count - HITS_BEFORE_CORRUPTION_START + 1) * 10.0

	if randf() * 100.0 >= chance_percent:
		return

	var available: Array[String] = []
	for element_name in CORRUPTIBLE_ELEMENTS:
		if durability[element_name] > 0.0:
			available.append(element_name)

	if available.is_empty():
		return

	var chosen: String = available[randi() % available.size()]
	var damage: float = randf_range(MIN_DAMAGE_PER_EVENT, MAX_DAMAGE_PER_EVENT)
	durability[chosen] = max(0.0, durability[chosen] - damage)

	print("%s durability: %d%%" % [chosen, int(durability[chosen])])

	if durability[chosen] <= 0.0 and chosen not in broken_elements:
		broken_elements.append(chosen)
		print("Corrupted: ", chosen)
		element_corrupted.emit(chosen)

	_save_data()

func is_element_broken(element_name: String) -> bool:
	return element_name in broken_elements

func get_durability(element_name: String) -> float:
	return durability.get(element_name, MAX_DURABILITY)
func is_element_low(element_name: String) -> bool:
	var value: float = get_durability(element_name)
	return value > 0.0 and value < LOW_DURABILITY_THRESHOLD

func fix_element(element_name: String) -> void:
	durability[element_name] = MAX_DURABILITY
	broken_elements.erase(element_name)
	_save_data()

func reset() -> void:
	hit_count = 0
	broken_elements.clear()
	_init_durability()
	_save_data()

func reset_hit_count() -> void:
	hit_count = 0

func _save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {"durability": durability, "broken_elements": broken_elements}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var content: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed and parsed.has("durability"):
		for element_name in parsed["durability"]:
			durability[element_name] = parsed["durability"][element_name]

	if parsed and parsed.has("broken_elements"):
		broken_elements.clear()
		for element_name in parsed["broken_elements"]:
			broken_elements.append(element_name)
