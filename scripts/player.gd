extends CharacterBody3D


const SPEED = 10.0
const JUMP_VELOCITY = 15.0

# Mecanica de escalar na parede ainda tá meio bugada a questão do double jump e funciona em qualquer parede
# Fazer com que tenha um unico pulo bonus até encostar no chão novamente
var climbing = false
func climb_surface():
	
	if is_on_wall() and not is_on_floor() and Input.is_action_pressed("ui_accept"):
		print("climbing!")
		velocity.y =  0.0
		climbing = true
	else:
		climbing = false	
	
var max_jumps = 2
var can_jump = max_jumps
var gravity_y = 20 # Só no eixo y por enquanto
func _physics_process(delta: float) -> void:
	
	# Add the gravity.
	if not is_on_floor() and not climbing:
		velocity.y -= gravity_y * delta
	else:
		can_jump = max_jumps
	
	# Pulo já com escalada.
	if Input.is_action_just_pressed("ui_accept") and can_jump:
		velocity.y = JUMP_VELOCITY
		can_jump -= 1
	climb_surface()
		
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
