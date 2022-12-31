#This is required to spawn and animate the player models.
#====================================== Core ======================================

# Determine if player has classic skin or slim skin this also works on npcs
#-Param 1: player - "The player or npc to collect the skin texture from"
pmodels_skin_type:
    type: procedure
    debug: false
    definitions: player
    script:
    - if <[player].is_npc||false>:
      - determine <util.parse_yaml[<npc[<[player]>].skin_blob.before[;].base64_to_binary.utf8_decode>].deep_get[textures.skin.metadata.model]||classic>
    - else if <[player].is_player||false>:
      - if <[player].is_online>:
        - determine <util.parse_yaml[<[player].skin_blob.before[;].base64_to_binary.utf8_decode>].deep_get[textures.skin.metadata.model]||classic>
      - else:
        - determine null
    - else:
      - determine null

pmodel_part_stand:
    type: entity
    debug: false
    entity_type: armor_stand
    mechanisms:
        marker: false
        gravity: false
        visible: false
        base_plate: false
        is_small: false
        invulnerable: true

pmodel_part_stand_small:
    type: entity
    debug: false
    entity_type: armor_stand
    mechanisms:
        marker: false
        gravity: false
        visible: false
        base_plate: false
        is_small: true
        invulnerable: true

# Spawns the player model at the location specified including if it should be only shown to a player
#-Param 1: The location to spawn the player model at
#-Param 2: The player or npc to get the skin from
#-Param 3: The player to fake the player model to
pmodels_spawn_model:
    type: task
    debug: false
    definitions: location|player|fake_to
    script:
    - if !<[player].exists>:
      - debug error "[Denizen Player Models] Must specify a player or npc to spawn the player model."
      - stop
    #Determine skin
    - if <[player].is_npc||false>:
      - define skin_type <[player].proc[pmodels_skin_type]>
    - else if <[player].is_player||false>:
      - define skin_type <[player].flag[pmodels_skin_type]||<[player].proc[pmodels_skin_type]>>
      - if <[skin_type]> == null:
        - flag <[player]> pmodels_skin_type:<[skin_type]>
    - else:
      - debug error "[Denizen Player Models] Could not determine a valid player or npc for the skin type."
      - stop
    #Classic or slim model
    - choose <[skin_type]>:
      - case classic:
        - define model_name player_model_template_norm
      - case slim:
        - define model_name player_model_template_slim
      - default:
        - debug error "[Denizen Player Models] <red>Something went wrong in pmodels_spawn_model invalid skin type."
        - stop
    - if !<server.has_flag[pmodels_data.model_<[model_name]>]>:
        - debug error "[Denizen Player Models] <red>Cannot spawn model <[model_name]>, model not loaded"
        - stop
    #1.379 seems to be the best for the player model and the .relative tag centers the location
    - define center <[location].with_pitch[0].below[1.379].relative[0.32,0,0]>
    - define yaw_mod <[location].yaw.add[180].to_radians>
    - if <[fake_to].exists>:
      - fakespawn pmodel_part_stand <[location]> d:infinite save:root
      - define root_entity <entry[root].faked_entity>
      - flag <[root_entity]> fake_to:<[fake_to]>
    - else:
      - spawn pmodel_part_stand <[location]> save:root
      - define root_entity <entry[root].spawned_entity>
    - flag <[root_entity]> pmodel_model_id:<[model_name]>
    - flag <[root_entity]> skin_type:<[skin_type]>
    - define skull_skin <[player].skull_skin>
    - foreach <server.flag[pmodels_data.model_<[model_name]>]> key:id as:part:
        - if !<[part.item].exists>:
            - foreach next
        #If the part is external skip it and store it as data to use later
        - else if <[part.type]> == external:
            - define external_parts.<[id]> <[part]>
            - foreach next
        #15.98 has been the best number for the player model based on multiple tests
        - define offset <location[<[part.origin]>].div[15.98]>
        - define rots <[part.rotation].split[,].parse[to_radians]||<list[0|0|0]>>
        - define pose <[rots].get[1].mul[-1]>,<[rots].get[2].mul[-1]>,<[rots].get[3]>
        - adjust <item[<[part.item]>]> skull_skin:<[skull_skin]> save:item
        - define part_item <entry[item].result>
        #When going too far from the player model textures can get messed up setting the tracking range to 256 fixes the issue
        - define loc <[center].add[<[offset].rotate_around_y[<[yaw_mod].mul[-1]>]>]>
        - define spawn_stand pmodel_part_stand[armor_pose=[right_arm=<[pose]>];tracking_range=256]
        - if <[fake_to].exists>:
          - fakespawn <[spawn_stand]> <[loc]> players:<[fake_to]> d:infinite save:spawned
          - define spawned <entry[spawned].faked_entity>
          - adjust <[fake_to]> fake_equipment:<[spawned]>|hand|<[part_item]>
        - else:
          - spawn <[spawn_stand]> <[loc]> persistent save:spawned
          - define spawned <entry[spawned].spawned_entity>
          - equip <[spawned]> right_arm:<[part_item]>
        - flag <[spawned]> pmodel_def_pose:<[pose]>
        - flag <[spawned]> pmodel_def_name:<[part.name]>
        - flag <[spawned]> pmodel_def_uuid:<[id]>
        - flag <[spawned]> pmodel_def_pos:<location[0,0,0]>
        - flag <[spawned]> pmodel_def_item:<item[<[part.item]>]>
        - flag <[spawned]> pmodel_def_offset:<[offset]>
        - flag <[spawned]> pmodel_root:<[root_entity]>
        - flag <[spawned]> pmodel_def_type:default
        - flag <[root_entity]> pmodel_parts:->:<[spawned]>
        - flag <[root_entity]> pmodel_anim_part.<[id]>:->:<[spawned]>
    - if <[external_parts].exists>:
      - flag <[root_entity]> external_parts:<[external_parts]>
    - determine <[root_entity]>

# Animates the player model
#-Param 1: root_entity - "The root entity of the model"
#-Param 2: animation - "The name of the animation to play"
#-Param 3: lerp_in - "Time to interpolate to the animation specified starting from the previous model's position"
#-Param 4: reset - "If the player model should reset it's position"
pmodels_animate:
    type: task
    debug: false
    definitions: root_entity|animation|lerp_in|reset
    script:
    - if !<[root_entity].is_spawned||false>:
      - debug error "[Denizen Player Models] <red>Cannot animate model <[root_entity]>, model not spawned"
      - stop
    - if <[reset]||true>:
      - run pmodels_reset_model_position def.root_entity:<[root_entity]>
    - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]||null>
    - if <[animation_data]> == null:
        - debug error "[Denizen Player Models] <red>Cannot animate entity <[root_entity].uuid> due to model <[root_entity].flag[pmodel_model_id]> not having an animation named <[animation]>."
        - stop
    - if <[root_entity].flag[pmodels_is_animating]||false>:
      - define is_animating true
    - else:
      - define is_animating false
    # Lerp in
    - define lerp_in <[lerp_in]||false>
    - if <duration[<[lerp_in]>]||null> != null:
      - define lerp_animation <[animation_data.animators].proc[pmodels_animation_lerp_frames].context[<[lerp_in]>|<[is_animating]>]>
      - flag <[root_entity]> pmodels_lerp:<[lerp_in]>
      - if !<[is_animating]>:
        - define lerp_animation.contains_before_frames true
        - flag <[root_entity]> pmodels_animation_to_interpolate:<[lerp_animation]>
      - else:
        # Gathers the data from the previous animation before starting the lerp in animation
        - flag <[root_entity]> pmodels_animation_to_interpolate:<[lerp_animation]>
        - flag <[root_entity]> pmodels_get_before_lerp
        - waituntil !<[root_entity].has_flag[pmodels_get_before_lerp]> max:1s
        - if <[root_entity].has_flag[pmodels_get_before_lerp]>:
          - stop
    - else:
      - flag <[root_entity]> pmodels_lerp:false
      - flag <[root_entity]> pmodels_animation_to_interpolate:!
    - if !<[is_animating]>:
      - flag <[root_entity]> pmodels_is_animating:true
    - flag <[root_entity]> pmodels_animation_id:<[animation]>
    - flag <[root_entity]> pmodels_anim_time:0
    - flag server pmodels_anim_active.<[root_entity].uuid>
    # Spawn external bones if they exist in the animation
    - if <[root_entity].has_flag[external_parts]> && !<[lerp_in].is_truthy>:
      - if <[root_entity].has_flag[fake_to]>:
        - define fake_to <[root_entity].flag[fake_to]>
      - else:
        - define fake_to null
      - define center <[root_entity].location.with_pitch[0].below[0.7]>
      - define yaw_mod <[root_entity].location.yaw.add[180].to_radians>
      - foreach <[root_entity].flag[external_parts]> key:id as:part:
        # Look for external bones in the animation
        - if <[animation_data.animators.<[id]>].exists>:
          - if !<[part.item].exists>:
              - foreach next
          - define offset <location[<[part.origin]>].div[15.98]>
          - define rots <[part.rotation].split[,].parse[to_radians]||<list[0,0,0]>>
          - define pose <[rots].get[1].mul[-1]>,<[rots].get[2].mul[-1]>,<[rots].get[3]>
          - define loc <[center].add[<[offset].rotate_around_y[<[yaw_mod].mul[-1]>]>]>
          - define spawn_stand pmodel_part_stand_small[equipment=[helmet=<[part.item]>];armor_pose=[head=<[pose]>];tracking_range=256]
          - if <[fake_to]> != null:
            - fakespawn <[spawn_stand]> <[loc]> players:<[fake_to]> d:infinite save:spawned
            - define spawned <entry[spawned].faked_entity>
          - else:
            - spawn <[spawn_stand]> <[loc]> save:spawned
            - define spawned <entry[spawned].spawned_entity>
          - flag <[spawned]> pmodel_def_pose:<[pose]>
          - flag <[spawned]> pmodel_def_name:<[part.name]>
          - flag <[spawned]> pmodel_def_uuid:<[id]>
          - flag <[spawned]> pmodel_def_pos:<location[0,0,0]>
          - flag <[spawned]> pmodel_def_item:<item[<[part.item]>]>
          - flag <[spawned]> pmodel_def_offset:<[offset]>
          - flag <[spawned]> pmodel_root:<[root_entity]>
          - flag <[spawned]> pmodel_def_type:external
          - flag <[root_entity]> pmodel_parts:->:<[spawned]>
          - flag <[root_entity]> pmodel_external_parts:->:<[spawned]>
          - flag <[root_entity]> pmodel_anim_part.<[id]>:->:<[spawned]>
    - flag server pmodels_anim_active:->:<[root_entity]>

# Creates the necessary lerp frames for the temporary animation used to interpolate to the new animation
# if the player model is in the default state it will provide the before frames as well otherwise just the after frames
#-Param 1: The animators of the animation to interpolate to
#-Param 2: The interpolation time it takes to get to the next animation
#-Param 3: Whether or not the player model is currently animating or in the default state
pmodels_animation_lerp_frames:
    type: procedure
    debug: false
    definitions: animators|lerp_in|is_animating
    script:
    - define lerp_in <duration[<[lerp_in]>].in_seconds>
    - foreach <[animators]> key:part_id as:animator:
      - foreach position|rotation as:channel:
        - define relevant_frames <[animator.frames.<[channel]>]||null>
        - define first_frame <[relevant_frames].first||null>
        - if <[first_frame]> == null || <[relevant_frames]> == null:
          - definemap first_frame channel:<[channel]> interpolation:linear time:<[lerp_in]> data:0,0,0
        - else:
          - define new_time <[lerp_in].add[<[first_frame.time]>]>
          - if <[new_time]> > <[lerp_in]>:
            - define new_time <[lerp_in]>
          - define first_frame.time <[new_time]>
        - define temp_animators.<[part_id]>.frames.<[channel]>:->:<[first_frame]>
        # If the player model is in the default position or not animating
        - if !<[is_animating]>:
          - definemap new_first_frame channel:<[channel]> interpolation:linear time:0 data:0,0,0
          - define temp_animators.<[part_id]>.frames.<[channel]>:->:<[new_first_frame]>
          - define temp_animators.<[part_id]>.frames.<[channel]> <[temp_animators.<[part_id]>.frames.<[channel]>].sort_by_value[get[time]]>
    - definemap temp_animation:
        animators: <[temp_animators]||<map>>
        length: <[lerp_in]>
        loop: hold
    - determine <[temp_animation]>

# Ends the animation
pmodels_end_animation:
    type: task
    debug: false
    definitions: root_entity
    script:
    - flag <[root_entity]> pmodels_animation_id:!
    - flag <[root_entity]> pmodels_anim_time:0
    - flag <[root_entity]> pmodels_lerp:!
    - flag <[root_entity]> pmodels_animation_to_interpolate:!
    - flag <[root_entity]> pmodels_is_animating:false
    - flag server pmodels_anim_active.<[root_entity].uuid>:!
    - run pmodels_reset_model_position def.root_entity:<[root_entity]>

pmodels_remove_model:
    type: task
    debug: false
    definitions: root_entity
    script:
    - remove <[root_entity].flag[pmodel_parts]>
    - flag <[root_entity]> pmodel_external_parts:!
    - remove <[root_entity]>

pmodels_remove_external_parts:
    type: task
    debug: false
    definitions: root_entity
    script:
    - if <[root_entity].has_flag[pmodel_external_parts]>:
      - remove <[root_entity].flag[pmodel_external_parts]>
      - flag <[root_entity]> pmodel_external_parts:!

pmodels_reset_model_position:
    type: task
    debug: false
    definitions: root_entity
    script:
    - define center <[root_entity].location.with_pitch[0].below[1.379].relative[0.32,0,0]>
    - define yaw_mod <[root_entity].location.yaw.add[180].to_radians>
    - foreach <[root_entity].flag[pmodel_parts]> as:part:
        - choose <[part].flag[pmodel_def_type]>:
          - case default:
            - adjust <[part]> armor_pose:[right_arm=<[part].flag[pmodel_def_pose]>]
          - case external:
            - define center <[root_entity].location.with_pitch[0].below[0.7]>
            - adjust <[part]> armor_pose:[head=<[part].flag[pmodel_def_pose]>]
        - teleport <[part]> <[center].add[<[part].flag[pmodel_def_offset].rotate_around_y[<[yaw_mod].mul[-1]>]>]>

# Note that this can take some time to process due to skin lookup
#-Param 1: The player to change the skin of can be an npc as well
#-Param 2: The root entity of the player model
pmodels_change_skin:
    type: task
    debug: false
    definitions: player|root_entity
    script:
    - if <[player].is_npc||false>:
      - define skull_skin <[player].skull_skin>
      - define skin_type <[player].proc[pmodels_skin_type]>
    - else if <[player].is_player||false>:
      - define skull_skin <[player].skull_skin>
      - define skin_type <[player].flag[pmodels_skin_type]||<[player].proc[pmodels_skin_type]>>
    - else:
      - debug error "[Denizen Player Models] Must specify a valid player or npc to change the player model skin."
      - stop
    - define fake_to <[root_entity].flag[fake_to]||null>
    - define parts <[root_entity].flag[pmodel_parts]||<list>>
    - define tex_load_order <list[player_root|head|hip|waist|chest|right_arm|right_forearm|left_arm|left_forearm|right_leg|right_foreleg|left_leg|left_foreleg]>
    - define norm_models <server.flag[pmodels_data.template_data.norm.models]||null>
    - define slim_models <server.flag[pmodels_data.template_data.slim.models]||null>
    - if <[norm_models]> == null || <[slim_models]> == null:
      - debug error "[Denizen Player Models] Could not find templates for player models in the config"
      - stop
    - foreach <[tex_load_order]> as:bone:
      - foreach <[parts]> as:part:
        - if <[part].flag[pmodel_def_name]> == <[bone]>:
          - define hand_item <[part].item_in_hand>
          # If the root model skin type does not equal the new model skin type change it
          - if <[root_entity].flag[skin_type]> != <[skin_type]>:
            - choose <[skin_type]>:
              - case classic:
                - foreach <[norm_models]> as:model:
                  - if <[model.name]> == <[bone]>:
                    - define hand_item <item[<[model.item]>]>
                    - define offset <location[<[model.origin]>].div[15.98]>
                    - flag <[part]> pmodel_def_offset:<[offset]>
              - case slim:
                - foreach <[slim_models]> as:model:
                  - if <[model.name]> == <[bone]>:
                    - define hand_item <item[<[model.item]>]>
                    - define offset <location[<[model.origin]>].div[15.98]>
                    - flag <[part]> pmodel_def_offset:<[offset]>
          - adjust <[hand_item]> skull_skin:<[skull_skin]> save:item
          - define item <entry[item].result>
          - if <[fake_to]> != null:
            - adjust <[fake_to]> fake_equipment:<[part]>|hand|<[item]>
          - else:
            - equip <[part]> hand:<[item]>
    - if <[root_entity].flag[skin_type]> != <[skin_type]>:
      - flag <[root_entity]> skin_type:<[skin_type]>
      - run pmodels_reset_model_position def.root_entity:<[root_entity]>

pmodels_move_to_frame:
    type: task
    debug: false
    definitions: root_entity|animation|timespot
    script:
    - define model_data <server.flag[pmodels_data.model_<[root_entity].flag[pmodel_model_id]>]>
    - define lerp_in <[root_entity].flag[pmodels_lerp]||false>
    - if <[lerp_in].is_truthy>:
      - define lerp_animation <[root_entity].flag[pmodels_animation_to_interpolate]>
      - if !<[lerp_animation.contains_before_frames]||false>:
        - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]>
        - define gather_before_frames true
      - else:
        - define animation_data <[lerp_animation]>
    - else:
      - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]>
    - if <[timespot]> > <[animation_data.length]>:
      - choose <[animation_data.loop]>:
        - case loop:
          - define timespot <[timespot].mod[<[animation_data.length]>]>
        - case once:
          - flag server pmodels_anim_active.<[root_entity].uuid>:!
          - if !<[lerp_in].is_truthy>:
            - run pmodels_reset_model_position def.root_entity:<[root_entity]>
          - stop
        - case hold:
          - define timespot <[animation_data.length]>
          - flag server pmodels_anim_active.<[root_entity].uuid>:!
          - if <[lerp_in].is_truthy>:
            - run pmodels_animate def.root_entity:<[root_entity]> def.animation:<[animation]> def.lerp_in:false def.reset:false
    - define yaw_mod <[root_entity].location.yaw.add[180].to_radians>
    - define parentage <map>
    - foreach <[animation_data.animators]> key:part_id as:animator:
      - define framedata.position 0,0,0
      - define framedata.rotation 0,0,0
      - foreach position|rotation as:channel:
        - define relevant_frames <[animator.frames.<[channel]>]||null>
        - if <[relevant_frames]> == null:
          - foreach next
        - define data <[relevant_frames].proc[pmodels_interpolation_data].context[<[timespot]>|<[animation_data.loop]>]>
        - define framedata.<[channel]> <[data]>
        - if <[gather_before_frames]||false>:
          - definemap lerp_before channel:<[channel]> interpolation:linear time:0 data:<[framedata.<[channel]>]>
          - define lerp_animation.animators.<[part_id]>.frames.<[channel]>:->:<[lerp_before]>
          - define lerp_animation.animators.<[part_id]>.frames.<[channel]> <[lerp_animation.animators.<[part_id]>.frames.<[channel]>].sort_by_value[get[time]]>
          - define animators_changed true
      - define this_part <[model_data.<[part_id]>]>
      - define this_rots <[this_part.rotation].split[,].parse[to_radians]||<list[0|0|0]>>
      - define pose <[this_rots].get[1].mul[-1]>,<[this_rots].get[2].mul[-1]>,<[this_rots].get[3]>
      - define parent_id <[this_part.parent]||<[part_id]>>
      - define parent_pos <location[<[parentage.<[parent_id]>.position]||0,0,0>]>
      - define parent_rot <location[<[parentage.<[parent_id]>.rotation]||0,0,0>]>
      - define parent_offset <location[<[parentage.<[parent_id]>.offset]||0,0,0>]>
      - define parent_raw_offset <[model_data.<[parent_id]>.origin]||0,0,0>
      - define rel_offset <location[<[this_part.origin]>].sub[<[parent_raw_offset]>]>
      - define rot_offset <[rel_offset].proc[pmodels_rot_proc].context[<[parent_rot]>]>
      - define new_pos <[framedata.position].as[location].proc[pmodels_rot_proc].context[<[parent_rot]>].add[<[rot_offset]>].add[<[parent_pos]>]>
      - define new_rot <[framedata.rotation].as[location].add[<[parent_rot]>].add[<[pose]>]>
      - define parentage.<[part_id]>.position:<[new_pos]>
      - define parentage.<[part_id]>.rotation:<[new_rot]>
      - define parentage.<[part_id]>.offset:<[rot_offset].add[<[parent_offset]>]>
      - foreach <[root_entity].flag[pmodel_anim_part.<[part_id]>]||<list>> as:ent:
        - define radian_rot <[new_rot].as[location].xyz.split[,]>
        - define pose <[radian_rot].get[1]>,<[radian_rot].get[2]>,<[radian_rot].get[3]>
        - adjust <[ent]> reset_client_location
        - choose <[ent].flag[pmodel_def_type]>:
          - case default:
            - define center <[root_entity].location.with_pitch[0].below[1.379].relative[0.32,0,0]>
            - teleport <[ent]> <[center].add[<[new_pos].div[15.98].rotate_around_y[<[yaw_mod].mul[-1]>]>]>
            - adjust <[ent]> armor_pose:[right_arm=<[pose]>]
          - case external:
            - define center <[root_entity].location.with_pitch[0].below[0.7]>
            - teleport <[ent]> <[center].add[<[new_pos].div[15.98].rotate_around_y[<[yaw_mod].mul[-1]>]>]>
            - adjust <[ent]> armor_pose:[head=<[pose]>]
        - adjust <[ent]> send_update_packets
    - if <[animators_changed]||false>:
      - define lerp_animation.contains_before_frames true
      - flag <[root_entity]> pmodels_animation_to_interpolate:<[lerp_animation]>
      - flag <[root_entity]> pmodels_get_before_lerp:!
      - if <server.flag[debug_once]||0> == 0:
        - ~filewrite data:<[lerp_animation].to_json[indent=4].utf8_encode> path:data/pmodels/debug/lerp_animation.json
        - flag server debug_once:++

pmodels_interpolation_data:
    type: procedure
    debug: false
    definitions: relevant_frames|timespot|loop
    script:
    - define before_frame <[relevant_frames].filter[get[time].is_less_than_or_equal_to[<[timespot]>]].last||null>
    - if <[before_frame]> == null:
      - determine 0,0,0
    - define after_frame <[relevant_frames].filter[get[time].is_more_than[<[before_frame.time]>]].first||<[before_frame]>>
    - define b_time <[before_frame.time]>
    - define time_range <[after_frame.time].sub[<[b_time]>]>
    - if <[time_range]> == 0:
      - define time_percent 0
    - else:
      - define time_percent <[timespot].sub[<[b_time]>].div[<[time_range]>]>
    - choose <[before_frame.interpolation]>:
        - case catmullrom:
          - define before_extra <[relevant_frames].filter[get[time].is_less_than[<[before_frame.time]>]].last||null>
          - if <[before_extra]> == null:
              - define before_extra <[loop].equals[loop].if_true[<[relevant_frames].last>].if_false[<[before_frame]>]>
          - define after_extra <[relevant_frames].filter[get[time].is_more_than[<[after_frame.time]>]].first||null>
          - if <[after_extra]> == null:
              - define after_extra <[loop].equals[loop].if_true[<[relevant_frames].first>].if_false[<[after_frame]>]>
          - define data <[before_extra.data].as[location].proc[pmodels_catmullrom_proc].context[<[before_frame.data].as[location]>|<[after_frame.data].as[location]>|<[after_extra.data].as[location]>|<[time_percent]>].xyz>
        - case linear:
          - define data <[after_frame.data].as[location].sub[<[before_frame.data]>].mul[<[time_percent]>].add[<[before_frame.data]>].xyz>
        - case step:
          - define data <[before_frame.data]>
    - determine <[data]||0,0,0>

pmodels_rot_proc:
    type: procedure
    debug: false
    definitions: loc|rot
    script:
    - determine <[loc].rotate_around_x[<[rot].x.mul[-1]>].rotate_around_y[<[rot].y.mul[-1]>].rotate_around_z[<[rot].z>]>

pmodels_catmullrom_get_t:
    type: procedure
    debug: false
    definitions: t|p0|p1
    script:
    # This is more complex for different alpha values, but alpha=1 compresses down to a '.vector_length' call conveniently
    - determine <[p1].sub[<[p0]>].vector_length.add[<[t]>]>

# Procedure script by mcmonkey creator of DModels https://github.com/mcmonkeyprojects/DenizenModels
pmodels_catmullrom_proc:
    type: procedure
    debug: false
    definitions: p0|p1|p2|p3|t
    script:
    # Zero distances are impossible to calculate
    - if <[p2].sub[<[p1]>].vector_length> < 0.01:
        - determine <[p2]>
    # Based on https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline#Code_example_in_Unreal_C++
    # With safety checks added for impossible situations
    - define t0 0
    - define t1 <proc[pmodels_catmullrom_get_t].context[0|<[p0]>|<[p1]>]>
    - define t2 <proc[pmodels_catmullrom_get_t].context[<[t1]>|<[p1]>|<[p2]>]>
    - define t3 <proc[pmodels_catmullrom_get_t].context[<[t2]>|<[p2]>|<[p3]>]>
    # Divide-by-zero safety check
    - if <[t1].abs> < 0.001 || <[t2].sub[<[t1]>].abs> < 0.001 || <[t2].abs> < 0.001 || <[t3].sub[<[t1]>].abs> < 0.001:
        - determine <[p2].sub[<[p1]>].mul[<[t]>].add[<[p1]>]>
    - define t <[t2].sub[<[t1]>].mul[<[t]>].add[<[t1]>]>
    # ( t1-t )/( t1-t0 )*p0 + ( t-t0 )/( t1-t0 )*p1;
    - define a1 <[p0].mul[<[t1].sub[<[t]>].div[<[t1]>]>].add[<[p1].mul[<[t].div[<[t1]>]>]>]>
    # ( t2-t )/( t2-t1 )*p1 + ( t-t1 )/( t2-t1 )*p2;
    - define a2 <[p1].mul[<[t2].sub[<[t]>].div[<[t2].sub[<[t1]>]>]>].add[<[p2].mul[<[t].sub[<[t1]>].div[<[t2].sub[<[t1]>]>]>]>]>
    # FVector A3 = ( t3-t )/( t3-t2 )*p2 + ( t-t2 )/( t3-t2 )*p3;
    - define a3 <[a1].mul[<[t2].sub[<[t]>].div[<[t2]>]>].add[<[a2].mul[<[t].div[<[t2]>]>]>]>
    # FVector B1 = ( t2-t )/( t2-t0 )*A1 + ( t-t0 )/( t2-t0 )*A2;
    - define b1 <[a1].mul[<[t2].sub[<[t]>].div[<[t2]>]>].add[<[a2].mul[<[t].div[<[t2]>]>]>]>
    # FVector B2 = ( t3-t )/( t3-t1 )*A2 + ( t-t1 )/( t3-t1 )*A3;
    - define b2 <[a2].mul[<[t3].sub[<[t]>].div[<[t3].sub[<[t1]>]>]>].add[<[a3].mul[<[t].sub[<[t1]>].div[<[t3].sub[<[t1]>]>]>]>]>
    # FVector C  = ( t2-t )/( t2-t1 )*B1 + ( t-t1 )/( t2-t1 )*B2;
    - determine <[b1].mul[<[t2].sub[<[t]>].div[<[t2].sub[<[t1]>]>]>].add[<[b2].mul[<[t].sub[<[t1]>].div[<[t2].sub[<[t1]>]>]>]>]>

#===== Events ===============================================================
pmodels_load_event:
    type: world
    debug: false
    events:
      after server start:
      - if <script[pmodel_config].data_key[config].get[load_on_start].if_null[false].equals[true]>:
        - ~run pmodels_load_bbmodel

pmodels_animator:
    type: world
    debug: false
    events:
        on tick server_flagged:pmodels_anim_active:
        - foreach <server.flag[pmodels_anim_active]> as:root:
          - if <[root].is_spawned||false>:
            - run pmodels_move_to_frame def.root_entity:<[root]> def.animation:<[root].flag[pmodels_animation_id]> def.timespot:<[root].flag[pmodels_anim_time].div[20]>
            - flag <[root]> pmodels_anim_time:++
        on server start priority:-1000:
        # Cleanup
        - flag server pmodels_data:!
        - flag server pmodels_anim_active:!
        #skin type
        after player joins:
        - wait 1t
        - define skin_type <player.proc[pmodels_skin_type]>
        - flag <player> pmodels_skin_type:<[skin_type]>
#================================================================================

#================================================================================================
