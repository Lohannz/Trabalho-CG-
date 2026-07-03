extends Camera3D

@export var offset_Z := 15.0
@export var offset_Y := 15.0
@export var lerp_speed := 3.0
@export var tilt_degrees := -50.0

@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")

# camera livre
@export var camera_speed := 40.0
@export var mouse_sensibility := 0.003
var _saved_position : Vector3
var _saved_basis : Basis

var yaw := 0.0
var pitch := 0.0
var free_cam := false

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

var _free_cam_basis : Basis  

func _input(event):
	if not free_cam: return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensibility
		pitch -= event.relative.y * mouse_sensibility
		pitch = clamp(pitch, -PI/2, PI/2)
		
		var yaw_basis = _saved_basis.rotated(_orientation.y, yaw)
		global_transform.basis = yaw_basis.rotated(yaw_basis.x, pitch).orthonormalized()
		get_viewport().set_input_as_handled()
		
func _process(delta: float) -> void:
	# Verifica se o player soltou a camera 'q'
	if Input.is_action_just_pressed("free_cam") and not player.USING_PORTAL:
		free_cam = !free_cam
		if free_cam:
			_saved_position = global_position
			_saved_basis = global_transform.basis
			yaw = 0.0   # delta a partir da basis salva
			pitch = 0.0
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			player.FREEZE = true
			player.input.DISABLED = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
			player.FREEZE = false
			player.input.DISABLED = false
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(self, "global_position", _saved_position, 0.5)
			tween.parallel().tween_method(_tween_look_at, global_transform.basis, _saved_basis, 0.5)

	# Camera fixada no player				
	if !free_cam:
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
			
	elif free_cam:
		var dir := Vector3.ZERO
		var basis = global_transform.basis  # usa a basis atual da câmera livre
		
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
			global_position += dir.normalized() * camera_speed * delta

func wait_camera_arrives() -> void:
	var target = player.global_position + _orientation.z * offset_Z + _orientation.y * offset_Y
	while global_position.distance_to(target) < 0.05:
		await get_tree().process_frame
