package main

import "core:math/rand"

Level :: struct {
    layout: [LEVEL_SIZE][LEVEL_SIZE]u32,
    explosions: [LEVEL_SIZE][LEVEL_SIZE]u8,
    entities: [dynamic]Entity
}

generate_level :: proc(box_density: f32 = .5) -> Level {
    level := generate_empty_level()

    for x in 0..<LEVEL_SIZE {
        for y in 0..<LEVEL_SIZE {
            if level.layout[x][y] == TEX_WALL {
                continue
            }
            if rand.float32_uniform(0, 1) <= box_density {
                level.layout[x][y] = TEX_BREAKABLE
            }
        }
    }

    level.layout[1][1] = TEX_FLOOR
    level.layout[1][2] = TEX_FLOOR
    level.layout[2][1] = TEX_FLOOR
    
    level.layout[LEVEL_SIZE - 2][1] = TEX_FLOOR
    level.layout[LEVEL_SIZE - 2][2] = TEX_FLOOR
    level.layout[LEVEL_SIZE - 3][1] = TEX_FLOOR
    
    level.layout[1][LEVEL_SIZE - 2] = TEX_FLOOR
    level.layout[2][LEVEL_SIZE - 2] = TEX_FLOOR
    level.layout[1][LEVEL_SIZE - 3] = TEX_FLOOR

    level.layout[LEVEL_SIZE - 2][LEVEL_SIZE - 2] = TEX_FLOOR
    level.layout[LEVEL_SIZE - 3][LEVEL_SIZE - 2] = TEX_FLOOR
    level.layout[LEVEL_SIZE - 2][LEVEL_SIZE - 3] = TEX_FLOOR
    return level
}

generate_empty_level :: proc() -> Level{
    level := Level{}
    for x in 0..<LEVEL_SIZE {
        for y in 0..<LEVEL_SIZE {
            level.explosions[x][y] = 0
            if x == 0 || x == LEVEL_SIZE - 1 || y == LEVEL_SIZE - 1 || y == 0 {
                level.layout[x][y] = TEX_WALL
                continue
            }
            if x % 2 == 0 && y % 2 == 0 {
                level.layout[x][y] = TEX_WALL
                continue
            }
            level.layout[x][y] = TEX_FLOOR
        }
    }
    return level
}

render_level :: proc(ctx: ^CTX) {
    for x in 0..<LEVEL_SIZE {
        for y in 0..<LEVEL_SIZE {
            currentTex := ctx.level.layout[x][y]
            DrawTextureAt(ctx.renderer, ctx.textures[currentTex], i32(x) * TILE_SIZE, i32(y) * TILE_SIZE)
        }
    }
}

render_entities :: proc(ctx: ^CTX) {
    tex_idx: u32
    pos: [2]int
    for e in ctx.level.entities {
        tex_idx = entity_idx(e)
        pos = entity_pos(e)
        DrawTextureAt(ctx.renderer, ctx.textures[tex_idx], i32(pos.x) * TILE_SIZE, i32(pos.y) * TILE_SIZE)
    }
}

render_explosions :: proc(ctx: ^CTX) {
    for x in 0..<LEVEL_SIZE {
        for y in 0..<LEVEL_SIZE {
            if ctx.level.explosions[x][y] > 0 {
                DrawTextureAt(ctx.renderer, ctx.textures[TEX_EXPLOSION], i32(x) * TILE_SIZE, i32(y) * TILE_SIZE)
            }
        }
    }
}

get_entity_at_position :: proc(ctx: ^CTX, pos: [2]int, self: Entity = nil) -> (entity: Entity, idx: int) {
    for i in 0..<len(ctx.level.entities) {
        e := ctx.level.entities[i]
        if e == self {
            continue
        }
        if entity_pos(e) == pos {
            entity = e
            idx = i
            return
        }
    }
    return nil, -1
}

remove_entity :: proc(ctx: ^CTX, entity: Entity) {
    for i in 0..<len(ctx.level.entities) {
        e := ctx.level.entities[i]
        if e == entity {
            unordered_remove(&ctx.level.entities, i)
            entity_free(e)
            return
        }
    }
}