extends Area3D

func _ready() -> void:
	body_entered.connect(_al_entrar_cuerpo)
	body_exited.connect(_al_salir_cuerpo)

func _al_entrar_cuerpo(body: Node3D) -> void:
	if body.has_method("establecer_en_agua"):
		body.establecer_en_agua(true)

func _al_salir_cuerpo(body: Node3D) -> void:
	if body.has_method("establecer_en_agua"):
		body.establecer_en_agua(false)
