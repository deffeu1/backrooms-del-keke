extends CanvasLayer

@onready var texto_rec: Label = $TextoRec
@onready var texto_tiempo: Label = $TextoTiempo

var tiempo_transcurrido := 0.0

func _process(delta: float) -> void:
	tiempo_transcurrido += delta
	
	texto_rec.visible = int(tiempo_transcurrido * 2.0) % 2 == 0
	
	var horas := int(tiempo_transcurrido / 3600)
	var minutos := int(tiempo_transcurrido / 60) % 60
	var segundos := int(tiempo_transcurrido) % 60
	texto_tiempo.text = "PLAY ►  %02d:%02d:%02d" % [horas, minutos, segundos]
