# laser.gd
extends Node3D

@onready var player = get_parent()
@export var max_bounces: int = 3
@export var laser_range: float = 100.0

var points: PackedVector3Array = []

func _process(_delta):
	return
	# Se quiser que o laser seja "contínuo" enquanto segura, chame aqui
	# Se for apenas um "tiro", chame via input
	if Input.is_action_just_pressed("mouse_left"): # Certifique-se de ter essa action no Input Map
		_calculate_laser()
		queue_redraw_laser()

func _ready() -> void:
	return
	var mesh_instance = $LaserMesh
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0, 0)
	mat.vertex_color_use_as_albedo = false
	mesh_instance.material_override = mat
func _calculate_laser():
	points.clear()
	
	# 1. Pegar a posição do mouse no mundo 3D
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	# Setup inicial do raio
	var origin = player.global_position
	var direction = (to - origin).normalized() # Atira em direção ao clique
	
	points.append(origin)
	
	var current_origin = origin
	var current_direction = direction

	for i in range(max_bounces + 1):
		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(current_origin, current_origin + current_direction * laser_range)
		query.exclude = [player] # Não acertar a si mesmo
		
		var result = space.intersect_ray(query)
		
		if result:
			points.append(result.position)
			# Reflete o vetor baseado na normal da face atingida
			current_direction = current_direction.bounce(result.normal).normalized()
			# Move a origem um pouco para fora da parede para evitar colidir com a mesma face instantaneamente
			current_origin = result.position + current_direction * 0.01
		else:
			# Se não bater em nada, termina o laser no alcance máximo
			points.append(current_origin + current_direction * laser_range)
			break
func draw_laser_in_3d():
	var mesh_instance = $LaserMesh
	var imm_mesh = ImmediateMesh.new()
	mesh_instance.mesh = imm_mesh
	
	imm_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		imm_mesh.surface_add_vertex(p - global_position) # Local space
	imm_mesh.surface_end()
func queue_redraw_laser():
	draw_laser_in_3d()
	print("Pontos do laser:", points)
