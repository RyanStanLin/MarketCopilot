#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

static float drawerSmootherstep(float value) {
    float t = clamp(value, 0.0f, 1.0f);
    return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
}

// A spatially varying blur with premultiplied alpha reveals the native drawer
// surface, without painting a tinted overlay. Perspective varies per scanline.
[[ stitchable ]] half4 drawerReel(float2 position, SwiftUI::Layer layer, float2 size, float rowY,
    float viewportHeight, float edgeHeight, float topStrength, float bottomStrength,
    float minimumScale, float maximumBlur, float motion) {
    float y = rowY + position.y;
    float top = topStrength * drawerSmootherstep((edgeHeight - y) / edgeHeight);
    float bottom = bottomStrength * drawerSmootherstep((y - viewportHeight + edgeHeight) / edgeHeight);
    float depth = max(top, bottom);
    float scale = mix(1.0f, minimumScale, depth * motion);
    // Blend anchors if the screen is short enough for the two edge bands to meet.
    float anchorY = size.y * top / max(top + bottom, 0.00001f);
    float2 anchor = float2(size.x * 0.5f, anchorY);
    float2 source = anchor + (position - anchor) / scale;
    float radius = maximumBlur * depth;

    if (radius < 0.01f) {
        return layer.sample(source) * half(1.0f - depth);
    }

    // Normalized 5x5 Gaussian approximation; only edge fragments take this path.
    const float weights[5] = { 1.0f, 4.0f, 6.0f, 4.0f, 1.0f };
    half4 color = half4(0.0h);
    for (int v = -2; v <= 2; ++v) {
        for (int u = -2; u <= 2; ++u) {
            float2 samplePosition = source + float2(u, v) * (radius * 0.5f);
            color += layer.sample(samplePosition) * half(weights[u + 2] * weights[v + 2] / 256.0f);
        }
    }
    return color * half(1.0f - depth);
}
