extends CharacterBody3D

@export_group("Movimiento y Estamina")
@export var velocidad_caminar := 4.0
@export var velocidad_correr := 6.8
@export var estamina_maxima := 100.0
@export var gasto_estamina := 28.0
@export var regeneracion_estamina := 18.0
@export var sensibilidad_mouse := 0.002

@export_group("Headbobbing y Pasos")
@export var bob_frecuencia := 2.2
@export var bob_amplitud := 0.05

@onready var cabeza: Node3D = $Cabeza
@onready var camara: Camera3D = $Cabeza/Camera3D
@onready var linterna: SpotLight3D = $Cabeza/Camera3D/SpotLight3D
@onready var pasos_audio: AudioStreamPlayer3D = $PasosAudio
@onready var respiracion_audio: AudioStreamPlayer = $RespiracionAudio

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var estamina_actual := 100.0
var agotado := false
var tiempo_bob := 0.0
var paso_dado := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	estamina_actual = estamina_maxima

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse)
		cabeza.rotate_x(-event.relative.y * sensibilidad_mouse)
		cabeza.rotation.x = clamp(cabeza.rotation.x, deg_to_rad(-85), deg_to_rad(85))
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			linterna.visible = not linterna.visible

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta

	var direccion_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direccion := (transform.basis * Vector3(direccion_input.x, 0, direccion_input.y)).normalized()

	var quiere_correr := Input.is_action_pressed("correr") and direccion.length() > 0.1
	var esta_corriendo := quiere_correr and not agotado and estamina_actual > 0.0

	if esta_corriendo:
		estamina_actual -= gasto_estamina * delta
		if estamina_actual <= 0.0:
			estamina_actual = 0.0
			agotado = true
			if not respiracion_audio.playing:
				respiracion_audio.play()
	else:
		estamina_actual += regeneracion_estamina * delta
		if estamina_actual >= estamina_maxima:
			estamina_actual = estamina_maxima
		if agotado and estamina_actual >= estamina_maxima * 0.8:
			agotado = false

	var velocidad_actual := velocidad_correr if esta_corriendo else velocidad_caminar

	if direccion:
		velocity.x = direccion.x * velocidad_actual
		velocity.z = direccion.z * velocidad_actual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		velocity.z = move_toward(velocity.z, 0, velocidad_actual)

	move_and_slide()
	_actualizar_headbob(delta, esta_corriendo)

func _actualizar_headbob(delta: float, corriendo: bool) -> void:
	var velocidad_horizontal := Vector2(velocity.x, velocity.z).length()
	var amplitud_actual := bob_amplitud * (1.35 if corriendo else 1.0)
	
	if is_on_floor() and velocidad_horizontal > 0.2:
		tiempo_bob += delta * velocidad_horizontal
		
		var pos_y := sin(tiempo_bob * bob_frecuencia) * amplitud_actual
		var pos_x := cos(tiempo_bob * bob_frecuencia * 0.5) * amplitud_actual
		camara.position = Vector3(pos_x, pos_y, 0.0)
		
		if pos_y < -amplitud_actual * 0.85:
			if not paso_dado:
				pasos_audio.play()
				paso_dado = true
		else:
			paso_dado = false
	else:
		tiempo_bob = 0.0
		paso_dado = false
		camara.position = camara.position.lerp(Vector3.ZERO, delta * 8.0)
