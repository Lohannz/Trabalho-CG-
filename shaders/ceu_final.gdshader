shader_type sky;

uniform vec3 top_color : source_color = vec3(0.05, 0.08, 0.40);
uniform vec3 horizon_color : source_color = vec3(0.50, 0.70, 1.00);

uniform vec3 cloud_color1 : source_color = vec3(1.00, 0.72, 0.84);
uniform vec3 cloud_color2 : source_color = vec3(0.95, 0.86, 1.00);

uniform float cloud_scale1 = 1.2;
uniform float cloud_scale2 = 0.6;

uniform float cloud_speed1 = 0.002;
uniform float cloud_speed2 = -0.001;

uniform float cloud_density1 = 0.55;
uniform float cloud_density2 = 0.65;

uniform float cloud_strength1 = 0.40;
uniform float cloud_strength2 = 0.20;

uniform sampler2D cloud_texture : filter_linear, repeat_enable;
uniform float png_cloud_scale = 1.0;
uniform float png_cloud_speed_x = 0.005;
uniform float png_cloud_speed_y = 0.0;
uniform float png_cloud_strength : hint_range(0.0, 1.0) = 1.0;
uniform vec4 png_cloud_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0); 

// Totalmente amigo
float hash(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0,0.0));
    float c = hash(i + vec2(0.0,1.0));
    float d = hash(i + vec2(1.0,1.0));

    vec2 u = f*f*(3.0-2.0*f);

    return mix(a,b,u.x)
        + (c-a)*u.y*(1.0-u.x)
        + (d-b)*u.x*u.y;
}

float fbm(vec2 p)
{
    float value = 0.0;
    float amp = 0.5;

    for(int i=0;i<6;i++)
    {
        value += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }

    return value;
}

void sky()
{
    float h = clamp(EYEDIR.y * 0.5 + 0.5, 0.0, 1.0);

    vec3 col = mix(
        horizon_color,
        top_color,
        pow(h,1.7)
    );

   
    vec2 png_uv = EYEDIR.xz / max(EYEDIR.y, 0.01); 
    png_uv *= png_cloud_scale;
    png_uv.x += TIME * png_cloud_speed_x;
    png_uv.y += TIME * png_cloud_speed_y;
    
    vec4 png_tex = texture(cloud_texture, png_uv * 0.5 + 0.5);
    
  
    float png_alpha = png_tex.a * png_cloud_strength * step(0.0, EYEDIR.y);
    vec3 png_final_color = png_tex.rgb * png_cloud_tint.rgb;
    
    col = mix(col, png_final_color, png_alpha);


    vec2 uv1 = EYEDIR.xz;

    uv1 *= cloud_scale1;
    uv1.x += TIME * cloud_speed1;

    float n1 = fbm(uv1);

    float c1 = smoothstep(
        cloud_density1,
        cloud_density1 + 0.15,
        n1
    );


    vec2 uv2 = EYEDIR.xz;

    uv2 *= cloud_scale2;
    uv2.y += TIME * cloud_speed2;

    float n2 = fbm(uv2);

    float c2 = smoothstep(
        cloud_density2,
        cloud_density2 + 0.18,
        n2
    );


    col = mix(
        col,
        cloud_color1,
        c1 * cloud_strength1
    );

    col = mix(
        col,
        cloud_color2,
        c2 * cloud_strength2
    );

    // no horizonte

    float glow = pow(1.0-h,4.0);

    col += vec3(1.0,0.65,0.9)
        * glow
        * 0.18;

    // escurecer no topo

    col *= mix(
        1.05,
        0.82,
        pow(h,3.0)
    );

    COLOR = col;
}