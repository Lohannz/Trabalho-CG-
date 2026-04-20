extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 15.0
var GRAVITY = 20
var WALL_SLIDE_VELOCITY = 0.3


enum State {GROUNDED, AIRBORNE, CLIMBING }
var state := State.GROUNDED
var can_jump := 2 


enum Face{ ONE, TWO, THREE, FOUR, FIVE, SIX}
var actual_face := Face.ONE
# horizontal, vertical e gravidade
var new_axis := {
	Face.ONE  : {"h": Vector3( 1, 0,  0), "v": Vector3( 0, 0, 1), "g": Vector3(0, -1,  0)},
	Face.TWO  : {"h": Vector3( 0, 0, -1), "v": Vector3( 1, 0,  0), "g": Vector3(0, -1,  0)},
	Face.THREE: {"h": Vector3( 0, 0,  1), "v": Vector3(-1, 0,  0), "g": Vector3(0, -1,  0)},
	Face.FOUR : {"h": Vector3( 1, 0,  0), "v": Vector3( 0, 1,  0), "g": Vector3(0,  0,  1)},
	Face.FIVE : {"h": Vector3( 1, 0,  0), "v": Vector3( 0,-1,  0), "g": Vector3(0,  0, -1)},
	Face.SIX  : {"h": Vector3(-1, 0,  0), "v": Vector3( 0, 0,  1), "g": Vector3(0, -1,  0)},
}
func _ready() -> void:
	pass	
	
func _physics_process(delta: float) -> void:
	_update_state()
	_player_input()
	_handle_gravity(delta)
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
			

# Responsável pela verificação de escalada (Ex. Layer escaláveis)
func _wants_to_climb():
	return is_on_wall() and Input.is_action_pressed("ui_accept")
	
var _was_climbing = false
func _handle_gravity(delta):
	_was_climbing = (state == State.CLIMBING)
	
	match state:
		State.GROUNDED:
			pass
		State.CLIMBING:
			var g = new_axis[actual_face]["g"]
			velocity += g * WALL_SLIDE_VELOCITY * delta
		State.AIRBORNE:
			var g = new_axis[actual_face]["g"]
			velocity += g * GRAVITY * delta

func _player_input():
	
	if Input.is_action_just_pressed("ui_accept") and can_jump > 0:
		if not  (state == State.CLIMBING and not _was_climbing):
			velocity.y = JUMP_VELOCITY
			can_jump -= 1
			if state == State.CLIMBING:
				state = State.AIRBORNE	
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	#### ERRO DA DIREÇÃO PROVAVELMENTE AQUI#####
	var actual_axis = new_axis[actual_face]
	var direction : Vector3 = actual_axis["h"] * input_dir.x + actual_axis["v"] * input_dir.y
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
		velocity.z = direction.z * SPEED
				
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	_change_face()
	##########
	
func _change_face():
	if Input.is_action_just_pressed("ui_right"):
		actual_face += 1
	elif Input.is_action_just_pressed("ui_left"):
		actual_face -= 1
		
	if actual_face >= 6:
		actual_face = 0
	elif actual_face < 0:
		actual_face = 5
		
