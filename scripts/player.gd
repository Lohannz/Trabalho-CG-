extends CharacterBody3D
@onready var camera = $Camera3D
@onready var areaDetection = $areaDetection
@onready var PORTAL_UI = $UI/ui_entered_portal
@onready var raycasts = $Raycasts

# Constantes: Movimentação do Player
const GRAVITY = 30.0
const SPEED = 15.0
const JUMP_VELOCITY = 20.0
const DASH_SPEED = 25.0

const SPEED_ACCELERATION = 32.0
const DASH_ACCELERATION = 45.0
const FRICTION = 18.0
const AIR_RESISTANCE = 22.5

const WALL_CLIMB_SPEED = 2.0 # Não ta implementado.
const WALL_CLIMB_FRICTION = 0.65
const WALL_JUMP_PUSHWAY = 12.0

# Constantes: Estados/Ações do Player
enum ACTION {MOVE,JUMP,CLIMB,DASH}
enum MOVEMENT_STATE {GROUNDED, AIRBORNE, CLIMBING, DASHING}
var state := MOVEMENT_STATE.GROUNDED

# Variáveis: Orientação da Câmera
var _orientation : Basis

# Variáveis: Input do Player
var input: PlayerInput

## Toda essa seção de portal não mudei nada.
## Acho que não deveria ter nada de portal dentro do player
# Variáveis: Orientação da Cubo
enum FACE {ONE, TWO, THREE, FOUR, FIVE, SIX} # Acho que eu coloquei porque vai ser preciso para o spawnpoint
var current_face = FACE.SIX

var IN_WIND : bool = false
var WIND_FORCE : Vector3 = Vector3.ZERO

var SIDE_OF_PORTAL : String # Variavel que guarda, se houver, o lado do portal

func _on_portal_nearby(is_near : bool) -> void:
	PORTAL_UI.visible = is_near
	SIDE_OF_PORTAL = raycasts.get_side()
	
func _on_portal_entered(destination : Vector3, face : int) -> void:
	## MUDANDO DE FACE
	global_position = destination
	current_face = face
	PORTAL_UI.visible = false
	
	## MUDAR ORIENTAÇÂO
	camera._change_orientation(SIDE_OF_PORTAL)

# Função Auxiliar: Projeção Vetorial no Plano
func project_on_plane(v: Vector3, normal: Vector3) -> Vector3:
	return v - normal * v.dot(normal)
	
# Função Auxiliar: Computar Direção do Movimento
func _get_move_direction() -> Vector3:
	var right = _orientation.x
	var forward = _orientation.z
	var direction = (right * input.move.x + forward * input.move.y)
	direction = project_on_plane(direction, _orientation.y)
	return direction.normalized() if direction.length() > 0.001 else Vector3.ZERO
	
func _ready():
	input = PlayerInput.new()
	_orientation = camera.global_transform.basis
	
	PORTAL_UI.visible = false
	camera.up_changed.connect(_change_gravity) #captura um signal quando o up muda
	for portal in get_tree().get_nodes_in_group("Portals"):
		portal.player_entered.connect(_on_portal_entered)
		portal.player_nearby.connect(_on_portal_nearby)

func _physics_process(delta: float) -> void:
	_orientation = camera.global_transform.basis
	
	var up = _orientation.y
	var right = _orientation.x
	var forward = _orientation.z
	
	# Verificar se importa forward e right ficarem perpendiculares
	forward = project_on_plane(forward, up).normalized()
	right = project_on_plane(right, up).normalized()
	
	#_handle_portal()
	input.update(delta)
	
	_update_state()
	_handle_actions(delta)
	_handle_gravity(delta)
	_handle_movement(delta)
	
	move_and_slide()
	
# Tentativa de Calcular Momento.
# Limit deveria ser a Velocidade Máxima Geral (TERMINAL)
# Limit no momento é a Velocidade Máxima (SPEED ou DASH_SPEED)
func _physics_momentum(delta, limit: float, acceleration: float):
	
	var up = _orientation.y
	var direction = _get_move_direction()
	
	var vertical = up * velocity.dot(up)
	var horizontal = velocity - vertical
	
	if direction.length() > 0:
		horizontal = horizontal.move_toward(direction * limit, acceleration * delta)
	else:
		var friction = FRICTION if is_on_floor() else AIR_RESISTANCE
		horizontal = horizontal.move_toward(Vector3.ZERO, friction * delta)
		
	if IN_WIND:
		vertical += WIND_FORCE * delta # tanto faz vertical ou horizontal
		
	velocity = horizontal + vertical

# Função de Controle: Ações do Player
func _handle_actions(delta):
	if input.dash.is_buffered() and _can_execute(ACTION.DASH):
		_execute_dash(delta)
		input.dash.consume()
		
	if input.jump.is_buffered() and _can_execute(ACTION.JUMP):
		_execute_jump()
		input.jump.consume()
		
	if input.climb.is_buffered() and _can_execute(ACTION.CLIMB):
		#_move_climb()
		input.climb.consume()
		
# Função de Controle: Condições para Ações do Player
# Acho que precisa melhorar as condições sem criar variáveis : bool desnecessárias
func _can_execute(action):
	var condition : bool
	match action:
		ACTION.DASH:
			condition = state == MOVEMENT_STATE.AIRBORNE
		ACTION.JUMP:
			condition = state in [MOVEMENT_STATE.GROUNDED,MOVEMENT_STATE.CLIMBING]
		ACTION.CLIMB:
			condition = state == MOVEMENT_STATE.CLIMBING
	return condition
	
func _update_state():
	if is_on_floor():
		state = MOVEMENT_STATE.GROUNDED
	elif is_on_wall():
		state = MOVEMENT_STATE.CLIMBING
	else:
		state = MOVEMENT_STATE.AIRBORNE
	# Não tem DASHING, não pensei em uma condição para troca de estado, sem ser ativar o DASH (Dãããr)

func _handle_gravity(delta):
	if state != MOVEMENT_STATE.GROUNDED:
		var grav_dir = -_orientation.y.normalized()
		match state:
			MOVEMENT_STATE.CLIMBING:
				# Reduz o peso da gravidade - Wall Slide
				velocity += grav_dir * (GRAVITY * WALL_CLIMB_FRICTION) * delta
			MOVEMENT_STATE.AIRBORNE:
				# Talvez dê para integrar o momento aqui?
				# Dar mais peso à gravidade com outra equação?
				velocity += grav_dir * GRAVITY * delta
				
func _handle_movement(delta):
	match state:
		MOVEMENT_STATE.GROUNDED, MOVEMENT_STATE.AIRBORNE:
			_physics_momentum(delta, SPEED, SPEED_ACCELERATION)
		MOVEMENT_STATE.DASHING:
			_physics_momentum(delta, DASH_SPEED, DASH_ACCELERATION)

# Não implementado, pode deixar o atual.
func _move_climb():
	pass

func _execute_dash(delta):
	state = MOVEMENT_STATE.DASHING
	var direction = _get_move_direction()
	if direction.length() > 0.01:
		velocity += direction.normalized() * DASH_SPEED
	
		get_tree().create_timer(0.05).timeout.connect(
			func(): if state == MOVEMENT_STATE.DASHING: state = MOVEMENT_STATE.AIRBORNE)
	
func _end_dash():
	if state == MOVEMENT_STATE.DASHING:
		_update_state()	

func _execute_jump():
	var up = _orientation.y
	if state == MOVEMENT_STATE.CLIMBING:
		var normal = get_wall_normal()
		velocity += normal * WALL_JUMP_PUSHWAY
	velocity += up * JUMP_VELOCITY
	
# Ativa quando o Up mudar no playerCamera
func _change_gravity(newUp: Vector3):
	print("Recebi o signal - newUp: ", newUp)
	var up = newUp
	up_direction = up
	#gravity = -UP
