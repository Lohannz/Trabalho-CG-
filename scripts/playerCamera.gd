extends Camera3D

@export var offset_Z := 15.0
@export var offset_Y := 15.0
@export var lerp_speed := 3.0
@export var tilt_degrees := -50.0

@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")

# camera livre
@export var velocidade_camera := 40.0
@export var sensibilidade_mouse := 0.003
var _saved_position : Vector3
var _saved_basis : Basis

var yaw := 0.0
var pitch := 0.0
var camera_livre := false

signal orientation_changed(newOrientation)

var _orientation : Basis
var changed

var game_basis : Basis:
	get: return _orientation

func _ready() -> void:
	set_process_input(true)
	_orientation = global_transform.basis
	position = _orientation.z * offset_Z
	position += _orientation.y * offset_Y

func _get_visual_basis(base: Basis) -> Basis:
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
	tween.tween_property(self, "global_position", target, 1.5)

	var target_visual_basis = _get_visual_basis(Transform3D().looking_at(-_orientation.z, _orientation.y).basis)
	tween.parallel().tween_method(_tween_look_at,global_transform.basis,target_visual_basis,1.5)

	if changed: emit_signal("orientation_changed", _orientation)
	await tween.finished

	global_position = (player.global_position + _orientation.z * offset_Z + _orientation.y * offset_Y)

func _tween_look_at(basis: Basis) -> void:
	global_transform.basis = basis

func _input(event):
	if not camera_livre:
		return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * sensibilidade_mouse
		pitch -= event.relative.y * sensibilidade_mouse
		pitch = clamp(pitch, -PI/2, PI/2)
		global_transform.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
		get_viewport().set_input_as_handled()
		
func _process(delta: float) -> void:
	# Verifica se o player soltou a camera 'q'
	if Input.is_action_just_pressed("camera_livre") and not player.using_portal:
		camera_livre = !camera_livre
		if camera_livre :
			_saved_position = global_position
			_saved_basis = global_transform.basis
			yaw = global_rotation.y
			pitch = global_rotation.x
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
			player.FREEZE = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
			player.FREEZE = false
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(self, "global_position", _saved_position, 0.5)
			tween.parallel().tween_method(_tween_look_at, global_transform.basis, _saved_basis, 0.5)

	# Camera fixada no player				
	if !camera_livre:
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

		if not player.FREEZE:
			var target = player.global_position + _orientation.z * offset_Z + _orientation.y * offset_Y
			global_position = global_position.lerp(target, lerp_speed * delta)

			var look = Transform3D().looking_at(player.global_position - global_position, _orientation.y)
			global_transform.basis = _get_visual_basis(look.basis)
			
	elif camera_livre:
		var dir := Vector3.ZERO
		var basis = global_transform.basis
		
		if Input.is_action_pressed("move_forward"):
			dir -= basis.z
		if Input.is_action_pressed("move_back"):
			dir += basis.z
		if Input.is_action_pressed("move_left"):
			dir -= basis.x
		if Input.is_action_pressed("move_right"):
			dir += basis.x
		if Input.is_action_pressed("action_jump"):
			dir += basis.y
		if Input.is_action_pressed("shift"):
			dir -= basis.y	
		
		if dir != Vector3.ZERO:
			global_position += dir.normalized() * velocidade_camera * delta
