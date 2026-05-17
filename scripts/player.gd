extends CharacterBody3D
@onready var camera = $"../Camera3D"
@onready var areaDetection = $areaDetection
@onready var PORTAL_UI = $UI/ui_entered_portal
@onready var raycasts = $Raycasts

## ATRIBUTOS DE MOVIMENTAÇÃO
const SPEED = 25.0
const ACCELERATION = 30.0

# Limites de Velocidade
const TERMINAL_SPEED = 70.0

const AIR_SPEED = 30.0
const CLIMB_SPEED = 10.0
const SLIDE_SPEED = 4.0

const DASH_SPEED = 85.0
const DASH_DURATION = 0.6
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

const JUMP_HEIGHT = 8.0
const JUMP_DURATION = 0.3
const GRAVITY = (2.0 * JUMP_HEIGHT) / (JUMP_DURATION * JUMP_DURATION)  
const JUMP_VERTICAL_BOOST = GRAVITY * JUMP_DURATION
const JUMP_HORIZONTAL_BOOST = GRAVITY * JUMP_DURATION * 0.2
const WALL_JUMP_PUSHWAY = 32.0

# Parâmetros de Atrito
const FRICTION = 300.0
const SLIDE_FRICTION = 400.0
const AIR_RESISTANCE = 65.0

# Parâmetros de Interação com Vento
var IN_WIND : bool = false
var WIND_FORCE : Vector3 = Vector3.ZERO

#Congela o player
var FREEZE : bool = false

# Parâmetros de Interação com Portais
var SIDE_OF_PORTAL : String


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
#var direction_v : Vector3 = Vector3.ZERO

# Variáveis: Orientação da Cubo
enum FACE {ONE, TWO, THREE, FOUR, FIVE, SIX} # Acho que eu coloquei porque vai ser preciso para o spawnpoint
@export var current_face = FACE.SIX
#TODO: A câmera poderia ter o enum FACE


## INTERAÇÃO COM PORTAIS
func _on_portal_nearby(is_near : bool) -> void:
	PORTAL_UI.visible = is_near
	SIDE_OF_PORTAL = raycasts.get_side()
	print(SIDE_OF_PORTAL)
	
func _on_portal_entered(destination : Vector3, face : int) -> void:
	# Mudando a FACE do cubo para o PLAYER
	global_position = destination
	current_face = face # Essa variável da apontando como não usada? Fernando aq, e ela n ta sendo usada. Leo aqui, ainda nao ta sendo usada, mas vai ser, someday
	PORTAL_UI.visible = false
	
	# Mudando a orientação com base na nova FACE
	velocity = Vector3.ZERO
	camera._change_orientation(SIDE_OF_PORTAL)
	FREEZE = true
	await get_tree().create_timer(1.0).timeout
	FREEZE = false
	



## FUNÇÕES AUXILIARES
# Função Auxiliar: Projeção Vetorial no Plano
func project_on_plane(v: Vector3, normal: Vector3) -> Vector3:
	return v - normal * v.dot(normal)
	

func _update_orientation() -> void:
	_orientation = camera.global_transform.basis
	up = _orientation.y
	right = _orientation.x
	forward = _orientation.z
	
# Função Auxiliar: Direção do Movimento
func _update_movement_direction(delta):
	input.update(delta)
	move_direction = right * input.move.x + forward * input.move.y
	#direction_v = up * 
	if input.has_movement():
		move_direction = move_direction.normalized()
	else:
		move_direction = Vector3.ZERO	
	
func _update_facing_direction(delta):
	if move_direction != Vector3.ZERO:
		_facing_direction = _facing_direction.slerp(move_direction, 10.0 * delta)
	_facing_direction.normalized()

	
## INICIALIZAÇÃO
func _ready() -> void:
	input = PlayerInput.new()
	_update_orientation()
	
	PORTAL_UI.visible = false
	camera.orientation_changed.connect(_change_gravity) #captura um signal quando o up muda
	for portal in get_tree().get_nodes_in_group("Portals"):
		portal.player_entered.connect(_on_portal_entered)
		portal.player_nearby.connect(_on_portal_nearby)

## PROCESSOS
func _physics_process(delta : float) -> void:
	_update_orientation()
	
	_update_movement_direction(delta)
	_update_facing_direction(delta)
	_update_state(delta)
	
	_handle_gravity(delta)
	_handle_actions()
	_handle_movement(delta)
	
	if FREEZE:
		velocity = Vector3.ZERO
	
	#NAO SPAMMAR DASH NO CHAO
	if dash_ground_timer > 0.0:
		dash_ground_timer -= delta
	
	move_and_slide()


## FÍSICA DO PLAYER
# Lógica da Física: MOMENTO
func _physics_momentum(delta: float, limit: float, accel: float, friction: float):
	var velocity_v = up * velocity.dot(up)
	var velocity_h = velocity - velocity_v
	
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
	return move_direction.dot(-normal) > 0.1
	

func _update_state(delta : float):
	var fatigue = 0.0
	
	if is_on_floor() and state != STATE.DASHING and not input.climb.is_down:
		state = STATE.GROUNDED
		has_dash = true
		if stamina < 100.0: fatigue = REST_FATIGUE
	
	elif is_on_wall():
		if input.climb.is_down and stamina > 0.0:
			if input.has_movement():
				state = STATE.CLIMBING
			else:
				state = STATE.STEADY
			fatigue = CLIMB_FATIGUE	
							
		elif is_pushing_wall() and stamina > -50.0:
			state = STATE.SLIDING
			fatigue = SLIDE_FATIGUE
			
		elif state != STATE.DASHING:
			state = STATE.AIRBORNE
			
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
	if input.jump.is_triggered() and _can_jump():
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
	# 	   um pouco para cima, não era para isso ser possível
	var normal = get_wall_normal().normalized()
	
	if state == STATE.STEADY and move_direction.dot(-normal) < 0.7:
		velocity = up * JUMP_VERTICAL_BOOST + (normal + _facing_direction) * WALL_JUMP_PUSHWAY
		
	if state in [STATE.SLIDING, STATE.CLIMBING]:
		velocity = up * JUMP_VERTICAL_BOOST + normal * WALL_JUMP_PUSHWAY
	else:
		velocity -= up * velocity.dot(up)
		velocity += up * JUMP_VERTICAL_BOOST + move_direction * JUMP_HORIZONTAL_BOOST
	
## MOVIMENTAÇÃO DO PLAYER
# Controle do Sistema: GRAVIDADE
func _handle_gravity(delta : float):
	if state in [STATE.AIRBORNE, STATE.SLIDING]:
		gravity = GRAVITY
		
		var speed_v = velocity.dot(up)
		var speed_h = velocity.dot(move_direction)
		var terminal_speed = -TERMINAL_SPEED
		
		match state:
			# Ajusta a suavidade da ascensão/queda.
			STATE.AIRBORNE:
				if speed_v < 0.0:
					gravity *= FALL_MULT
				else:
					gravity *= ASCEND_MULT
					
					# Controle da distância/altura do pulo.
					if input.jump.released:
						velocity -= up * speed_v * 0.6
					
						if speed_h > 0.0:
							velocity -= move_direction * speed_h * 0.4
					
			# Limita a velocidade do SLIDE.	
			STATE.SLIDING:
				gravity *= SLIDE_MULT
				terminal_speed = -SLIDE_SPEED
				# Aplica SLIDE_FRICTION para segurar a velocidade da queda.
				
		if speed_v > terminal_speed:
			velocity -= up * gravity * delta #* friction * delta
			


# Controle do Sistema: MOVIMENTAÇÃO E MOMENTO
func _handle_movement(delta : float):
	match state:
		STATE.GROUNDED:
			_physics_momentum(delta, SPEED, ACCELERATION, FRICTION)
		STATE.AIRBORNE:
			_physics_momentum(delta, AIR_SPEED, ACCELERATION, AIR_RESISTANCE * 0.6)
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
