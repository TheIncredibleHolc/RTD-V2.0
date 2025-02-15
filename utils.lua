-- RTD Utilities n' shit

------------------------------------------------------------------------------------------------------------------------------------------------
-------- Mod Menu

local function autoroll_toggle()
    if network_is_server() and gGlobalSyncTable.autoroll then
        djui_chat_message_create("Auto-rolling disabled.")
        gGlobalSyncTable.autoroll = false
    elseif network_is_server() and gGlobalSyncTable.autoroll == false then
        djui_chat_message_create("Auto-rolling enabled!")
        gGlobalSyncTable.autoroll = true
    elseif not network_is_server() then
        djui_chat_message_create("Option only available for host.")
    end
end
hook_mod_menu_checkbox("Enable Automatic Rolling [HOST]", false, autoroll_toggle)

--[[
local function disable_notifications()
	if RTDnotifications then
		RTDnotifications = false
		djui_chat_message_create("RTD Notifications have been turned off!")
	else
		RTDnotifications = true
		djui_chat_message_create("RTD Notifications have been turned on!")
	end
end
hook_mod_menu_checkbox("Disable RTD Notifications", false, disable_notifications)
]]

local function disable_bullshit()
	bullshit = false
end
hook_mod_menu_checkbox("Disable Bullshit", false, disable_bullshit)
------------------------------------------------------------------------------------------------------------------------------------------------
-------- gStateExtras
gStateExtras = {}
for i = 0, MAX_PLAYERS-1 do
	gStateExtras[i] = {
        enderpearl = false,
		invisible = 0,
		sharting = false,
		fovStretch = false,
	}
end

rerolling = false
dead = false
--RTDnotifications = true

------------------------------------------------------------------------------------------------------------------------------------------------
-------- Audio Engine


--Functions
function stream_stop_all()
	audio_stream_stop(moon)
	audio_stream_stop(metalcap)
	audio_stream_stop(dance)
	audio_stream_stop(gold)
	currentlyPlaying = nil
end

function loop(music) audio_stream_set_looping(music, true) end
currentlyPlaying = nil
local fadeTimer = 0
local fadePeak = 0
local volume = 1
PACKET_SOUND = 1
function stream_play(a)
	if currentlyPlaying then audio_stream_stop(currentlyPlaying) end
	audio_stream_play(a, true, 1)
	currentlyPlaying = a
	fadeTimer = 0
end
function stream_fade(time)
	fadePeak = time
	fadeTimer = time
end
function stream_set_volume(vol)
	volume = vol
end
hook_event(HOOK_UPDATE, function ()
	if fadeTimer > 0 then
		fadeTimer = fadeTimer - 1
		if fadeTimer == 0 then
			stream_stop_all()
		end
	end
	if currentlyPlaying then
		audio_stream_set_volume(currentlyPlaying, (is_game_paused() and 0.2 or (fadeTimer ~= 0 and fadeTimer/fadePeak or 1)) * volume)
	end
end)
function local_play(id, pos, vol)
	audio_sample_play(gSamples[id], pos, (is_game_paused() and 0 or vol))
end
function network_play(id, pos, vol, i)
    local_play(id, pos, vol)
    network_send(true, {type = PACKET_SOUND, id = id, x = pos.x, y = pos.y, z = pos.z, vol = vol, i = network_global_index_from_local(i)})
end
function stop_all_samples()
	for _, audio in pairs(gSamples) do
		audio_sample_stop(audio)
	end
end
hook_event(HOOK_ON_PACKET_RECEIVE, function (data)
	if data.type == PACKET_SOUND and is_player_active(gMarioStates[network_local_index_from_global(data.i)]) ~= 0 then
		local_play(data.id, {x=data.x, y=data.y, z=data.z}, data.vol)
	end
end)

function get_random_nearby_player() --Gets the player index number of a random player in the same level and area as you.
    local nearbyPlayers = {}
    local np = gNetworkPlayers
    for i = 1, MAX_PLAYERS - 1 do
        if i ~= 0 and np[i].connected and np[i].currLevelNum == np[0].currLevelNum and np[i].currAreaIndex == np[0].currAreaIndex then
            table.insert(nearbyPlayers, gMarioStates[i].playerIndex)
        end
    end
	if #nearbyPlayers ~= 0 then return nearbyPlayers[math.random(1, #nearbyPlayers)] end
end

--Samples
gSamples = {
	audio_sample_load("bonebreak.ogg"),
	audio_sample_load("rtdready.ogg"),
	audio_sample_load("special.ogg"),
	audio_sample_load("thunder.ogg"),
	audio_sample_load("cooloff.ogg"),
	audio_sample_load("nesdeath.ogg"),
	audio_sample_load("jackpot.ogg"),
	audio_sample_load("beetle.ogg"),
	audio_sample_load("cheeseburger.ogg"),
	audio_sample_load("homer.ogg"),
	audio_sample_load("moonjump.ogg"),
	audio_sample_load("angrymario.ogg"),
	audio_sample_load("angryluigi.ogg"),
	audio_sample_load("angrytoad.ogg"),
	audio_sample_load("angrywaluigi.ogg"),
	audio_sample_load("angrywario.ogg"),
	audio_sample_load("teleport.ogg"),
	audio_sample_load("success.ogg"),
	audio_sample_load("troll.ogg"),
	audio_sample_load("ka.ogg"),
	audio_sample_load("boom.ogg"),
	audio_sample_load("fart5.ogg"),
	audio_sample_load("nope.ogg"),
	audio_sample_load("nicebobomb1.ogg"),
	audio_sample_load("nicebobomb2.ogg"),
	audio_sample_load("nicebobomb3.ogg"),
	audio_sample_load("bobomb1.ogg"),
	audio_sample_load("bobomb2.ogg"),
	audio_sample_load("bobomb3.ogg"),
	audio_sample_load("nescastletimerfuse.ogg"),
	audio_sample_load("spring.ogg"),
	audio_sample_load("shart.ogg"),
	audio_sample_load("fov.ogg"),
	audio_sample_load("teleport2.ogg"),
	audio_sample_load("gunshot.ogg"),
	audio_sample_load("bulletmiss.ogg"),
	audio_sample_load("bulletsplat.ogg"),
	audio_sample_load("gunspawn.ogg")
}

sBoneBreak = 1
sRTDready = 2
sSpecial = 3
sThunder = 4
sCooloff = 5
sNesdeath = 6
sJackpot = 7
sBeetle = 8
sCheeseburger = 9
sHomer = 10
sMoonjump = 11
sAngrymario = 12
sAngryluigi = 13
sAngrytoad = 14
sAngrywaluigi = 15
sAngrywario = 16
sTeleport = 17
sSuccess = 18
sTroll = 19
sKa = 20
sBoom = 21
sFart = 22
sNope = 23
sGoodbobomb1 = 24
sGoodbobomb2 = 25
sGoodbobomb3 = 26
sBobomb1 = 27
sBobomb2 = 28
sBobomb3 = 29
sNEScastle = 30
sSpring = 31
sShart = 32
sFov = 33
sTeleport2 = 34
sGunshot = 35
sBulletMiss = 36
sBulletSplat = 37
sGunspawn = 38

--Streams
moon = audio_stream_load("moon.ogg")
metalcap = audio_stream_load("metalcap.ogg")
dance = audio_stream_load("mariodance.ogg")
gold = audio_stream_load("betterthangold.ogg")

--Custom Models
E_MODEL_GUN_SNIPER = smlua_model_util_get_id("gun_sniper_geo")
E_MODEL_GUN_SNIPER_ACTIVE = smlua_model_util_get_id("gun_sniperActive_geo")
E_MODEL_GUN_SNIPER_SMOKE = smlua_model_util_get_id("sniper_smoke_geo")
COL_GUN_SNIPER = smlua_collision_util_get("gun_sniper_collision")
E_MODEL_SNIPER_BULLET = smlua_model_util_get_id("sniper_bullet_geo")
COL_SNIPER_BULLET = smlua_collision_util_get("sniper_bullet_collision")

define_custom_obj_fields({
    oAmmo = "u32",
    oTracerScale = "u32"
})

------------------------------------------------------------------------------------------------------------------------------------------------
-------- Helper Functions

function is_lowest_active_player()
	return get_network_player_smallest_global().localIndex == 0
end

function ia(m)
	return m.playerIndex == 0
end
function lerp(a, b, t) return a * (1 - t) + b * t end

function vec3f() return {x=0,y=0,z=0} end

function limit_angle(a) return (a + 0x8000) % 0x10000 - 0x8000 end

function spawn_sync_if_main(behaviorId, modelId, x, y, z, objSetupFunction, i)
	print("index:", i)
	print("attempt by "..get_network_player_smallest_global().name)
	print(get_network_player_smallest_global().localIndex + i)
	if get_network_player_smallest_global().localIndex + i == 0 then print("passed!") return spawn_sync_object(behaviorId, modelId, x, y, z, objSetupFunction) end
end


------------------------------------------------------------------------------------------------------------------------------------------------
-------- Custom Actions

ACT_INVISIBLE = allocate_mario_action(ACT_FLAG_MOVING)
function act_invisible(m)
	local s = gStateExtras[m.playerIndex]
    m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags & ~GRAPH_RENDER_ACTIVE
	m.actionTimer = m.actionTimer + 1
	if m.actionTimer == m.actionArg then
		local savedY = m.pos.y
		m.pos.y = savedY
	end
	if m.actionTimer == 30 then
		set_mario_action(m, ACT_IDLE, 0)
	elseif m.actionTimer >= 150 then
		m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
		set_mario_action(m, ACT_IDLE, 0)
	end
	if m.action == ACT_PUNCHING or m.action == ACT_GROUND_BONK or m.action == ACT_FORWARD_GROUND_KB or m.action == ACT_BACKWARD_GROUND_KB or m.action == ACT_HARD_FORWARD_GROUND_KB or m.action == ACT_HARD_BACKWARD_GROUND_KB or m.action == ACT_SOFT_FORWARD_GROUND_KB or m.action == ACT_SOFT_BACKWARD_GROUND_KB then
		set_mario_action(m, ACT_IDLE, 0)
		djui_chat_message_create("reset")
	end

end
hook_mario_action(ACT_INVISIBLE, act_invisible)



ACT_RAGDOLL = allocate_mario_action(ACT_GROUP_CUTSCENE|ACT_FLAG_STATIONARY|ACT_FLAG_INTANGIBLE)
function act_ragdoll(m)
    local s = gStateExtras[0]
    local stepResult = perform_air_step(m, 0)

    if stepResult == AIR_STEP_LANDED then
        if m.floor.type == SURFACE_BURNING then
            set_mario_action(m, ACT_LAVA_BOOST, 0)
		else
			set_mario_action(m, ACT_FORWARD_GROUND_KB, 0)
		end

    end
    set_character_animation(m, CHAR_ANIM_AIRBORNE_ON_STOMACH)
    m.marioBodyState.eyeState = MARIO_EYES_DEAD
    if m.actionArg == 1 then
        local l = gLakituState
        l.posHSpeed, l.posVSpeed, l.focHSpeed, l.focVSpeed = 0, 0, 0, 0
    end
    vec3s_set(m.angleVel, 2000, 1000, 400)
    vec3s_add(m.faceAngle, m.angleVel)
    vec3s_copy(m.marioObj.header.gfx.angle, m.faceAngle)
end
hook_mario_action(ACT_RAGDOLL, act_ragdoll)

ACT_SHART = allocate_mario_action(ACT_FLAG_INTANGIBLE|ACT_FLAG_INVULNERABLE|ACT_GROUP_CUTSCENE)
function act_shart(m)
	local s = gStateExtras[m.playerIndex]
	obj_update_gfx_pos_and_angle(m.marioObj)
	if m.pos.y ~= m.floorHeight then
		m.pos.y = math.max(m.floorHeight, m.pos.y - 100)
	end
	m.actionTimer = m.actionTimer + 1
	set_mario_animation(m, MARIO_ANIM_SHOCKED)

	if m.actionTimer == 2 then
		if m.character.type ~= CT_MARIO then
			play_character_sound(m, CHAR_SOUND_WAAAOOOW)
		end
	end

	if m.actionTimer == 10 or m.actionTimer == 20 or m.actionTimer == 30 or m.actionTimer == 40 or m.actionTimer == 50 or m.actionTimer == 60 or m.actionTimer == 70 or m.actionTimer == 80 or m.actionTimer == 90 or m.actionTimer == 100 or m.actionTimer == 110
	or m.actionTimer == 120 or m.actionTimer == 130 or m.actionTimer == 140 or m.actionTimer == 150 or m.actionTimer == 160 then
		m.particleFlags = PARTICLE_MIST_CIRCLE
	end

	if m.actionTimer >= 50 and m.actionTimer < 150 then
		m.marioBodyState.eyeState = MARIO_EYES_DEAD
	end

	if m.actionTimer >= 200 then
		play_character_sound(m, CHAR_SOUND_EEUH)
		m.actionTimer = 0
		s.sharting = false
		set_mario_action(m, ACT_IDLE, 0)
	end
end
hook_mario_action(ACT_SHART, act_shart)

