extends Node3D

@export var cooldown_timer : float = 4.5
@export var event_duration : float = 6.0

var active_event := false
var nevoas = []
@onready var Nevasca = $"/root/Principal/Camera3D/Pos-processamento/nevasca"
@onready var Nevoa = $"../Nevoa"

func _ready():
	for node in get_tree().get_nodes_in_group("neblina"):
		nevoas.append(node)
		node.collision_layer = 2
		
		print(node.name)
		print(node.get_class())
		
	Nevasca.hide()
	Nevoa.hide()
	event_loop()

func event_loop():
	while true:
		await get_tree().create_timer(cooldown_timer).timeout
		start_nevasca()

		await get_tree().create_timer(event_duration).timeout
		end_nevasca()

func start_nevasca():
	active_event = true

	for n in nevoas:
		n.collision_layer = 1
		
	Nevasca.show()
	Nevoa.show()

func end_nevasca():
	active_event = false

	for nevoa in nevoas:
		nevoa.collision_layer = 2

	Nevasca.hide()
	Nevoa.hide()
