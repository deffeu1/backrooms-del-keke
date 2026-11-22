extends Control

@export_file("*.tscn") var ruta_nivel := "res://escenas/nivel_backrooms.tscn"

@onready var boton_jugar: Button = $CapaUI/BotonJugar
@onready var boton_salir: Button = $CapaUI/BotonSalir

func _ready() -> void:
	# Asegura que el mouse esté libre si vienes de una pantalla anterior
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	boton_jugar.pressed.connect(_al_presionar_jugar)
	boton_salir.pressed.connect(_al_presionar_salir)

func _al_presionar_jugar() -> void:
	get_tree().change_scene_to_file(ruta_nivel)

func _al_presionar_salir() -> void:
	get_tree().quit()
