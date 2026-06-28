extends CharacterBody3D
@onready var camera = get_tree().current_scene.get_node("Camera3D")
@onready var areaDetection = $areaDetection
@onready var PORTAL_UI = $"/root/Principal/Camera3D/UI/Control/Label"


## ATRIBUTOS DE MOVIMENTAÇÃO
const SPEED = 30.0
const ACCELERATION = 150.0

# Limites de Velocidade
const TERMINAL_SPEED = 80.0
const MOMENTUM = TERMINAL_SPEED * 2.5

const AIR_SPEED = 50.0
const CLIMB_SPEED = 20.0
const SLIDE_SPEED = 4.0

const DASH_DISTANCE = 15
const DASH_SPEED = 85.0
const DASH_DECAY = 200.0
const DASH_FALLSPEED = 250.0
const DASH_CORRECTION = 180.0
var has_dash : bool = true
var dash_lock : bool = false

enum DashPhase {START, CONTROL, END}
var dash_phase : DashPhase = DashPhase.START
var dash_progress : float = 0.0
var dash_start : Vector3

# Desgaste de Energia
const REST_FATIGUE = 100.0
const SLIDE_FATIGUE = -10.0
const CLIMB_FATIGUE = -25.0
var stamina: float = 100.0

# Multiplicadores de Movimento
const ASCEND_MULT = 0.8
const FALL_MULT = 1.2
const CLIMB_MULT = 0.4
const WALL_JUMP_MULT = 0.2

# Parâmetros de Pulo
const DASH_IMPULSE = 60.0

const JUMP_HEIGHT = 12.5
const JUMP_DURATION = 0.28
const GRAVITY = (2.0 * JUMP_HEIGHT) / (JUMP_DURATION * JUMP_DURATION)  
const JUMP_VERTICAL_BOOST = GRAVITY * JUMP_DURATION
const JUMP_HORIZONTAL_BOOST = GRAVITY * JUMP_DURATION * 0.2
const WALL_JUMP_PUSHWAY = 32.0

# Parâmetros de Atrito
const FRICTION = 300.0
const AIR_RESISTANCE = 45.0
const SLIDE_FRICTION = 600.0

# Parâmetros de Interação com Vento
var IN_WIND : bool = false
var WIND_FORCE : Vector3 = Vector3.ZERO

#Congela o player
var FREEZE : bool = false

const COYOTE_MAX = 0.25
var COYOTE_TIMER : float = COYOTE_MAX
var IS_FALLING : bool = false

## ATRIBUTOS GERAIS
# Constantes: Estados/Ações do Player
enum STATE {GROUNDED, AIRBORNE, CLIMBING, STEADY, DASHING, SLIDING}
var state : STATE = STATE.GROUNDED

# Variáveis: Orientação da Câmera
var _orientation : Basis
var _visual_direction: Vector3 = Vector3.FORWARD
var up		: Vector3 = Vector3.ZERO
var right	: Vector3 = Vector3.ZERO
var forward : Vector3 = Vector3.ZERO

# Variáveis: Input do Player
var input: PlayerInput
var move_direction : Vector3 = Vector3.ZERO

var spawnpoint : int = 0

# INTERAÇÃO COM PORTAL #
func use_portal(portal):
	velocity = Vector3.ZERO
	global_position = portal.destination.global_position
	
	FREEZE = true
	
	spawnpoint = portal.destination.spawnpoint
	PORTAL_UI.visible = false
	camera._change_orientation(portal.get_normal())
	
	await get_tree().create_timer(0.9).timeout
	FREEZE = false


## FUNÇÕES AUXILIARES
# Função Auxiliar: Projeção Vetorial no Plano
func project_on_plane(v : Vector3, normal : Vector3) -> Vector3:
	return v - normal * v.dot(normal)
	

func _update_orientation() -> void:
	_orientation = camera.game_basis
	up = _orientation.y
	right = _orientation.x
	forward = _orientation.z
	
# Função Auxiliar: Direção do Movimento
func _update_movement_direction(delta : float):
	input.update(delta)
	move_direction = right * input.move.x + forward * input.move.y
	move_direction = move_direction.normalized()
	
func _get_visual_direction() -> Vector3:
	var vel = velocity - up * velocity.dot(up)
	match state:
		STATE.CLIMBING, STATE.STEADY, STATE.SLIDING:
			return -get_wall_normal().normalized()

		STATE.DASHING:
			if vel.length_squared() > 0.001:
				return vel.normalized()

	if move_direction != Vector3.ZERO:
		return move_direction
		
	else: return _visual_direction.normalized()
	
func _update_visual_rotation(delta):
	
	var dir = _get_visual_direction()
	_visual_direction = dir
	
	var angle = atan2(dir.dot(right),dir.dot(forward))
	var basis_rotation = _orientation.rotated(up, angle).orthonormalized()
	var basis_scale = $cat_obj.scale
	
	$cat_obj.global_basis = $cat_obj.global_basis.orthonormalized().slerp(basis_rotation,12.0 * delta).orthonormalized()
	$cat_obj.scale = basis_scale

## INICIALIZAÇÃO
func _ready() -> void:
	input = PlayerInput.new()
	_update_orientation()
	PORTAL_UI.visible = false
	camera.orientation_changed.connect(_change_gravity)

## PROCESSOS
func _physics_process(delta : float) -> void:
	for body in areaDetection.get_overlapping_bodies():
		if body.is_in_group("killObj"): die()
		
	if not FREEZE:
		_update_orientation()

		_update_movement_direction(delta)

		_handle_actions()
		_handle_movement(delta)

		move_and_slide()

		_update_state(delta)
		_update_visual_rotation(delta)
		
		if is_on_floor():
			COYOTE_TIMER = COYOTE_MAX
		else:
			COYOTE_TIMER -= delta
	else:
		velocity = Vector3.ZERO

## Função que gerencia o que acontece quando o player morre
func die() -> void:
	print("morreu!")
	velocity = Vector3.ZERO
	global_position = get_parent()._get_spawnpoint_position(spawnpoint)
	

## MOVIMENTO DO PLAYER
# Funções Auxiliares
func mult(x : PackedVector3Array, lambda : float) -> void:
	for i in range(x.size()):
		x[i] = x[i] * lambda
		
func add(x : PackedVector3Array, y : PackedVector3Array) -> void:
	for i in range(min(x.size(),y.size())):
		x[i] += y[i]

# Forças externas
# TODO: enum EFFECT: {FLYING...} para VENTO ao invés de um BOOL?
func _apply_external_forces(vel : PackedVector3Array, delta : float):
	if IN_WIND:
		var wind_v = up * WIND_FORCE.dot(up)
		var wind_h = WIND_FORCE - wind_v
		var wind : PackedVector3Array = [wind_h, wind_v]
		
		mult(wind,delta)
		add(vel,wind)
		
		vel[0] = vel[0].limit_length(SPEED + 40.0)
		vel[1] = vel[1].limit_length(SPEED + 20.0)

# Lógica da Física: GROUNDED
func _movement_grounded(vel : PackedVector3Array, delta : float):
	var speed = move_direction * SPEED
	var accel = ACCELERATION if move_direction != Vector3.ZERO else FRICTION
	
	if vel[0].length_squared() > 0.0 and move_direction.dot(vel[0]) < 0.0: accel *= 2.0
	vel[0] = vel[0].move_toward(speed, accel * delta)
	
func _movement_airborne(vel : PackedVector3Array, delta : float):
	var speed_h = move_direction * AIR_SPEED
	var accel = ACCELERATION if move_direction != Vector3.ZERO else AIR_RESISTANCE

	if vel[0].length_squared() > 0.0 and move_direction.dot(vel[0]) < 0.0: accel *= 0.5
	vel[0] = vel[0].move_toward(speed_h, accel * delta)

	# Movimento de queda
	var speed_v = vel[1].dot(up)
	var gravity = GRAVITY
	if speed_v > 0.0:
		gravity *= ASCEND_MULT

		if input.jump.released:
			speed_v *= 0.4
			vel[1] = up * speed_v

		if $AnimationPlayer.current_animation == &"jump":
			var jump_animation = $AnimationPlayer.current_animation_length
			var remaining = speed_v/gravity
			$AnimationPlayer.speed_scale = clampf(jump_animation/max(remaining, 0.1),0.5,2.5)
	else:
		gravity *= FALL_MULT
		$AnimationPlayer.speed_scale = 1.0
		COYOTE_TIMER -= delta

	speed_v = max(speed_v - gravity * delta, -TERMINAL_SPEED)
	vel[1] = up * speed_v
	
func _movement_sliding(vel: PackedVector3Array, delta: float):
	var normal = get_wall_normal().normalized()
	var stick = -normal * 0.1
	var speed_v = up * -SLIDE_SPEED
	
	vel[1] = vel[1].move_toward(speed_v, SLIDE_FRICTION * delta)
	vel[0] = stick

func _movement_dashing(vel : PackedVector3Array, delta : float):
	var dir = Vector3.ZERO
	# direção do movimento para o DASH
	if input.has_movement():
		dir = move_direction
	else:
		dir = _visual_direction

	match dash_phase:
		# fase de impulso inicial
		DashPhase.START:
			vel[1] = Vector3.ZERO
			vel[0] = dir * DASH_IMPULSE
			velocity = vel[0] + vel[1]
			dash_phase = DashPhase.CONTROL

		# fase de controle da direção
		DashPhase.CONTROL:
			var target = dir * DASH_SPEED
			vel[0] = vel[0].move_toward(target, DASH_CORRECTION * delta)
			vel[1] = Vector3.ZERO

			velocity = vel[0] + vel[1]
			if dash_progress >= 0.75:
				dash_phase = DashPhase.END

		# fase de queda e desaceleração
		DashPhase.END:
			vel[0] = vel[0].move_toward(Vector3.ZERO,DASH_DECAY * delta)
			vel[1] += vel[1].move_toward(Vector3.ZERO,DASH_FALLSPEED * delta)
			velocity = vel[0] + vel[1]
			
	dash_progress = global_position.distance_to(dash_start)/DASH_DISTANCE
	if dash_progress >= 1.0: 
		finish_dash(STATE.GROUNDED if is_on_floor() else STATE.AIRBORNE)
		
func finish_dash(next_state : STATE):
	dash_lock = dash_lock and next_state == STATE.GROUNDED
	state = next_state

# Lógica da Física: CLIMB
func _movement_climbing(vel : PackedVector3Array, delta : float):
	# Projeção do movimento na parede.
	var normal = get_wall_normal().normalized()
	var push_up = move_direction.dot(-normal)
	var slide = move_direction.slide(normal)
	
	# Forças para agarrar/deslizar na parede.
	var stick = -normal * 0.1 
	var slip = -up * (CLIMB_SPEED * CLIMB_MULT if stamina < 20.0 else 0.0)
	
	var speed_h = slide * CLIMB_SPEED + stick
	var speed_v = (up * push_up) * CLIMB_SPEED + slip
	var accel = ACCELERATION * CLIMB_MULT
	
	vel[0] = vel[0].move_toward(speed_h, accel * delta)
	vel[1] = vel[1].move_toward(speed_v, accel * delta)

# Lógica da Física: STEADY
func _movement_steady(vel : PackedVector3Array):
	var normal = get_wall_normal().normalized()
	var stick = -normal * 0.1
	vel[1] = Vector3.ZERO
	vel[0] = stick
	
# Verificação Movimentação contra parede
func is_pushing_wall() -> bool:
	var normal = get_wall_normal().normalized()
	return move_direction.dot(-normal) > 0.2
"""
func is_on_layer(layer : int) -> bool:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		var parent = collider.get_parent()
		# Camadas para entidades com Mesh.
		if parent is MeshInstance3D:
			return parent.get_layer_mask_value(layer)
		# Camadas para entidades somente com StaticBody.
		elif collider is StaticBody3D:		
			return collider.get_collision_mask_value(layer)
	return false
"""
func is_on_layer(layer: int) -> bool:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider is CollisionObject3D:
			if collider.get_collision_layer_value(layer):
				return true
	return false
	

# Controle do Sistema: MOVIMENTAÇÃO E MOMENTO
func _handle_movement(delta : float):
	var vel_v = up * velocity.dot(up)
	var vel_h = velocity - vel_v
	var vel : PackedVector3Array = [vel_h,vel_v]

	match state:
		STATE.GROUNDED:
			_movement_grounded(vel,delta)
		STATE.AIRBORNE:
			_movement_airborne(vel,delta)
		STATE.DASHING:
			_movement_dashing(vel,delta)
		STATE.SLIDING:
			_movement_sliding(vel,delta)
		STATE.CLIMBING:
			_movement_climbing(vel,delta)
		STATE.STEADY:
			_movement_steady(vel)
	
	_apply_external_forces(vel,delta)
	velocity = vel[0].limit_length(MOMENTUM) + vel[1].limit_length(MOMENTUM)
	
func _update_state(delta):
	var fatigue := 0.0

	if state == STATE.DASHING:
		if is_on_wall() or is_pushing_wall():
			finish_dash(STATE.AIRBORNE)

	elif input.climb.is_down and _can_climb():
		if state != STATE.CLIMBING: velocity = Vector3.ZERO
		state = STATE.CLIMBING if input.has_movement() else STATE.STEADY
		fatigue = CLIMB_FATIGUE
			
	elif is_pushing_wall() and _can_slide():
		state = STATE.SLIDING
		fatigue = SLIDE_FATIGUE

	elif is_on_floor():
		state = STATE.GROUNDED
		
		if not has_dash: 
			if not dash_lock: 
				has_dash = true 
				input.dash.reset()
			elif not input.dash.is_ready(): 
				has_dash = true 
		
		if stamina < 100.0:
			fatigue = REST_FATIGUE
			
		if input.has_movement():
			if $AnimationPlayer.current_animation != &"run": 
				$AnimationPlayer.play(&"run") 
				$AnimationPlayer.speed_scale = 1.5 	
		else: 
			$AnimationPlayer.play(&"idle") 
			$AnimationPlayer.speed_scale = 1.0
	else:
		state = STATE.AIRBORNE

	if IN_WIND:
		fatigue = REST_FATIGUE * 0.5

	stamina = clamp(stamina + fatigue * delta, -50.0, 100.0)
	
func _can_climb():
	return is_on_wall() and is_on_layer(3) and stamina > 0.0
	
func _can_slide():
	return is_on_wall() and not is_on_layer(2) and stamina > -50.0

## AÇÕES DO PLAYER
func _handle_actions():
	if input.reset.is_triggered(): die()

	elif input.dash.is_triggered() and _can_dash():
		_execute_dash()
		input.dash.consume()
		state = STATE.DASHING

	elif input.jump.is_triggered() and _can_jump():
		if state == STATE.DASHING: finish_dash(STATE.AIRBORNE)
		_execute_jump()
		input.jump.consume()
		state = STATE.AIRBORNE
	
func _can_jump():
	return is_on_floor() or is_on_wall() and state != STATE.AIRBORNE 

func _can_dash():
	return has_dash and state not in [STATE.SLIDING,STATE.CLIMBING,STATE.STEADY]
	
func restore_dash() -> void:
	has_dash = true
	if state == STATE.DASHING:
		pass
		#state = STATE.AIRBORNE
		
# Executor da Ação: DASH
func _execute_dash():
	dash_start = global_position
	dash_lock = state == STATE.GROUNDED
	dash_phase = DashPhase.START
	has_dash = false 
	velocity = Vector3.ZERO
	
# Executor da Ação: PULO
func _execute_jump():
	var normal = get_wall_normal().normalized()
	var vertical = velocity.dot(up)
	velocity -= up * vertical
	
	if state == STATE.STEADY and move_direction.dot(-normal) < 0.7:
		velocity = up * JUMP_VERTICAL_BOOST + (normal + move_direction) * WALL_JUMP_PUSHWAY
		
	elif state in [STATE.SLIDING, STATE.CLIMBING]:
		velocity = up * JUMP_VERTICAL_BOOST + normal * WALL_JUMP_PUSHWAY
		
	else:
		velocity -= up * velocity.dot(up)
		velocity += up * JUMP_VERTICAL_BOOST + move_direction * JUMP_HORIZONTAL_BOOST
		$AnimationPlayer.play(&"jump")

func _change_gravity(newOrientation : Basis):
	up_direction = newOrientation.y
