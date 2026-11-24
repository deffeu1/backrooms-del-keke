extends CharacterBody3D

@export_group("Movimiento y Estamina")
@export var velocidad_caminar := 4.0
@export var velocidad_correr := 6.8
@export var fuerza_salto := 4.4
@export var costo_estamina_salto := 12.0
@export var estamina_maxima := 100.0
@export var gasto_estamina := 28.0
@export var regeneracion_estamina := 18.0
@export var sensibilidad_mouse := 0.002
@export var puede_saltar := false

@export_group("Headbobbing y Pasos")
@export var bob_frecuencia := 2.2
@export var bob_amplitud := 0.05
@export var bob_frecuencia_agua := 1.8
@export var bob_amplitud_agua := 0.065
@export var multiplicador_agua := 0.55

@export_group("Efecto Bodycam")
@export var inclinacion_lateral := 2.2
@export var inercia_giro := 0.04
@export var suavizado_bodycam := 8.0
@export var temblor_respiracion := 0.25

@export_group("Linterna y Batería")
@export var duracion_linterna := 35.0
@export var energia_linterna_base := 3.5
@export var umbral_parpadeo := 0.30
@export var fuerza_sacudida_minima := 45.0
@export var recarga_por_sacudida := 22.0

@onready var icono_agitar: TextureRect = $CapaHUDLimpia/IconoAgitarLinterna
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
var estaba_en_suelo := true
var impacto_aterrizaje := 0.0
var icono_agitar_visible := false
var tween_icono: Tween
var tiempo_agitacion_ui := 0.0
var bateria_linterna := 100.0
var linterna_descargada := false
var timer_parpadeo := 0.0
var impulso_mouse := Vector2.ZERO
var ruido := FastNoiseLite.new()
var tiempo_ruido := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	estamina_actual = estamina_maxima
	linterna.light_energy = energia_linterna_base
	
	icono_agitar.modulate.a = 0.0
	icono_agitar.pivot_offset = icono_agitar.size * 0.5
	ruido.seed = randi()
	ruido.frequency = 0.6
	
	_configurar_audio_nivel()

func _configurar_audio_nivel() -> void:
	var nombre_escena := get_tree().current_scene.name
	
	if nombre_escena == "nosequerooms":
		pasos_audio.bus = "AireLibre"
		respiracion_audio.bus = "AireLibre"
		linterna_audio.bus = "AireLibre"
		sacudir_audio.bus = "AireLibre"
	elif nombre_escena == "poolrooms":
		pasos_audio.bus = "Master"
		respiracion_audio.bus = "Master"
		linterna_audio.bus = "Master"
		sacudir_audio.bus = "Master"
	else:
		pasos_audio.bus = "Eco"
		respiracion_audio.bus = "Eco"
		linterna_audio.bus = "Eco"
		sacudir_audio.bus = "Eco"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse)
		cabeza.rotate_x(-event.relative.y * sensibilidad_mouse)
		cabeza.rotation.x = clampf(cabeza.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
		
		impulso_mouse = event.relative
		
		if not linterna.visible and bateria_linterna < 100.0:
			if event.relative.length() > fuerza_sacudida_minima:
				_recargar_linterna_por_sacudida()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_alternar_linterna()

func _alternar_linterna() -> void:
	var va_a_encender := not linterna.visible
	linterna_audio.pitch_scale = 1.08 if va_a_encender else 0.92
	linterna_audio.play()
	
	if linterna.visible:
		linterna.visible = false
	elif not linterna_descargada and bateria_linterna > 5.0:
		linterna.visible = true
		linterna.light_energy = energia_linterna_base
	elif linterna_descargada:
		_mostrar_icono_agitar()

func _recargar_linterna_por_sacudida() -> void:
	bateria_linterna = minf(100.0, bateria_linterna + recarga_por_sacudida)
	
	if not sacudir_audio.playing:
		sacudir_audio.pitch_scale = randf_range(0.95, 1.05)
		sacudir_audio.play()
	
	if linterna_descargada and bateria_linterna >= 30.0:
		linterna_descargada = false
		_ocultar_icono_agitar()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta
	elif puede_saltar and Input.is_action_just_pressed("saltar") and not agotado and estamina_actual >= costo_estamina_salto:
		velocity.y = fuerza_salto * (0.75 if en_agua else 1.0)
		estamina_actual -= costo_estamina_salto
		if estamina_actual <= 0.0:
			estamina_actual = 0.0
			agotado = true
			if not respiracion_audio.playing:
				respiracion_audio.play()

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
	
	if is_on_floor() and not estaba_en_suelo:
		impacto_aterrizaje = -0.14
		if en_agua:
			pasos_agua_audio.play()
		else:
			pasos_audio.play()
	estaba_en_suelo = is_on_floor()
	
	_actualizar_headbob(delta, esta_corriendo)
	_actualizar_bodycam(delta, direccion_input, esta_corriendo)
	_actualizar_linterna(delta)

func _actualizar_bodycam(delta: float, input_dir: Vector2, corriendo: bool) -> void:
	tiempo_ruido += delta * (2.5 if agotado else 1.0)
	
	var roll_movimiento: float = -input_dir.x * deg_to_rad(inclinacion_lateral)
	var roll_giro: float = clampf(-impulso_mouse.x * inercia_giro * 0.05, -0.12, 0.12)
	
	var factor_temblor: float = 2.2 if (corriendo or agotado) else 1.0
	var ruido_x: float = ruido.get_noise_1d(tiempo_ruido * 10.0) * deg_to_rad(temblor_respiracion * factor_temblor)
	var ruido_y: float = ruido.get_noise_1d(tiempo_ruido * 10.0 + 100.0) * deg_to_rad(temblor_respiracion * factor_temblor)
	var ruido_z: float = ruido.get_noise_1d(tiempo_ruido * 8.0 + 200.0) * deg_to_rad(temblor_respiracion * 1.5 * factor_temblor)
	
	var pitch_sway: float = clampf(-impulso_mouse.y * inercia_giro * 0.03, -0.08, 0.08)
	var yaw_sway: float = clampf(-impulso_mouse.x * inercia_giro * 0.03, -0.08, 0.08)
	
	var rotacion_objetivo := Vector3(
		pitch_sway + ruido_x,
		yaw_sway + ruido_y,
		roll_movimiento + roll_giro + ruido_z
	)
	
	camara.rotation = camara.rotation.lerp(rotacion_objetivo, delta * suavizado_bodycam)
	impulso_mouse = impulso_mouse.lerp(Vector2.ZERO, delta * 12.0)

func _actualizar_linterna(delta: float) -> void:
	if not linterna.visible:
		return
	
	bateria_linterna -= (100.0 / duracion_linterna) * delta
	
	if bateria_linterna <= 0.0:
		bateria_linterna = 0.0
		linterna.visible = false
		linterna_descargada = true
		_mostrar_icono_agitar()
		return
	
	var porcentaje := bateria_linterna / 100.0
	if porcentaje <= umbral_parpadeo:
		timer_parpadeo -= delta
		if timer_parpadeo <= 0.0:
			if randf() < 0.45:
				linterna.light_energy = randf_range(0.0, energia_linterna_base * 0.25)
				timer_parpadeo = randf_range(0.04, 0.12)
			else:
				linterna.light_energy = energia_linterna_base * randf_range(0.7, 1.0)
				timer_parpadeo = randf_range(0.08, 0.35)
	else:
		linterna.light_energy = energia_linterna_base

func _actualizar_headbob(delta: float, corriendo: bool) -> void:
	var velocidad_horizontal := Vector2(velocity.x, velocity.z).length()
	
	var frecuencia_base := bob_frecuencia_agua if en_agua else bob_frecuencia
	var amplitud_base := bob_amplitud_agua if en_agua else bob_amplitud
	var amplitud_actual := amplitud_base * (1.35 if corriendo else 1.0)
	
	impacto_aterrizaje = lerpf(impacto_aterrizaje, 0.0, delta * 10.0)
	
	if is_on_floor() and velocidad_horizontal > 0.2:
		tiempo_bob += delta * velocidad_horizontal
		
		var pos_y := sin(tiempo_bob * frecuencia_base) * amplitud_actual + impacto_aterrizaje
		var pos_x := cos(tiempo_bob * frecuencia_base * 0.5) * amplitud_actual
		camara.position = Vector3(pos_x, pos_y, 0.0)
		
		if pos_y - impacto_aterrizaje < -amplitud_actual * 0.85:
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
		var objetivo := Vector3(0.0, impacto_aterrizaje, 0.0)
		camara.position = camara.position.lerp(objetivo, delta * 10.0)

func establecer_en_agua(estado: bool) -> void:
	en_agua = estado

func _process(delta: float) -> void:
	if icono_agitar.modulate.a > 0.01:
		tiempo_agitacion_ui += delta * 18.0
		icono_agitar.rotation_degrees = sin(tiempo_agitacion_ui) * 14.0
		icono_agitar.position.x += cos(tiempo_agitacion_ui) * 25.0 * delta
	else:
		icono_agitar.rotation_degrees = 0.0

func _mostrar_icono_agitar() -> void:
	if icono_agitar_visible:
		return
	icono_agitar_visible = true
	
	if tween_icono:
		tween_icono.kill()
	tween_icono = create_tween()
	tween_icono.tween_property(icono_agitar, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)

func _ocultar_icono_agitar() -> void:
	if not icono_agitar_visible:
		return
	icono_agitar_visible = false
	
	if tween_icono:
		tween_icono.kill()
	tween_icono = create_tween()
	tween_icono.tween_property(icono_agitar, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
