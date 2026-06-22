extends SpotLight3D
@onready var area = $Area3D

var active_rays: Dictionary = {}

# Cores de objetos iluminados/obscurecido
const ICE_LIT_BASE = Color(0.3, 0.7, 1.0, 0.15)
const ICE_LIT_FRES = Color(0.0, 0.35, 0.6, 0.3)

const ICE_DARK_BASE = Color(0.0, 0.75, 0.95, 1.0)
const ICE_DARK_FRES = Color(0.0, 0.7, 1.6, 1.0)

func _ready() -> void:
	await get_tree().physics_frame
	for body in area.get_overlapping_bodies():
		_register_body(body)

func _process(_delta: float) -> void:
	for body in active_rays.keys():
		if not is_instance_valid(body):
			_remove_ray(body)
		_handle_light(body)

func _handle_light(body: Node3D) -> void:
	var parent = body.get_parent()
	if not (parent is MeshInstance3D and parent.get_layer_mask_value(4)): return
	
	var material = parent.material_override as ShaderMaterial
	if not material: return

	var ray: RayCast3D = active_rays[body]
	
	ray.target_position = ray.to_local(body.global_position)
	ray.force_raycast_update()
	
	var collider = ray.get_collider()

	if collider == body:
		_apply_material_colors(material, ICE_LIT_BASE, ICE_LIT_FRES)
		body.set_collision_layer_value(1, false)
	else:
		_apply_material_colors(material, ICE_DARK_BASE, ICE_DARK_FRES)
		body.set_collision_layer_value(1, true)

func _register_body(body: Node3D) -> void:
	if body.is_in_group("lightSensitive") and not active_rays.has(body):
		var ray = RayCast3D.new()
		add_child(ray)
		print(body.get_parent().name)
		# Configurações iniciais do Raycast temporário.
		ray.enabled = true
		ray.hit_from_inside = false
		ray.hit_back_faces = true
		ray.collide_with_areas = false
		ray.collide_with_bodies = true
		ray.exclude_parent = true
		
		for i in range(1, 5):
			ray.set_collision_mask_value(i, true)
		active_rays[body] = ray
	
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	_register_body(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if active_rays.has(body):
		var parent = body.get_parent()
		if parent is MeshInstance3D and parent.get_layer_mask_value(4):
			var material = parent.material_override as ShaderMaterial
			if material: 
				_apply_material_colors(material, ICE_DARK_BASE, ICE_DARK_FRES)
				body.set_collision_layer_value(1, true)
		_remove_ray(body)

func _remove_ray(body: Node3D) -> void:
	if active_rays.has(body):
		var ray = active_rays[body]
		active_rays.erase(body)
		if is_instance_valid(ray):
			ray.queue_free()

func _apply_material_colors(material: ShaderMaterial, base_color: Color, fres_color: Color) -> void:
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("fres_color", fres_color)
