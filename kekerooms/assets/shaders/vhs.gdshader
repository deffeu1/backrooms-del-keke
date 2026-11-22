shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float curvatura : hint_range(0.0, 10.0) = 3.5;
uniform float aberracion_cromatica : hint_range(0.0, 0.02) = 0.0025;
uniform float intensidad_ruido : hint_range(0.0, 0.3) = 0.06;
uniform float intensidad_scanlines : hint_range(0.0, 0.5) = 0.12;
uniform float vinieta : hint_range(0.0, 2.0) = 0.65;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 curvar_uv(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / vec2(curvatura, curvatura);
	uv = uv + uv * offset * offset;
	uv = uv * 0.5 + 0.5;
	return uv;
}

void fragment() {
	vec2 uv = curvatura > 0.0 ? curvar_uv(SCREEN_UV) : SCREEN_UV;

	// Bordes negros fuera de la curvatura del lente
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// Línea sutil de tracking VHS que recorre la pantalla
		float tracking = sin(uv.y * 8.0 + TIME * 1.5) * sin(uv.y * 25.0 - TIME * 4.0);
		float jitter = smoothstep(0.96, 1.0, tracking) * 0.004;
		uv.x += jitter;

		// Separación de canales RGB (aberración cromática)
		float r = texture(screen_texture, uv + vec2(aberracion_cromatica, 0.0)).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - vec2(aberracion_cromatica, 0.0)).b;
		vec3 color = vec3(r, g, b);

		// Líneas horizontales de escaneo (scanlines)
		float scanline = sin(uv.y * 650.0) * intensidad_scanlines;
		color -= scanline;

		// Grano / estática animada de cinta
		float grano = (random(uv + fract(TIME)) - 0.5) * intensidad_ruido;
		color += grano;

		// Oscurecimiento en las esquinas (viñeta)
		vec2 centro = uv - 0.5;
		float dist = dot(centro, centro);
		color *= 1.0 - dist * vinieta;

		COLOR = vec4(color, 1.0);
	}
}