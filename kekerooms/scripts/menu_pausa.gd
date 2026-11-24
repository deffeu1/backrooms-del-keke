extends CanvasLayer

@export_file("*.tscn") var ruta_menu_principal := "res://escenas/menu_principal.tscn"
@export_file("*.tscn") var ruta_nivel_1 := "res://escenas/nivel_backrooms.tscn"
@export_file("*.tscn") var ruta_poolrooms := "res://escenas/nivel_poolrooms.tscn"

@onready var contenedor: Control = $ContenedorPausa
@onready var boton_reanudar: Button = $ContenedorPausa/VBoxContainer/BotonReanudar
@onready var boton_nivel_1: Button = $ContenedorPausa/VBoxContainer/BotonNivel1
@onready var boton_poolrooms: Button = $ContenedorPausa/VBoxContainer/BotonPoolrooms
@onready var boton_menu: Button = $ContenedorPausa/VBoxContainer/BotonMenu
@onready var sonido_hover: AudioStreamPlayer = $SonidoHover
@onready var sonido_click: AudioStreamPlayer = $SonidoClick

func _ready() -> void:
	contenedor.visible = false
	get_tree().paused = false
	
	for boton in $ContenedorPausa/VBoxContainer.get_children():
		if boton is Button:
			boton.mouse_entered.connect(_reproducir_hover)
			boton.pressed.connect(_reproducir_click)
	
	boton_reanudar.pressed.connect(_reanudar)
	boton_nivel_1.pressed.connect(_cambiar_nivel.bind(ruta_nivel_1))
	boton_poolrooms.pressed.connect(_cambiar_nivel.bind(ruta_poolrooms))
	boton_menu.pressed.connect(_ir_al_menu)

func _reproducir_hover() -> void:
	sonido_hover.pitch_scale = randf_range(0.96, 1.04)
	sonido_hover.play()

func _reproducir_click() -> void:
	sonido_click.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_reanudar()
		else:
			_pausar()

func _pausar() -> void:
	contenedor.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _reanudar() -> void:
	contenedor.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _cambiar_nivel(ruta: String) -> void:
	await get_tree().create_timer(0.12, true).timeout
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file(ruta)

func _ir_al_menu() -> void:
	await get_tree().create_timer(0.12, true).timeout
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(ruta_menu_principal)
