package main

import sdl "vendor:sdl2"
import "core:image/png"
import "core:fmt"
import "core:math"
import "core:time"
import "core:container/queue"

import "resload"

LEVEL_SIZE :: 19
TILE_SCALE :: 2.5
TILE_SIZE  :: 16 * TILE_SCALE
WIN_HEIGHT :: i32(LEVEL_SIZE * TILE_SIZE)
WIN_WIDTH  :: i32(LEVEL_SIZE * TILE_SIZE) * 4 / 3
TARGET_FPS :: 60

EventQueue :: queue.Queue(sdl.Event)

Input :: struct {
    up: bool,
    down: bool,
    left: bool,
    right: bool,
    bomb: bool,
}

CTX :: struct {
    window: ^sdl.Window,
    renderer: ^sdl.Renderer,
    textures: map[u32]resload.Texture,
    fonts: map[u32]resload.Font,
    level: Level,
    input1: Input,
    input2: Input,

    should_quit: bool,

    start_time: time.Time,
    current_time: f64,
}

main :: proc() {
    fmt.println("game starting")
    ctx := CTX{}
    fmt.println("initialising game...")
    init(&ctx)
    fmt.println("running game loop...")
    mainloop(&ctx)
    fmt.println("game ended. cleanup...")
    cleanup(&ctx)
}

init :: proc(ctx: ^CTX) {
    fmt.println("initialising context...")
    ctx.should_quit = false
    fmt.println("- window...")
    ctx.window = sdl.CreateWindow("test", 50, 50, WIN_WIDTH, WIN_HEIGHT, {})
    fmt.println("- renderer...")
    ctx.renderer = sdl.CreateRenderer(ctx.window, 0, {})
    fmt.println("- textures map...")
    ctx.textures = make(map[u32]resload.Texture)
    fmt.println("- fonts map...")
    ctx.fonts = make(map[u32]resload.Font)
    ctx.start_time = time.now()
    fmt.println("done")
    
    fmt.println("initialising game state...")
    init_game_state(ctx)
    fmt.println("done")
    
    fmt.println("loading textures...")
    register_texture(ctx, TEX_FLOOR,     "./res/img/floor.png",         {0, 0})
    register_texture(ctx, TEX_WALL,      "./res/img/wall.png",          {0, 0})
    register_texture(ctx, TEX_BREAKABLE, "./res/img/breakablewall.png", {0, 0})
    register_texture(ctx, TEX_PLAYER,    "./res/img/player.png",        {0, 0})
    register_texture(ctx, TEX_PLAYER2,   "./res/img/player2.png",       {0, 0}) 
    register_texture(ctx, TEX_DEAD,      "./res/img/dead.png",          {0, 0}) 
    
    register_texture(ctx, TEX_BOMB1, "./res/img/bomb-1.png", {0, 0})
    register_texture(ctx, TEX_BOMB2, "./res/img/bomb-2.png", {0, 0})
    register_texture(ctx, TEX_BOMB3, "./res/img/bomb-3.png", {0, 0})
    register_texture(ctx, TEX_BOMB4, "./res/img/bomb-4.png", {0, 0})
    register_texture(ctx, TEX_BOMB5, "./res/img/bomb-5.png", {0, 0})
    register_texture(ctx, TEX_EXPLOSION, "./res/img/explosion.png", {0, 0})
    
    register_texture(ctx, TEX_BOMB_UP, "./res/img/bomb-up.png", {0, 0})
    register_texture(ctx, TEX_FIRE_UP, "./res/img/fire-up.png", {0, 0})
    fmt.println("done")
}

init_game_state :: proc(ctx: ^CTX) {
    ctx.input1 = {false, false, false, false, false}
    ctx.input2 = {false, false, false, false, false}

    ctx.level = generate_level(.75)
    
    player1 := spawn_player({1, 1}, &ctx.input1, TEX_PLAYER)
    player2 := spawn_player({LEVEL_SIZE - 2, LEVEL_SIZE - 2}, &ctx.input2, TEX_PLAYER2)
    append(&ctx.level.entities, cast(Entity)player1)
    append(&ctx.level.entities, cast(Entity)player2)
}

register_texture :: proc(ctx: ^CTX, id: u32, path: string, pivot: struct{x: f32, y:f32} = {0.5, 0.5}) {
    tex, ok := resload.make_texture(ctx.renderer, resload.load_png(path), TILE_SCALE, pivot)
    if !ok {
        fmt.println("could not create texture")
        return
    }
    ctx.textures[id] = tex
}

register_font :: proc(ctx: ^CTX, id: u32, path: cstring, size: i32) {
    font := resload.load_font(path, size)
    // if font == nil {
    if font == 0 {
        fmt.println("could not load font")
        return
    }
    ctx.fonts[id] = font
}

tick: u32 = 0
prev_tick: u32 = 0

mainloop :: proc(ctx: ^CTX) {
    event_queue: queue.Queue(sdl.Event)
    queue.init(&event_queue)

    for !ctx.should_quit {
        ctx.current_time = f64(time.duration_seconds(time.diff(ctx.start_time, time.now())))

        gather_event(ctx, &event_queue)
        tick = sdl.GetTicks()
        delta := tick - prev_tick
        if (delta <= 1000/TARGET_FPS) {
            continue
        }
        prev_tick = tick

        for x in 0..<LEVEL_SIZE {
            for y in 0..<LEVEL_SIZE {
                if (ctx.level.explosions[x][y] > 0) {
                    ctx.level.explosions[x][y] -= 1
                }
            }
        }
        
        process_events(ctx, &event_queue)
        for e in ctx.level.entities {
            entity_tick(e, ctx)
        }
        draw(ctx)
    }
}

process_events :: proc (ctx: ^CTX, q: ^EventQueue) {
    for event in queue.pop_front_safe(q) {
        #partial switch event.type {
            case .QUIT:
                ctx.should_quit = true
            case .KEYDOWN:
                #partial switch event.key.keysym.scancode {
                    case .W: ctx.input1.up = true
                    case .S: ctx.input1.down = true
                    case .A: ctx.input1.left = true
                    case .D: ctx.input1.right = true
                    case .SPACE: ctx.input1.bomb = true

                    case .UP: ctx.input2.up = true
                    case .DOWN: ctx.input2.down = true
                    case .LEFT: ctx.input2.left = true
                    case .RIGHT: ctx.input2.right = true
                    case .RETURN: ctx.input2.bomb = true
                    case .R: reset(ctx)
                }
            case .KEYUP:
                #partial switch event.key.keysym.scancode {
                    case .W: ctx.input1.up = false
                    case .S: ctx.input1.down = false
                    case .A: ctx.input1.left = false
                    case .D: ctx.input1.right = false
                    case .SPACE: ctx.input1.bomb = false

                    case .UP: ctx.input2.up = false
                    case .DOWN: ctx.input2.down = false
                    case .LEFT: ctx.input2.left = false
                    case .RIGHT: ctx.input2.right = false
                    case .RETURN: ctx.input2.bomb = false
                }
        }
    }
}

gather_event :: proc(ctx: ^CTX, q: ^EventQueue) {
    e: sdl.Event
    for sdl.PollEvent(&e) {
        queue.push_back(q, e)
    }
}

draw :: proc(ctx: ^CTX) {
    render_level(ctx)
    render_entities(ctx)
    render_explosions(ctx)
    sdl.RenderPresent(ctx.renderer)
    sdl.UpdateWindowSurface(ctx.window)
}

reset :: proc(ctx: ^CTX) {
    for e in ctx.level.entities {
        entity_free(e)
    }

    init_game_state(ctx)
}

cleanup :: proc(ctx: ^CTX) {
    sdl.DestroyRenderer(ctx.renderer)
    sdl.DestroyWindow(ctx.window)
    sdl.Quit()
    delete(ctx.textures)
    for id, f in ctx.fonts {
        resload.destroy_font(f)
    }
    delete(ctx.fonts)
    for e in ctx.level.entities {
        entity_free(e)
    }
    delete(ctx.level.entities)
    free(ctx.window)
    free(ctx.renderer)
}

input_any :: proc(input: ^Input) -> bool {
    return input.up || input.down || input.left || input.right
}