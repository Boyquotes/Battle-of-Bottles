shader_type canvas_item;
render_mode unshaded;

uniform int blurSize : hint_range(0,50);

void fragment() {
    COLOR = texture(SCREEN_TEXTURE, SCREEN_UV, float(blurSize)/10.0);
    float avg = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
    COLOR.rgb = vec3(avg);
}