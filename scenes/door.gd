extends Node3D
class_name Door

@onready var area: Area3D = $PortalArea
@onready var lights: Array[MeshInstance3D] = [
	$Luzes/MeshInstance3D,
	$Luzes/MeshInstance3D2,
	$Luzes/MeshInstance3D3,
	$Luzes/MeshInstance3D4,
]

static var total = 4
var _placed_keys: int = 0
var _player: CharacterBody3D = null

func _ready() -> void:
	_update_lights()
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)

func _on_area_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		body.PORTAL_UI.visible = true
		_player = body

func _on_area_body_exited(body: Node3D) -> void:
	if body == _player:
		body.PORTAL_UI.visible = false
		_player = null

func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return
	
	if event.is_action_pressed("ui_F"):
		place_keys()

func place_keys() -> void:
	if _placed_keys >= total:
		open_door()
		return

	var disponible: int = Key.keys.size()
	if disponible <= 0:
		return

	var resting: int = total - _placed_keys
	var used: int = min(disponible, resting)
	Key.give_keys(used) 
	
	_placed_keys += used
	_update_lights()
	
	if _placed_keys >= total:
		open_door()

func _update_lights() -> void:
	var total_placed: bool = _placed_keys >= total

	for i in lights.size():
		var material := lights[i].get_active_material(0) as StandardMaterial3D
		if material == null:
			continue

		material.emission_enabled = i < _placed_keys
		material.emission_energy_multiplier = 16.0 if i < _placed_keys else 0.0

		if total_placed:
			material.emission = Color.YELLOW
		else:
			material.emission = Color.RED

func open_door() -> void:
	if _player and _player.has_method("use_portal"):
		_player.use_portal(area)
