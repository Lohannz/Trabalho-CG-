extends Node3D

@export var cooldown_timer : float = 4.5
@export var event_duration : float = 6.0

var active_event := false
var snows : Array[GPUParticles3D]

@onready var weather = get_tree().current_scene.get_node("Camera3D/Pos-processamento/Nevasca/nevasca")
@onready var mist = $"Nevoa"
@onready var blizzard = self

func _ready():
	for snow in blizzard.get_children():
		if snow is GPUParticles3D:
			snows.append(snow)
		
	weather.hide()
	mist.hide()
	event_loop()

func event_loop():
	while true:
		await get_tree().create_timer(cooldown_timer).timeout
		start_blizzard()

		await get_tree().create_timer(event_duration).timeout
		end_blizzard()

func start_blizzard():
	active_event = true
	mist.get_node("NevoaBody/NevoaCol").disabled = false

	for snow in snows:
		var particle : ParticleProcessMaterial = snow.process_material
		particle.initial_velocity_min = 10.0
		particle.initial_velocity_max = 20.0
		particle.linear_accel_min = 30.0
		particle.linear_accel_max = 50.0
		snow.speed_scale = 10.0
		snow.amount = 1500
	
	var screen_blizz = weather.material as ShaderMaterial
	screen_blizz.set_shader_parameter("weather_fog",0.6)
	screen_blizz.set_shader_parameter("wind",7.0)
	
	weather.show()
	mist.show()

func end_blizzard():
	active_event = false
	mist.get_node("NevoaBody/NevoaCol").disabled = true

	for snow in snows:
		var particle : ParticleProcessMaterial = snow.process_material
		particle.initial_velocity_min = 0.0
		particle.initial_velocity_max = 5.0
		particle.linear_accel_min = 0.0
		particle.linear_accel_max = 0.0
		snow.speed_scale = 1.0
		snow.amount = 500
		
		
	weather.hide()
	mist.hide()
