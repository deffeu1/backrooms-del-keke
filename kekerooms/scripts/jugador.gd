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

@export_group("Linterna y Batería")
@export var duracion_linterna := 35.0       # Segundos totales encendida
@export var energia_linterna_base := 3.5    # Intensidad normal de tu SpotLight3D
@export var umbral_parpadeo := 0.30         # Empieza a titilar al 25% de batería
@export var fuerza_sacudida_minima := 45.0  # Qué tan rápido hay que mover el mouse
@export var recarga_por_sacudida := 22.0    # Cuánto recarga al agitar
@export var multiplicador_agua := 0.55  # Reduce la velocidad al 55% dentro del agua

@onready var cabeza: Node3D = $Cabeza
@onready var camara: Camera3D = $Cabeza/Camera3D
@onready var linterna: SpotLight3D = $Cabeza/Camera3D/SpotLight3D
@onready var pasos_audio: AudioStreamPlayer3D = $PasosAudio
@onready var respiracion_audio: AudioStreamPlayer3D = $RespiracionAudio
@onready var linterna_audio: AudioStreamPlayer3D = $LinternaAudio
@onready var sacudir_audio: AudioStreamPlayer3D = $SacudirLinternaAudio
@onready var pasos_agua_audio: AudioStreamPlayer3D = $PasosAguaAudio

var en_agua := false
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var estamina_actual := 100.0
var agotado := false
var tiempo_bob := 0.0
var paso_dado := false

var bateria_linterna := 100.0
var linterna_descargada := false
var timer_parpadeo := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	estamina_actual = estamina_maxima
	linterna.light_energy = energia_linterna_base

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse)
		cabeza.rotate_x(-event.relative.y * sensibilidad_mouse)
		cabeza.rotation.x = clamp(cabeza.rotation.x, deg_to_rad(-85), deg_to_rad(85))
		
		# Detectar sacudida brusca del mouse cuando la linterna está apagada y necesita carga
		if not linterna.visible and bateria_linterna < 100.0:
			if event.relative.length() > fuerza_sacudida_minima:
				_recargar_linterna_por_sacudida()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_alternar_linterna()

func _alternar_linterna() -> void:
	# Siempre suena el click del botón al apretar F
	var va_a_encender := not linterna.visible
	linterna_audio.pitch_scale = 1.08 if va_a_encender else 0.92
	linterna_audio.play()
	
	if linterna.visible:
		linterna.visible = false
	elif not linterna_descargada and bateria_linterna > 5.0:
		linterna.visible = true
		linterna.light_energy = energia_linterna_base

func _recargar_linterna_por_sacudida() -> void:
	bateria_linterna = min(100.0, bateria_linterna + recarga_por_sacudida)
	
	if not sacudir_audio.playing:
		sacudir_audio.pitch_scale = randf_range(0.95, 1.05)
		sacudir_audio.play()
	
	# Desbloquea la linterna cuando recupera al menos un 30%
	if linterna_descargada and bateria_linterna >= 30.0:
		linterna_descargada = false

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
		if agotado and estamina_actual >= estamina_maxima * 0.3:
			agotado = false

	var velocidad_actual := velocidad_correr if esta_corriendo else velocidad_caminar
	if en_agua:
		velocidad_actual *= multiplicador_agua

	if direccion:
		velocity.x = direccion.x * velocidad_actual
		velocity.z = direccion.z * velocidad_actual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		velocity.z = move_toward(velocity.z, 0, velocidad_actual)

	move_and_slide()
	_actualizar_headbob(delta, esta_corriendo)
	_actualizar_linterna(delta)

func _actualizar_linterna(delta: float) -> void:
	if not linterna.visible:
		return
	
	# Descuenta batería según la duración configurada
	bateria_linterna -= (100.0 / duracion_linterna) * delta
	
	if bateria_linterna <= 0.0:
		bateria_linterna = 0.0
		linterna.visible = false
		linterna_descargada = true
		return
	
	# Destellos/parpadeos antes de apagarse
	var porcentaje := bateria_linterna / 100.0
	if porcentaje <= umbral_parpadeo:
		timer_parpadeo -= delta
		if timer_parpadeo <= 0.0:
			if randf() < 0.45:
				# Caída brusca de luz (destello apagándose)
				linterna.light_energy = randf_range(0.0, energia_linterna_base * 0.25)
				timer_parpadeo = randf_range(0.04, 0.12)
			else:
				# Vuelve a encender con un poco menos de fuerza
				linterna.light_energy = energia_linterna_base * randf_range(0.7, 1.0)
				timer_parpadeo = randf_range(0.08, 0.35)
	else:
		linterna.light_energy = energia_linterna_base

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
				if en_agua:
					pasos_agua_audio.play()
				else:
					pasos_audio.play()
				paso_dado = true
		else:
			paso_dado = false
	else:
		tiempo_bob = 0.0
		paso_dado = false
		camara.position = camara.position.lerp(Vector3.ZERO, delta * 8.0)

func establecer_en_agua(estado: bool) -> void:
	en_agua = estado
