extends Camera3D
@export var offset := 15.0
@export var lerp_speed := 3.0
@onready var player : CharacterBody3D = get_tree().current_scene.get_node("player")

signal orientation_changed(newOrientation)

var _orientation : Basis
var changed

func _ready() -> void:
	_orientation = global_transform.basis
	position = _orientation.z * offset
	
func _change_orientation(normal: Vector3):
	var up = _orientation.y
	var right = _orientation.x
	var orthogonality = normal.dot(right)
	print(orthogonality)
	
	if is_equal_approx(orthogonality, -1.0):
		_orientation = _orientation.rotated(up, deg_to_rad(-90.0))
		player.rotate(up, deg_to_rad(-90.0))

	elif is_equal_approx(orthogonality, 1.0):
		_orientation = _orientation.rotated(up, deg_to_rad(90.0))
		player.rotate(up, deg_to_rad(90.0))
	# Recalcula aqui para evitar calculos desnecessarios no início
	orthogonality = normal.dot(up)
	
	if is_equal_approx(orthogonality, -1.0):
		_orientation = _orientation.rotated(right, deg_to_rad(90.0))
		player.rotate(right, deg_to_rad(90.0))
		
	elif is_equal_approx(orthogonality, 1.0):
		_orientation = _orientation.rotated(right, deg_to_rad(-90.0))
		player.rotate(right, deg_to_rad(-90.0))
		
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

func _process(delta: float) -> void:
	var target = player.global_position + _orientation.z * offset
	global_position = global_position.lerp(target, lerp_speed * delta)
