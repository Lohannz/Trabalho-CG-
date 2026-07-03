class_name Chave
extends Area3D

# Contador/fila próprios da chave, sem nenhuma dependência do Collectable.
static var chaves_seguindo: int = 0
static var _fila: Array[Chave] = []

# Ajuste os nomes abaixo para os nós reais dentro da cena da chave.
@onready var mesh = $MeshInstance3D
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

		collision.set_deferred("monitoring", false)
		_queue_index = _fila.size()
		_fila.append(self)
		chaves_seguindo += 1

func _process(delta: float) -> void:
	mesh.rotate(Vector3.UP, deg_to_rad(60) * delta)
	_time_elapsed += delta
	if _following and is_instance_valid(_player):
		# Sem checagem de DYING (não reseta ao morrer) e sem checagem de
		# USING_PORTAL (não é coletada pelo portal). A chave só sai de cena
		# quando a porta chama Chave.entregar_chaves().
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

# Chamado pela porta (PortaChaves.colocar_chaves) quando o jogador interage.
# Retorna quantas chaves realmente foram entregues.
static func entregar_chaves(quantidade: int) -> int:
	var entregues := 0
	while entregues < quantidade and _fila.size() > 0:
		var chave: Chave = _fila.pop_front()
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
