extends Sprite2D

signal cartridge_inserted(cartridge_type: String)
signal cartridge_ejected(cartridge_type: String)

var is_slot_occupied: bool = false
var current_cartridge: Area2D = null

func _ready() -> void:
	$Slot.input_event.connect(_on_slot_input_event)

func get_insert_position() -> Vector2:
	return $Slot/InsertPosition.global_position

func try_insert(cartridge: Area2D) -> bool:
	if is_slot_occupied:
		return false

	var overlapping: Array[Area2D] = $Slot.get_overlapping_areas()
	if not overlapping.has(cartridge):
		return false

	is_slot_occupied = true
	current_cartridge = cartridge
	return true

func notify_inserted(cartridge_type: String) -> void:
	cartridge_inserted.emit(cartridge_type)

func _on_slot_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_slot_occupied and current_cartridge != null:
			eject_cartridge()

func eject_cartridge() -> void:
	var cartridge_type: String = current_cartridge.cartridge_type
	current_cartridge.reset_to_tray()

	is_slot_occupied = false
	current_cartridge = null

	cartridge_ejected.emit(cartridge_type)
