extends Camera3D
@onready var player : CharacterBody3D = get_parent()
@export var offset := 25.0
@export var lerp_speed := 3.0
signal up_changed(newUp)

enum State {FRONT, MIDDLE, BACK}
var state : State = State.FRONT
@export var depthMiddle = 4.0
@export var depthFront = 1.0

var _orientation : Basis
var changed
var initial_position = 18
func _ready() -> void:
	_orientation = global_transform.basis

func _change_orientation(new_orientation : String):
	var up = _orientation.y
	var right = _orientation.x
	var changed = false
	
	if new_orientation == "right":
		_orientation = _orientation.rotated(up,deg_to_rad(90.0))
		
	elif new_orientation == "left":
		_orientation = _orientation.rotated(up,deg_to_rad(-90.0))
		
	elif new_orientation == "up":
		_orientation = _orientation.rotated(right,deg_to_rad(-90.0))
		changed = true

	elif new_orientation == "down":
		_orientation = _orientation.rotated(right,deg_to_rad(90.0))
		changed = true
	
	_orientation = _orientation.orthonormalized()
	
	if(changed):
		emit_signal("up_changed",_orientation.y)
		
func _process(delta: float) -> void:
	
	_handle_states()
	_handle_movement()
	# Atualiza a orientação trocando, igual antes, mas simples.
	if Input.is_action_just_pressed("ui_right"):
		_change_orientation("right")

	if Input.is_action_just_pressed("ui_left"):
		_change_orientation("left")
		
	if Input.is_action_just_pressed("ui_up"):
		_change_orientation("up")

	if Input.is_action_just_pressed("ui_down"):
		_change_orientation("down")
	# atualiza a posicao da camera
	look_at(get_parent().global_position, _orientation.y)

func _get_depth():
	var to_player = abs(player.global_position - global_position)
	return to_player.dot(-_orientation.z)
		
## Vai verificar a posição do player e atualizar o estado da câmera
func _handle_states():
	var depth = _get_depth()
	if depth < depthFront:
		state = State.FRONT
	elif depth < depthMiddle:
		state = State.MIDDLE
	else:
		state = State.BACK
		
## Verifica o estado e faz a transição para o proximo estado(se tiver)
func _handle_movement():
	match state:
		State.FRONT:
			position = position.lerp(_orientation.z * offset, lerp_speed * get_process_delta_time())
		State.MIDDLE:
			var target = _orientation.z * offset + _orientation.y * 3.0  # sobe um pouco
			position = position.lerp(target, lerp_speed * get_process_delta_time())
		State.BACK:
			var target = _orientation.z * offset + _orientation.y * 6.0  # sobe mais
			position = position.lerp(target, lerp_speed * get_process_delta_time())
