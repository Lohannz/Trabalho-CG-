extends CharacterBody3D
@onready var camera = get_tree().current_scene.get_node("Camera3D")
@onready var areaDetection = $areaDetection
@onready var PORTAL_UI = $"/root/Principal/Camera3D/UI/Control/Label"


## ATRIBUTOS DE MOVIMENTAÇÃO
const SPEED = 28.0
const ACCELERATION = 70.0

# Limites de Velocidade
const TERMINAL_SPEED = 70.0

const AIR_SPEED = 30.0
const CLIMB_SPEED = 20.0
const SLIDE_SPEED = 4.0

const DASH_SPEED = 85.0
const DASH_DURATION = 0.5
const DASH_DECAY = 90.0
const DASH_FALLSPEED = 125.0
const DASH_CORRECTION = 180.0
var dash_timer : float = DASH_DURATION
var has_dash : bool = true
const DASH_GROUND_COOLDOWN = 2.0
var dash_ground_timer := 0.0

enum DashPhase {START, CONTROL, END}
var dash_phase := DashPhase.START

# Desgaste de Energia
const REST_FATIGUE = 100.0
const SLIDE_FATIGUE = -10.0
const CLIMB_FATIGUE = -25.0
var stamina: float = 100.0

# Multiplicadores de Movimento
const ASCEND_MULT = 0.8
const FALL_MULT = 1.2
const SLIDE_MULT = 1.25
const CLIMB_MULT = 0.4
const WALL_JUMP_MULT = 0.2

# Parâmetros de Impulso
const DASH_IMPULSE = 50.0

const JUMP_HEIGHT = 11.5
const JUMP_DURATION = 0.28
const GRAVITY = (2.0 * JUMP_HEIGHT) / (JUMP_DURATION * JUMP_DURATION) 
const JUMP_VERTICAL_BOOST = GRAVITY * JUMP_DURATION
const JUMP_HORIZONTAL_BOOST = GRAVITY * JUMP_DURATION * 0.2
const WALL_JUMP_PUSHWAY = 32.0

# Parâmetros de Atrito
const FRICTION = 300.0
const SLIDE_FRICTION = 400.0
const AIR_RESISTANCE = 55.0

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
var _facing_direction: Vector3 = Vector3.FORWARD
var up		: Vector3 = Vector3.ZERO
var right	: Vector3 = Vector3.ZERO
var forward : Vector3 = Vector3.ZERO

# Variáveis: Input do Player
var input: PlayerInput
var gravity : float = GRAVITY
var move_direction : Vector3 = Vector3.ZERO

var spawnpoint : int = 0

# INTERAÇÃO COM PORTAL #
func use_portal(portal):
	velocity = Vector3.ZERO
	global_position = portal.destination.global_position
	FREEZE = true
	#process_mode = Node.PROCESS_MODE_DISABLED
	spawnpoint = portal.destination.spawnpoint
	PORTAL_UI.visible = false
	camera._change_orientation(portal.get_normal())
	await get_tree().create_timer(0.9).timeout
	#process_mode = Node.PROCESS_MODE_ALWAYS
	FREEZE = false


## FUNÇÕES AUXILIARES
# Função Auxiliar: Projeção Vetorial no Plano
func project_on_plane(v: Vector3, normal: Vector3) -> Vector3:
	return v - normal * v.dot(normal)
	

func _update_orientation() -> void:
	_orientation = camera.game_basis
	up = _orientation.y
	right = _orientation.x
	forward = _orientation.z
	
# Função Auxiliar: Direção do Movimento
func _update_movement_direction(delta):
	input.update(delta)
	move_direction = right * input.move.x + forward * input.move.y
	move_direction = move_direction.normalized()
	
func _update_facing_direction(delta):
	if move_direction != Vector3.ZERO:
		_facing_direction = _facing_direction.slerp(move_direction, 10.0 * delta).normalized()
	_facing_direction = _facing_direction.normalized()
	
	if move_direction != Vector3.ZERO:
		var y = up.normalized()
		var z = move_direction.normalized()
		var x = y.cross(z).normalized()
		z = x.cross(y).normalized()
		var orientation = Basis(x,	y,z)
		$cat_obj.global_transform.basis = $cat_obj.global_transform.basis.slerp(orientation, 12.0 * delta).orthonormalized()
		
## INICIALIZAÇÃO
func _ready() -> void:
	input = PlayerInput.new()
	_update_orientation()
	PORTAL_UI.visible = false
	camera.orientation_changed.connect(_change_gravity) #captura um signal quando o up muda

## PROCESSOS
func _physics_process(delta : float) -> void:
	for body in areaDetection.get_overlapping_bodies():
		if body.is_in_group("killObj"):
			die()
		#if(body != self):
		#	print(body.name)
	if not FREEZE:
		_update_orientation()
		
		_update_movement_direction(delta)
		_update_facing_direction(delta)
		_update_state(delta)
		
		_handle_gravity(delta)
		_handle_actions()
		_handle_movement(delta)
		
		#NAO SPAMMAR DASH NO CHAO
		if dash_ground_timer > 0.0:
			dash_ground_timer -= delta
			
		move_and_slide()
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
	

## FÍSICA DO PLAYER
# Lógica da Física: MOMENTO
func _physics_momentum(delta: float, limit: float, accel: float, friction: float):
	var velocity_v = up * velocity.dot(up)
	var velocity_h = velocity - velocity_v
	
	if state == STATE.AIRBORNE:
		IS_FALLING = not is_on_floor() and velocity.dot(_orientation.y) < 0
		COYOTE_TIMER -= delta
	else:
		IS_FALLING = false
		
	var speed = move_direction * limit
	var adaptative_accel = accel if move_direction != Vector3.ZERO else friction

	if velocity_h.length_squared() > 0.0 and move_direction.dot(velocity_h) < 0.0:
		adaptative_accel *= 2.0

	# Movimento base
	velocity_h = velocity_h.move_toward(speed, adaptative_accel * delta)

	# Forças externas
	# TODO: enum EFFECT: {FLYING...} para VENTO ao invés de um BOOL?
	# TODO: Talvez separar um _func só para efeitos de debilitação/ajuda no movimento.
	if IN_WIND:
		var wind_v = up * WIND_FORCE.dot(up)
		var wind_h = WIND_FORCE - wind_v

		velocity_h += wind_h * delta
		velocity_v += wind_v * delta

		velocity_h = velocity_h.limit_length(limit + 40.0)
		velocity_v = velocity_v.limit_length(limit + 10.0)

	# Clamp final
	velocity_h = velocity_h.limit_length(TERMINAL_SPEED)
	velocity = velocity_h + velocity_v

# Lógica da Física: DASH
# TODO: limitar a velocidade semelhante ao controle do momentum, mas com um limite maior.
# TODO: ajustar as fases do DASH, a ideia é:
#		START: inicia com um impulso forte para uma direção
#		CONTROL: corrige a direção com um pouco de esforço
#		END: decaimento da velocidade e queda
func _physics_dashing(delta: float):
	var velocity_v = up * velocity.dot(up)
	var velocity_h = velocity - velocity_v
	var dir = Vector3.ZERO
	
	# direção do movimento para o DASH
	if input.has_movement():
		dir = move_direction
	else:
		dir = _facing_direction
	
	dash_timer -= delta
	
	match dash_phase:
		# fase de impulso inicial
		DashPhase.START:
			velocity_v = Vector3.ZERO # Zera a velocidade vertical
			velocity_h += dir * DASH_IMPULSE #impulso apenas na horizontal
			velocity = velocity_h + velocity_v
			dash_phase = DashPhase.CONTROL
			
		# fase de controle da direção
		DashPhase.CONTROL:
			var target = dir * DASH_SPEED
			velocity_h = velocity_h.move_toward(target, DASH_CORRECTION * delta)
			
			if input.jump.is_down:
				velocity_v = velocity_v.move_toward(up * DASH_SPEED, DASH_CORRECTION * delta)
			else:
				velocity_v = Vector3.ZERO #Dash continua zerado
			
			if dash_timer <= 0.25: 
				dash_phase = DashPhase.END
		
		# fase de queda e desaceleração
		DashPhase.END:
			velocity_h = velocity_h.move_toward(Vector3.ZERO, DASH_DECAY * delta)
			velocity_v += -up * DASH_FALLSPEED * delta
			velocity = velocity_h + velocity_v

	# termina o estado de dash
	if dash_timer <= 0.0:
		state = STATE.AIRBORNE

# Lógica da Física: CLIMB
func _physics_climbing():
	var normal = get_wall_normal().normalized()

	# Movimentação vertical/horizontal na parede.
	var push_up = move_direction.dot(-normal)
	var slide = move_direction.slide(normal)
	move_direction = slide + (up * push_up)
	
	var stick = -normal * 0.1 
	var slip = -up * (CLIMB_MULT if stamina < 20 else 0.0)
	
	velocity = (move_direction * CLIMB_SPEED) + slip + stick

func _physics_steady():
	# Zera a gravidade e o movimento, mas mantém colado na parede
	var normal = get_wall_normal()
	velocity = -normal * 0.1

# Verificação Movimentação contra parede
func is_pushing_wall() -> bool:
	var normal = get_wall_normal()
	return move_direction.dot(-normal) > 0.

func is_on_layer(layer : int) -> bool:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		var parent = collider.get_parent()
		if parent is MeshInstance3D and parent.get_layer_mask_value(layer):
			return true
	return false
	
func _update_state(delta : float):
	var fatigue = 0.0
	
	if is_on_floor() and state != STATE.DASHING and not input.climb.is_down:
			state = STATE.GROUNDED
			has_dash = true
			if stamina < 100.0: fatigue = REST_FATIGUE
			
			if input.has_movement():
				if $AnimationPlayer.current_animation != &"run": 
					$AnimationPlayer.play(&"run")
					$AnimationPlayer.speed_scale = 1.5
	
				#$AnimationPlayer.speed_scale = clamp(speed/SPEED, 0.2, 4.5)
			else:
				$AnimationPlayer.play(&"idle")
				$AnimationPlayer.speed_scale = 1.0
			
	elif is_on_wall():
		if is_on_layer(3) and input.climb.is_down and stamina > 0.0:
			if input.has_movement():
				state = STATE.CLIMBING
			else:
				state = STATE.STEADY
			fatigue = CLIMB_FATIGUE	
							
		elif not is_on_layer(2) and is_pushing_wall() and stamina > -50.0:
			state = STATE.SLIDING
			fatigue = SLIDE_FATIGUE
					
		elif state != STATE.DASHING:
			state = STATE.AIRBORNE
			
		else: velocity = Vector3.ZERO
		
			
	elif state != STATE.DASHING:
		state = STATE.AIRBORNE
	
 	# Recuperação de STAMINA no vento
	if IN_WIND:
		fatigue = REST_FATIGUE * 0.5

	stamina = clamp(stamina + fatigue * delta, -50.0, 100.0)

## AÇÕES DO PLAYER
# Controlade do Sistema: AÇÕES
func _handle_actions():
	# PULO (Espaço - gerenciado pelo seu sistema)
	if input.jump.is_triggered() and (_can_jump() or (state == STATE.AIRBORNE and COYOTE_TIMER > 0)):
		COYOTE_TIMER = 0
		_execute_jump()
		input.jump.consume()
		state = STATE.AIRBORNE

	# DASH
	if Input.is_action_just_pressed("action_dash") or input.dash.is_triggered():
		if _can_dash():
			_execute_dash()
			# Tenta consumir o input do seu script para ele não atrapalhar
			if input.dash.has_method("consume"):
				input.dash.consume()
			state = STATE.DASHING
	
	# RESET (mal feito, vou melhorar dps)
	if input.reset.is_triggered():
		die()


	if input.dash.is_triggered() and _can_dash():
		_execute_dash()
		input.dash.consume()
		state = STATE.DASHING
		
func _can_jump():
	return state not in [STATE.AIRBORNE, STATE.DASHING]

func _can_dash():
	#NAO SPAMMAR DASH NO CHAO
	if is_on_floor() and dash_ground_timer > 0.0:
		return false
	return has_dash and state != STATE.CLIMBING
	
func restore_dash() -> void:
	has_dash = true
	if state == STATE.DASHING:
		state = STATE.AIRBORNE
# Executor da Ação: DASH
func _execute_dash():
	dash_phase = DashPhase.START
	dash_timer = DASH_DURATION
	has_dash = false # Gasta o dash ao usar
	#NAO SPAMMAR DASH NO CHAO
	if is_on_floor():
		dash_ground_timer = DASH_GROUND_COOLDOWN
	# ADICIONADO: Zera totalmente a velocidade acumulada antes de dar o novo impulso
	# Assim o novo dash não soma velocidade com o antigo pra n sair um super pulo
	velocity = Vector3.ZERO
	
# Executor da Ação: PULO
func _execute_jump():
	#TODO: atualmente dá para pular enquanto STEADY na parede, isso faz o jogador deslizar
	# 	    um pouco para cima, não era para isso ser possível
	var normal = get_wall_normal().normalized()
	var vertical = velocity.dot(up)
	velocity -= up * vertical
	
	if state == STATE.STEADY and move_direction.dot(-normal) < 0.7:
		velocity = up * JUMP_VERTICAL_BOOST + (normal + _facing_direction) * WALL_JUMP_PUSHWAY
		
	if state in [STATE.SLIDING, STATE.CLIMBING]:
		velocity = up * JUMP_VERTICAL_BOOST + normal * WALL_JUMP_PUSHWAY
	else:
		velocity -= up * velocity.dot(up)
		velocity += up * JUMP_VERTICAL_BOOST + move_direction * JUMP_HORIZONTAL_BOOST
		$AnimationPlayer.play(&"jump")
		
## MOVIMENTAÇÃO DO PLAYER
# Controle do Sistema: GRAVIDADE
func _handle_gravity(delta : float):
	if state in [STATE.AIRBORNE, STATE.SLIDING]:
		gravity = GRAVITY
		var speed_v = velocity.dot(up)
		var terminal_speed = -TERMINAL_SPEED
		
		match state:
			STATE.AIRBORNE:
				if speed_v > 0.0: 
					gravity *= ASCEND_MULT
					
					if input.jump.released: # Jump cut
						velocity -= up * speed_v * 0.6
						speed_v = velocity.dot(up)
						
					# Sincroniza a animação com o tempo restante do salto.
					if $AnimationPlayer.current_animation == &"jump":
						var jump_animation = $AnimationPlayer.current_animation_length
						
						# Tempo restante até a queda.
						var lasting_time = speed_v/gravity
						var scale = jump_animation/max(lasting_time, 0.1)
						$AnimationPlayer.speed_scale = clampf(scale, 0.5, 2.5)
					else:
						$AnimationPlayer.speed_scale = 1.0
				else:
					gravity *= FALL_MULT
					$AnimationPlayer.speed_scale = 1.0

			# Limita a velocidade do slide.
			STATE.SLIDING:
				gravity *= SLIDE_MULT
				terminal_speed = -SLIDE_SPEED
				$AnimationPlayer.speed_scale = 1.0

		if speed_v > terminal_speed:
			velocity -= up * gravity * delta
		
# Controle do Sistema: MOVIMENTAÇÃO E MOMENTO
func _handle_movement(delta : float):
	match state:
		STATE.GROUNDED:
			_physics_momentum(delta, SPEED, ACCELERATION, FRICTION)
		STATE.AIRBORNE:
			_physics_momentum(delta, AIR_SPEED, AIR_RESISTANCE, FRICTION)
		STATE.DASHING:
			_physics_dashing(delta)
		STATE.SLIDING:
			_physics_momentum(delta, SLIDE_SPEED, ACCELERATION, SLIDE_FRICTION)
		STATE.CLIMBING:
			_physics_climbing()
		STATE.STEADY:
			_physics_steady()

func _change_gravity(newOrientation : Basis):
	up_direction = newOrientation.y
