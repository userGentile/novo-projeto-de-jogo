shader_type canvas_item;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    if (color.rgb.r < 0.05 &&
        color.rgb.g < 0.05 &&
        color.rgb.b < 0.05) {
        color.a = 0.0;
    }

    COLOR = color;
}
