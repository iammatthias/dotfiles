// crt.glsl — subtle CRT treatment for Ghostty (Shadertoy-style API)
// Static effects only (no iTime) so Ghostty doesn't need a continuous
// render loop. Tuned to stay well below the readability threshold.

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 t = texture(iChannel0, uv);
    vec3 col = t.rgb;

    // Phosphor glow: cheap 4-tap neighbor bleed
    vec2 px = 1.0 / iResolution.xy;
    vec3 glow = texture(iChannel0, uv + vec2(px.x, 0.0)).rgb
              + texture(iChannel0, uv - vec2(px.x, 0.0)).rgb
              + texture(iChannel0, uv + vec2(0.0, px.y)).rgb
              + texture(iChannel0, uv - vec2(0.0, px.y)).rgb;
    col += glow * 0.045;

    // Horizontal scanlines (2px period; reads as texture on retina)
    col *= 0.94 + 0.06 * sin(fragCoord.y * 3.14159);

    // Faint vertical phosphor mask
    col *= 0.97 + 0.03 * sin(fragCoord.x * 3.14159);

    // Vignette: corners fall off to ~85%
    vec2 v = uv * (1.0 - uv);
    col *= 0.85 + 0.15 * pow(clamp(v.x * v.y * 16.0, 0.0, 1.0), 0.35);

    fragColor = vec4(col, t.a);
}
