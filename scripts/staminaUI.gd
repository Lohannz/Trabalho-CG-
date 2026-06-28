extends TextureProgressBar

@onready var player: CharacterBody3D = get_tree().current_scene.get_node("player")

func _ready() -> void:
	min_value = -50.0
	max_value = 100.0
	value = 100.0
	tint_progress = Color(0.192, 0.733, 1.0)

func _process(_delta: float) -> void:
	value = remap(player.stamina,-50.0,100.0,0.0,100.0)
	if player.has_dash:
		tint_progress = Color(0.192, 0.733, 1.0)
	else:
		if player.stamina <= -25.0:
			tint_progress = Color(0.45, 0.1, 0.1)
		elif player.stamina <= 0.0:
			tint_progress = Color(1.0, 0.1, 0.1)
		elif player.stamina <= 100.0:
			tint_progress = Color(1.0, 0.65, 0.2)
