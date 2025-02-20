-- delete original main.lua and make this the new one when done

EVENT_RANDOM_HEALTH = 1 << 0
EVENT_BROKEN_LEG = 1 << 1
EVENT_LIGHTNING = 1 << 2
EVENT_ANGRY_MARIO = 1 << 3
EVENT_MARIO_DANCE = 1 << 4
EVENT_SUPER_SPEED = 1 << 5
EVENT_MARIO_FUSE = 1 << 6
EVENT_MOONJUMP = 1 << 7
EVENT_BLIND = 1 << 8
EVENT_CLUSTER_BOMB = 1 << 9
EVENT_FLY_TO_MOON = 1 << 10
EVENT_BACKFLIP = 1 << 11
EVENT_HERE_COMES_THE_MONEY = 1 << 12
EVENT_SUCKED_INTO_GROUND = 1 << 13
EVENT_JACKPOT = 1 << 14
EVENT_MUSHROOM = 1 << 15
EVENT_LOW_GRAVITY = 1 << 16
EVENT_ENEMY_APOCALYPSE = 1 << 17
EVENT_INVISIBLE_PLAYER = 1 << 18

HOOK_MARIO_UPDATE_LOCAL = 1
HOOK_MARIO_UPDATE_GLOBAL = 2
HOOK_ON_DICE_ROLL = 3
HOOK_ON_HUD_RENDER = 4

MUSHROOM_TYPE_GREEN_DEMON = 0
MUSHROOM_TYPE_BURGER = 1

local ps = gPlayerSyncTable
local np = gNetworkPlayers

for i = 0, MAX_PLAYERS - 1 do
    ps[i].event = 0x0
    ps[i].eventTimers = {}
end

local function event_random_health(m, timer)
    m.health = math.random(0xFF, 0x880)
end

local function event_broken_leg_hud(m, timer, sWidth, sHeight)
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_render_texture(texbrokenleg, 20, 33, 0.1, 0.1)
end

local function event_on_broken_leg_roll(m)
    network_play(sBoneBreak, m.pos, 1, m.playerIndex)
    set_mario_action(m, ACT_THROWN_FORWARD, 0)
    djui_popup_create_global(gNetworkPlayers[m.playerIndex].name .. " broke his leg!", 1)
end

local function event_broken_leg(m, timer)
    if m.action ~= ACT_THROWN_FORWARD and m.action ~= ACT_HARD_FORWARD_AIR_KB then
        if m.forwardVel > 30 and m.action & ACT_FLAG_BUTT_OR_STOMACH_SLIDE == 0 then
            m.forwardVel = m.forwardVel - 25
            network_play(sBoneBreak, m.pos, 1, m.playerIndex)
            set_mario_action(m, ACT_THROWN_FORWARD, 0)
        end
    end

    if m.controller.buttonPressed & A_BUTTON ~= 0 then
        if m.action ~= ACT_THROWN_FORWARD and m.action ~= ACT_BACKWARD_AIR_KB and m.action ~= ACT_HARD_FORWARD_AIR_KB then
            if m.action == ACT_JUMP or m.action == ACT_SIDE_FLIP or m.forwardVel > 35 then
                network_play(sBoneBreak, m.pos, 1, m.playerIndex)
                set_mario_action(m, ACT_THROWN_FORWARD, 0)
            end
            if m.action == ACT_BACKFLIP or m.action == ACT_SLIDE_KICK then
                network_play(sBoneBreak, m.pos, 1, m.playerIndex)
                set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
            end
            if m.action == ACT_LONG_JUMP then
                m.pos.y = m.pos.y + 20
                m.forwardVel = 40
                set_mario_action(m, ACT_HARD_FORWARD_AIR_KB, 0)
            end
        end
    end
end

local function event_on_lightning_roll(m, timer)
    spawn_sync_object(id_bhvLightning, E_MODEL_LIGHTNING, m.pos.x, m.pos.y + 400, m.pos.z, nil)
    network_play(sThunder, m.pos, 1, m.playerIndex)
    local stepResult = perform_air_step(m, 0)
    if stepResult == AIR_STEP_LANDED then
        set_mario_action(m, ACT_SHOCKED, 0)
    else
        set_mario_action(m, ACT_THROWN_FORWARD, 0)
    end
    m.health = m.health - 1024
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got struck by lightning!", 1)
end

local function event_angry_mario(m, timer)
    if m.action == ACT_PUTTING_ON_CAP then ps[m.playerIndex].eventTimers[EVENT_ANGRY_MARIO] = 0 end

    if timer == 5 then
        set_mario_action(m, ACT_PUNCHING, 1)
    end

    if timer == 1 then
        cutscene_put_cap_on(m)
        mario_blow_off_cap(m, 300)
        save_file_clear_flags(SAVE_FLAG_CAP_ON_GROUND | SAVE_FLAG_CAP_ON_KLEPTO | SAVE_FLAG_CAP_ON_UKIKI | SAVE_FLAG_CAP_ON_MR_BLIZZARD)
        --set_mario_action(m, MARIO_CAPS, 0)
    end
end

local function event_on_angry_mario_roll(m, timer)
    if m.flags & MARIO_CAP_ON_HEAD ~= 0 then
        if m.character.type == CT_MARIO then
            network_play(sAngrymario, m.pos, 1, m.playerIndex)
        elseif m.character.type == CT_LUIGI then
            network_play(sAngryluigi, m.pos, 1, m.playerIndex)
        elseif m.character.type == CT_TOAD then
            network_play(sAngrytoad, m.pos, 1, m.playerIndex)
        elseif m.character.type == CT_WALUIGI then
            network_play(sAngrywaluigi, m.pos, 1, m.playerIndex)
        elseif m.character.type == CT_WARIO then
            network_play(sAngrywario, m.pos, 1, m.playerIndex)
        end
        cutscene_take_cap_off(m)
        set_mario_action(m, ACT_HOLD_FREEFALL_LAND, 1)
        djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " threw their cap in a fit of RAGE!", 1)
    else
        save_file_clear_flags(SAVE_FLAG_CAP_ON_GROUND | SAVE_FLAG_CAP_ON_KLEPTO | SAVE_FLAG_CAP_ON_UKIKI | SAVE_FLAG_CAP_ON_MR_BLIZZARD)
        cutscene_put_cap_on(gMarioStates[0])
        set_mario_action(m, ACT_PUTTING_ON_CAP, 1)
        m.cap = m.cap & ~(SAVE_FLAG_CAP_ON_GROUND | SAVE_FLAG_CAP_ON_KLEPTO | SAVE_FLAG_CAP_ON_UKIKI | SAVE_FLAG_CAP_ON_MR_BLIZZARD)
        djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " found a replacement cap!", 1)
    end
end

local function event_on_mario_dance_roll(m, timer)
    fadeout_music(0)
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " is showing their moves!", 1)
    stream_play(dance)
    set_mario_action(m, ACT_PUNCHING, 9) --breakdance
end

local function event_mario_dance(m, timer)
    m.faceAngle.y = m.faceAngle.y + 4950
    m.forwardVel = 0
    m.controller.stickX = 0
    m.controller.stickY = 0
    m.controller.rawStickX = 0
    m.controller.rawStickY = 0
    m.intendedYaw = 0

    if (timer % 21) == 0 then
        set_mario_action(gMarioStates[0], ACT_CROUCHING, 0)
    end

    if (timer) % 20 == 0 then
        set_mario_action(gMarioStates[0], ACT_PUNCHING, 9) --breakdance
    end

    if (timer) == 1 then
        stream_stop_all()
        set_background_music(0, get_current_background_music(), 0)
    end
end

local function event_on_super_speed_roll(m, timer)
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " rolled super speed!", 1)
    fadeout_music(3)
    stream_play(gold)
end

local function event_super_speed(m, timer)
    if m.action == ACT_WALKING or m.action == ACT_LONG_JUMP then
        m.forwardVel = 140
    elseif m.forwardVel > 50 then
        m.forwardVel = 35
    end

    if timer == 1 then
        stream_stop_all()
        set_background_music(0, get_current_background_music(), 0)
    end
end

local function event_super_speed_hud(m, timer, sWidth, sHeight)
    djui_hud_set_resolution(RESOLUTION_N64);
    djui_hud_render_texture(texspeed, 20, 33, 0.1, 0.1)
end

local function event_on_mario_fuse_roll(m, timer)
    fadeout_music(0)
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " is about to blow up!", 1)
    network_play(sNEScastle, m.pos, 1, m.playerIndex)
    play_secondary_music(0,0,0,0)
end

local function event_mario_fuse_hud(m, timer, sWidth, sHeight)
    if timer <= 0 or timer >= 240 then return end

    djui_hud_set_resolution(RESOLUTION_N64)

    local tex = ((timer // 30) % 2 == 0) and texexplosion or texexplosion2
    djui_hud_render_texture(tex, 20, 33, 0.1, 0.1)
end

local function event_mario_fuse(m, timer)
    if m.playerIndex ~= 0 then return end

    local mariotouchingwater = m.pos.y <= m.waterLevel
    local mariotouchingfloodwater = false

    if gGlobalSyncTable.floodenabled then
        local floodwater = obj_get_first_with_behavior_id(bhvFloodWater)
        if floodwater then
            mariotouchingfloodwater = m.pos.y <= floodwater.oPosY
        end
    end

    if mariotouchingwater or mariotouchingfloodwater then
        spawn_mist_particles()

        djui_popup_create_global(gNetworkPlayers[m.playerIndex].name .. " successfully put out the fuse!", 1)
        ps[m.playerIndex].eventTimers[EVENT_MARIO_FUSE] = 1

        stop_all_samples()
        network_play(sCooloff, m.pos, 1, m.playerIndex)
        stop_secondary_music(0)
        set_background_music(0, get_current_background_music(), 0)

        if not obj_get_first_with_behavior_id(id_bhvActSelector) then
            spawn_sync_object(id_bhvHidden1upInPole, E_MODEL_1UP, m.pos.x, m.pos.y, m.pos.z, function(obj)
                obj.oBehParams2ndByte = 2
                obj.oAction = 3
            end)
        end
    end

    spawn_sync_object(id_bhvBobombFuseSmoke, E_MODEL_SMOKE, m.pos.x + math.random(-75, 25), m.pos.y - 100, m.pos.z, nil)
    cur_obj_play_sound_1(SOUND_AIR_BOBOMB_LIT_FUSE)

    if timer == 1 then
        network_play(sNesdeath, m.pos, 1, m.playerIndex)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z, nil)
        m.health = 0xff
        stop_secondary_music(0)
        stream_stop_all()
    end
end

local function event_moon_jump_hud(m, timer, sWidth, sHeight)
    djui_hud_set_resolution(RESOLUTION_N64);
    djui_hud_render_texture(texmoonjump, 20, 33, .1, .1)
end

local function event_on_moon_jump_roll(m, timer)
    network_play(sMoonjump, m.pos, 1, m.playerIndex)
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got MOON JUMP!", 1)
end

local function event_moon_jump(m, timer)
    if (m.controller.buttonDown & A_BUTTON) ~= 0 then
        m.vel.y = 25
    end
end

local function event_on_blind_roll(m, timer)
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " is getting trolled!", 1)
    local_play(sTroll, m.pos, 1)
end

local function event_blind_hud(m, timer, sWidth, sHeight)
    local wh = textroll.width
    local texheight = textroll.height
    local s = sWidth / sHeight

    djui_hud_set_resolution(RESOLUTION_DJUI)
    djui_hud_render_texture(textroll, 0, (sHeight - texheight) / -2, s*2, s*1.5)
    --djui_hud_render_texture(textroll, -20, -50, .9, .7)

    djui_hud_set_resolution(RESOLUTION_N64);
    djui_hud_render_texture(textrollhud, 20, 33, .1, .1)
end

local function event_on_cluster_bomb_roll(m, timer)
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " dropped a cluster bomb!", 1)
    network_play(sKa, m.pos, 1, m.playerIndex)
    set_mario_action(m, ACT_TRIPLE_JUMP, 0)
end

local function spawn_explosions(m, offset)

    local positions = {
        { offset,  offset}, { offset,  0}, { offset, -offset},
        { 0,      offset}, { 0,      -offset},
        {-offset,  offset}, {-offset, 0}, {-offset, -offset}
    }

    for _, pos in ipairs(positions) do
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION,
            m.pos.x + pos[1], m.pos.y, m.pos.z + pos[2],
            function (exp) exp.oBehParams = 20 end
        )
    end
end

local function event_cluster_bomb(m, timer)

    if m.marioObj.oFlyGuyUnusedJitter <= 0 then
        if (timer) == 55 and m.action ~= ACT_GROUND_POUND then
            set_mario_action(m, ACT_GROUND_POUND, 0)
            ps[m.playerIndex].eventTimers[EVENT_CLUSTER_BOMB] = 9000
        end

        if m.action == ACT_GROUND_POUND_LAND then
            m.marioObj.oFlyGuyUnusedJitter = 1
            network_play(sBoom, m.pos, 1, m.playerIndex)
            ps[m.playerIndex].eventTimers[EVENT_CLUSTER_BOMB] = 55
        end

        m.peakHeight = m.pos.y
    end

    if m.marioObj.oFlyGuyUnusedJitter > 0 then
        local explosion_steps = {30, 35, 40, 45, 50}
        local offsets = {1200, 700, 500, 300, 100}

        for i, step in ipairs(explosion_steps) do
            if timer == step then
                spawn_explosions(m, offsets[i])
            end
        end
    end

    if timer <= 1 then
        m.marioObj.oFlyGuyUnusedJitter = 0
    end
end

local function event_on_fly_to_moon_roll(m, timer)
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " went to the moon!", 1)
    fadeout_music(0)
    m.pos.y = m.pos.y + 10
    play_secondary_music(0,0,0,0)
    stream_play(moon)
end

local function event_fly_to_moon(m, timer)
    if moontimer == 20 then
        stop_secondary_music(0)
        set_background_music(0, get_current_background_music(), 0)
    end

    if timer > 500 and math.abs(m.floorHeight - m.pos.y) < 1000 then --Send Mario to the damn moon.
        set_mario_action(m, ACT_JUMP, 0)
        m.pos.y = m.floorHeight
        m.pos.y = m.pos.y + 30000
    end
end

local function event_on_backflip_roll(m, timer)
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " did a sick backflip!", 1)
    network_play(sSpecial, m.pos, 1, m.playerIndex)
    set_mario_action(m, ACT_BACKFLIP, 0)
end

local function event_on_money_roll(m, timer)
    djui_popup_create_global(tostring(gNetworkPlayers[gMarioStates[0].playerIndex].name) .. " gives RICHES AND GLORY FOR ALL!", 1)
    for i = 0, 71 do
        if m.playerIndex ~= 0 then return end
        spawn_sync_object(id_bhvTenCoinsSpawn, E_MODEL_EXCLAMATION_POINT, m.pos.x, m.pos.y - 50, m.pos.z, nil)
    end
    for i = 0, 40 do
        if m.playerIndex ~= 0 then return end
        spawn_sync_object(id_bhv1upRunningAway,E_MODEL_1UP,m.pos.x, m.pos.y - 50, m.pos.z,nil)
    end
end

local function event_on_sucked_into_earth_roll(m, timer)

    if math.random(1,5) == 5 then
        djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " was sucked into the ground!", 1)
        set_mario_action(gMarioStates[0], ACT_QUICKSAND_DEATH, 0)
    else
        roll_dice(m)
    end
end

local function spawn_coins(m, model, behavior, y_offset)
    local offsets = {
        { 50,  0}, { 50,  50}, {  0,  50}, {-50,  50},
        {-50,  0}, {-50, -50}, {  0, -50}, { 50, -50}
    }

    for _, pos in ipairs(offsets) do
        spawn_sync_object(behavior, model, m.pos.x + pos[1], m.pos.y + y_offset, m.pos.z + pos[2], nil)
    end
end

local function event_on_jackpot_roll(m, timer)
    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " won the lottery!", 1)
    network_play(sJackpot, m.pos, 1, m.playerIndex)

    spawn_coins(m, E_MODEL_YELLOW_COIN, id_bhvMovingYellowCoin, 100)

    spawn_coins(m, E_MODEL_BLUE_COIN, id_bhvBlueCoinJumping, 100)
    spawn_coins(m, E_MODEL_BLUE_COIN, id_bhvBlueCoinJumping, 200)
end

local function event_on_mushroom_roll(m, timer)
    local mushroomType = math.random(1, 3)

    if obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil then return end

    local mushroomEffects = {
        {
            message = " got a 1-UP!",
            sound = sBeetle,
            model = E_MODEL_1UP,
            behavior = id_bhvHidden1upInPole,
            type = nil,
        },
        {
            message = " spawned a DEMON!",
            soundBit = SOUND_OBJ_BOWSER_LAUGH,
            model = E_MODEL_GREEN_DEMON,
            behavior = id_bhvCustom1up,
            type = MUSHROOM_TYPE_GREEN_DEMON,
            musicFade = true,
        },
        {
            message = " spawned a cheeseburger!",
            sound = sCheeseburger,
            model = E_MODEL_CHEESE_BURGER,
            behavior = id_bhvCustom1up,
            type = MUSHROOM_TYPE_BURGER,
        }
    }

    local effect = mushroomEffects[mushroomType]
    if not effect then return end

    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. effect.message, 1)
    if effect.musicFade then fadeout_music(0) end
    if effect.sound then
        local_play(effect.sound, m.pos, 1)
    elseif effect.soundBit then
        play_sound(effect.soundBit, gGlobalSoundSource)
    end

    local spawnFunc = (mushroomType == 1) and spawn_sync_object or spawn_non_sync_object
    spawnFunc(effect.behavior, effect.model, m.pos.x, m.pos.y + (mushroomType == 3 and 50 or 200), m.pos.z, function(obj)
        if effect.type then obj.o1upType = effect.type end
        obj.oBehParams2ndByte = 2
        obj.oAction = 3
    end)
end

local function event_on_low_gravity_roll(m, timer)
    fadeout_music(0)
    stream_play(metalcap)
    djui_popup_create_global(tostring(gNetworkPlayers[gMarioStates[0].playerIndex].name) .. " has low gravity!", 1)
end

local function event_low_gravity(m, timer)
    m.peakHeight = 0
    if (m.action & ACT_FLAG_AIR) ~= 0 and m.action ~= ACT_LONG_JUMP then
        m.vel.y = m.vel.y + 2.5
    end
    if m.action == ACT_LONG_JUMP then
        m.vel.y = m.vel.y + 1.5
    end
end

local function event_on_enemy_apocalypse_roll(m, timer)
    local random = math.random(1,2)
    network_play(sHomer, m.pos, 1, m.playerIndex)
    if random == 1 then
        djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a Bobomb-pocalypse!", 1)
        for i = 0, 30 do
            local xoffset = math.random(-1200, 1200)
            local zoffset = math.random(-1200, 1200)
            spawn_sync_object(id_bhvBobomb, E_MODEL_BLACK_BOBOMB, m.pos.x + xoffset, m.pos.y, m.pos.z + zoffset, function (bobomb)
                bobomb.oBobombFuseLit = 1
                bobomb.oAction = BOBOMB_ACT_CHASE_MARIO
                bobomb.oForwardVel = 35
            end)
        end
    else
        djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a Goompocalypse!", 1)
        for i = 0, 40 do
            local xoffset = math.random(-200, 200)
            local zoffset = math.random(-200, 200)
            spawn_sync_object(id_bhvGoomba, E_MODEL_GOOMBA, m.pos.x + xoffset, m.pos.y, m.pos.z + zoffset, nil)
        end
    end
end

local function event_invisible_player(m, timer)
    obj_scale(m.marioObj, 0)
end

local sEventTable = {
   {id = EVENT_RANDOM_HEALTH, func = event_random_health, timerMax = 3 * 30, hook = HOOK_MARIO_UPDATE_LOCAL},

   {id = EVENT_BROKEN_LEG, func = event_broken_leg, timerMax = 5 * 30, hook = HOOK_MARIO_UPDATE_LOCAL, timerOwner = HOOK_MARIO_UPDATE_LOCAL},
   {id = EVENT_BROKEN_LEG, func = event_on_broken_leg_roll, timerMax = 5 * 30, hook = HOOK_ON_DICE_ROLL},
   {id = EVENT_BROKEN_LEG, func = event_broken_leg_hud, timerMax = 5 * 30, hook = HOOK_ON_HUD_RENDER},

   {id = EVENT_LIGHTNING, func = event_on_lightning_roll, timerMax = 0, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_ANGRY_MARIO, func = event_angry_mario, timerMax = 55, hook = HOOK_MARIO_UPDATE_LOCAL, timerOwner = HOOK_MARIO_UPDATE_LOCAL},
   {id = EVENT_ANGRY_MARIO, func = event_on_angry_mario_roll, timerMax = 55, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_MARIO_DANCE, func = event_mario_dance, timerMax = 100, hook = HOOK_MARIO_UPDATE_LOCAL, timerOwner = HOOK_MARIO_UPDATE_LOCAL},
   {id = EVENT_MARIO_DANCE, func = event_on_mario_dance_roll, timerMax = 100, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_SUPER_SPEED, func = event_super_speed, timerMax = 8 * 30, hook = HOOK_MARIO_UPDATE_LOCAL, timerOwner = HOOK_MARIO_UPDATE_LOCAL},
   {id = EVENT_SUPER_SPEED, func = event_on_super_speed_roll, timerMax = 8 * 30, hook = HOOK_ON_DICE_ROLL},
   {id = EVENT_SUPER_SPEED, func = event_super_speed_hud, timerMax = 8 * 30, hook = HOOK_ON_HUD_RENDER},

   {id = EVENT_MARIO_FUSE, func = event_mario_fuse, timerMax = 8 * 30, hook = HOOK_MARIO_UPDATE_LOCAL, timerOwner = HOOK_MARIO_UPDATE_LOCAL},
   {id = EVENT_MARIO_FUSE, func = event_mario_fuse_hud, timerMax = 8 * 30, hook = HOOK_ON_HUD_RENDER},
   {id = EVENT_MARIO_FUSE, func = event_on_mario_fuse_roll, timerMax = 8 * 30, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_MOONJUMP, func = event_moon_jump_hud, timerMax = 8 * 30, hook = HOOK_ON_HUD_RENDER},
   {id = EVENT_MOONJUMP, func = event_on_moon_jump_roll, timerMax = 8 * 30, hook = HOOK_ON_DICE_ROLL},
   {id = EVENT_MOONJUMP, func = event_moon_jump, timerMax = 8 * 30, hook = HOOK_MARIO_UPDATE_LOCAL, timerOwner = HOOK_MARIO_UPDATE_LOCAL},

   {id = EVENT_BLIND, func = event_on_blind_roll, timerMax = 5 * 30, hook = HOOK_ON_DICE_ROLL},
   {id = EVENT_BLIND, func = event_blind_hud, timerMax = 5 * 30, hook = HOOK_ON_HUD_RENDER, timerOwner = HOOK_ON_HUD_RENDER},

   {id = EVENT_CLUSTER_BOMB, func = event_on_cluster_bomb_roll, timerMax = (2 * 30) + 5, hook = HOOK_ON_DICE_ROLL},
   {id = EVENT_CLUSTER_BOMB, func = event_cluster_bomb, timerMax = (2 * 30) + 5, hook = HOOK_MARIO_UPDATE_LOCAL, timerOwner = HOOK_MARIO_UPDATE_LOCAL},

   {id = EVENT_FLY_TO_MOON, func = event_on_fly_to_moon_roll, timerMax = 17 * 30, hook = HOOK_ON_DICE_ROLL},
   {id = EVENT_FLY_TO_MOON, func = event_fly_to_moon, timerMax = 17 * 30, hook = HOOK_MARIO_UPDATE_LOCAL, timerOwner = HOOK_MARIO_UPDATE_LOCAL},

   {id = EVENT_BACKFLIP, func = event_on_backflip_roll, timerMax = 0, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_HERE_COMES_THE_MONEY, func = event_on_money_roll, timerMax = 0, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_SUCKED_INTO_GROUND, func = event_on_sucked_into_earth_roll, timerMax = 0, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_JACKPOT, func = event_on_jackpot_roll, timerMax = 0, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_MUSHROOM, func = event_on_mushroom_roll, timerMax = 0, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_LOW_GRAVITY, func = event_on_low_gravity_roll, timerMax = 8 * 30, hook = HOOK_ON_DICE_ROLL},
   {id = EVENT_LOW_GRAVITY, func = event_low_gravity, timerMax = 8 * 30, hook = HOOK_MARIO_UPDATE_LOCAL, timerOwner = HOOK_MARIO_UPDATE_LOCAL},

   {id = EVENT_ENEMY_APOCALYPSE, func = event_on_enemy_apocalypse_roll, timerMax = 0, hook = HOOK_ON_DICE_ROLL},

   {id = EVENT_INVISIBLE_PLAYER, func = event_invisible_player, timerMax = 8 * 30, hook = HOOK_MARIO_UPDATE_GLOBAL},
}

local eventCount = {}

for _, event in ipairs(sEventTable) do
    eventCount[event.id] = (eventCount[event.id] or 0) + 1
end

for _, event in ipairs(sEventTable) do
    if not event.timerOwner and eventCount[event.id] == 1 then
        event.timerOwner = event.hook
    end
end

local function run_events(hook, m, ...)
    local pst = ps[m.playerIndex]

    for _, event in ipairs(sEventTable) do
        if (pst.event & event.id) ~= 0 and event.hook == hook then
            event.func(m, pst.eventTimers[event.id], ...)

            if event.timerOwner == hook and pst.eventTimers[event.id] then
                pst.eventTimers[event.id] = pst.eventTimers[event.id] - 1
                if pst.eventTimers[event.id] <= 0 then
                    pst.event = pst.event & ~event.id
                    pst.eventTimers[event.id] = nil
                end
            end
        end
    end
end

function roll_dice(m)
    local randomEvent = sEventTable[math.random(#sEventTable)]
    local pst = ps[m.playerIndex]

    m.marioObj.oFlyGuyUnusedJitter = 0

    if (pst.event & randomEvent.id) == 0 then
        pst.event = pst.event | randomEvent.id
        pst.eventTimers[randomEvent.id] = randomEvent.timerMax
    end

    run_events(HOOK_ON_DICE_ROLL, m)
end

local function mario_update(m)
    if m.controller.buttonPressed & X_BUTTON ~= 0 and m.playerIndex == 0 then
        roll_dice(m)
    end

    run_events(HOOK_MARIO_UPDATE_GLOBAL, m)

    if m.playerIndex == 0 then
        run_events(HOOK_MARIO_UPDATE_LOCAL, m)
    end
end

local function on_hud_render_behind()
    local sWidth = djui_hud_get_screen_width()
    local sHeight = djui_hud_get_screen_height()
    run_events(HOOK_ON_HUD_RENDER, gMarioStates[0], sWidth, sHeight)
end

hook_event(HOOK_ON_HUD_RENDER_BEHIND, on_hud_render_behind)
hook_event(HOOK_MARIO_UPDATE, mario_update)

define_custom_obj_fields({
    o1upType = "u32"
})

local function custom_1up_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE | OBJ_FLAG_COMPUTE_DIST_TO_MARIO | OBJ_FLAG_COMPUTE_ANGLE_TO_MARIO
    bhv_1up_common_init()
    bhv_1up_init()
    obj_set_billboard(o)

    if o.o1upType == MUSHROOM_TYPE_GREEN_DEMON then
        local hitbox = get_temp_object_hitbox()

        hitbox.interactType = INTERACT_DAMAGE
        hitbox.radius = 50
        hitbox.height = 50
        hitbox.damageOrCoinValue = 100

        obj_set_hitbox(o, hitbox)
    elseif o.o1upType == MUSHROOM_TYPE_BURGER then
        local hitbox = get_temp_object_hitbox()

        hitbox.interactType = INTERACT_WATER_RING
        hitbox.radius = 50
        hitbox.height = 50

        obj_set_hitbox(o, hitbox)
    end
end

local function custom_1up_loop(o)
    bhv_1up_hidden_in_pole_loop()

    if o.oAction ~= 3 and o.oInteractStatus & INT_STATUS_INTERACTED ~= 0 then
        if o.o1upType == MUSHROOM_TYPE_BURGER then
            local m = nearest_mario_state_to_object(o)

            m.numLives = m.numLives - 2
            m.health = m.health + 256
        else
            m.numLives = m.numLives - 1
        end
    end

    o.oInteractStatus = 0
end

id_bhvCustom1up = hook_behavior(nil, OBJ_LIST_GENACTOR, true, custom_1up_init, custom_1up_loop, "bhvCustom1up")