#include <metal_stdlib>
using namespace metal;

// The scale varies for every scanline. Rows are never uniformly scaled as a whole.
[[ stitchable ]] float2 drawerReel(float2 position, float2 size, float rowY,
    float viewportHeight, float edgeHeight, float topActive, float bottomActive) {
    float y = rowY + position.y;
    float top = topActive * clamp((edgeHeight - y) / edgeHeight, 0.0f, 1.0f);
    float bottom = bottomActive * clamp((y - viewportHeight + edgeHeight) / edgeHeight, 0.0f, 1.0f);
    float scale = 1.0f - 0.1f * max(top, bottom);
    float2 anchor = float2(size.x * 0.5f, top > bottom ? size.y : 0.0f);
    return anchor + (position - anchor) / scale;
}
