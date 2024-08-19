package main

import sdl "vendor:sdl2"
// import ttf "vendor:sdl2/ttf"
import c "core:c/libc"
import "resload"

Texture :: resload.Texture

DrawTextureAt :: proc(renderer: ^sdl.Renderer, tex: Texture, x: i32, y: i32) {
    rect := sdl.Rect {
        x = x - i32(f32(tex.w) * tex.scale * tex.pivot.x),
        y = y - i32(f32(tex.h) * tex.scale * tex.pivot.y),
        w = i32(f32(tex.w) * tex.scale),
        h = i32(f32(tex.h) * tex.scale),
    }
    sdl.RenderCopy(renderer, tex.tex, nil, &rect)
}

// DrawText :: proc(renderer: ^sdl.Renderer, font: ^ttf.Font, text: cstring, colour: sdl.Color, x, y: i32) {
//     surface := ttf.RenderText_Solid(font, text, colour)
//     texture := sdl.CreateTextureFromSurface(renderer, surface)
//     w, h: c.int
//     ttf.SizeText(font, text, &w, &h)
//     rect := sdl.Rect {
//         x = x,
//         y = y,
//         w = w,
//         h = h,
//     }
//     sdl.RenderCopy(renderer, texture, nil, &rect)
//     sdl.FreeSurface(surface)
//     sdl.DestroyTexture(texture)
// }