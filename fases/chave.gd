class_name Chave
extends Node3D

static var chaves_seguindo: int = 0
static var _fila: Array[Chave] = []

@onready var mesh: MeshInstance3D = $Cubo_001
@onready var area: Area3D = $Area3D
@onready var collision: CollisionShape3D = $Area3D/CollisionShape3D
@onready var camera: Camera3D = get_tree().current_scene.get_node("Camera3D")

@export var delay: float = 5.0

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

		area.monitoring = false

		_queue_index = _fila.size()
		_fila.append(self)
		chaves_seguindo += 1

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

static func entregar_chaves(quantidade: int) -> int:
	var entregues := 0

	while entregues < quantidade and !_fila.is_empty():
		var chave = _fila.pop_front()

		if is_instance_valid(chave):
			chave._entregar()
			entregues += 1

	_reordenar_fila()
	chaves_seguindo = max(chaves_seguindo - entregues, 0)

	return entregues

func _entregar() -> void:
	_following = false
	_player = null
	queue_free()

static func _reordenar_fila() -> void:
	for i in _fila.size():
		if is_instance_valid(_fila[i]):
			_fila[i]._queue_index = i
