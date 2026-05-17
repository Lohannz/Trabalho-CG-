extends Camera3D
@export var offset := 25.0
@export var lerp_speed := 3.0
@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")
signal up_changed(newUp)
signal horizontal_changed

var _orientation : Basis
var changed
func _ready() -> void:
	_orientation = global_transform.basis
	position = _orientation.z * offset

func _change_orientation(new_orientation : String):
	var up = _orientation.y
	var right = _orientation.x
	var changed = false
	var changed2 = false
	
	if new_orientation == "right":
		_orientation = _orientation.rotated(up, deg_to_rad(90.0))
		_change_player_orientation(up, 90)
		changed2 = true
	elif new_orientation == "left":
		_orientation = _orientation.rotated(up, deg_to_rad(-90.0))
		_change_player_orientation(up, -90)
		changed2 = true
	elif new_orientation == "up":
		_orientation = _orientation.rotated(right, deg_to_rad(-90.0))
		_change_player_orientation(right, -90)
		changed = true
		changed2 = true
	elif new_orientation == "down":
		_orientation = _orientation.rotated(right, deg_to_rad(90.0))
		_change_player_orientation(right, 90)
		changed = true
		changed2 = true
	
	_orientation = _orientation.orthonormalized()
	
	var target = player.global_position + _orientation.z * offset
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target, 0.6)
	
	tween.tween_method(_tween_look_at, global_transform.basis, 
		Transform3D().looking_at(-_orientation.z, _orientation.y).basis, 0.6)
	
	if changed:
		emit_signal("up_changed", _orientation.y)
	if changed2:
		emit_signal("horizontal_changed", _orientation.x, _orientation.y)

func _tween_look_at(basis: Basis) -> void:
	global_transform.basis = basis

func _change_player_orientation(vetor : Vector3, angle):
	player.rotate(vetor, deg_to_rad(angle))

func _process(delta: float) -> void:
	var up = _orientation.y
	var right = _orientation.x
	
	# Atualiza a orientação trocando, igual antes, mas simples.
	if Input.is_action_just_pressed("ui_right"):
		_change_orientation("right")

	if Input.is_action_just_pressed("ui_left"):
		_change_orientation("left")
		
	if Input.is_action_just_pressed("ui_up"):
		_change_orientation("up")
		
	if Input.is_action_just_pressed("ui_down"):
		_change_orientation("down")


	var target = player.global_position + _orientation.z * offset
	global_position = global_position.lerp(target, lerp_speed * delta)
