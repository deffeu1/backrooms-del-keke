extends Node3D

func _ready() -> void:
	for nodo in find_children("*", "AudioStreamPlayer3D", true, false):
		if nodo.name != "RespiracionAudio":
			nodo.bus = &"Poolrooms"
