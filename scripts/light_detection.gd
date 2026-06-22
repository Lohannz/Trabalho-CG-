extends SpotLight3D

@onready var area = $Area3D
@onready var ray = $RayCast3D

var detected_objects: Array[Node3D] = []

func _process(delta: float) -> void:
	for body in detected_objects:
		_handle_light(body)

func _handle_light(body):
	ray.target_position = ray.to_local(body.global_position)
	ray.force_raycast_update()
	
	var collider = ray.get_collider()
	var mesh = body.get_parent() as MeshInstance3D
	
	if body in detected_objects:
		var material = mesh.material_override as ShaderMaterial
		var target = (collider == body) or (collider != null and collider == mesh.get_parent())
		
		if target:
			material.set_shader_parameter("base_color", Color(0.0, 0.7, 1.6, 1.0))
		else:
			material.set_shader_parameter("base_color", Color(0.0, 0.7, 1.6, 0.06))
		
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("lightSensitive"):
		if not detected_objects.has(body):
			detected_objects.append(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if detected_objects.has(body):
		detected_objects.erase(body)
