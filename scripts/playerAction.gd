class_name PlayerAction
var buffer   : Buffer
var cooldown : Cooldown

var pressed  := false
var released := false
var is_down := false

func _init(buff_lifetime: float = 0.0, cool_duration: float = 0.0):
	buffer = Buffer.new(buff_lifetime)
	cooldown = Cooldown.new(cool_duration)

func update(delta: float, just_pressed: bool):
	pressed = false
	released = false
	
	if just_pressed and not is_down:
		pressed = true
		buffer.start()
		
	elif not just_pressed and is_down:
		released = true
	
	is_down = just_pressed

	buffer.update(delta)
	cooldown.update(delta)

func is_triggered() -> bool:
	return buffer.is_buffered() and cooldown.is_ready()

func consume():
	buffer.consume()
	cooldown.start()
