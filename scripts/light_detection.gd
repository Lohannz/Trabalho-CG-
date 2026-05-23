extends SpotLight3D

@onready var area = $Area3D
@onready var ray = $RayCast3D

var Objects = []

func _process(delta: float) -> void:
	for obj in Objects:
		_handle_light(obj)
	pass

func _handle_light(body):
	var target = body.global_position
	ray.target_position = ray.to_local(target)
	ray.force_raycast_update()
	var cObj = ray.get_collider()
	
	var meshInstance = body.get_parent()
	if meshInstance is not MeshInstance3D:
		return
	var material = meshInstance.get_active_material(0).duplicate()
	meshInstance.set_surface_override_material(0, material)
	
	if cObj == body:
		material.albedo_color = Color(1, 1, 1, 1)
		print("UUUUUUUUUUUUUUUUUUUUUUu")
		
	else:
		material.albedo_color = Color(1, 0, 0, 1)
		print("AAAAAAAAAAAAAAAAAAAAAAAA")

	
func _on_area_3d_body_entered(body):
	if body.is_in_group("light_sensitive"):
		Objects.append(body)
