extends Node3D

@export var tiempo_minimo := 18.0
@export var tiempo_maximo := 45.0
@export var distancia_minima := 10.0
@export var distancia_maxima := 22.0

@onready var sonido_aleatorio: AudioStreamPlayer3D = $SonidoAmbienteAleatorio
@onready var timer_sonido: Timer = $SonidoAmbienteAleatorio/TimerSonidoAleatorio
@onready var jugador: Node3D = find_child("Jugador", true, false)

func _ready() -> void:
	for nodo in find_children("*", "AudioStreamPlayer3D", true, false):
		if nodo.name != "RespiracionAudio":
			nodo.bus = &"Poolrooms"
	
	if jugador and "puede_saltar" in jugador:
		jugador.puede_saltar = true
	
	timer_sonido.timeout.connect(_reproducir_sonido_aleatorio)
	_programar_siguiente_sonido()

func _programar_siguiente_sonido() -> void:
	timer_sonido.wait_time = randf_range(tiempo_minimo, tiempo_maximo)
	timer_sonido.start()

func _reproducir_sonido_aleatorio() -> void:
	if jugador:
		var angulo := randf() * TAU
		var distancia := randf_range(distancia_minima, distancia_maxima)
		var desplazamiento := Vector3(cos(angulo) * distancia, 0.0, sin(angulo) * distancia)
		sonido_aleatorio.global_position = jugador.global_position + desplazamiento
	
	sonido_aleatorio.pitch_scale = randf_range(0.92, 1.08)
	sonido_aleatorio.play()
	_programar_siguiente_sonido()
