extends Area3D

static var collected: int = 0
static var _following_counter: int = 0 

@onready var mesh = $mesh_livro
@onready var collision = $CollisionShape3D
@onready var camera: Camera3D = get_tree().current_scene.get_node("Camera3D")

@export var delay: float = 5.0 
@export var displacement: Vector3 = Vector3(0, 1.2, 0) 

var _player: CharacterBody3D = null
var _following: bool = false

var _initial_position: Vector3
var _queue_index: int = 0
var _time_elapsed: float = 0.0
var _smoothed_visual: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_initial_position = global_position 
	_time_elapsed = randf_range(0.0, 10.0)

func _on_body_entered(body: Node3D) -> void:
	if _following: return
	if body is CharacterBody3D and not body.DYING:
		_player = body
		_following = true
		collision.disabled = true
	
		_queue_index = _following_counter
		_following_counter += 1

func _process(delta: float) -> void:
	rotate(camera._orientation.y, deg_to_rad(1))
	_time_elapsed += delta

	if _following and _player != null:
		if _player.DYING:
			_reset_item()
			return

		var base_height = _player.up * 5.0
		var camera_backward = camera._orientation.z
		
		_smoothed_visual = _smoothed_visual.lerp(_player._visual_direction, 5.0 * delta)
		var base_back = (-_smoothed_visual * 4.5 * (0.8 * (_queue_index + 1)))
		var queue_offset = (camera_backward * (0.6 * _queue_index + 1)) + base_back
	
		var wave_bobbing = Vector3(
			sin(_time_elapsed * 3.0 + _queue_index) * 0.1,
			cos(_time_elapsed * 2.5 + _queue_index) * 0.1,
			0)
		
		var target_pos = _player.global_position + base_height + queue_offset + wave_bobbing
		global_position = global_position.lerp(target_pos, delay * delta)
		
		if _player.USING_PORTAL: 
			_collect()

func _collect() -> void:

	if _following: _following_counter = max(0, _following_counter - 1)
	collected += 1
	
	_following = false
	_player = null
	
	get_tree().call_group("contador_ui", "atualizar", collected)
	queue_free()

func _reset_item() -> void:
	if !_following: return
	_following = false

	if _following_counter > 0:
		_following_counter -= 1

	_queue_index = 0
	if is_instance_valid(_player): await _player.transition.animation_finished	
	if !is_instance_valid(self): return

	_player = null
	global_position = _initial_position
	mesh.visible = true
	collision.disabled = false
