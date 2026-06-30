extends SpotLight3D

@onready var area: Area3D = $Area3D
var exceptions: Array

var active_rays: Dictionary = {}

# Cores de objetos iluminados/obscurecidos
const ICE_LIT_BASE = Color(0.3, 0.7, 1.0, 0.15)
const ICE_LIT_FRES = Color(0.0, 0.35, 0.6, 0.3)

const ICE_DARK_BASE = Color(0.0, 0.75, 0.95, 1.0)
const ICE_DARK_FRES = Color(0.0, 0.7, 1.6, 1.0)

func _ready() -> void:
	exceptions = get_tree().get_nodes_in_group("invWall")
	await get_tree().physics_frame
	for body in area.get_overlapping_bodies():
		_register_body(body)

func _physics_process(_delta: float) -> void:
	for body in active_rays.keys():
		var ray = active_rays.get(body)
		if not is_instance_valid(ray): 
			_restore_body(body)
		else:
			ray.global_position = global_position
			ray.target_position = ray.to_local(body.global_position)
			
			_handle_light(body, ray)

func _handle_light(body: StaticBody3D, ray: RayCast3D) -> void:
	if body.get_collision_layer_value(4):
		ray.force_raycast_update()
		var collider = ray.get_collider()
		if collider == body:
			ray.debug_shape_custom_color = Color(0.095, 1.054, 0.0, 1.0)
			if body.get_collision_layer_value(1):
				_melt_body(body)
		else:
			ray.debug_shape_custom_color = Color(0.904, 0.071, 0.0, 1.0)
			if not body.get_collision_layer_value(1):
				_freeze_body(body)

func _register_body(body: Node3D) -> void:
	if body is StaticBody3D and body.is_in_group("lightSensitive") and not active_rays.has(body):
		
		# Duplicação para evitar conflito.
		if body.get_collision_layer_value(4):
			var mesh = body.get_parent() as MeshInstance3D
			if mesh and mesh.material_override is ShaderMaterial:
				if not mesh.material_override.resource_local_to_scene:
					mesh.material_override = mesh.material_override.duplicate()
				
		var ray = RayCast3D.new()
		add_child(ray)
		ray.enabled = true
		ray.hit_from_inside = false
		ray.hit_back_faces = true
		ray.collide_with_areas = false
		ray.collide_with_bodies = true
		ray.exclude_parent = true
		ray.debug_shape_custom_color = Color(0.095, 1.054, 0.0, 1.0)
		
		for exception in exceptions:
			ray.add_exception(exception)
			
		for i in range(1, 5):
			ray.set_collision_mask_value(i, true)

		active_rays[body] = ray
		
func _on_area_3d_body_entered(body: Node3D) -> void:
	_register_body(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	_remove_ray(body)

func _remove_ray(body: Node3D) -> void:
	if active_rays.has(body):
		var ray = active_rays[body]
		await get_tree().physics_frame
		if is_instance_valid(ray):
			ray.queue_free()

func _restore_body(body: Node3D):
	if body.get_collision_layer_value(4):
		_freeze_body(body)
	active_rays.erase(body)

func _freeze_body(body: Node3D):
	var material : ShaderMaterial = _get_shader_material(body)
	if material:
		_apply_material_colors(material, ICE_DARK_BASE, ICE_DARK_FRES)
		body.set_collision_layer_value(1, true)
		body.set_collision_layer_value(2, true)
	
func _melt_body(body: Node3D):
	var material : ShaderMaterial = _get_shader_material(body)
	if material:
		_apply_material_colors(material, ICE_LIT_BASE, ICE_LIT_FRES)
		body.set_collision_layer_value(1, false)
		body.set_collision_layer_value(2, false)

func _get_shader_material(body: Node3D) -> ShaderMaterial:
	var material = null
	var mesh = body.get_parent() as MeshInstance3D
	if mesh: material = mesh.material_override as ShaderMaterial
	return material

func _apply_material_colors(material: ShaderMaterial, base_color: Color, fres_color: Color) -> void:
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("fres_color", fres_color)
