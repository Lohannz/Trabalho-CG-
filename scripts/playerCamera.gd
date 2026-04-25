extends Camera3D
@export var offset := 25.0
@export var lerp_speed := 3.0
signal up_changed(newUp)

var _orientation : Basis
var changed
func _ready() -> void:
	_orientation = global_transform.basis
	position = _orientation.z * offset

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
		
	
	
func _process(_delta: float) -> void:
	
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
	position = position.lerp(_orientation.z * offset, lerp_speed * _delta)

	# sempre olha para o jogador e mantem o up na orientacao certa
	look_at(get_parent().global_position, _orientation.y)
