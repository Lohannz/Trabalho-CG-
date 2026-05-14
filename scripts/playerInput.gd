class_name PlayerInput
extends Node
const DEADZONE := 0.001

var move := Vector2.ZERO
var jump  : PlayerAction
var dash  : PlayerAction
var climb : PlayerAction
var _actions : Array[PlayerAction] = []

func _init():
	jump  = _create_action(0.2, 0.1)
	dash  = _create_action(0.2, 2.0)
	climb = _create_action(0.4, 0.0)

func _create_action(buff_lifetime, cool_duration) -> PlayerAction:
	var action = PlayerAction.new(buff_lifetime, cool_duration)
	_actions.append(action)
	return action
	
func has_movement():
	return move.length_squared() > DEADZONE
	
func update(delta: float):
	move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	jump.update(delta, Input.is_action_pressed("action_jump"))
	dash.update(delta, Input.is_action_just_pressed("action_dash"))
	climb.update(delta, Input.is_action_pressed("action_climb"))
	# Alterar tecla do climb ou mudar para just_pressed (Não da para andar diagonal direita/cima com o 'KEY E').
