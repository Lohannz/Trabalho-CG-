extends Camera3D
@export var offset := 25.0
@export var lerp_speed := 3.0
@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")
signal orientation_changed(newOrientation)

var _orientation : Basis
var changed
func _ready() -> void:
	_orientation = global_transform.basis
	position = _orientation.z * offset

func _change_orientation(new_orientation : String):
	var up = _orientation.y
	var right = _orientation.x


	if new_orientation == "right":
		_orientation = _orientation.rotated(up, deg_to_rad(90.0))
		
	elif new_orientation == "left":
		_orientation = _orientation.rotated(up, deg_to_rad(-90.0))

	elif new_orientation == "up":
		_orientation = _orientation.rotated(right, deg_to_rad(-90.0))

	elif new_orientation == "down":
		_orientation = _orientation.rotated(right, deg_to_rad(90.0))

	changed = true
	_orientation = _orientation.orthonormalized()
	
	# Anima a transição para a nova posição
	var target = player.global_position + _orientation.z * offset
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target, 0.6)
	
	# Atualiza o look_at gradualmente via callback
	tween.tween_method(_tween_look_at, global_transform.basis, 
		Transform3D().looking_at(-_orientation.z, _orientation.y).basis, 0.6)
	
	if changed:
		emit_signal("orientation_changed", _orientation)

func _tween_look_at(basis: Basis) -> void:
	global_transform.basis = basis

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
