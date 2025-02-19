--RTD custom actors n' shit
------------------------------------------------------------------
E_MODEL_LIGHTNING = smlua_model_util_get_id("lightning_geo")
E_MODEL_LIGHTNING2 = smlua_model_util_get_id("lightning2_geo")
E_MODEL_LIGHTNING3 = smlua_model_util_get_id("lightning3_geo")

function lightning_init(obj)
    local m = gMarioStates[0]

    obj.oFlags = (OBJ_FLAG_ACTIVE_FROM_AFAR | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE)
    vec = {x=obj.oPosX, y=obj.oPosY, z=obj.oPosZ}
    local yaw = calculate_yaw(vec, gLakituState.pos)
    obj.oFaceAngleYaw = yaw -22000
	obj_scale(obj, 1.5)

    if lateral_dist_between_objects(obj, m.marioObj) < 700 then
        play_transition(WARP_TRANSITION_FADE_INTO_COLOR, 1, 255, 255, 255)
        play_transition(WARP_TRANSITION_FADE_FROM_COLOR, 3, 255, 255, 255)
    end

end

function lightning_loop(obj)
    if obj.oTimer == 2 then
        obj_set_model_extended(obj, E_MODEL_LIGHTNING2)
    end
    if obj.oTimer == 3 then
        obj_set_model_extended(obj, E_MODEL_LIGHTNING3)
    end
    if obj.oTimer == 4 then
        obj_set_model_extended(obj, E_MODEL_LIGHTNING)
    end
    if obj.oTimer == 5 then
        obj_set_model_extended(obj, E_MODEL_LIGHTNING2)
    end
    if obj.oTimer == 6 then
        obj_set_model_extended(obj, E_MODEL_LIGHTNING3)
    end
    if obj.oTimer == 7 then
        obj_set_model_extended(obj, E_MODEL_LIGHTNING)
    end
    if obj.oTimer >= 8 then
        obj_mark_for_deletion(obj)
    end
end

id_bhvLightning = hook_behavior(nil, OBJ_LIST_GENACTOR, false, lightning_init, lightning_loop, "bhvLightning")

------------------------------------------------------------------
-----------------------------------------------------------
--Sniper Rifle

function gun_sniper_init(o)
    o.oFlags = OBJ_FLAG_ACTIVE_FROM_AFAR | OBJ_FLAG_COMPUTE_DIST_TO_MARIO | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE | OBJ_FLAG_HOLDABLE | OBJ_COL_FLAG_GROUNDED
    o.oInteractType = INTERACT_GRABBABLE
    o.header.gfx.skipInViewCheck = true
    o.collisionData = COL_GUN_SNIPER
    o.oCollisionDistance = 10000
    o.oFriction = 0.8
    o.oAmmo = 20
    o.oAction = 1
    o.oBulletPosX = o.oPosX
    o.oBulletPosY = o.oPosY
    o.oBulletPosZ = o.oPosZ
    o.oGunAngle = o.oFaceAngleYaw
    o.oDestroyTimer = 0
    network_init_object(o, true, {'oAmmo', 'oBulletPosX', 'oBulletPosY', 'oBulletPosZ', 'oGunAngle','oDestroyTimer'})
end

function gun_sniper_loop(o)
    local m = gMarioStates[0]
    o.oInteractStatus = 0
    cur_obj_update_floor_height_and_get_floor()
    load_object_collision_model()
    cur_obj_move_standard(-78)
    cur_obj_move_using_fvel_and_gravity()

    if o.oAction == 1 then
        cur_obj_enable_rendering_and_become_tangible(o)
        if o.oPosY > o.oFloorHeight + 100 then
            o.oGravity = -1
        elseif o.oAction == 1 then
            o.oDestroyTimer = o.oDestroyTimer + 1
            if o.oDestroyTimer >= 240 then
                cur_obj_wait_then_blink(0, 60)
            end
            if o.oDestroyTimer >= 300 then
                spawn_non_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, o.oPosX, o.oPosY, o.oPosZ, nil)
                obj_mark_for_deletion(o)
            end
            o.oPosY = o.oFloorHeight + 100
            o.oGravity = 0
            o.oFaceAngleYaw = o.oFaceAngleYaw + 768
            o.oMoveAngleYaw = o.oFaceAngleYaw
            local offset = math.random(-60, 60)
            spawn_non_sync_object(id_bhvSparkleParticleSpawner, E_MODEL_SPARKLES, o.oPosX + offset, o.oPosY - 30, o.oPosZ + offset, nil)
        end
    end

    if m.heldObj == o and m.intendedMag ~= 0 and m.forwardVel < 35 and (m.action & ACT_FLAG_AIR) == 0 then
        m.forwardVel = m.forwardVel + 1.2
    end

    if m.heldObj == o then
        o.oDestroyTimer = 0
        o.oAction = 2
        cur_obj_disable_rendering_and_become_intangible(o)
        obj_set_model_extended(o, E_MODEL_GUN_SNIPER_ACTIVE)
        o.oGraphYOffset = 200
        network_send_object(o, true)
    else
        obj_set_model_extended(o, E_MODEL_GUN_SNIPER)
        o.oGraphYOffset = 0
    end

    if o.oAction == 2 then
        cur_obj_disable_rendering_and_become_intangible(o)
        if o.oAmmo == 0 then return end
        local dropped = true
        for i = 0, MAX_PLAYERS-1 do
            if gMarioStates[i].heldObj == o then
                dropped = false
            end
        end
        if dropped then
            o.oAction = 1
            network_send_object(o, true)
        end
    end

    
    if m.heldObj == o then
        --[[
        if m.controller.buttonDown & L_TRIG == 0 then
            marioAngle = m.faceAngle.y
        end

        if m.controller.buttonDown & L_TRIG ~= 0 then
            m.forwardVel = 0
            m.faceAngle.y = marioAngle
            m.intendedYaw = marioAngle
            --djui_chat_message_create("strafing")
        end]]

        if m.controller.buttonPressed & Y_BUTTON ~= 0 then
            local offset = 0
            if m.character.type == CT_MARIO then
                offset = 60
            elseif m.character.type == CT_LUIGI then
                offset = 60
            elseif m.character.type == CT_TOAD then
                offset = 60
            elseif m.character.type == CT_WARIO then
                offset = 60
            elseif m.character.type == CT_WALUIGI then
                offset = 60
            end
            o.oBulletPosX = m.pos.x
            o.oBulletPosY = m.pos.y + offset
            o.oBulletPosZ = m.pos.z
            o.oGunAngle = m.faceAngle.y
            spawn_sync_object(id_bhvMistCircParticleSpawner, E_MODEL_MIST, o.oBulletPosX, o.oBulletPosY, o.oBulletPosZ, nil)
            spawn_sync_object(id_bhvSniperSmoke, E_MODEL_GUN_SNIPER_SMOKE, o.oBulletPosX, o.oBulletPosY, o.oBulletPosZ, function(tracer) tracer.oFaceAngleYaw = o.oGunAngle end)
            spawn_sync_object(id_bhvSniperBullet, E_MODEL_SNIPER_BULLET, o.oBulletPosX, o.oBulletPosY + 20, o.oBulletPosZ, function(bullet) bullet.oFaceAngleYaw = o.oGunAngle end)
            o.oAmmo = o.oAmmo - 1
            network_play(sGunshot, m.pos, 0.6, m.playerIndex)
            o.oAction = 2

        end
    end

    if o.oAmmo == 0 and o.oAction ~= 3 then --No more ammo, therefore the holding Mario will THROW the gun.
        if m.heldObj == o then
            mario_drop_held_object(m)
            set_mario_action(m, ACT_THROWING, 0)
            cur_obj_move_after_thrown_or_dropped(30, 35)
            o.oPosY = o.oPosY + 50
            o.oAction = 3
        else
            o.oAction = 3
        end
    end

    if o.oAction == 3 then --Gun has been thrown and will explode on impact.
        if o.oPosY > o.oFloorHeight then
            o.oFaceAnglePitch = o.oFaceAnglePitch + 2048
            o.oMoveAnglePitch = o.oFaceAnglePitch
            o.oFaceAngleRoll = o.oFaceAngleRoll + 4196
            o.oMoveAngleRoll = o.oFaceAngleRoll
            o.oGravity = -1
        else
            spawn_sync_if_main(id_bhvExplosion, E_MODEL_EXPLOSION, o.oPosX, o.oPosY, o.oPosZ, nil, m.playerIndex)
            spawn_triangle_break_particles(30, 138, 1, 4)
            set_camera_shake_from_hit(SHAKE_POS_SMALL)
            obj_mark_for_deletion(o)
        end
    end
end

function sniper_smoke_init(o)
    o.oFlags = OBJ_FLAG_ACTIVE_FROM_AFAR | OBJ_FLAG_COMPUTE_DIST_TO_MARIO | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE | OBJ_FLAG_MOVE_XZ_USING_FVEL
    o.header.gfx.skipInViewCheck = true
    o.oOpacity = 110
    oTracerScale = 0.1
    cur_obj_disable_rendering()
end

function sniper_smoke_loop(o)
    if o.oTimer == 6 then
        cur_obj_enable_rendering()
    end
    o.oPosY = o.oPosY + 3
    o.oForwardVel = 14
    o.oOpacity = math.max(0, o.oOpacity - 2)
    if o.oTimer > 90 then
        obj_mark_for_deletion(o)
    end
    o.oTracerScale = o.oTracerScale + 0.05
    --obj_set_gfx_scale(o, 1, 1, o.oTracerScale)
    cur_obj_move_using_fvel_and_gravity()
end

function sniper_bullet_init(o)
    o.oFlags = OBJ_FLAG_ACTIVE_FROM_AFAR | OBJ_FLAG_COMPUTE_DIST_TO_MARIO | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE | OBJ_FLAG_MOVE_XZ_USING_FVEL
    o.header.gfx.skipInViewCheck = true
    o.collisionData = COL_SNIPER_BULLET
    o.oCollisionDistance = 10000
    o.hitboxRadius = 220
    o.hitboxHeight = 220
    o.oWallHitboxRadius = 50
    o.oInteractType = INTERACT_DAMAGE
    obj_scale(o, 2)
    obj_set_hurtbox_radius_and_height(o, 150, 150)
end

function sniper_bullet_loop(o)
    local m = gMarioStates[0]
    load_object_collision_model()
    o.oForwardVel = 600
    cur_obj_update_floor_height_and_get_floor()
    cur_obj_update_floor_and_walls()

    if o.oTimer > 90 then
        obj_mark_for_deletion(o)
    end

    if obj_check_hitbox_overlap(o, m.marioObj) and o.oTimer > 1 and m.action ~= ACT_DEATH_ON_STOMACH then
        m.pos.y = m.pos.y + 4
        m.vel.y = 70
        m.vel.x = m.vel.x + sins(o.oMoveAngleYaw) * 50
        m.vel.z = m.vel.z + coss(o.oMoveAngleYaw) * 50
        if m.health < 2040 then
            set_mario_action(m, ACT_HARD_FORWARD_GROUND_KB, 0)
            m.health = 0xFF
        else
            set_mario_action(m, ACT_RAGDOLL, 0)
            m.health = 256
        end
        network_play(sBulletSplat, m.pos, 1, m.playerIndex)
        obj_mark_for_deletion(o)
    elseif o.oMoveFlags & OBJ_MOVE_HIT_WALL ~= 0 then
        --djui_chat_message_create("hit wall!")
        spawn_non_sync_object(id_bhvBulletMiss, E_MODEL_NONE, o.oPosX, o.oPosY, o.oPosZ, nil)
        obj_mark_for_deletion(o)
    end

end

function bullet_miss(o)
	local m = gMarioStates[0]
    local oPos = {
        x = o.oPosX,
        y = o.oPosY,
        z = o.oPosZ
    }
	cur_obj_update_floor_height_and_get_floor()
	local_play(sBulletMiss, oPos, 1)
	spawn_non_sync_object(id_bhvDirtParticleSpawner, E_MODEL_DIRT_ANIMATION, o.oPosX, o.oPosY, o.oPosZ, nil)
	obj_mark_for_deletion(o)
end

id_bhvSniper = hook_behavior(nil, OBJ_LIST_GENACTOR, false, gun_sniper_init, gun_sniper_loop)
id_bhvSniperSmoke = hook_behavior(nil, OBJ_LIST_GENACTOR, false, sniper_smoke_init, sniper_smoke_loop)
id_bhvSniperBullet = hook_behavior(nil, OBJ_LIST_GENACTOR, false, sniper_bullet_init, sniper_bullet_loop)
id_bhvBulletMiss = hook_behavior(nil, OBJ_LIST_GENACTOR, true, nil, bullet_miss, "bhvBulletMiss")
--------------------------------------------------
-- Faster shockwaves that don't hurt the main (farting) player.
function shockwave(o)
    local m = gMarioStates[0]
    o.hitboxHeight = 20
    if o.oBehParams == 4 then
        o.oTimer = o.oTimer + 2
    end
end
hook_behavior(id_bhvBowserShockWave, OBJ_LIST_GENACTOR, false, nil, shockwave)
--------------------------------------------------
--Sonic Rings

E_MODEL_RING = smlua_model_util_get_id("ring_geo")

function ring_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.header.gfx.skipInViewCheck = true
    o.hitboxHeight = 75
	o.hitboxRadius = 75
    o.oGravity = -2
    o.oGraphYOffset = 60
    o.oFriction = 0.98
    
    local velOffset = math.random(10,35)
    o.oVelY = velOffset

    local speedOffset = math.random(8,12)
    o.oForwardVel = speedOffset

    cur_obj_become_intangible()
    --network_init_object(o, true, {'oAngleToMario'})
end

function ring_loop(o)
    local m = gMarioStates[0]
    o.oGraphYOffset = 0
    o.oFaceAngleYaw = o.oFaceAngleYaw + 1000 --Standard ring spinning effect.
    cur_obj_update_floor_height()
    cur_obj_update_floor_and_walls()
    cur_obj_if_hit_wall_bounce_away()
    cur_obj_move_xz_using_fvel_and_yaw()
    cur_obj_move_y(-5, 1.6, 1.6)

    if o.oAngleToMario ~= nil then
        o.oMoveAngleYaw = o.oAngleToMario
    end

    if o.oPosY < o.oFloorHeight + 10 then
        o.oPosY = o.oFloorHeight
    end

    object_step()

    if o.oTimer < 20 then
        cur_obj_become_intangible()
    else
        cur_obj_become_tangible()
    end
    if o.oTimer > 150 then
        cur_obj_wait_then_blink(1, 30)
    end
    if o.oTimer > 210 then
        obj_mark_for_deletion(o)
    end

    if obj_check_hitbox_overlap(m.marioObj, o) and o.oTimer > 50 then
        obj_mark_for_deletion(o)
        spawn_non_sync_object(id_bhvGoldenCoinSparkles, E_MODEL_SPARKLES, o.oPosX, o.oPosY, o.oPosZ, nil)
        local_play(sRingCollect, m.pos, 1)
    end
end

id_bhvRing = hook_behavior(nil, OBJ_LIST_GENACTOR, true, ring_init, ring_loop)
--------------------------------------------------
--Grenade

function grenade_init(o)
    o.oFlags = OBJ_FLAG_ACTIVE_FROM_AFAR | OBJ_FLAG_COMPUTE_DIST_TO_MARIO | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE | OBJ_FLAG_HOLDABLE | OBJ_COL_FLAG_GROUNDED | OBJ_COL_FLAG_HIT_WALL
    o.oInteractType = INTERACT_GRABBABLE
    o.oWallHitboxRadius = 100
    o.header.gfx.skipInViewCheck = true
    o.collisionData = COL_GUN_SNIPER
    o.oCollisionDistance = 10000
    o.oFriction = 0.8
    o.oAmmo = 1
    o.oAction = 1
    o.oBulletPosX = o.oPosX
    o.oBulletPosY = o.oPosY
    o.oBulletPosZ = o.oPosZ
    o.oGunAngle = o.oFaceAngleYaw
    o.oDestroyTimer = 0
    network_init_object(o, true, {'oAmmo','oThrowDistance', 'oDestroyTimer'})
end

function grenade_loop(o)
    local m = gMarioStates[0]
    o.oInteractStatus = 0
    cur_obj_update_floor_and_walls()
    cur_obj_resolve_wall_collisions()
    cur_obj_update_floor_height_and_get_floor()
    load_object_collision_model()
    cur_obj_move_standard(-78)
    cur_obj_move_using_fvel_and_gravity()
    cur_obj_if_hit_wall_bounce_away()
    obj_scale(o, 2.4)

    if o.oAction == 1 then
        cur_obj_enable_rendering_and_become_tangible(o)
        if o.oPosY > o.oFloorHeight + 100 then
            o.oGravity = -1
        elseif o.oAction == 1 then
            o.oDestroyTimer = o.oDestroyTimer + 1
            if o.oDestroyTimer >= 240 then
                cur_obj_wait_then_blink(0, 60)
            end
            if o.oDestroyTimer >= 300 then
                spawn_non_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, o.oPosX, o.oPosY, o.oPosZ, nil)
                obj_mark_for_deletion(o)
            end
            o.oPosY = o.oFloorHeight + 100
            o.oGravity = 0
            o.oFaceAngleYaw = o.oFaceAngleYaw + 768
            o.oMoveAngleYaw = o.oFaceAngleYaw
            local offset = math.random(-60, 60)
            spawn_non_sync_object(id_bhvSparkleParticleSpawner, E_MODEL_SPARKLES, o.oPosX + offset, o.oPosY - 30, o.oPosZ + offset, nil)
        end
    end

    if m.heldObj == o and m.intendedMag ~= 0 and m.forwardVel < 35 and (m.action & ACT_FLAG_AIR) == 0 then
        m.forwardVel = m.forwardVel + 1.2
    end

    if m.heldObj == o then
        o.oDestroyTimer = 0
        o.oAction = 2
        cur_obj_disable_rendering_and_become_intangible(o)
        --obj_set_model_extended(o, E_MODEL_GUN_SNIPER_ACTIVE)
        o.oGraphYOffset = 200
        network_send_object(o, true)
    else
        --cur_obj_enable_rendering_and_become_tangible(o)
        --obj_set_model_extended(o, E_MODEL_GRENADE)
        o.oGraphYOffset = 0
    end

    if o.oAction == 2 then
       cur_obj_disable_rendering_and_become_intangible(o)
        if o.oAmmo == 0 then return end
        local dropped = true
        for i = 0, MAX_PLAYERS-1 do
            if gMarioStates[i].heldObj == o then
                dropped = false
            end
        end
        if dropped then
            o.oAction = 1
            network_send_object(o, true)
        end
    end

    
    if m.controller.buttonPressed & Y_BUTTON ~= 0 then
        o.oThrowDistance = 2
    elseif m.controller.buttonPressed & B_BUTTON ~= 0 or m.controller.buttonPressed & X_BUTTON ~= 0 then
        o.oThrowDistance = 1
    end
    
    if m.heldObj == o then

        if m.controller.buttonPressed & Y_BUTTON ~= 0 or m.controller.buttonPressed & B_BUTTON ~= 0 or m.controller.buttonPressed & X_BUTTON ~= 0 then
            --mario_drop_held_object(m)
            --o.oPosX = m.pos.x
            --o.oPosY = m.pos.y
            --o.oPosZ = m.pos.z
            cur_obj_enable_rendering_and_become_tangible(o)
            network_play(sGrenadePin, m.pos, 1.2, m.playerIndex)
            o.oAmmo = 0
            o.oAction = 2
            network_send_object(o, true)
        end

    end

    if o.oAmmo == 0 and o.oAction ~= 3 then --No more ammo, therefore the holding Mario will THROW the gun.
        cur_obj_enable_rendering_and_become_tangible(o)
        if m.heldObj == o then
            cur_obj_enable_rendering_and_become_tangible(o)
            mario_drop_held_object(m)
            if m.action & ACT_FLAG_AIR ~= 0 then
                set_mario_action(m, ACT_AIR_THROW, 0)
            else
                set_mario_action(m, ACT_THROWING, 0)
            end
            if o.oThrowDistance == 1 then
                cur_obj_move_after_thrown_or_dropped(18, 35)
            else
                cur_obj_move_after_thrown_or_dropped(60, 40)
            end
            o.oPosY = o.oPosY + 50
            o.oAction = 3
        else
            o.oAction = 3
        end
        network_send_object(o, true) --Literally just addded this before going to work. I will test it when I get home!
    end

    if o.oAction == 3 then --Grenade has been thrown and will explode on impact.
        cur_obj_enable_rendering_and_become_tangible(o)
        if o.oPosY > o.oFloorHeight then
            o.oFaceAnglePitch = o.oFaceAnglePitch + 2048
            o.oMoveAnglePitch = o.oFaceAnglePitch
            o.oFaceAngleRoll = o.oFaceAngleRoll + 4196
            o.oMoveAngleRoll = o.oFaceAngleRoll
            o.oGravity = -1
        else
            local oPos = {
                x = o.oPosX,
                y = o.oPosY,
                z = o.oPosZ
            }
            local_play(sExplosion, oPos, 1)
            cur_obj_shake_screen(SHAKE_POS_LARGE)
            spawn_non_sync_object(id_bhvBowserBombExplosion, E_MODEL_BOWSER_FLAMES, o.oPosX, o.oPosY, o.oPosZ, nil)
            if dist_between_objects(o, m.marioObj) <= 850 then
                play_character_sound(m, CHAR_SOUND_ATTACKED)
                o.oMoveAngleYaw = obj_angle_to_object(o, m.marioObj)
                m.pos.y = m.pos.y + 4
                m.vel.y = 50
                m.vel.x = m.vel.x + sins(o.oMoveAngleYaw) * 50
                m.vel.z = m.vel.z + coss(o.oMoveAngleYaw) * 50
                set_mario_action(m, ACT_RAGDOLL, 0)
                m.health = 0xFF
            end
            obj_mark_for_deletion(o)
        end
    end
end

id_bhvGrenade = hook_behavior(nil, OBJ_LIST_GENACTOR, false, grenade_init, grenade_loop)
