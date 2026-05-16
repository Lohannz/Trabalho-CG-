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
		_orientation = _orientation.rotated(up,deg_to_rad(90.0))
		changed2 = true
		
	elif new_orientation == "left":
		_orientation = _orientation.rotated(up,deg_to_rad(-90.0))
		changed2 = true
		
	elif new_orientation == "up":
		_orientation = _orientation.rotated(right,deg_to_rad(-90.0))
		changed = true
		changed2 = true

	elif new_orientation == "down":
		_orientation = _orientation.rotated(right,deg_to_rad(90.0))
		changed = true
		changed2 = true
	
	_orientation = _orientation.orthonormalized()
	
	if(changed):
		emit_signal("up_changed",_orientation.y)
	if(changed2):
		emit_signal("horizontal_changed", _orientation.x, _orientation.y)
	

# Vai mudar mesh, collision, etc do player, menos a camera(TEM QUE TIRAR ELA DO PLAYER)
func _change_player_orientation(vetor : Vector3, angle):
	player.rotate(vetor, deg_to_rad(angle))

func _process(delta: float) -> void:
	var up = _orientation.y
	var right = _orientation.x
	
	# Atualiza a orientação trocando, igual antes, mas simples.
	if Input.is_action_just_pressed("ui_right"):
		_change_orientation("right")
		_change_player_orientation(up, 90)

	if Input.is_action_just_pressed("ui_left"):
		_change_orientation("left")
		_change_player_orientation(up, -90)
		
	if Input.is_action_just_pressed("ui_up"):
		_change_orientation("up")
		_change_player_orientation(right, -90)
		
	if Input.is_action_just_pressed("ui_down"):
		_change_orientation("down")
		_change_player_orientation(right, 90)


	var target = player.global_position + _orientation.z * offset
	global_position = global_position.lerp(target, lerp_speed * delta)
	# sempre olha para o jogador e mantem o up na orientacao certa
	look_at(player.global_position, _orientation.y)
