class_name PlayerInput
const MOVE_BUFFER_MAX := 0.1

var move := Vector2.ZERO
var move_buffer := Vector2.ZERO
var move_buffer_time := 0.0

var jump : PlayerAction
var dash : PlayerAction
var climb : PlayerAction

func _init():
	jump = PlayerAction.new(0.15,0.1)
	dash = PlayerAction.new(0.1,1.0)
	climb = PlayerAction.new(0.2,0.2)
	
func update(delta):
	var raw_move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# --- buffer de movimento ---
	if raw_move.length() > 0:
		move_buffer = raw_move
		move_buffer_time = MOVE_BUFFER_MAX
	else:
		move_buffer_time = max(move_buffer_time - delta, 0.0)
	
	move = move_buffer if move_buffer_time > 0.05 else Vector2.ZERO
	
	if Input.is_action_just_pressed("ui_accept"):
		jump.press()
		
	if Input.is_physical_key_pressed(KEY_SHIFT):
		dash.press()
	
	# Não ta implementado.
	if Input.is_physical_key_pressed(KEY_E):
		climb.press()
	
	jump.update(delta)
	dash.update(delta)
	climb.update(delta)
