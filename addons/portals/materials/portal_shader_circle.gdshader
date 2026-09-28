shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D albedo: hint_default_black, source_color;

// --- Настройки Dissolve ---
uniform float dissolve_amount : hint_range(-0.5, 1.5) = 0.0;
uniform float edge_width : hint_range(0.01, 0.2) = 0.06;
uniform vec3 edge_color_1 : source_color = vec3(0.2, 0.5, 2.0); // Основной цвет разлома (синий)
uniform vec3 edge_color_2 : source_color = vec3(1.0, 0.2, 0.0); // Горячий цвет на самом краю (красный)

// --- Настройки шума ---
uniform float noise_scale = 4.0;
uniform float noise_speed = 1.5; // Скорость анимации края
uniform float noise_strength = 0.5; // Сила искажения края (насколько он рваный)
uniform float edge_glow_intensity = 5.0; // Яркость свечения

// --- Процедурные функции шума (Value Noise) ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0); // smoothstep

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Фрактальный шум (FBM)
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec3 portal_color = texture(albedo, SCREEN_UV).rgb;

    // 1. Вычисляем расстояние от центра UV (0.5, 0.5)
    float dist = distance(UV, vec2(0.5));
    
    // 2. Анимированный шум (оставлен без изменений)
    vec2 animated_uv = UV * noise_scale + vec2(TIME * noise_speed * 0.7, TIME * noise_speed * 0.4);
    float turbulence = fbm(animated_uv + TIME * 0.5);
    float final_noise = fbm(animated_uv + turbulence * 0.5);

    // 3. Формируем круглую маску растворения
    // Базовый радиус портала — 0.5 (чтобы он вписывался в квадратный меш).
    // Вычитаем шум (noise_strength), чтобы край круга стал "рваным".
    // Умножаем на 2.0, чтобы привести диапазон значений к 0.0 - 1.0.
    float circle_mask = (0.5 - dist - (final_noise - 0.5) * noise_strength) * 2.0;

    // 4. Отсечение пикселей
    if (circle_mask < dissolve_amount) {
        discard;
    }

    // 5. Тяжелый светящийся край
    // Градиент от границы растворения к центру портала
    float edge_gradient = 1.0 - smoothstep(dissolve_amount, dissolve_amount + edge_width, circle_mask);
    
    // Двухцветный край: срез (красный), глубже (синий)
    float hot_edge = smoothstep(0.0, 0.5, edge_gradient);
    vec3 final_edge_color = mix(edge_color_2, edge_color_1, hot_edge);

    // Смешиваем цвет портала и цвет края
    vec3 final_color = mix(portal_color, final_edge_color, edge_gradient);

    ALBEDO = final_color;
    
    // Мощная эмиссия на краю
    EMISSION = final_edge_color * edge_gradient * edge_glow_intensity;
}