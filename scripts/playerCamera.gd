extends Camera3D

@export var offset_Z := 15.0
@export var offset_Y := 15.0
@export var lerp_speed := 3.0
@export var tilt_degrees := -50.0  # inclinação visual — ajuste aqui

@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")

signal orientation_changed(newOrientation)

var _orientation : Basis  # basis puro de jogo, NUNCA tem tilt
var changed

# Propriedade pública: o player lê isso em vez de global_transform.basis
var game_basis : Basis:
	get:
		return _orientation

func _ready() -> void:
	_orientation = global_transform.basis
	position = _orientation.z * offset_Z
	position += _orientation.y * offset_Y

func _get_visual_basis(base: Basis) -> Basis:
	# Aplica tilt apenas no eixo X local (inclinação para baixo)
	var tilt = Basis(base.x, deg_to_rad(tilt_degrees))
	return base * tilt

func _change_orientation(normal: Vector3):
	var up = _orientation.y
	var right = _orientation.x
	var orthogonality = normal.dot(right)

	if is_equal_approx(orthogonality, -1.0):
		_orientation = _orientation.rotated(up, deg_to_rad(-90.0))
		player.rotate(up, deg_to_rad(-90.0))
	elif is_equal_approx(orthogonality, 1.0):
		print("aq")
		_orientation = _orientation.rotated(up, deg_to_rad(90.0))
		player.rotate(up, deg_to_rad(90.0))

	orthogonality = normal.dot(up)

	if is_equal_approx(orthogonality, -1.0):
		_orientation = _orientation.rotated(right, deg_to_rad(90.0))
		player.rotate(right, deg_to_rad(90.0))
	elif is_equal_approx(orthogonality, 1.0):
		_orientation = _orientation.rotated(right, deg_to_rad(-90.0))
		player.rotate(right, deg_to_rad(-90.0))

	changed = true
	_orientation = _orientation.orthonormalized()

	var target = player.global_position + _orientation.z * offset_Z + _orientation.y * offset_Y
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target, 1.5) # aumentei kkkk

	# Anima o basis visual (com tilt) — _orientation continua intocado
	var target_visual_basis = _get_visual_basis(
		Transform3D().looking_at(-_orientation.z, _orientation.y).basis
	)
	tween.tween_method(_tween_look_at, global_transform.basis, target_visual_basis, 0.6)

	if changed:
		emit_signal("orientation_changed", _orientation)  # emite sempre sem tilt

func _tween_look_at(basis: Basis) -> void:
	global_transform.basis = basis

func _process(delta: float) -> void:
	var up = _orientation.y
	var right = _orientation.x
	
	if Input.is_action_just_pressed("ui_right"):
		_change_orientation(right)

	if Input.is_action_just_pressed("ui_left"):
		_change_orientation(-right)
		
	if Input.is_action_just_pressed("ui_up"):
		_change_orientation(up)
		
	if Input.is_action_just_pressed("ui_down"):
		_change_orientation(-up)

	
	var target = player.global_position + _orientation.z * offset_Z + _orientation.y * offset_Y
	global_position = global_position.lerp(target, lerp_speed * delta)

	# Aplica tilt visual continuamente sem tocar em _orientation
	var look = Transform3D().looking_at(player.global_position - global_position, _orientation.y)
	global_transform.basis = _get_visual_basis(look.basis)
