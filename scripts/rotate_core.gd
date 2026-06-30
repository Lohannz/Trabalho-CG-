extends Node3D

func _process(_delta: float) -> void:
	rotate(Vector3(0,1,0), deg_to_rad(0.2))
