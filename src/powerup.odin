package main

import "core:math/rand"

Powerup_Type :: enum u8 {
    BombUp = 0,
    FireUp = 1,
}

Powerup :: struct {
    pos: [2]int,
    type: Powerup_Type,
}

spawn_powerup_random :: proc(ctx: ^CTX, pos: [2]int) -> ^Powerup {
    powerup := new(Powerup)

    powerup.pos = pos
    powerup.type = rand.choice_enum(Powerup_Type)
    return powerup
}

powerup_tick :: proc(powerup: ^Powerup, ctx: ^CTX) {
    using powerup
    entity, idx := get_entity_at_position(ctx, pos, powerup)
    player, ok := entity.(^Player)
    if !ok {
        return
    }
    add_powerup(player, type)
    remove_entity(ctx, powerup)
} 

add_powerup :: proc(player: ^Player, powerup: Powerup_Type) {
    switch powerup {
        case .BombUp:
            player.bombs += 1
        case .FireUp:
            player.power += 1
    }
}