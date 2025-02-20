-- name: Roll The Dice! V2.0 [WIP]
-- description: Press Dpad+Up to ROLL THE DICE for a random buff, debuff, or special event!\n\nMod by TheIncredibleHolc and contributions from the GORE Team!

-- DISCLAIMER! This is a crude attempt of a V2 overhaul of my very first mod. This code is ATROCIOUS since I had no idea what I was doing back then.
-- With the knowledge that I've gained from making Gore Hardmode and Frogger, I'm carrying over a lot of QoL fixes to this old mod.
-- Custom networking audio engine (as used in Gore mods) provided by CoolioKid956. Thanks Coolio!

-- I hope you enjoy the mode, and you're welcome to message me on Discord for questions or recommendations! -TheIncredibleHolc

------Variables n' stuff------
moontimer = 0
E_MODEL_GREEN_DEMON = smlua_model_util_get_id("green_demon_geo")
E_MODEL_CHEESE_BURGER = smlua_model_util_get_id("cheese_burger_geo")
randomhealthtimer = 0
brokenleg = 0
brokenlegtimer = 0
rtdtimer = 1
lightningcounter = 0
angrycounter = 0
firstpress = 0
mariospin = 0
speeen = 0
nospeen = 0
marioboostrtd = 0
speedcounter = 0
m = gMarioStates[0]
mariofusetime = 0
fusecounter = 0
moonjumpcount = 0
blind = 0
blindcounter = 0
clusterbomb = 0
clusterbombtimer = 0
clusterbombexplosions = 0
clusterbombtimer2 = 0
alwaysrunning = 0
alwaysrunningtimer = 0
megamushroom = 0
welcomeprompt = 1
rtdstall = 0

gGlobalSyncTable.autoroll = false

--------locals--------
local network_player_connected_count,init_single_mario,warp_to_level,play_sound,network_is_server,network_get_player_text_color_string,djui_chat_message_create,disable_time_stop,network_player_set_description,set_mario_action,obj_get_first_with_behavior_id,obj_check_hitbox_overlap,spawn_mist_particles,vec3f_dist,play_race_fanfare,play_music,djui_hud_set_resolution,djui_hud_get_screen_height,djui_hud_get_screen_width,djui_hud_render_rect,djui_hud_set_font,djui_hud_world_pos_to_screen_pos,clampf,math_floor,djui_hud_measure_text,djui_hud_print_text,hud_render_power_meter,hud_get_value,save_file_erase_current_backup_save,save_file_set_flags,save_file_set_using_backup_slot,find_floor_height,spawn_non_sync_object,set_environment_region,vec3f_set,vec3f_copy,math_random,set_ttc_speed_setting,get_level_name,hud_hide,smlua_text_utils_secret_star_replace,smlua_audio_utils_replace_sequence = network_player_connected_count,init_single_mario,warp_to_level,play_sound,network_is_server,network_get_player_text_color_string,djui_chat_message_create,disable_time_stop,network_player_set_description,set_mario_action,obj_get_first_with_behavior_id,obj_check_hitbox_overlap,spawn_mist_particles,vec3f_dist,play_race_fanfare,play_music,djui_hud_set_resolution,djui_hud_get_screen_height,djui_hud_get_screen_width,djui_hud_render_rect,djui_hud_set_font,djui_hud_world_pos_to_screen_pos,clampf,math.floor,djui_hud_measure_text,djui_hud_print_text,hud_render_power_meter,hud_get_value,save_file_erase_current_backup_save,save_file_set_flags,save_file_set_using_backup_slot,find_floor_height,spawn_non_sync_object,set_environment_region,vec3f_set,vec3f_copy,math.random,set_ttc_speed_setting,get_level_name,hud_hide,smlua_text_utils_secret_star_replace,smlua_audio_utils_replace_sequence
local texInfo = get_texture_info('rtd')
local texexplosion = get_texture_info('fuselit')
local texexplosion2 = get_texture_info('touchwater')
local texlowgravity = get_texture_info('lowgravity')
local texspeed = get_texture_info('speed')
local texlightning = get_texture_info('lightning')
local texbrokenleg = get_texture_info('brokenleg')
local texmoonjump = get_texture_info('moonjump')
local textroll = get_texture_info('troll')
local textrollhud = get_texture_info('trollhud')
local texsleep = get_texture_info('sleep')
local texwelcome = get_texture_info('welcome')

counter_stuff = {
    display_number_time = 0,
    counter_func = nil
}

--------playersynctable--------

for i = 0, MAX_PLAYERS - 1 do
    gPlayerSyncTable[i].megamushroom = false
    gPlayerSyncTable[i].megamushroomscale = 1
    gPlayerSyncTable[i].powerup_timer = 1
end

--------functions--------

function RTDclock (m)
    if not dead and rtdstall == 0 then
        rtdtimer = rtdtimer - 1
    end

    rtdstall = clampf(rtdstall - 1, 0, math.huge)
end

function mariobrokenleg (m)
    if (brokenleg) == 1 then
        if (brokenlegtimer) >= 150 then
            brokenleg = 0
            brokenlegtimer = 0
        else
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texbrokenleg, 20, 33, .1, .1)
            brokenlegtimer = brokenlegtimer + 1
        end
    end
end

function moonclock (m)
    if moontimer == 20 then
        stop_secondary_music(0)
        set_background_music(0, get_current_background_music(), 0)
    end
    if moontimer > 0 then
        moontimer = moontimer - 1
    end
end

function display_countdown()
    if counter_stuff.display_number_time ~= 0 then
        local time_string = tostring(math.floor(counter_stuff.display_number_time / 30))
        local number_textures = {
            [1] = {tex = get_texture_info('1'), color = {r = 255, g = 46, b = 46}},
            [2] = {tex = get_texture_info('2'), color = {r = 53, g = 255, b = 46}},
            [3] = {tex = get_texture_info('3'), color = {r = 46, g = 49, b = 255}},
            [4] = {tex = get_texture_info('4'), color = {r = 210, g = 255, b = 46}},
            [5] = {tex = get_texture_info('5'), color = {r = 255, g = 46, b = 46}},
            [6] = {tex = get_texture_info('6'), color = {r = 53, g = 255, b = 46}},
            [7] = {tex = get_texture_info('7'), color = {r = 46, g = 49, b = 255}},
            [8] = {tex = get_texture_info('8'), color = {r = 210, g = 255, b = 46}},
            [9] = {tex = get_texture_info('9'), color = {r = 255, g = 46, b = 46}},
            [0] = {tex = get_texture_info('0'), color = {r = 53, g = 255, b = 46}}
        }

        djui_hud_set_resolution(RESOLUTION_N64);

        for i = 1, string.len(time_string) do
            local display_number = number_textures[tonumber(string.sub(time_string, i, i))]
            local width_offset = 16 * (i - 1)

            djui_hud_set_color(display_number.color.r, display_number.color.g, display_number.color.b, 255)

            djui_hud_render_texture(display_number.tex, 38 + width_offset, 40, 0.25, 0.25)
        end
    end

    if counter_stuff.counter_func and counter_stuff.display_number_time == 0 then
        counter_stuff.counter_func()
        counter_stuff.counter_func = nil
    end

    counter_stuff.display_number_time = clampf(counter_stuff.display_number_time - 1, 0, math.huge)
end

local function reset_music_and_turn_off_low_gravity()
    set_background_music(0, get_current_background_music(), 0)
    if (lowgravity) == 1 then
        lowgravity = 0
    end
end

function on_hud_render(m)
    local m = gMarioStates[0]
    if rtdtimer == 0 then
        local_play(sRTDready, m.pos, 1)
        djui_hud_set_resolution(RESOLUTION_N64);
        djui_hud_render_texture(texInfo, 20, 24, .2, .2)
        rtdtimer = rtdtimer -1
    end
    if rtdtimer <= -1 then
        djui_hud_set_resolution(RESOLUTION_N64);
        djui_hud_render_texture(texInfo, 20, 24, .2, .2)
    end
end

function randomizehealth (m)
    if (randomhealth) == 1 then
        mariohealth = math.random(256, 2048)
        gMarioStates[0].health = mariohealth
        --gMarioStates[0].health = 2048
        if (randomhealthtimer) == 90 then
            randomhealthtimer = 0
            randomhealth = 0
        else
            randomhealthtimer = randomhealthtimer + 1
        end
    else
    end
end

local function modsupport()
    for key,value in pairs(gActiveMods) do
        if (value.name == "Flood") or _G.floodExpanded then
            if network_is_server() then
                --djui_chat_message_create("Gore/HM Flood compatibility enabled.")
                gGlobalSyncTable.floodenabled = true

            end
        else
            if network_is_server() then
                gGlobalSyncTable.floodenabled = false
                --djui_chat_message_create("no flood")
            end
        end
    end
end
hook_event(HOOK_ON_LEVEL_INIT, modsupport)

function deadcheck()
    local m = gMarioStates[0]
    if m.health < 256 then
        dead = true
    end
end
hook_event(HOOK_UPDATE, deadcheck)

function alive()
    dead = false
end
hook_event(HOOK_ON_WARP, alive)

function rtd(m)
    local s = gStateExtras[0]
    if m.playerIndex ~= 0 then return end
    if (m.controller.buttonPressed & U_JPAD) ~= 0 or (gGlobalSyncTable.autoroll) or rerolling then --ROLL THE DICE!!
        if (rtdtimer) <= 0 and not dead then
            if m.playerIndex ~= 0 then return end
            rerolling = false
            RandomEvent = 35
            if not gGlobalSyncTable.autoroll then
                rtdtimer = 30 * 10 --10 seconds
            else
                rtdtimer = 30 * 15 --15 seconds. Cuz autoroll gets really busy really fast.
            end
            if (RandomEvent) == 1 then --Mario Trips and breaks his leg, can't jump for 5 seconds (Updated!)
                network_play(sBoneBreak, m.pos, 1, m.playerIndex)
                set_mario_action(m, ACT_THROWN_FORWARD, 0)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " broke his leg!", 1)
                brokenlegtimer = 0
                brokenleg = 1
                count_with_function_at_end(150, nil)
            end
            if (RandomEvent) == 2 then --Mario goes to the MOON! (Updated!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " went to the moon!", 1)
                fadeout_music(0)
                moontimer = 30 * 17
                m.pos.y = m.pos.y + 10
                play_secondary_music(0,0,0,0)
                stream_play(moon)
            end
            if (RandomEvent) == 3 then --Mario does a backflip.(Original)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " did a sick backflip!", 1)
                network_play(sSpecial, m.pos, 1, m.playerIndex)
                set_mario_action(m, ACT_BACKFLIP, 0)
            end
            if (RandomEvent) == 4 then --Mario gets struck by lightning! (Updated!)
                lightningstrike = 1
                spawn_sync_object(id_bhvLightning, E_MODEL_LIGHTNING, m.pos.x, m.pos.y + 400, m.pos.z, nil)
                network_play(sThunder, m.pos, 1, m.playerIndex)
                local stepResult = perform_air_step(m, 0)
                if stepResult == AIR_STEP_LANDED then
                    set_mario_action(gMarioStates[0], ACT_SHOCKED, 0)
                else
                    set_mario_action(m, ACT_THROWN_FORWARD, 0)
                end
                gMarioStates[0].health = gMarioStates[0].health - 1024
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got struck by lightning!", 1)

            end
            if (RandomEvent) == 5 then --TONS OF COINS! (Original)
                djui_popup_create_global(tostring(gNetworkPlayers[gMarioStates[0].playerIndex].name) .. " gives RICHES AND GLORY FOR ALL!", 1)
                for i = 0, 240 do
                    if m.playerIndex ~= 0 then return end
                    spawn_sync_object(id_bhvThreeCoinsSpawn,E_MODEL_EXCLAMATION_POINT,m.pos.x, m.pos.y - 50, m.pos.z,nil)                end
                for i = 0, 40 do
                    if m.playerIndex ~= 0 then return end
                    spawn_sync_object(id_bhv1upRunningAway,E_MODEL_1UP,m.pos.x, m.pos.y - 50, m.pos.z,nil)
                end
            end
            if (RandomEvent) == 6 then --Mario has to jump in water or he EXPLODES! (Updated!)
                fadeout_music(0)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " is about to blow up!", 1)
                network_play(sNEScastle, m.pos, 1, m.playerIndex)
                play_secondary_music(0,0,0,0)
                mariofuse = 1

                count_with_function_at_end(240, reset_music_and_turn_off_low_gravity)
            end
            if (RandomEvent) == 7 then --Mario gets sucked into the earth. (Updated!)
                local random = math.random(1,5)
                if random == 5 then
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " was sucked into the ground!", 1)
                    set_mario_action(gMarioStates[0], ACT_QUICKSAND_DEATH, 0)
                else
                    reroll()
                end
            end
            if (RandomEvent) == 8 then --Mario gets a coin jackpot! (Original)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " won the lottery!", 1)
                network_play(sJackpot, m.pos, 1, m.playerIndex)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x + 50, m.pos.y + 100, m.pos.z, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x + 50, m.pos.y + 100, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x, m.pos.y + 100, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x - 50, m.pos.y + 100, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x - 50, m.pos.y + 100, m.pos.z, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x - 50, m.pos.y + 100, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x, m.pos.y + 100, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x + 50, m.pos.y + 100, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x + 50, m.pos.y + 100, m.pos.z, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x + 50, m.pos.y + 100, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x, m.pos.y + 100, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x - 50, m.pos.y + 100, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x - 50, m.pos.y + 100, m.pos.z, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x - 50, m.pos.y + 100, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x, m.pos.y + 100, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvMovingYellowCoin, E_MODEL_YELLOW_COIN, m.pos.x + 50, m.pos.y + 100, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x + 50, m.pos.y + 100, m.pos.z, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x + 50, m.pos.y + 100, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x, m.pos.y + 100, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x - 50, m.pos.y + 100, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x - 50, m.pos.y + 100, m.pos.z, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x - 50, m.pos.y + 100, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x, m.pos.y + 100, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x + 50, m.pos.y + 100, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x + 50, m.pos.y + 200, m.pos.z, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x + 50, m.pos.y + 200, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x, m.pos.y + 200, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x - 50, m.pos.y + 200, m.pos.z + 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x - 50, m.pos.y + 200, m.pos.z, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x - 50, m.pos.y + 200, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x, m.pos.y + 200, m.pos.z - 50, nil)
                spawn_sync_object(id_bhvBlueCoinJumping, E_MODEL_BLUE_COIN, m.pos.x + 50, m.pos.y + 200, m.pos.z - 50, nil)
            end
            if (RandomEvent) == 9 then --Mario spawns a cheeseburger, green demon, or 1-up chaser!(Updated!)
                mushroomrandom = math.random(1,3)
                if (mushroomrandom) == 1 then --Mario gets a 1-up!
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got a 1-UP!", 1)
                    local_play(sBeetle, m.pos, 1)
                    if not (obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil) then
                        local obj = spawn_sync_object(
                            id_bhvHidden1upInPole,
                            E_MODEL_1UP,
                            gMarioStates[0].pos.x, gMarioStates[0].pos.y + 200, gMarioStates[0].pos.z + 0,
                            function(obj)
                                obj.oBehParams2ndByte = 2
                                obj.oAction = 3
                            end)
                    end
                end
                if (mushroomrandom) == 2 then --Mario spawns a GREEN DEMON!
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a DEMON!", 1)
                    mushroombehavior = 2 --Green Demon!
                    fadeout_music(0)
                    play_sound(SOUND_OBJ_BOWSER_LAUGH, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                    if not (obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil) then
                        local obj = spawn_non_sync_object(
                        id_bhvHidden1upInPole,
                        E_MODEL_GREEN_DEMON,
                        gMarioStates[0].pos.x, gMarioStates[0].pos.y + 200, gMarioStates[0].pos.z + 0,
                        function(obj)
                            obj.oBehParams2ndByte = 2
                            obj.oAction = 3
                        end)
                    end
                end
                if (mushroomrandom) == 3 then --Cheeseburger spawns and chases mario for health regen. (DONE)
                    mushroombehavior = 3 --Cheeseburger!
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a cheeseburger!", 1)
                    local_play(sCheeseburger, m.pos, 1)
                    if not (obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil) then
                        local obj = spawn_sync_object(
                        id_bhvHidden1upInPole,
                        E_MODEL_CHEESE_BURGER,
                        gMarioStates[0].pos.x, gMarioStates[0].pos.y + 50, gMarioStates[0].pos.z + 0,
                        function(obj)
                            obj.oBehParams2ndByte = 2
                            obj.oAction = 3
                        end)
                    end
                end
            end
            if (RandomEvent) == 10 then --Mario gets low gravity!(Updated!)
                lowgravity = 1
                fadeout_music(0)
                stream_play(metalcap)
                djui_popup_create_global(tostring(gNetworkPlayers[gMarioStates[0].playerIndex].name) .. " has low gravity!", 1)
                count_with_function_at_end(240, reset_music_and_turn_off_low_gravity)

                RandomEvent = 0
            end
            if (RandomEvent) == 11 then --Enemy apacalypse!! (Updated!)
                local m = gMarioStates[0]
                local random = math.random(1,2)
                network_play(sHomer, m.pos, 1, m.playerIndex)
                if random == 1 then
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a Bobomb-pacalypse!", 1)
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
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a Goompacalypse!", 1)
                    for i = 0, 40 do
                        local xoffset = math.random(-200, 200)
                        local zoffset = math.random(-200, 200)
                        spawn_sync_object(id_bhvGoomba, E_MODEL_GOOMBA, m.pos.x + xoffset, m.pos.y, m.pos.z + zoffset, nil)
                    end
                end
            end
            if (RandomEvent) == 12 then --Mario becomes INVISIBLE! (New!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " is invisible!", 1)
                s.invisible = 1
                gPlayerSyncTable[m.playerIndex].invisible = true
                count_with_function_at_end(240, reset_music_and_turn_off_low_gravity)
                spawn_mist_particles()
                --set_mario_action(m, ACT_INVISIBLE, 0)
            end
            if (RandomEvent) == 13 then --Spawns a random enemy! (Updated!)
                local randomenemy = math.random(1,6)
                if randomenemy == 1 then
                    spawn_sync_object(id_bhvBigBully,E_MODEL_BULLY_BOSS,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200, function(enemy)
                        enemy.oFaceAnglePitch = 0
                        enemy.oMoveAnglePitch = enemy.oFaceAnglePitch
                    end)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a big bully!", 1)
                elseif randomenemy == 2 then
                    spawn_sync_object(id_bhvBulletBill,E_MODEL_BULLET_BILL,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200, function(enemy)
                        enemy.oFaceAnglePitch = 0
                        enemy.oMoveAnglePitch = enemy.oFaceAnglePitch
                    end)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a bullet bill!", 1)
                elseif randomenemy == 3 then
                    spawn_sync_object(id_bhvHeaveHo,E_MODEL_HEAVE_HO,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200, function(enemy)
                        enemy.oFaceAnglePitch = 0
                        enemy.oMoveAnglePitch = enemy.oFaceAnglePitch
                    end)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a heave-ho!", 1)
                elseif randomenemy == 4 then
                    spawn_sync_object(id_bhvSmallWhomp,E_MODEL_WHOMP,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200, function(enemy)
                        enemy.oFaceAnglePitch = 0
                        enemy.oMoveAnglePitch = enemy.oFaceAnglePitch
                    end)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a whomp!", 1)
                elseif randomenemy == 5 then
                    spawn_sync_object(id_bhvMadPiano,E_MODEL_MAD_PIANO,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200, function(enemy)
                        enemy.oFaceAnglePitch = 0
                        enemy.oMoveAnglePitch = enemy.oFaceAnglePitch
                    end)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a piano!", 1)
                elseif randomenemy == 6 then
                    spawn_sync_object(id_bhvChuckya,E_MODEL_CHUCKYA,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200, function(enemy)
                        enemy.oFaceAnglePitch = 0
                        enemy.oMoveAnglePitch = enemy.oFaceAnglePitch
                    end)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a chuckya!", 1)
                end
            end
            if (RandomEvent) == 14 then --Mario gets MOONJUMP!(Original)
                network_play(sMoonjump, m.pos, 1, m.playerIndex)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got MOON JUMP!", 1)
                moonjump = 1
                RandomEvent = 0
                count_with_function_at_end(240, reset_music_and_turn_off_low_gravity)
            end
            if (RandomEvent) == 15 then --Mario freaks out and throws his cap. Regenerates cap if no cap. (Original)
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
                    angrymario = 1
                else
                    save_file_clear_flags(SAVE_FLAG_CAP_ON_GROUND | SAVE_FLAG_CAP_ON_KLEPTO | SAVE_FLAG_CAP_ON_UKIKI | SAVE_FLAG_CAP_ON_MR_BLIZZARD)
                    cutscene_put_cap_on(gMarioStates[0])
                    set_mario_action(m, ACT_PUTTING_ON_CAP, 1)
                    m.cap = m.cap & ~(SAVE_FLAG_CAP_ON_GROUND | SAVE_FLAG_CAP_ON_KLEPTO | SAVE_FLAG_CAP_ON_UKIKI | SAVE_FLAG_CAP_ON_MR_BLIZZARD)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " found a replacement cap!", 1)
                end
            end
            if (RandomEvent) == 16 then --Randomized mario's health. (Original)
                if not gGlobalSyncTable.floodenabled then
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got randomized health!", 1)
                    randomhealth = 1
                else
                    reroll()
                end
            end
            if (RandomEvent) == 17 then --Teleport Mario to a random location (New!)
                local s = gStateExtras[0]
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " used an Ender Pearl!", 1)
                s.enderpearl = true
            end
            if (RandomEvent) == 18 then --Mario gets koopa shell! (Original)
                local_play(sSuccess, m.pos, 1)
                spawn_sync_object(id_bhvKoopaShell,E_MODEL_KOOPA_SHELL,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200,nil)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got a koopa shell!", 1)
            end
            if (RandomEvent) == 19 then --Mario breakdances! (Updated!)
                fadeout_music(0)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " is showing their moves!", 1)
                stream_play(dance)
                set_mario_action(m, ACT_PUNCHING, 9) --breakdance
                mariospin = 1
            end
            if (RandomEvent) == 20 then --8 seconds of SPEED! (Updated!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " rolled super speed!", 1)
                fadeout_music(3)
                stream_play(gold)
                marioboostrtd = 1
                count_with_function_at_end(240, reset_music_and_turn_off_low_gravity)
            end
            if (RandomEvent) == 21 then --Spawn a lit bob-omb in Marios hands! (Original)
                spawnedenemy = math.random(2,3)
                if (spawnedenemy) == 1 then --Spawn King Bobomb in Marios hand.
                    djui_popup_create_global(tostring(gNetworkPlayers[gMarioStates[0].playerIndex].name) .. " picked up KING BOBOMB!", 1)
                    spawnedenemybhv = id_bhvKingBobomb
                    spawnedenemymodel = E_MODEL_KING_BOBOMB
                end
                if (spawnedenemy) == 2 then --Spawn a friendly Bobomb in Marios hand.
                    djui_popup_create_global(tostring(gNetworkPlayers[gMarioStates[0].playerIndex].name) .. " picked up a friendly bob-omb!", 1)
                    bobombcomm = math.random(1,3)
                    if (bobombcomm) == 1 then
                        network_play(sGoodbobomb1, m.pos, 1, m.playerIndex)
                    end
                    if (bobombcomm) == 2 then
                        network_play(sGoodbobomb2, m.pos, 1, m.playerIndex)
                    end
                    if (bobombcomm) == 3 then
                        network_play(sGoodbobomb3, m.pos, 1, m.playerIndex)
                    end
                    spawnedenemybhv = id_bhvBobomb
                    spawnedenemymodel = E_MODEL_BOBOMB_BUDDY
                end
                if (spawnedenemy) == 3 then --Spawn an evil Bobomb in Marios hand.
                    djui_popup_create_global(tostring(gNetworkPlayers[gMarioStates[0].playerIndex].name) .. " picked up an evil bob-omb!", 1)
                    bobombcomm = math.random(1,3)
                    if (bobombcomm) == 1 then
                        network_play(sBobomb1, m.pos, 1, m.playerIndex)
                    end
                    if (bobombcomm) == 2 then
                        network_play(sBobomb2, m.pos, 1, m.playerIndex)
                    end
                    if (bobombcomm) == 3 then
                        network_play(sBobomb3, m.pos, 1, m.playerIndex)
                    end
                    spawnedenemybhv = id_bhvBobomb
                    spawnedenemymodel = E_MODEL_BLACK_BOBOMB
                end
                local obj = spawn_sync_object(spawnedenemybhv, spawnedenemymodel, m.pos.x + 100, m.pos.y, m.pos.z, function(obj)
                    obj.oFlags = OBJ_FLAG_HOLDABLE
                    obj.oInteractType = obj.oInteractType | INTERACT_GRABBABLE
                end)
                if (obj) ~= nil then
                    m.usedObj = obj
                    mario_grab_used_object(m)
                    set_mario_action(m, ACT_HOLD_IDLE, 0)
                end
            end
            if (RandomEvent) == 22 then --Free random cap! (Original)
                randomcap = math.random(1,4)
                if (randomcap) == 1 then --metal cap
                    local_play(sSuccess, m.pos, 1)
                    spawn_sync_object(id_bhvMetalCap,E_MODEL_MARIOS_METAL_CAP,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200,nil)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got a metal cap!", 1)
                end
                if (randomcap) == 2 then --wing cap
                    local_play(sSuccess, m.pos, 1)
                    spawn_sync_object(id_bhvWingCap,E_MODEL_MARIOS_WING_CAP,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200,nil)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got a wing cap!", 1)
                end
                if (randomcap) == 3 then --vanish cap
                    local_play(sSuccess, m.pos, 1)
                    spawn_sync_object(id_bhvVanishCap,E_MODEL_MARIOS_CAP,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200,nil)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got a vanish cap!", 1)
                end
                if (randomcap) == 4 then --all caps
                    local_play(sSuccess, m.pos, 1)
                    spawn_sync_object(id_bhvVanishCap,E_MODEL_MARIOS_CAP,gMarioStates[0].pos.x,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z - 200,nil)
                    spawn_sync_object(id_bhvWingCap,E_MODEL_MARIOS_WING_CAP,gMarioStates[0].pos.x - 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200,nil)
                    spawn_sync_object(id_bhvMetalCap,E_MODEL_MARIOS_METAL_CAP,gMarioStates[0].pos.x + 200,gMarioStates[0].pos.y + 200,gMarioStates[0].pos.z + 200,nil)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got ALL 3 CAPS!", 1)
                end
            end
            if (RandomEvent) == 23 then --Mario Shart 64 (New!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " is sharting!", 1)
                s.sharting = true
                set_mario_action(m, ACT_SHART, 0)
                network_play(sShart, m.pos, 1, m.playerIndex)
                RandomEvent = 0
            end
            if (RandomEvent) == 24 then --Mario gets a troll face that blocks view for 8 seconds (Updated!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " is getting trolled!", 1)
                local_play(sTroll, m.pos, 1)
                blind = 1
                RandomEvent = 0

                count_with_function_at_end(150, nil)
            end
            if (RandomEvent) == 25 then --Clusterbomb! Spawn explosions everywhere. (Updated!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " dropped a cluster bomb!", 1)
                network_play(sKa, m.pos, 1, m.playerIndex)
                clusterbomb = 1
            end
            if (RandomEvent) == 26 then --Mario falls asleep for 5 seconds. (Updated!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " fell asleep!", 1)
                play_sound(SOUND_MARIO_IMA_TIRED, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                mariosleepcounter = 0
                marioasleep = 1
                RandomEvent = 0

                count_with_function_at_end(150, nil)
            end
            if (RandomEvent) == 27 then --Mega fart shockwave. (Updated!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " unleashed a fart shockwave!", 1)
                network_play(sFart, m.pos, 1, m.playerIndex)
                spawn_mist_particles()
                spawn_sync_object(id_bhvBowserShockWave, E_MODEL_BOWSER_WAVE,gMarioStates[0].pos.x,gMarioStates[0].pos.y + 60,gMarioStates[0].pos.z, function (shockwave)
                    shockwave.oFaceAnglePitch = 0
                    shockwave.oFaceAngleRoll = 0
                    shockwave.oBehParams = 4
                end)
                RandomEvent = 0
            end
            if (RandomEvent) == 28 then --FLING! (New!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " got yeeted!", 1)
                spawn_mist_particles()
                rtd_fling()
                RandomEvent = 0
            end
            if (RandomEvent) == 29 then --Mario gets CANNON'ed! (Updated!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " spawned a cannon!", 1)
                m.pos.y = m.pos.y + 1000
                m.forwardVel = 0
                m.vel.y = 0
                vec = {x=0,y=0,z=0}
                cannon = spawn_non_sync_object(id_bhvCannon, E_MODEL_NONE, m.pos.x, m.pos.y - 200, m.pos.z,
                function (obj)
                    obj.oBehParams = obj.oBehParams | 1
                    obj.oBehParams2ndByte = 2
                    obj.oAction = 3
                end)
            end
            if (RandomEvent) == 30 then --FOV Stretch (New!)
                if gGlobalSyncTable.floodenabled then
                    --reroll because flood breaks the fov
                    if not gGlobalSyncTable.autoroll then
                        reroll()
                    end
                    --rtdtimer = 10
                    RandomEvent = 0
                else
                    local np = gNetworkPlayers[0]
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " had their camera stretched!", 1)
                    s.fovStretch = true
                    set_fov_function(140)
                    network_play(sFov, m.pos, 1.5, m.playerIndex)
                    RandomEvent = 0
                end
            end
            if (RandomEvent) == 31 then --Teleports you to a random nearby player! (New!)
                local targetIndex = get_random_nearby_player()
                if targetIndex == nil then
                    reroll()
                else
                    m.pos.x = gMarioStates[targetIndex].pos.x
                    m.pos.y = gMarioStates[targetIndex].pos.y
                    m.pos.z = gMarioStates[targetIndex].pos.z
                    network_play(sTeleport2, gMarioStates[0].pos, 1, m.playerIndex)
                    djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " teleported to " .. tostring(gNetworkPlayers[targetIndex].name), 1)
                end
                RandomEvent = 0
            end
            if (RandomEvent) == 32 then --Sniper Rifle! (New!)
                local np = gNetworkPlayers[0]
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " HAS A GUN!!", 1)
                spawn_sync_object(id_bhvSniper, E_MODEL_GUN_SNIPER, m.pos.x, m.pos.y, m.pos.z, nil)
                network_play(sGunspawn, m.pos, 0.9, m.playerIndex)
                RandomEvent = 0
            end
            if (RandomEvent) == 33 then --Grenade! (New!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " HAS A GRENADE!", 1)
                spawn_sync_object(id_bhvGrenade, E_MODEL_GRENADE, m.pos.x, m.pos.y, m.pos.z, nil)
                network_play(sGunspawn, m.pos, 0.9, m.playerIndex)
                RandomEvent = 0
            end
            if (RandomEvent) == 34 then --Mario drops rings (New!)
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " lost his rings!", 1)
                local ringcount = math.random(30,60)
                m.pos.y = m.pos.y + 5
                m.vel.y = 35
                m.forwardVel = -10
                set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
                play_character_sound(m, CHAR_SOUND_ATTACKED)
                network_play(sRingDrop, m.pos, 0.8, m.playerIndex)

                m.particleFlags = PARTICLE_19 | PARTICLE_DIRT | PARTICLE_HORIZONTAL_STAR | PARTICLE_TRIANGLE
                for i = 1, ringcount do
                    local radius = 120
                    local angle = i * (2 * math.pi) / ringcount
                    local x = m.pos.x + radius * math.cos(angle)
                    local z = m.pos.z + radius * math.sin(angle)

                    spawn_sync_object(id_bhvRing, E_MODEL_RING, x, m.pos.y, z, function(ring)
                        local angletomario = obj_angle_to_object(m.marioObj, ring)
                        if angletomario > 0 then
                            angletomario = angletomario*1
                        else
                            angletomario = angletomario*1
                        end
                        ring.oAngleToMario = angletomario
                    end)
                end

                RandomEvent = 0
            end
            if (RandomEvent) == 35 then --Mario gets huyge new!
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " became HUGE!!!", 1)
                fadeout_music(0)
                play_secondary_music(0,0,0,0)
                stream_play(mega)
                network_play(sGrow, m.pos, 1, m.playerIndex)

                gPlayerSyncTable[m.playerIndex].megamushroom = true
                gPlayerSyncTable[m.playerIndex].powerup_timer = 300
                gStatePowerupExtras.megaMushroom.scale = 2

                megamushroom = 1

                RandomEvent = 0

                count_with_function_at_end(300, reset_music_and_turn_off_low_gravity)
                rtd_stall(150)
            end
            if (RandomEvent) == 36 then --Template for a new event in case you (yes, YOU!) wanted to add something into the mix. Disabled by default. See the notes below!
                djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " rolled a new event!", 1)
                --Put all your code here!
                --Be sure to also update the RTD Picker on line 260 to include 33 (or however many more you add) events!
                RandomEvent = 0
            end
        elseif gGlobalSyncTable.autoroll then
            --This blank spot prevents Nope sound from playing 30 times per second when auto-roll is enabled.
        else
            local_play(sNope, m.pos, 1)
        end
    end
end

function reroll()
    rtdtimer = 0
    rerolling = true
    RandomEvent = 0
end

function rtd_fling ()
    local m = gMarioStates[0]
    local flingVel = math.random(60, 300)
    m.pos.y = m.pos.y + 20
    set_mario_action(m, ACT_RAGDOLL, 0)
    m.vel.y = m.vel.y + flingVel
    network_play(sSpring, m.pos, 1.5, m.playerIndex)
    play_character_sound(m, CHAR_SOUND_WAAAOOOW)
end

function bhv_custom_cannon_loop(o)
    if m.playerIndex ~= 0 then return end
    local m = gMarioStates[0]
    if m.action == ACT_SHOT_FROM_CANNON and o.parentObj.oBehParams & 0xFF ~= 0 then
        play_sound(SOUND_GENERAL2_BOBOMB_EXPLOSION, m.pos)
        obj_spawn_yellow_coins(o, 3)
        obj_explode_and_spawn_coins(10, 10)
        obj_mark_for_deletion(o.parentObj)
    end
end

function clusterbombs(m)
    local m = gMarioStates[0]
    if (clusterbomb) == 1 then --starts the timer for the jumping and ground pound
        clusterbombtimer2 = clusterbombtimer2 + 1
    end

    if (clusterbombtimer2) == 1 then --One count in, it initiates a triple jump.
    set_mario_action(gMarioStates[0], ACT_TRIPLE_JUMP,0)
    end

    if (clusterbombtimer2) == 10 then --10 frames later, this initiates the ground pound.
        set_mario_action(gMarioStates[0], ACT_GROUND_POUND,0)
    end

    if clusterbombtimer2 > 10 and gMarioStates[0].action == ACT_GROUND_POUND_LAND then --Ground pound triggers the "boom!" sound effect when animation plays. Checks CBtime2 to know the process is initiated.
        clusterbombtimer = 28
        clusterbombtimer = clusterbombtimer + 1
        clusterbombexplosions = 1
    end

    if (clusterbombtimer2) >= 120 then
        clusterbomb = 0
        clusterbombexplosions = 0
        clusterbombtimer = 0
        clusterbombtimer2 = 0
    end

    if (clusterbombtimer) == 30 then --Plays the "boom!" after butt pound, which forces the number to 28. (Can clean up, was just testing things.)
        network_play(sBoom, m.pos, 1, m.playerIndex)
    end

    if (clusterbombexplosions) == 1 then --Initiates the counter for the actual exploisions.
        clusterbombtimer = clusterbombtimer + 1
    end

    if (clusterbombtimer) == 30 then
        --top right, right, bottom right explosions

        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 100, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 100, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 100, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 100, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 100, function (exp) exp.oBehParams = 20 end)

        --Mid top, mid bottom explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 100, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 100, function (exp) exp.oBehParams = 20 end)

        --Top left, middle left, bottom left  explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 100, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 100, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 100, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 100, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 100, function (exp) exp.oBehParams = 20 end)
    end
    if (clusterbombtimer) == 35 then
        --top right, right, bottom right explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 300, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 300, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 300, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 300, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 300, function (exp) exp.oBehParams = 20 end)

        --Mid top, mid bottom explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 300, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 300, function (exp) exp.oBehParams = 20 end)

        --Top left, middle left, bottom left  explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 300, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 300, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 300, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 300, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 300, function (exp) exp.oBehParams = 20 end)
    end
    if (clusterbombtimer) == 40 then
        --top right, right, bottom right explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 500, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 500, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 500, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 500, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 500, function (exp) exp.oBehParams = 20 end)

        --Mid top, mid bottom explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 500, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 500, function (exp) exp.oBehParams = 20 end)

        --Top left, middle left, bottom left  explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 500, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 500, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 500, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 500, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 500, function (exp) exp.oBehParams = 20 end)
    end
    if (clusterbombtimer) == 45 then
        --top right, right, bottom right explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 700, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 700, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 700, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 700, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 700, function (exp) exp.oBehParams = 20 end)

        --Mid top, mid bottom explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 700, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 700, function (exp) exp.oBehParams = 20 end)

        --Top left, middle left, bottom left  explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 700, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 700, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 700, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 700, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 700, function (exp) exp.oBehParams = 20 end)
    end
    if (clusterbombtimer) == 50 then
        --top right, right, bottom right explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 1200, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 1200, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 1200, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 1200, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 1200, function (exp) exp.oBehParams = 20 end)

        --Mid top, mid bottom explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 1200, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 1200, function (exp) exp.oBehParams = 20 end)

        --Top left, middle left, bottom left  explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 1200, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 1200, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 1200, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 1200, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 1200, function (exp) exp.oBehParams = 20 end)
    end
    if (clusterbombtimer) == 55 then
        --top right, right, bottom right explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 1500, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 1500, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 1500, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 1500, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 1500, function (exp) exp.oBehParams = 20 end)

        --Mid top, mid bottom explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 1500, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 1500, function (exp) exp.oBehParams = 20 end)

        --Top left, middle left, bottom left  explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 1500, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 1500, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 1500, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 1500, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 1500, function (exp) exp.oBehParams = 20 end)
    end
    if (clusterbombtimer) == 60 then
        --top right, right, bottom right explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 2000, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 2000, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 2000, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x + 2000, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 2000, function (exp) exp.oBehParams = 20 end)

        --Mid top, mid bottom explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 2000, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 2000, function (exp) exp.oBehParams = 20 end)

        --Top left, middle left, bottom left  explosions
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 2000, gMarioStates[0].pos.y, gMarioStates[0].pos.z  + 2000, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 2000, gMarioStates[0].pos.y, gMarioStates[0].pos.z, function (exp) exp.oBehParams = 20 end)
        spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, gMarioStates[0].pos.x - 2000, gMarioStates[0].pos.y, gMarioStates[0].pos.z  - 2000, function (exp) exp.oBehParams = 20 end)
    end
    if (clusterbombtimer) == 65 then
        clusterbomb = 0
        clusterbombexplosions = 0
        clusterbombtimer = 0
        clusterbombtimer2 = 0
    end
end

function findcap(unloadedcap)
    nearestcap = nearest_mario_state_to_object(unloadedcap)
    if (get_id_from_behavior(unloadedcap.behavior) == id_bhvNormalCap and nearest.playerIndex == 0) then
        save_file_clear_flags(SAVE_FLAG_CAP_ON_GROUND | SAVE_FLAG_CAP_ON_KLEPTO | SAVE_FLAG_CAP_ON_UKIKI | SAVE_FLAG_CAP_ON_MR_BLIZZARD)
        cutscene_put_cap_on(gMarioStates[0])
        set_mario_action(gMarioStates[0], ACT_PUTTING_ON_CAP, 1)
        gMarioStates[0].cap = gMarioStates[0].cap & ~(SAVE_FLAG_CAP_ON_GROUND | SAVE_FLAG_CAP_ON_KLEPTO | SAVE_FLAG_CAP_ON_UKIKI | SAVE_FLAG_CAP_ON_MR_BLIZZARD)
    end
end

function mushroom_surprise(unloadedObj)
    nearest = nearest_mario_state_to_object(unloadedObj)
    if (get_id_from_behavior(unloadedObj.behavior) == id_bhvHidden1upInPole and nearest.playerIndex == 0) then
        --1UP mushroom behaviors:
        --1 = Normal
        --2 = GREEN DEMON (Death)
        --3 = Cheeseburger (health refill)

        if (mushroombehavior) == 1 then --1UP
        end
        if (mushroombehavior) == 2 then --GREEN DEMON
            play_sound(SOUND_MARIO_ATTACKED, gMarioStates[0].marioObj.header.gfx.cameraToObject)
            obj_explode_and_spawn_coins(0,0)
            bhv_explosion_init()
            set_environmental_camera_shake(SHAKE_ENV_EXPLOSION)
            spawn_mist_particles()
            stream_stop_all()
            set_background_music(0, get_current_background_music(), 0)
            gMarioStates[0].health = 0xff
        end
        if (mushroombehavior) == 3 then --Cheeseburger
            --add health to Mario
            gMarioStates[0].numLives = gMarioStates[0].numLives - 1
            gMarioStates[0].health = gMarioStates[0].health + 256
        end
    end
end

function hook_update()
	local m = gMarioStates[0]
    local s = gStateExtras[0]
    local np = gNetworkPlayers[0]

    --Zoomed out camera
    if s.fovStretch then
        if rtdtimer > 0 then
            set_override_fov(140)
        else
            set_override_fov(0)
            s.fovStretch = false
        end
    end

    --Mario Spin Timer
    if (mariospin) == 1 then
        speeen = speeen + 1
        m.faceAngle.y = m.faceAngle.y + 4950
        m.forwardVel = 0
        m.controller.stickX = 0
        m.controller.stickY = 0
        m.controller.rawStickX = 0
        m.controller.rawStickY = 0
        m.intendedYaw = 0
    end

    --EnderPearl Teleporting
	if not s.enderpearl and moontimer <= 0 then
		curpos = {
			x = m.pos.x,
			y = m.pos.y,
			z = m.pos.z
		}
	end
    if moontimer > 500 and vec3f_dist(curpos, m.pos) < 1000 then --Send Mario to the damn moon.
        set_mario_action(m, ACT_JUMP, 0)
        m.pos.y = m.floorHeight
        m.pos.y = m.pos.y + 30000
    end
    if s.enderpearl then --Teleport Mario to a random spot within 40,000 units.
        if vec3f_dist(curpos, m.pos) < 1000 then
                marx = math.random(-19500,19500)
                mary = math.random(0,4400)
                marz = math.random(-19500,19500)
                m.pos.x = marx + m.pos.x
                m.pos.y = mary + m.pos.y
                m.pos.z = marz + m.pos.z
        else
            m.pos.y = m.floorHeight + 200
            network_play(sTeleport, m.pos, 1, m.playerIndex)
            s.enderpearl = false
        end
    end

    --Mario Spinning
    if (mariospin) == 1 then

        if (speeen % 20) == 0 then
            set_mario_action(gMarioStates[0], ACT_CROUCHING, 0)
        end

        if (speeen) % 21 == 0 then
            set_mario_action(gMarioStates[0], ACT_PUNCHING, 9) --breakdance
            nospeen = nospeen + 1
            speeen = 0
        end

        if (nospeen) == 5 then
            nospeen = 0
            speeen = 0
            mariospin = 0
            stream_stop_all()
            set_background_music(0, get_current_background_music(), 0)
        end
    end

end

function on_warp()
    stream_stop_all()
end

function mario_update(m)
    local s = gStateExtras[m.playerIndex]
    local st = gPlayerSyncTable[m.playerIndex]

    --Invisible
    if s.invisible > 0 and s.invisible < 240 then
        obj_set_model_extended(m.marioObj, E_MODEL_NONE)
        s.invisible = s.invisible + 1
    elseif s.invisible > 239 then
        s.invisible = 0
        gPlayerSyncTable[m.playerIndex].invisible = false
    end

    for i = 0, (MAX_PLAYERS - 1) do
		if gPlayerSyncTable[i].invisible then
			local m = gMarioStates[i]
			obj_set_model_extended(m.marioObj, E_MODEL_NONE)
		end
	end


    --Moon jumping
    if (moonjump) == 1 then
        if (m.controller.buttonDown & A_BUTTON) ~= 0 then
            m.vel.y = 25
        end
    end

    --Low gravity
    if (lowgravity) == 1 then
        m.peakHeight = 0
        if (m.action & ACT_FLAG_AIR) ~= 0 and m.action ~= ACT_LONG_JUMP then
            m.vel.y = m.vel.y + 2.5
        end
        if m.action == ACT_LONG_JUMP then
            m.vel.y = m.vel.y + 1.5
        end
    end

    --Mario Broken Leg
    if brokenleg == 1 then
        local m = gMarioStates[0]

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
    --Mario defusing in water
    if (mariofuse) == 1 then
        if m.playerIndex ~= 0 then return end
        mariotouchingwater = m.pos.y <= m.waterLevel

        if gGlobalSyncTable.floodenabled then
            floodwater = obj_get_first_with_behavior_id(bhvFloodWater)
            if floodwater ~= nil then
                mariotouchingfloodwater = m.pos.y <= floodwater.oPosY
            else
                mariotouchingfloodwater = false
            end
        else
            mariotouchingfloodwater = false
        end

        if mariotouchingwater or mariotouchingfloodwater then
            spawn_mist_particles()
            spawn_mist_particles()
            spawn_mist_particles()
            spawn_mist_particles()
            spawn_mist_particles()
            djui_popup_create_global(tostring(gNetworkPlayers[m.playerIndex].name) .. " successfully put out the fuse!", 1)
            fusecounter = 0
            stop_all_samples()
            network_play(sCooloff, m.pos, 1, m.playerIndex)
            stop_secondary_music(0)
            set_background_music(0, get_current_background_music(), 0)
            mushroombehavior = 1 --1up
            if not (obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil) then
                local obj = spawn_sync_object(
                    id_bhvHidden1upInPole,
                    E_MODEL_1UP,
                    gMarioStates[0].pos.x, gMarioStates[0].pos.y + 0, gMarioStates[0].pos.z + 0,
                    function(obj)
                        obj.oBehParams2ndByte = 2
                        obj.oAction = 3
                    end)
            end
            mariofuse = 0

        end
    end

    -- Mega Mushroom
    if megamushroom == 1 and m.playerIndex == 0 then
        gStatePowerupExtras.megaMushroom.curScale = approach_f32_asymptotic(gStatePowerupExtras.megaMushroom.curScale, gStatePowerupExtras.megaMushroom.scale, 0.1)

        gPlayerSyncTable[0].synced_size = gStatePowerupExtras.megaMushroom.curScale

        if m.action == ACT_JUMP then
            m.action = ACT_DOUBLE_JUMP
        end

        m.marioObj.hitboxHeight = 256
        m.marioObj.hitboxRadius = 64

        m.marioObj.hurtboxHeight = 256
        m.marioObj.hurtboxRadius = 64

        m.squishTimer = 0

        if m.action == ACT_WALKING then
            m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.intendedYaw, 1)
        else
            m.faceAngle.y = approach_s16_symmetric(m.faceAngle.y, m.intendedYaw, 1024)
        end

        m.hurtCounter = 0
        m.health = 2176

        if m.action == ACT_WALKING then
            m.forwardVel = clampf(m.forwardVel * 1.35, 0, 55)
        end

        if gPlayerSyncTable[0].powerup_timer ~= 0 then
            gPlayerSyncTable[0].powerup_timer = gPlayerSyncTable[0].powerup_timer - 1
        end

        if gPlayerSyncTable[0].powerup_timer <= 15 then
            gStatePowerupExtras.megaMushroom.scale = 1

            if gPlayerSyncTable[0].powerup_timer == 0 then
                gPlayerSyncTable[0].megamushroom = false
                megamushroom = 0
            end
        end
    end

    if st.megamushroom then
        obj_scale(m.marioObj, st.synced_size)

        if not
        (m.action == ACT_BBH_ENTER_SPIN or
        m.action == ACT_BBH_ENTER_JUMP or
        m.action == ACT_HOLD_IDLE) and
        (m.action & ACT_FLAG_AIR) == 0 and
        (m.action & ACT_FLAG_IDLE) == 0 then
            if m.peakHeight >= 100 and m.vel.y <= -10 then
                play_sound(SOUND_GENERAL_BIG_POUND, m.pos)
                spawn_non_sync_object(id_bhvMistCircParticleSpawner, E_MODEL_NONE, m.pos.x, m.pos.y, m.pos.z, nil)
            end
        end
    end
end

function hud_timers()
    local m = gMarioStates[0]
    local screenHeight = djui_hud_get_screen_height()
    local screenWidth = djui_hud_get_screen_width()

    --Welcome prompt
    if (welcomeprompt) == 1 then
        if m.marioObj.oTimer >= 500 or (m.controller.buttonPressed & U_JPAD) ~= 0 then
            welcomeprompt = 0
        end
    end
    if (welcomeprompt) == 1 then
        local sh = djui_hud_get_screen_height()
        local wh = 512

        djui_hud_set_resolution(RESOLUTION_DJUI)
        djui_hud_set_filter(FILTER_LINEAR)
        djui_hud_render_texture(texwelcome, ((screenWidth-wh))/2, ((screenHeight-wh))/2, 1, 1)

    end

    --HUD Ammo counter
    if m.heldObj ~= nil then
        if obj_has_behavior_id(m.heldObj, id_bhvSniper) then
            local ammoString = "Ammo: " .. tostring(m.heldObj.oAmmo)
            local measured_ammo = djui_hud_measure_text(ammoString)
            local centered_ammo_printX = (screenWidth/2) - ((measured_ammo) / 2)
            local centered_ammo_printY = (screenHeight)
            if m.heldObj.oAmmo > 0 then
                djui_hud_print_text(ammoString, centered_ammo_printX, centered_ammo_printY - (centered_ammo_printY / 4), 1)
            end
        end
    end

    --Mario Sleeping
    if (marioasleep) == 1 then
        mariosleepcounter = mariosleepcounter + 1
        set_mario_action(gMarioStates[0], ACT_SLEEPING, 1)
        djui_hud_set_resolution(RESOLUTION_N64);
        djui_hud_render_texture(texsleep, 31, 33, .1, .1)
    end
    if (mariosleepcounter) == 150 then
        mariosleepcounter = 0
        marioasleep = 0
    end

    --Blindness
    if (blind) == 1 then
        blindcounter = blindcounter + 1
        local sw = djui_hud_get_screen_width()
        local sh = djui_hud_get_screen_height()
        local wh = textroll.width
        local texheight = textroll.height
        local s = sh/wh

        djui_hud_set_resolution(RESOLUTION_DJUI)
        djui_hud_render_texture(textroll, 0, (sh-texheight)/-2, s*2, s*1.5)
        --djui_hud_render_texture(textroll, -20, -50, .9, .7)

        djui_hud_set_resolution(RESOLUTION_N64);
        djui_hud_render_texture(textrollhud, 20, 33, .1, .1)
    end
    if (blindcounter) == 150 then
        blindcounter = 0
        blind = 0
    end

    --Moon Jump Timer
    if (moonjump) == 1 then
        moonjumpcount = moonjumpcount + 1
        djui_hud_set_resolution(RESOLUTION_N64);
        djui_hud_render_texture(texmoonjump, 20, 33, .1, .1)
    end
    if (moonjumpcount) == 240 then
        moonjumpcount = 0
        moonjump = 0
    end

    --Mario Fuse Timer
    if (mariofuse) == 1 then
        fusecounter = fusecounter + 1
        local offsetsmoke = math.random(-75,25)
        spawn_sync_object(id_bhvBobombFuseSmoke, E_MODEL_SMOKE, gMarioStates[0].pos.x + offsetsmoke, gMarioStates[0].pos.y - 100, gMarioStates[0].pos.z, nil)
        cur_obj_play_sound_1(SOUND_AIR_BOBOMB_LIT_FUSE)
    end
    if (mariotouchingwater) then

    else
        if (fusecounter) > 0 and (fusecounter) < 30 then
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texexplosion, 20, 33, .1, .1)

        end
        if (fusecounter) >= 30 and (fusecounter) < 60 then
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texexplosion, 20, 33, .1, .1)
        end
        if (fusecounter) >= 60 and (fusecounter) < 90 then
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texexplosion2, 20, 33, .1, .1)
        end
        if (fusecounter) >= 90 and (fusecounter) < 120 then
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texexplosion2, 20, 33, .1, .1)
        end
        if (fusecounter) >= 120 and (fusecounter) < 150 then
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texexplosion, 20, 33, .1, .1)
        end
        if (fusecounter) >= 150 and (fusecounter) < 180 then
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texexplosion, 20, 33, .1, .1)
        end
        if (fusecounter) >= 180 and (fusecounter) < 210 then
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texexplosion2, 20, 33, .1, .1)
        end
        if (fusecounter) >= 210 and (fusecounter) < 240 then
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texexplosion2, 20, 33, .1, .1)
        end
            if (fusecounter) == 240 then
            network_play(sNesdeath, m.pos, 1, m.playerIndex)
            spawn_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z, nil)
            m.health = 0xff
            stop_secondary_music(0)
            stream_stop_all()
            --set_background_music(0, get_current_background_music(), 0)
            mariofuse = 0
            fusecounter = 0
        end
    end

    --Mario Boost Timer
    if (marioboostrtd) == 1 then
        --if m.action ~= ACT_JUMP or m.action ~= ACT_DOUBLE_JUMP or m.action ~= ACT_TRIPLE_JUMP or m.action ~= ACT_LONG_JUMP or m.action ~= ACT_DIVE or m.action ~= ACT_SIDE_FLIP or m.action ~= ACT_SLIDE_KICK then
        if m.action == ACT_WALKING or m.action == ACT_LONG_JUMP then
            m.forwardVel = 140
        elseif m.forwardVel > 50 then
            m.forwardVel = 35
        end
        djui_hud_set_resolution(RESOLUTION_N64);
        djui_hud_render_texture(texspeed, 20, 33, .1, .1)
    end
    if (marioboostrtd) == 1 then
        speedcounter = speedcounter + 1
    end
    if (speedcounter) == 240 then
        marioboostrtd = 0
        speedcounter = 0
        stream_stop_all()
        set_background_music(0, get_current_background_music(), 0)
    end

    --Lightning effect
    if (lightningstrike) == 1 then
        if (lightningcounter) >= 1 then
            lightningstrike = 0
            lightningcounter = 0
        else
            djui_hud_set_resolution(RESOLUTION_N64);
            djui_hud_render_texture(texlightning, 0, 0, 1.1, 1.1)
            lightningcounter = lightningcounter + 1
        end
    end

    --Mario Angry Throwing Cap
    if (angrymario) == 1 then
        if (angrycounter) == 50 then
            set_mario_action(gMarioStates[0], ACT_PUNCHING, 1)
            angrycounter = angrycounter + 1
        else
            angrycounter = angrycounter + 1
        end

        if (angrycounter) >=55 then
            cutscene_put_cap_on(gMarioStates[0])
            mario_blow_off_cap(gMarioStates[0], 300)
            save_file_clear_flags(SAVE_FLAG_CAP_ON_GROUND | SAVE_FLAG_CAP_ON_KLEPTO | SAVE_FLAG_CAP_ON_UKIKI | SAVE_FLAG_CAP_ON_MR_BLIZZARD)
            angrycounter = 0
            RandomEvent = 0
            angrymario = 0
            --set_mario_action(m, MARIO_CAPS, 0)

        end
    end

end

local function before_set_mario_action(m,action)
    if m.playerIndex ~= 0 then return end

    if marioasleep == 1 and m.pos.y == m.floorHeight then --Stops mario from waking if sleep event enabled. Also prevents from sleeping while in-air.
        if action == ACT_WAKING_UP then return ACT_SLEEPING end
    end

    --[[
    if mariospin == 1 then
        if action == ACT_WALKING then set_mario_action(m, ACT_PUNCHING, 9) end
    end
    ]]

end





--------Hooks--------
---

hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_HUD_RENDER, clusterbombs)
hook_behavior(id_bhvCannonBarrel, OBJ_LIST_DEFAULT, false, nil, bhv_custom_cannon_loop, "bhvCannonBarrel")
hook_event(HOOK_ON_OBJECT_UNLOAD, findcap)
hook_event(HOOK_MARIO_UPDATE, rtd)
hook_event(HOOK_ON_HUD_RENDER, display_countdown)
hook_event(HOOK_ON_HUD_RENDER, mariobrokenleg)
hook_event(HOOK_ON_HUD_RENDER, randomizehealth)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_HUD_RENDER, RTDclock)
hook_event(HOOK_ON_HUD_RENDER, moonclock)
hook_event(HOOK_ON_OBJECT_UNLOAD, mushroom_surprise)

hook_event(HOOK_CHARACTER_SOUND, function(m, sound)
    if sound == CHAR_SOUND_PUNCH_HOO and mariospin ~= 0 then return 0 end
end)
