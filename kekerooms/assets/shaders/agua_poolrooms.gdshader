shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, specular_schlick_ggx;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

uniform vec3 color_superficie : source_color = vec3(0.75, 0.94, 0.96);
uniform vec3 color_profundo : source_color = vec3(0.25, 0.68, 0.78);
uniform float fuerza_refraccion : hint_range(0.0, 0.1) = 0.025;
uniform float velocidad_ondas : hint_range(0.0, 2.0) = 0.35;
uniform float escala_ondas : hint_range(1.0, 30.0) = 8.0;
uniform float transparencia : hint_range(0.0, 1.0) = 0.35;

// Función de ondas suaves combinadas
float calcular_onda(vec2 uv, float tiempo) {
	float o1 = sin(uv.x * escala_ondas + tiempo * 2.0) * cos(uv.y * escala_ondas * 0.8 + tiempo * 1.5);
	float o2 = sin((uv.x + uv.y) * escala_ondas * 1.3 - tiempo * 1.8);
	return (o1 + o2) * 0.5;
}

void fragment() {
	float t = TIME * velocidad_ondas;
	
	// Perturbación de normales para reflejos y refracción
	float delta = 0.02;
	float h0 = calcular_onda(UV, t);
	float hx = calcular_onda(UV + vec2(delta, 0.0), t);
	float hy = calcular_onda(UV + vec2(0.0, delta), t);
	vec3 normal_onda = normalize(vec3((h0 - hx) * 1.5, 1.0, (h0 - hy) * 1.5));
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(normal_onda, 0.0)).xyz, 0.6));

	// Distorsión de lo que se ve debajo del agua (refracción)
	vec2 uv_pantalla = SCREEN_UV + normal_onda.xz * fuerza_refraccion;
	vec3 color_fondo = texture(screen_texture, uv_pantalla).rgb;

	// Mezcla de color turquesa cristalino
	vec3 color_agua = mix(color_fondo, color_superficie, transparencia);
	color_agua = mix(color_agua, color_profundo, 0.25);

	ALBEDO = color_agua;
	ROUGHNESS = 0.06;  // Muy lisa para reflejar el sol de la ventana
	SPECULAR = 0.85;
	METALLIC = 0.05;
}