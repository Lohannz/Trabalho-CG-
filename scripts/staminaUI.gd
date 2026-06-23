extends TextureProgressBar

@onready var player: CharacterBody3D = $"../../../../player"

func _ready() -> void:
	min_value = -50.0
	max_value = 100.0
	value = 100.0
	tint_progress = Color(0.192, 0.733, 1.0, 1.0) # verde padrão

func _process(_delta: float) -> void:
	value = player.stamina
	
	if player.stamina <= 0.0:
		tint_progress = Color(1.0, 0.1, 0.1) # vermelho: exausto
	elif player.state == 2 or player.state == 5: # CLIMBING ou SLIDING
		tint_progress = Color(1.0, 0.65, 0.2) # laranja clarinho
	else:
		tint_progress = Color(0.192, 0.733, 1.0, 1.0) # verde padrão
