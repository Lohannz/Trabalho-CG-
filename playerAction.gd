class_name PlayerAction

var buffer := 0.0
var cooldown := 0.0

var buffer_max := 0.0
var cooldown_max := 0.0

func press():
	buffer = buffer_max

func update(delta):
	buffer = max(buffer - delta, 0.0)
	cooldown = max(cooldown - delta, 0.0)

func is_buffered() -> bool:
	return buffer > 0.0 and cooldown <= 0.0

func consume():
	buffer = 0.0
	cooldown = cooldown_max

func _init(buffer_time,cooldown_time):
	buffer_max = buffer_time
	cooldown_max = cooldown_time
