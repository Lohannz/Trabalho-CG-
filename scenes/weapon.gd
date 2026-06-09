extends Node3D
@onready var hitbox : Area3D = get_node("Area3D")
var damage = 10;
var can_attack = true
func _ready() -> void:
	visible = false 

func _process(delta: float) -> void:
	pass

# função que vai atacar e verificar se colidiu, se sim, retorna true
func attack():
	
	if not can_attack:
		return
	visible = true
	
	var bodies = hitbox.get_overlapping_bodies()
		
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
	await get_tree().create_timer(0.5).timeout
	visible = false
	can_attack = true
