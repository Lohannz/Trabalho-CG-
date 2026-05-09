class_name Cooldown
signal ready
var timer 	 : float = 0.0
var duration : float = 0.0

func _init(cool_duration: float):
	duration = cool_duration
	
func start():
	if  timer <= 0.0:
		timer = duration
func is_ready() -> bool: return timer <= 0.0
func update(delta: float):
	if timer > 0.0:
		timer = max(timer - delta, 0.0)
		if timer <= 0.0: ready.emit()
