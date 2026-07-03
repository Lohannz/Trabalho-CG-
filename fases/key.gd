class_name Key
extends Node3D

@onready var mesh: MeshInstance3D = $Cubo_001
@onready var area: Area3D = $Area3D
@onready var collision: CollisionShape3D = $Area3D/CollisionShape3D
@onready var camera: Camera3D = get_tree().current_scene.get_node("Camera3D")
@export var delay: float = 5.0

static var keys: Array[Key] = []

var _player: CharacterBody3D = null
var _following := false
var _queue_index := 0
var _time_elapsed := 0.0
var _smoothed_visual := Vector3.ZERO

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	_time_elapsed = randf_range(0.0, 10.0)

func _on_body_entered(body: Node3D) -> void:
	if _following:
		return

	if body is CharacterBody3D and not body.DYING:
		_player = body
		_following = true
		collision.set_deferred("monitoring", false)
		
		_queue_index = keys.size()
		keys.append(self)

func _process(delta: float) -> void:
	mesh.rotate_y(deg_to_rad(60) * delta)
	_time_elapsed += delta

	if !_following or !is_instance_valid(_player):
		return

	var base_height = _player.up * 5.0
	var camera_backward = camera._orientation.z

	_smoothed_visual = _smoothed_visual.lerp(_player._visual_direction, 5.0 * delta)

	var base_back = -_smoothed_visual * 4.5 * (0.8 * (_queue_index + 1))
	var queue_offset = camera_backward * (0.6 * _queue_index + 1) + base_back

	var wave = Vector3(
		sin(_time_elapsed * 3.0 + _queue_index) * 0.1,
		cos(_time_elapsed * 2.5 + _queue_index) * 0.1,
		0.0
	)

	var target = _player.global_position + base_height + queue_offset + wave
	global_position = global_position.lerp(target, delay * delta)

static func give_keys(amount: int) -> void:
	var keys_to_remove: Array[Key] = []
	
	var limit = min(amount, keys.size())
	for i in range(limit):
		keys_to_remove.append(keys[i])
		
	for key in keys_to_remove:
		if is_instance_valid(key):
			key._give()
			keys.erase(key)
		
	for i in range(keys.size()):
		if is_instance_valid(keys[i]):
			keys[i]._queue_index = i

func _give() -> void:
	_following = false
	_player = null
	queue_free()
