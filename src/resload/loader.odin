package resload

import sdl "vendor:sdl2"
// import "vendor:sdl2/ttf"
import "core:image/png"
import img "core:image"
import "core:fmt"

ImgSurface :: struct {
    surface : ^sdl.Surface,
    image : ^img.Image,
}

Texture :: struct {
    tex: ^sdl.Texture,
    w: i32,
    h: i32,
    scale: f32,
    pivot: struct {
        x: f32,
        y: f32,
    },
}

// Font :: ^ttf.Font
Font :: int

load_png :: proc(path: string) -> ^ImgSurface {
    img, err := png.load(path)
    if err != nil {
        fmt.printf("could not load %s\n", path)
        return nil
    }

    surface := new(ImgSurface)
    surface.image = img

    mask_r: u32 = 0x000000ff
    mask_g: u32 = 0x0000ff00
    mask_b: u32 = 0x00ff0000
    mask_a: u32 = 0xff000000 if img.channels == 4 else 0

    depth := i32(img.depth) * i32(img.channels)
    pitch := i32(img.width) * i32(img.channels)

    surface.surface = sdl.CreateRGBSurfaceFrom(
        raw_data(img.pixels.buf),
        i32(img.width), i32(img.height),
        depth, pitch,
        mask_r, mask_g, mask_b, mask_a)
    return surface
}

make_texture :: proc(renderer: ^sdl.Renderer, surf: ^ImgSurface, scale: f32, pivot: struct{x: f32, y: f32}) -> (texture: Texture, ok: bool) {
    if (surf == nil) {
        fmt.printf("error creating texture\n")
        return Texture{}, false
    }
    tex: ^sdl.Texture = sdl.CreateTextureFromSurface(renderer, surf.surface)
    sdl.SetTextureBlendMode(tex, .BLEND)
    if tex == nil {
        fmt.printf("error converting texture\n")
        return Texture{}, false
    }

    texture_asset := Texture {
        tex = tex,
        w = surf.surface.w,
        h = surf.surface.h,

        scale = scale,
        pivot = pivot,
    }
    destroy_surface(surf)
    return texture_asset, true
}

destroy_surface :: proc(surf: ^ImgSurface) {
    assert(surf != nil)
    png.destroy(surf.image)
    sdl.FreeSurface(surf.surface)
    free(surf)
}

load_font :: proc(path: cstring, size: i32) -> Font {
    // return ttf.OpenFont(path, size)
    return 0
}

destroy_font :: proc(font: Font) {
    // ttf.CloseFont(font)
}