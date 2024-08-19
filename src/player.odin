package main

import "core:fmt"

Player :: struct {
    pos: [2]int,
    alive: bool,
    bombs: u32,
    power: u32,
    input: ^Input,
    tex_id: u32,

    move_delay: u32,
    move_ticks: u32,
}

spawn_player :: proc(pos: [2]int, input: ^Input, tex_id: u32) -> ^Player {
    player := new(Player)
    player.pos = pos
    player.bombs = 1
    player.power = 1
    player.input = input
    player.tex_id = tex_id
    player.alive = true
    player.move_delay = 6
    player.move_ticks = 0
    return player
}

get_move_directions :: proc(player: ^Player, ctx: ^CTX) -> (up, down, left, right: bool) {
    positions: [4][2]int = {
        player.pos + {0, -1},
        player.pos + {0, 1},
        player.pos + {-1, 0},
        player.pos + {1, 0},
    }
    up = ctx.level.layout[positions[0].x][positions[0].y] == TEX_FLOOR 
    down = ctx.level.layout[positions[1].x][positions[1].y] == TEX_FLOOR 
    left = ctx.level.layout[positions[2].x][positions[2].y] == TEX_FLOOR 
    right = ctx.level.layout[positions[3].x][positions[3].y] == TEX_FLOOR

    up &= !check_for_bomb(ctx, positions[0])
    down &= !check_for_bomb(ctx, positions[1])
    left &= !check_for_bomb(ctx, positions[2])
    right &= !check_for_bomb(ctx, positions[3])

    return 
}

check_for_bomb :: proc(ctx: ^CTX, pos: [2]int) -> bool {
    e: Entity
    e, _ = get_entity_at_position(ctx, pos)
    _, ok := e.(^Bomb)
    return ok
}

player_tick :: proc(player: ^Player, ctx: ^CTX) {
    using player

    if !alive {
        return
    }

    if ctx.level.explosions[pos.x][pos.y] > 0 {
        alive = false
        return
    }

    if !input_any(input) {
        move_ticks = 0
    }

    up, down, left, right := get_move_directions(player, ctx)
    if input.up && up {
        if move_ticks == 0 {
            move_ticks = move_delay
            pos[1] -= 1
        }
        else {
            move_ticks -= 1
        }
    }
    else if input.down && down {
        if move_ticks == 0 {
            move_ticks = move_delay
            pos[1] += 1
        }
        else {
            move_ticks -= 1
        }
    }
    else if input.right && right {
        if move_ticks == 0 {
            move_ticks = move_delay
            pos[0] += 1
        }
        else {
            move_ticks -= 1
        }
    }
    else if input.left && left {
        if move_ticks == 0 {
            move_ticks = move_delay
            pos[0] -= 1
        }
        else {
            move_ticks -= 1
        }
    }

    if input.bomb && !bomb_search_predicate(ctx.level.entities[:], player) {
        if bombs > 0 {
            append(&ctx.level.entities, cast(Entity)spawn_bomb(pos.x, pos.y, player, power))
            bombs -= 1
            fmt.println("Placing bomb, bombs left:", bombs)
        }
        input.bomb = false
    }
}

bomb_search_predicate :: proc(entities: []Entity, player: ^Player) -> bool {
    out := false

    for elem in entities {
        if _, ok := elem.(^Bomb); !ok {
            continue
        }
        out |= entity_pos(elem) == player.pos
        if (out) {
            break
        }
    }

    return out
}

