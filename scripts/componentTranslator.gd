extends Node3D

@export var speed := 3.0

func _process(delta):
	rotate_object_local(Vector3.UP, speed * delta)
