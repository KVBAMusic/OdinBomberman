package main

import "core:math/rand"
import "core:fmt"

EXPLOSION_DURATION :: 8

Bomb :: struct {
    pos: [2]int,
    life: int,
    power: u32,
    parent: ^Player
}

spawn_bomb :: proc(x, y: int, parent: ^Player, power: u32 = 1) -> ^Bomb {
    bomb := new(Bomb)
    bomb.pos = {x, y}
    bomb.life = 100
    bomb.power = power
    bomb.parent = parent
    return bomb
}

bomb_tick :: proc(bomb: ^Bomb, ctx: ^CTX) {
    using bomb
    life -= 1
    if life == 0 || ctx.level.explosions[pos.x][pos.y] > 0 {
        explode(bomb, ctx)
    }
}

explode :: proc(bomb: ^Bomb, ctx: ^CTX) {
    e: Entity
    bomb.parent.bombs += 1
    fmt.println("Bomb exploded, parent bombs:", bomb.parent.bombs)
    for i in 0..<len(ctx.level.entities) {
        e = ctx.level.entities[i]
        if b, ok := e.(^Bomb); ok {
            pos := b.pos
            power := b.power

            unordered_remove(&ctx.level.entities, i)
            entity_free(e)

            ctx.level.explosions[pos.x][pos.y] = EXPLOSION_DURATION
            propagate_explosion(ctx, pos, power, {0, 1})
            propagate_explosion(ctx, pos, power, {0, -1})
            propagate_explosion(ctx, pos, power, {1, 0})
            propagate_explosion(ctx, pos, power, {-1, 0})
        }
    }
}

propagate_explosion :: proc(ctx: ^CTX, origin: [2]int, power: u32, delta: [2]int) {
    pos := origin
    power := power
    for power > 0 {
        pos += delta
        if ctx.level.layout[pos.x][pos.y] == TEX_WALL {
            return
        }
        ctx.level.explosions[pos.x][pos.y] = EXPLOSION_DURATION
        if ctx.level.layout[pos.x][pos.y] == TEX_BREAKABLE {
            power = 0
            if rand.int_max(10) == 0 {
                append(&ctx.level.entities, spawn_powerup_random(ctx, pos))
            }
        }
        else {
            power -= 1
        }
        ctx.level.layout[pos.x][pos.y] = TEX_FLOOR
    }
}