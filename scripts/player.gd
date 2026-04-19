extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 15.0
var GRAVITY = 20
var WALL_SLIDE_VELOCITY = 0.3

enum State {GROUNDED, AIRBORNE, CLIMBING }
var state := State.GROUNDED
var can_jump := 2 

func _physics_process(delta: float) -> void:
	_update_state()
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
			print("Estou no chão")
		State.CLIMBING:
			velocity.y -= WALL_SLIDE_VELOCITY * delta
			print("Estou escalando")
		State.AIRBORNE:
			velocity.y -= GRAVITY * delta
			print("Estou em queda")	
		
	
var _was_climbing = false
func _player_input():
	
	if Input.is_action_just_pressed("ui_accept") and can_jump > 0:
		if not  (state == State.CLIMBING and not _was_climbing):
			velocity.y = JUMP_VELOCITY
			can_jump -= 1
			if state == State.CLIMBING:
				state = State.AIRBORNE	
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
