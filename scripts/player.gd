extends CharacterBody3D
@onready var camera = $Camera3D
@onready var areaDetection = $areaDetection


const SPEED = 10.0
const JUMP_VELOCITY = 15.0
var GRAVITY = 20
var WALL_SLIDE_VELOCITY = 0.3
var _was_climbing = false


enum State {GROUNDED, AIRBORNE, CLIMBING }
var state := State.GROUNDED
var can_jump := 2 

## DASH, tlg ne, podem mexer se quiserem, eu decho
var is_dashing := false
var can_dash := true 
var locked_dash_direction := Vector3.ZERO


## CUBO
# Face e sua correspondente coordenada
enum FACE {ONE, TWO, THREE, FOUR, FIVE, SIX}
@export var current_face = FACE.ONE


## CAMERA
var	CAM_BASIS
var FORWARD : Vector3
var RIGHT : Vector3
var UP : Vector3 = Vector3(0, 1, 0)
var gravity : Vector3 = Vector3(0, -1 , 0)

# Funcao para projecao no plano
func project_on_plane(v: Vector3, normal: Vector3) -> Vector3:
	return v - normal * v.dot(normal)

# Função responsavel por verificar colisão com portal e  chamar a _change_face
func _handle_portal():
	for area in areaDetection.get_overlapping_areas():
		if area.name == "portal 1":
			print("encostei no portal 1")
		elif area.name == "portal 2":
			print("encostei no portal 2")
		elif area.name == "portal 3":
			print("encostei no portal 3")
	
func _ready() -> void:
	camera.up_changed.connect(_change_gravity) #captura um signal quando o up muda

func _physics_process(delta: float) -> void:
	# movimento baseado na camera
	CAM_BASIS = camera.global_transform.basis
	
	# Remove movimentos na direçao do eixo UP e deixa os vetores alinhados com o "chao"
	FORWARD = project_on_plane(CAM_BASIS.z, UP).normalized() #pode ser que de merda se ficar igual ao up
	RIGHT = project_on_plane(CAM_BASIS.x, UP).normalized()   #tem que ver se vai ficar perpendicular
	
	_handle_portal()
	_update_state()
	_handle_gravity(delta)
	_player_input(delta)
	move_and_slide()

func _update_state():
	
	if is_on_floor():
		if state != State.GROUNDED:
			state = State.GROUNDED;
			can_jump = 2
	elif _wants_to_climb():
		if state != State.CLIMBING:
			state = State.CLIMBING
			can_jump = 1
	else:
		if state != State.AIRBORNE:
			state = State.AIRBORNE

# Responsável pela verificação de escadalada (Ex. Layer escaláveis)
func _wants_to_climb():
	return is_on_wall() and Input.is_action_pressed("ui_accept")
	
func _handle_gravity(delta):
	match state:
		State.GROUNDED:
			pass
			#print("Estou no chão")
		State.CLIMBING:
			var g_dir = gravity.normalized()
			velocity -= g_dir * velocity.dot(g_dir) # EU NÃO SEI POR QUE FUNCIONA OU NÃO FUNCIONA, SLA
			velocity += gravity * WALL_SLIDE_VELOCITY * delta
			#print("Estou escalando")
		State.AIRBORNE:
			velocity += gravity * GRAVITY * delta
			#print("Estou em queda")	
		
	
func _player_input(delta):
	_was_climbing = (state == State.CLIMBING)
	## PULO
	if Input.is_action_just_pressed("ui_accept") and can_jump > 0:
		if not  (state == State.CLIMBING and not _was_climbing):
			var g_dir = gravity.normalized()
			velocity -= g_dir * velocity.dot(g_dir) # zera a velocidade antes de pular dnv
			velocity -= gravity * JUMP_VELOCITY
			can_jump -= 1
			if state == State.CLIMBING:
				state = State.AIRBORNE	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Pega a direcao projetada em relacao ao UP
	var direction = (RIGHT * input_dir.x + FORWARD * input_dir.y)
	direction = project_on_plane(direction, UP).normalized()
	
	var horizontal = project_on_plane(velocity, UP)
	var vertical = UP * velocity.dot(UP)
	
	# Para o movimento caso o input pare
	if direction.length() > 0:
		horizontal = direction * SPEED
	else:
		horizontal = horizontal.move_toward(Vector3.ZERO, SPEED)

	velocity = horizontal + vertical
	
	# Checa se da pra dar dash no shift ( fora do cooldown e nao estar dashando)
	if Input.is_physical_key_pressed(KEY_SHIFT) and not is_dashing and can_dash:
		if input_dir.x != 0: # Faz nao dar dash Parado
			is_dashing = true
			can_dash = false # Trava o dash com coodlown
			locked_dash_direction = (RIGHT * input_dir.x).normalized()
			
			# Duração do dash - Da pra mudar dentro desse timer ae
			get_tree().create_timer(0.15).timeout.connect(func(): is_dashing = false)
			
			# Cooldown do dash - Da pra mudar dentro desse timer ae
			get_tree().create_timer(0.3).timeout.connect(func(): can_dash = true)
			
	# 2. Executa o dash rapidao
	if is_dashing:
		# Faz o dash e trava a direção papai
		velocity.x = locked_dash_direction.x * 40.0 
		velocity.z = locked_dash_direction.z * 40.0
	
# Ativa quando o Up mudar no playerCamera
func _change_gravity(newUp: Vector3):
	#UP = FOWARD.cross(RIGHT).normalized()
	print("Recebi o signal - newUp: ", newUp)
	UP = newUp
	up_direction = UP
	gravity = -UP
	
