extends CharacterBody3D
@onready var camera = get_tree().current_scene.get_node("Camera3D")
@onready var areaDetection = $areaDetection
@onready var PORTAL_UI = get_tree().current_scene.get_node("Camera3D/UI/Control/Label")
signal change_level(next_level_path: String)

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
const DASH_IMPULSE = 50.0
const JUMP_HEIGHT = 12.5
const JUMP_DURATION = 0.28
const GRAVITY = (2.0 * JUMP_HEIGHT) / (JUMP_DURATION * JUMP_DURATION)  
const JUMP_VERTICAL_BOOST = GRAVITY * JUMP_DURATION
const JUMP_HORIZONTAL_BOOST = GRAVITY * JUMP_DURATION * 0.2
const WALL_JUMP_PUSHWAY = 30.0
const COYOTE_MAX = 0.25
var COYOTE_TIMER : float = COYOTE_MAX


# Parâmetros de Atrito
const FRICTION = 300.0
const AIR_RESISTANCE = 125.0
const SLIDE_FRICTION = 900.0

# Parâmetros de Efeitos Externos
var ext_effects : Array[Globals.EFFECTS]
var WIND_FORCE : Vector3 = Vector3.ZERO
var ICE_INERTIA: float = 80.0

## ATRIBUTOS GERAIS
# Constantes: Estados/Ações do Player
enum STATE {GROUNDED, AIRBORNE, CLIMBING, STEADY, DASHING, SLIDING, DYING}
var state : STATE = STATE.GROUNDED

# Variáveis: Partículas de Movimentação
@onready var running_particles: CPUParticles3D = $cat_obj/RunParticles
@onready var sliding_particles: CPUParticles3D = $cat_obj/SlidingParticles
@onready var jumping_particles: CPUParticles3D = $cat_obj/JumpParticles
@onready var dashing_particles: CPUParticles3D = $cat_obj/DashParticles


# Variáveis: Orientação da Câmera
var _orientation : Basis
var _visual_direction: Vector3 = Vector3.FORWARD
var up		: Vector3 = Vector3.ZERO
var right	: Vector3 = Vector3.ZERO
var forward : Vector3 = Vector3.ZERO

# Variáveis: Input do Player
var input: PlayerInput
var move_direction : Vector3 = Vector3.ZERO

var FREEZE : bool = false
var spawnpoint : Vector3 = Vector3.ZERO

# INTERAÇÃO COM PORTAL #
func use_portal(portal):
	velocity = Vector3.ZERO
	if portal.get_parent().name == "PortalFinal":
		FREEZE = true
		PORTAL_UI.visible = false

		change_level.emit(portal.next_level_path)
		await get_parent().level_ready 

		global_transform.basis = Basis.IDENTITY
		camera._orientation = Basis.IDENTITY
		up_direction = Vector3.UP
		
		await get_tree().physics_frame
		_update_orientation()
		
		FREEZE = false
	else:
		global_position = portal.destination.global_position
		
		FREEZE = true
		PORTAL_UI.visible = false
		camera._change_orientation(portal.get_normal())
		_update_orientation()
		spawnpoint = portal.destination.get_spawn()
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
func _physics_process(delta: float) -> void:
	if state != STATE.DYING:
		for body in areaDetection.get_overlapping_bodies():
			if body.is_in_group("killObj"):
				die()
				break
			
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


## MORTE DO PLAYER
func die() -> void:
	state = STATE.DYING
	FREEZE = true
	velocity = Vector3.ZERO
	
	set_collision_layer_value(1, false)
	areaDetection.set_deferred("monitoring", false) 
	
	if $AnimationPlayer.current_animation != &"dead": 
		$AnimationPlayer.play(&"dead")
		$AnimationPlayer.speed_scale = 0.8
	await $AnimationPlayer.animation_finished

	global_position = spawnpoint
	state = STATE.GROUNDED
	FREEZE = false
	
	set_collision_layer_value(1, true)
	areaDetection.set_deferred("monitoring", true)
	$AnimationPlayer.play(&"idle")
	
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
	if Globals.EFFECTS.WIND in ext_effects:
		var wind_v = up * WIND_FORCE.dot(up)
		var wind_h = WIND_FORCE - wind_v
		var wind : PackedVector3Array = [wind_h, wind_v]
		
		mult(wind,delta)
		add(vel,wind)
		
		vel[0] = vel[0].limit_length(TERMINAL_SPEED + 40.0)
		vel[1] = vel[1].limit_length(SPEED + 20.0)
		
	if Globals.EFFECTS.ICE in ext_effects:
		var ice_factor = pow(ICE_INERTIA, delta)
		vel[0] = vel[0] * ice_factor
		vel[0] = vel[0].limit_length(TERMINAL_SPEED + 100.0)


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
	return move_direction.dot(-normal) > 0.5

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
		if state != STATE.CLIMBING:
			velocity = Vector3.ZERO
			$AnimationPlayer.play(&"climb")
			$AnimationPlayer.pause()
			$AnimationPlayer.seek(0.0, true)
			
		if input.has_movement():
			state = STATE.CLIMBING
			$AnimationPlayer.play(&"climb")
			$AnimationPlayer.speed_scale = 1.5
		else:
			state = STATE.STEADY
			$AnimationPlayer.pause()
			$AnimationPlayer.seek(0.0, true)
		fatigue = CLIMB_FATIGUE
		
	elif is_pushing_wall() and _can_slide():
		$AnimationPlayer.play(&"slide")
		state = STATE.SLIDING
		fatigue = SLIDE_FATIGUE
		
	elif is_on_floor():
		if state == STATE.AIRBORNE:
			var particles = jumping_particles.duplicate()
			get_parent().add_child(particles)
			particles.global_position = jumping_particles.global_position
			particles.emitting = true
			particles.finished.connect(particles.queue_free)
	
		state = STATE.GROUNDED
		if not has_dash: 
			if not dash_lock: restore_dash()
			elif input.dash.is_ready(): 
				has_dash = true 
			
		if stamina < 100.0:
			fatigue = REST_FATIGUE
			
		if input.has_movement():
			if $AnimationPlayer.current_animation != &"run": 
				$AnimationPlayer.play(&"run") 
				$AnimationPlayer.speed_scale = 1.5 	
		else: 
			$AnimationPlayer.play(&"idle") 
			$AnimationPlayer.speed_scale = 0.5
			
	else:
		state = STATE.AIRBORNE
		if $AnimationPlayer.current_animation == &"fall": 
			$AnimationPlayer.seek(0.4, true)
			
		elif $AnimationPlayer.current_animation != &"jump": 
			$AnimationPlayer.play(&"fall")
			

	if Globals.EFFECTS.WIND in ext_effects:
		fatigue = REST_FATIGUE * 0.5

	stamina = clamp(stamina + fatigue * delta, -50.0, 100.0)
	_update_particles()

func _update_particles() -> void:
	match state:
		STATE.GROUNDED:
			running_particles.show()

			var vel_h := velocity - up * velocity.dot(up)
			running_particles.emitting = input.has_movement() and vel_h.length() >= 15.0
			if sliding_particles.visible:
				sliding_particles.emitting = false
				sliding_particles.hide()

		STATE.AIRBORNE:
			running_particles.emitting = false
			running_particles.hide()
			running_particles.restart()

			sliding_particles.emitting = false
			sliding_particles.hide()
			sliding_particles.restart()

		STATE.DASHING:
			running_particles.emitting = false
			if sliding_particles.visible:
				sliding_particles.emitting = false
				sliding_particles.hide()
				sliding_particles.restart()

		STATE.SLIDING:
			running_particles.emitting = false
			if !sliding_particles.visible:
				await get_tree().create_timer(0.2).timeout
				if state == STATE.SLIDING:
					sliding_particles.show()
					sliding_particles.emitting = true

		STATE.CLIMBING, STATE.STEADY:
			running_particles.emitting = false
			if sliding_particles.visible:
				sliding_particles.emitting = false
				sliding_particles.hide()
				sliding_particles.restart()
		
func _can_climb():
	return is_on_wall() and is_on_layer(3) and stamina > 0.0
	
func _can_slide():
	return is_on_wall_only() and not is_on_layer(2) and stamina > -50.0

## AÇÕES DO PLAYER
func _handle_actions():
	if input.reset.is_triggered(): 
		input.reset.consume()
		die()

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
	input.dash.reset()
	
# Executor da Ação: DASH
func _execute_dash():
	dash_start = global_position
	dash_lock = state == STATE.GROUNDED
	dash_phase = DashPhase.START
	has_dash = false 
	velocity = Vector3.ZERO
	
	var particles = dashing_particles.duplicate()
	get_parent().add_child(particles)
	particles.global_position = dashing_particles.global_position
	particles.global_rotation = dashing_particles.global_rotation
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

# Executor da Ação: PULO
func _execute_jump():
	var normal = get_wall_normal().normalized()
	var vertical = velocity.dot(up)
	velocity -= up * vertical
	
	if state == STATE.STEADY and move_direction.dot(-normal) < 0.7:
		velocity = up * JUMP_VERTICAL_BOOST + (normal + move_direction) * WALL_JUMP_PUSHWAY
		$AnimationPlayer.play(&"jump")

	elif state in [STATE.SLIDING, STATE.CLIMBING]:
		velocity = up * JUMP_VERTICAL_BOOST + normal * WALL_JUMP_PUSHWAY
		$AnimationPlayer.play(&"jump")

	else:
		velocity -= up * velocity.dot(up)
		velocity += up * JUMP_VERTICAL_BOOST + move_direction * JUMP_HORIZONTAL_BOOST
		$AnimationPlayer.play(&"jump")

func _change_gravity(newOrientation : Basis):
	up_direction = newOrientation.y
