extends Node3D

func _ready() -> void:
	for nodo in find_children("*", "AudioStreamPlayer3D", true, false):
		if nodo.name != "RespiracionAudio":
			nodo.bus = &"Poolrooms"
	
	var jugador := find_child("Jugador", true, false)
	if jugador and "puede_saltar" in jugador:
		jugador.puede_saltar = true
