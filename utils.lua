-- RTD Utilities n' shit
------------------------------------------------------------------------------------------------------------------------------------------------
-------- gStateExtras
gStateExtras = {}
for i = 0, MAX_PLAYERS-1 do
	gStateExtras[i] = {
        enderpearl = false
	}
end

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

	if data.type == PACKET_UNLOCK then
		unlock_trophy(data.id)
	end
end)

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
	audio_sample_load("nescastletimerfuse.ogg")
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

--Streams
moon = audio_stream_load("moon.ogg")
metalcap = audio_stream_load("metalcap.ogg")
dance = audio_stream_load("mariodance.ogg")
gold = audio_stream_load("betterthangold.ogg")

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

function vec3f_rotate_zyx(dest, rotate)
    local v = { x = dest.x, y = dest.y, z = dest.z }
    
    local sx = sins(rotate.x)
    local cx = coss(rotate.x)

    local sy = sins(rotate.y)
    local cy = coss(rotate.y)

    local sz = sins(rotate.z)
    local cz = coss(rotate.z)

    -- Rotation around Z axis
    local xz = v.x * cz - v.y * sz
    local yz = v.x * sz + v.y * cz
    local zz = v.z

    -- Rotation around Y axis
    local xy = xz * cy + zz * sy
    local yy = yz
    local zy = -xz * sy + zz * cy

    -- Rotation around X axis
    dest.x = xy
    dest.y = yy * cx - zy * sx
    dest.z = yy * sx + zy * cx

    return dest
end

function limit_angle(a) return (a + 0x8000) % 0x10000 - 0x8000 end

function spawn_sync_if_main(behaviorId, modelId, x, y, z, objSetupFunction, i)
	print("index:", i)
	print("attempt by "..get_network_player_smallest_global().name)
	print(get_network_player_smallest_global().localIndex + i)
	if get_network_player_smallest_global().localIndex + i == 0 then print("passed!") return spawn_sync_object(behaviorId, modelId, x, y, z, objSetupFunction) end
end