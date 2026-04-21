extends CharacterBody3D
@onready var camera = $Camera3D
@onready var areaDetection = $areaDetection


const SPEED = 10.0
const JUMP_VELOCITY = 15.0
var GRAVITY = 20
var WALL_SLIDE_VELOCITY = 0.3

enum State {GROUNDED, AIRBORNE, CLIMBING }
var state := State.GROUNDED
var can_jump := 2 

## CUBO
	# Face e sua correspondente coordenada
enum FACE {ONE, TWO, THREE, FOUR, FIVE, SIX}
#var faces := {ONE : {},}


## CAMERA
var	CAM_BASIS
var FOWARD : Vector3
var RIGHT : Vector3
var UP : Vector3

var gravity : Vector3 =	Vector3(0, -1 , 0)

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
	pass 

func _physics_process(delta: float) -> void:
	# movimento baseado na camera
	CAM_BASIS = camera.global_transform.basis
	FOWARD = (CAM_BASIS.z * Vector3(1, 0, 1)).normalized()
	RIGHT = (CAM_BASIS.x * Vector3(1, 0, 1)).normalized()
	
	_handle_portal()
	_update_state()
	_change_gravity_based_on_camera()
	_handle_gravity(delta)
	_player_input()
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
			velocity += gravity * WALL_SLIDE_VELOCITY * delta
			#print("Estou escalando")
		State.AIRBORNE:
			velocity += gravity * GRAVITY * delta
			#print("Estou em queda")	
		
	
var _was_climbing = false
func _player_input():
	
	if Input.is_action_just_pressed("ui_accept") and can_jump > 0:
		if not  (state == State.CLIMBING and not _was_climbing):
			velocity -= gravity * JUMP_VELOCITY
			can_jump -= 1
			if state == State.CLIMBING:
				state = State.AIRBORNE	
				
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var direction = (RIGHT * input_dir.x + FOWARD * input_dir.y).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
func _change_gravity_based_on_camera():
	UP = FOWARD.cross(RIGHT).normalized()
	up_direction = UP
	gravity = -UP
	
	
