extends Node3D

@export var speed := 0.5
@export var reset_offset := -89.0   
@export var limit_x := 100.0         

var meshes := []
var camera: Camera3D

func _ready():
	camera = get_viewport().get_camera_3d()
	
	for child in get_children():
		if child is Node3D:
			meshes.append(child)

func _process(delta):
	var cam_x = camera.global_transform.origin.x

	for mesh in meshes:
		mesh.translate(Vector3(speed * delta, 0, 0))

		if mesh.global_transform.origin.x > cam_x + limit_x:
			var pos = mesh.global_transform.origin
			pos.x = cam_x + reset_offset
			mesh.global_transform.origin = pos
