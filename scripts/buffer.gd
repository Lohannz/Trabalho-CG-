class_name Buffer
var timer  	 : float = 0.0
var lifetime : float = 0.0

func _init(buff_lifetime: float):
	lifetime = buff_lifetime
func start(): timer = lifetime
func consume(): timer = 0.0
func update(delta: float): timer = max(timer - delta, 0.0)
