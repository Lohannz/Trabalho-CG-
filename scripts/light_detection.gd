extends Light3D

@onready var main : Node3D = get_tree().current_scene
@export var area: Area3D
var exceptions: Array

var active_rays: Dictionary = {}

# Cores de objetos iluminados/obscurecidos
const ICE_LIT_BASE = Color(0.3, 0.7, 1.0, 0.15)
const ICE_LIT_FRES = Color(0.0, 0.35, 0.6, 0.3)

const ICE_DARK_BASE = Color(0.0, 0.75, 0.95, 1.0)
const ICE_DARK_FRES = Color(0.0, 0.7, 1.6, 1.0)

func _ready() -> void:
	exceptions = get_tree().get_nodes_in_group("invWall")
	exceptions.append(get_tree().current_scene.get_node("player"))
	
	await get_tree().physics_frame
	for body in area.get_overlapping_bodies():
		_register_body(body)

func _physics_process(_delta: float) -> void:
	for body in area.get_overlapping_bodies():
		_register_body(body)

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
			match main.current_level.name:
				"FASE 1": if body.get_collision_layer_value(1): _melt_body(body)
				"FASE 2": if not body.get_meta("irradiated"): _irradiate_body(body, true)
		else:
			ray.debug_shape_custom_color = Color(0.904, 0.071, 0.0, 1.0)
			match main.current_level.name:
				"FASE 1": if not body.get_collision_layer_value(1): _freeze_body(body)
				"FASE 2": if body.get_meta("irradiated"): _irradiate_body(body, false)
		
func _register_body(body: Node3D) -> void:
	if body is StaticBody3D and body.is_in_group("lightSensitive") and not active_rays.has(body):
		
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
			
		for i in range(1,5):
			ray.set_collision_mask_value(i, true)

		active_rays[body] = ray
		
func _on_area_3d_body_entered(body: Node3D) -> void:
	_register_body(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if "FASE 2" == main.current_level.name:
		_irradiate_body(body, false)
	_remove_ray(body)

func _remove_ray(body: Node3D) -> void:
	if active_rays.has(body):
		var ray = active_rays[body]
		active_rays.erase(body)
		await get_tree().physics_frame
		if is_instance_valid(ray):
			ray.queue_free()

func _restore_body(body: Node3D) -> void:
	if body.get_collision_layer_value(4):
		match main.current_level.name:
			"FASE 1": _freeze_body(body)
			"FASE 2": _irradiate_body(body, false)
	
	active_rays.erase(body)

func _freeze_body(body: Node3D) -> void:
	var material : ShaderMaterial = _get_shader_material(body)
	if material:
		_apply_material_colors(material, ICE_DARK_BASE, ICE_DARK_FRES)
		body.set_collision_layer_value(1, true)
		body.set_collision_layer_value(2, true)
	
func _melt_body(body: Node3D) -> void:
	var material : ShaderMaterial = _get_shader_material(body)
	if material:
		_apply_material_colors(material, ICE_LIT_BASE, ICE_LIT_FRES)
		body.set_collision_layer_value(1, false)
		body.set_collision_layer_value(2, false)

func _irradiate_body(body: Node3D, has_light: bool) -> void:
	
	body.set_meta("irradiated", has_light)
	
	var mesh = body.get_parent() as MeshInstance3D
	if not mesh: return
	
	if body.has_meta("transparency_tween"):
		var old_tween = body.get_meta("transparency_tween")
		if is_instance_valid(old_tween):
			old_tween.kill()
	
	var target_transparency : float = 0.0 if has_light else 1.0
	var target_time : float = 12.0 if has_light else 4.5
			
	var tween = create_tween()
	body.set_meta("transparency_tween", tween)
	tween.tween_property(mesh, "transparency", target_transparency, target_time)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func _get_shader_material(body: Node3D) -> ShaderMaterial:
	var material = null
	var mesh = body.get_parent() as MeshInstance3D
	if mesh: material = mesh.material_override as ShaderMaterial
	return material

func _apply_material_colors(material: ShaderMaterial, base_color: Color, fres_color: Color) -> void:
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("fres_color", fres_color)
