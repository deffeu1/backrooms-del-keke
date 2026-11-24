extends Node3D

@onready var sonido_ambiente: AudioStreamPlayer = $SonidoAmbiente
@onready var timer_ambiente: Timer = $SonidoAmbiente/TimerAmbiente

var sonidos_aire_libre: Array[AudioStream] = [
	preload("res://assets/SONIDOS/ambiente/viento_suave.wav"),
	preload("res://assets/SONIDOS/ambiente/pajaros_lejanos.wav")
]

func _ready() -> void:
	timer_ambiente.timeout.connect(_on_timer_ambiente_timeout)
	iniciar_siguiente_temporizador()

func iniciar_siguiente_temporizador() -> void:
	timer_ambiente.wait_time = randf_range(8.0, 20.0)
	timer_ambiente.start()

func _on_timer_ambiente_timeout() -> void:
	if sonidos_aire_libre.size() > 0 and not sonido_ambiente.playing:
		sonido_ambiente.stream = sonidos_aire_libre.pick_random()
		sonido_ambiente.pitch_scale = randf_range(0.92, 1.08)
		sonido_ambiente.play()
	iniciar_siguiente_temporizador()
