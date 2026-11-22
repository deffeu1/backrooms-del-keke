extends CanvasLayer

@export_file("*.tscn") var ruta_menu_principal := "res://escenas/menu_principal.tscn"

@onready var contenedor: Control = $ContenedorPausa
@onready var boton_reanudar: Button = $ContenedorPausa/VBoxContainer/BotonReanudar
@onready var boton_menu: Button = $ContenedorPausa/VBoxContainer/BotonMenu

func _ready() -> void:
	# Empieza oculto y con el juego corriendo
	contenedor.visible = false
	get_tree().paused = false
	
	boton_reanudar.pressed.connect(_reanudar)
	boton_menu.pressed.connect(_ir_al_menu)

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

func _ir_al_menu() -> void:
	# Siempre despausar antes de cambiar de escena
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(ruta_menu_principal)
