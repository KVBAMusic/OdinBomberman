package main

Entity :: union {^Player, ^Bomb, ^Powerup}

entity_tick :: proc(entity: Entity, ctx: ^CTX) {
    switch e in entity {
        case ^Player:
            player_tick(e, ctx)
        case ^Bomb:
            bomb_tick(e, ctx)
        case ^Powerup:
            powerup_tick(e, ctx)
        }
}

entity_idx :: proc(entity: Entity) -> u32 {
    switch e in entity {
        case ^Player: 
            if (e.alive) {
                return e.tex_id
            }
            return TEX_DEAD
        case ^Bomb:
            if e.life <= 20 do return TEX_BOMB5
            if e.life <= 40 do return TEX_BOMB4
            if e.life <= 60 do return TEX_BOMB3
            if e.life <= 80 do return TEX_BOMB2
            return TEX_BOMB1
        case ^Powerup:
            switch e.type {
                case .BombUp: return TEX_BOMB_UP
                case .FireUp: return TEX_FIRE_UP
            }
    }
    return ~(u32(0))
}

entity_pos :: proc(entity: Entity) -> [2]int {
    switch e in entity {
        case ^Player: return e.pos
        case ^Bomb: return e.pos
        case ^Powerup: return e.pos
    }
    return -1
}

entity_free :: proc(entity: Entity) {
    switch e in entity {
        case ^Player: free(e)
        case ^Bomb: free(e)
        case ^Powerup: free(e)
    }
}
