extends Camera3D

@export var distancia := 25.0
@export var lerp_speed := 3.0
signal up_changed(newUp)

# Listas circulares em relaçao a um eixo dominate (quem controla cima ou baixo)
var listY := [
	{"num": 6, "cam": Vector3(0, 0, -1), "nUp": Vector3(0,0,1)}, #6
	{"num": 3, "cam": Vector3(-1, 0, 0), "nUp": Vector3(1,0,0)},  #3
	{"num": 1, "cam": Vector3(0, 0, 1), "nUp": Vector3(0,0,-1)}, #1
	{"num": 2, "cam": Vector3(1, 0, 0), "nUp": Vector3(-1,0,0)} #2
]
var listZ := [
	{"num": 4, "cam": Vector3(0, 1, 0), "nUp": Vector3(0,-1,0)},  #4
	{"num": 3, "cam": Vector3(-1, 0, 0), "nUp": Vector3(1,0,0)},  #3
	{"num": 5, "cam": Vector3(0, -1, 0), "nUp": Vector3(0,1,0)},  #5
	{"num": 2, "cam": Vector3(1, 0, 0), "nUp": Vector3(-1,0,0)}  #2
]
var listX := [
	{"num": 1, "cam": Vector3(0, 0, 1), "nUp": Vector3(0,0,-1)},  #1
	{"num": 5, "cam": Vector3(0, -1, 0), "nUp": Vector3(0,1,0)},  #5
	{"num": 6, "cam": Vector3(0, 0, -1), "nUp": Vector3(0,0,1)},  #6
	{"num": 4, "cam": Vector3(0, 1, 0), "nUp": Vector3(0,-1,0)}   #4
]

# inicializaçao padrao das variaveis
var face_atual = Vector3(0, 0, 1) 
var currentUp = Vector3(0,1,0) # mostra o lado de cima da camera
var currentList = listY
var currentIndex = 2
var state

func _ready() -> void:
	position = face_atual * distancia

# funcao pra pegar o eixo, lista referente ao eixo e o seu sinal
func get_axis_and_sign(up: Vector3):
	var abs_up = up.abs()
	
	#verifica quem eh o eixo dominante
	if abs_up.x > abs_up.y and abs_up.x > abs_up.z:
		return {"axis": "x", "axisList": listX, "sign": sign(up.x)}
	elif abs_up.y > abs_up.z:
		return {"axis": "y", "axisList": listY, "sign": sign(up.y)}
	else:
		return {"axis": "z", "axisList": listZ, "sign": sign(up.z)}	

# funcao para atualizar o index ao trocar de listas
func updateIndex(axis, sign):
	#debug
	print("sign: ", sign)
	print("axis: ", axis)
	
	# define o numero da face que deve procurar (fixos para cada lista/eixo)
	var targetNum
	if axis == "x":
		if sign >= 0:
			targetNum = 2
		else:
			targetNum = 3
	if axis == "y":
		if sign >= 0:
			targetNum = 4
		else:
			targetNum = 5
	if axis == "z":
		if sign >=0:
			targetNum = 1
		else:
			targetNum = 6
	
	# atuliza o index depois de achar na lista
	for i in range(currentList.size()):
		print(i)
		if currentList[i]["num"] == targetNum:
			currentIndex = i
			break

# funcao de debug
func debug():
	print("Index: ", currentIndex)
	print("Lista: ", get_axis_and_sign(currentUp)["axis"])
	print("Up: ", currentUp)
	print("Face: ", currentList[currentIndex]["num"])
	print()

func _process(delta: float) -> void:
	# Se for direita ou esquerda so anda na lista atual
	# Se for cima ou baixo tem que troca de lista
	
	if Input.is_action_just_pressed("ui_right"):
		var upSign = get_axis_and_sign(currentUp)["sign"]
		
		if upSign >= 0:
			currentIndex = (currentIndex + 1) % currentList.size()
		else:
			currentIndex = (currentIndex - 1 + currentList.size()) % currentList.size()
			
	if Input.is_action_just_pressed("ui_left"):
		var upSign = get_axis_and_sign(currentUp)["sign"]
		
		if upSign >= 0:
			currentIndex = (currentIndex - 1 + currentList.size()) % currentList.size()
		else:
			currentIndex = (currentIndex + 1) % currentList.size()
	
	if Input.is_action_just_pressed("ui_up"):
		var info = get_axis_and_sign(currentUp)       # pega as info do eixo antes de atualizar o up
		currentUp = currentList[currentIndex]["nUp"]  # atualiza o up
		currentList = get_axis_and_sign(currentUp)["axisList"]  # entra na lista do novo eixo
		updateIndex(info["axis"], info["sign"])                 # atualiza o index
		emit_signal("up_changed", currentUp)
		
		debug()
		
	if Input.is_action_just_pressed("ui_down"):
		var info = get_axis_and_sign(currentUp)
		currentUp = currentList[currentIndex]["nUp"] * Vector3(-1,-1,-1) #negativo pq pra baixo eh invertido
		currentList = get_axis_and_sign(currentUp)["axisList"]
		updateIndex(info["axis"], -1*info["sign"])    #negativo pq pra baixo eh invertido
		emit_signal("up_changed", currentUp)
		debug()
		
	# pega o novo estado na lista e sua face
	state = currentList[currentIndex]
	face_atual = state["cam"]
	
	# atualiza a posicao da camera
	position = position.lerp(face_atual * distancia, lerp_speed * delta)  
	
	# sempre olha para o jogador e mantem o up na orientacao certa
	look_at(get_parent().global_position, currentUp)
