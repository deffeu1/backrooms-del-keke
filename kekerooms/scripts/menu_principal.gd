extends Control

@export_file("*.tscn") var ruta_nivel := "res://escenas/nivel_backrooms.tscn"

@onready var boton_jugar: Button = $CapaUI/BotonJugar
@onready var boton_salir: Button = $CapaUI/BotonSalir
@onready var sonido_hover: AudioStreamPlayer = $SonidoHover
@onready var sonido_click: AudioStreamPlayer = $SonidoClick

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	for boton in $CapaUI.get_children():
		if boton is Button:
			boton.mouse_entered.connect(_reproducir_hover)
			boton.pressed.connect(_reproducir_click)
	
	boton_jugar.pressed.connect(_al_presionar_jugar)
	boton_salir.pressed.connect(_al_presionar_salir)

func _reproducir_hover() -> void:
	sonido_hover.pitch_scale = randf_range(0.96, 1.04)
	sonido_hover.play()

func _reproducir_click() -> void:
	sonido_click.play()

func _al_presionar_jugar() -> void:
	await get_tree().create_timer(0.12).timeout
	get_tree().change_scene_to_file(ruta_nivel)

func _al_presionar_salir() -> void:
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()
