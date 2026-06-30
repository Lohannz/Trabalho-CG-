extends Node3D
@export var angle := 0.2
func _process(_delta: float) -> void:
	rotate(Vector3(0,1,0), deg_to_rad(angle))
