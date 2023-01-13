#This is required to spawn and animate the player models.
#====================================== Core ==========================================================

pmodels_skin_type:
    type: procedure
    description: Determines if the player has a classic skin or slim skin
    debug: false
    definitions: player[(PlayerTag) - The player or npc to collect the skin texture from]
    script:
    - if <[player].is_npc||false>:
      - determine <util.parse_yaml[<npc[<[player]>].skin_blob.before[;].base64_to_binary.utf8_decode>].deep_get[textures.skin.metadata.model]||classic>
    - else if <[player].is_player||false>:
      - if <[player].is_online>:
        - determine <util.parse_yaml[<[player].skin_blob.before[;].base64_to_binary.utf8_decode>].deep_get[textures.skin.metadata.model]||classic>
      - determine null
    - else:
      - determine null

pmodel_part_stand:
    type: entity
    description: The base armor stand for the player model
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
    description: The small armor stand for the player model
    debug: false
    entity_type: armor_stand
    mechanisms:
        marker: false
        gravity: false
        visible: false
        base_plate: false
        is_small: true
        invulnerable: true

pmodels_spawn_model:
    type: task
    description: Spawns the player model at the location specified including if it should be only shown to a player
    debug: false
    definitions: location[(LocationTag) - The location to spawn the player model at] | player[(PlayerTag or NPCTag) - The player or npc to use for the model] | fake_to[(PlayerTag) - The player(s) to fake the player model to]
    script:
    - if !<[player].exists>:
      - debug error "[Denizen Player Models] Must specify a player or npc to spawn the player model."
      - stop
    #Determine skin
    - if <[player].is_npc||false>:
      - define skin_type <[player].proc[pmodels_skin_type]>
    - else if <[player].is_player||false>:
      - define skin_type <[player].flag[pmodels_skin_type]||<[player].proc[pmodels_skin_type]>>
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

pmodels_animate:
    type: task
    description: Animates a player model including if the player model should lerp in to the animation
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model] | animation[(ElementTag) - The animation the player model will play] | lerp_in[(DurationTag) - How long it takes to lerp in to the animation's first position] | reset[(Boolean) - Whether or not the player model will reset to the default position]
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
        - flag <[root_entity]> pmodels_animation_to_interpolate:<[lerp_animation]>
      - else:
        # Gathers the data from the previous animation before starting the lerp in animation
        - flag <[root_entity]> pmodels_get_before_lerp
        - flag <[root_entity]> pmodels_animation_to_interpolate:<[lerp_animation]>
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
    # Spawn external bones if they exist in the animation
    - if <[root_entity].has_flag[external_parts]> && !<[lerp_in].is_truthy>:
      - if <[root_entity].has_flag[fake_to]>:
        - define fake_to <[root_entity].flag[fake_to]>
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
          - if <[fake_to].exists>:
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
    - if <server.flag[pmodels_anim_active].contains[<[root_entity]>]||false>:
      - flag server pmodels_anim_active:<-:<[root_entity]>
    - flag server pmodels_anim_active:->:<[root_entity]>

pmodels_animation_lerp_frames:
    type: procedure
    description:
    - Creates the necessary lerp frames for the temporary animation used to interpolate to the new animation
    - if the player model is in the default state it will provide the before frames as well otherwise just the after frames
    debug: false
    definitions: animators[(MapTag) - The animators of the animation] | lerp_in[(DurationTag) - The length on how long it will take to get to the next animation] | is_animating[(Boolean) - Whether or not the player model is currently animating or in the default state]
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
        contains_before_frames: <[is_animating].if_true[false].if_false[true]>
    - determine <[temp_animation]>

pmodels_end_animation:
    type: task
    description: Ends the animation the player model is currently playing
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model] | reset[(Boolean) - Whether the player model should be reset to the default position]
    script:
    - flag server pmodels_anim_active:<-:<[root_entity].uuid>
    - flag <[root_entity]> pmodels_animation_id:!
    - flag <[root_entity]> pmodels_anim_time:0
    - flag <[root_entity]> pmodels_animation_to_interpolate:!
    - flag <[root_entity]> pmodels_is_animating:false
    - if <[reset]||true>:
      - run pmodels_reset_model_position def.root_entity:<[root_entity]>

pmodels_remove_model:
    type: task
    description: Removes the player model from the world
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model]
    script:
    - remove <[root_entity].flag[pmodel_parts]>
    - flag <[root_entity]> pmodel_external_parts:!
    - remove <[root_entity]>

pmodels_remove_external_parts:
    type: task
    description: Removes all external parts from the player model
    debug: false
    definitions: root_entity
    script:
    - if <[root_entity].has_flag[pmodel_external_parts]>:
      - remove <[root_entity].flag[pmodel_external_parts]>
      - flag <[root_entity]> pmodel_external_parts:!

pmodels_reset_model_position:
    type: task
    description: Resets the player model to the default position
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model]
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

pmodels_change_skin:
    type: task
    description:
    - Changes the skin of the player model to the given player or npc's skin
    - Note that this can take some time to process due to skin lookup
    debug: false
    definitions: player[(PlayerTag or NPCTag) - The player or npc skin the player model will change to] | root_entity[(EntityTag) - The root entity of the player model]
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
      - debug error "[Denizen Player Models] Could not find templates for player models in the server data."
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
    description: Moves the player model to a frame in the animation
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model] | animation[(ElementTag) - The animation the player model will move to] | timespot[(Ticks) - The timespot the player model will move to]
    script:
    - define model_data <server.flag[pmodels_data.model_<[root_entity].flag[pmodel_model_id]>]>
    - define lerp_in <[root_entity].flag[pmodels_lerp]||false>
    - if <[lerp_in].is_truthy>:
      - define lerp_animation <[root_entity].flag[pmodels_animation_to_interpolate]>
      - if !<[lerp_animation.contains_before_frames]||false>:
        - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]||null>
        - define gather_before_frames true
      - else:
        - define animation_data <[lerp_animation]>
    - else:
      - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]||null>
    - if <[animation_data]> == null:
      - stop
    - if <[timespot]> > <[animation_data.length]>:
      - choose <[animation_data.loop]>:
        - case loop:
          - define timespot <[timespot].mod[<[animation_data.length]>]>
        - case once:
          - if !<[lerp_in].is_truthy>:
            - define reset true
          - run pmodels_end_animation def.root_entity:<[root_entity]> def.reset:<[reset]||false>
          - stop
        - case hold:
          - define timespot <[animation_data.length]>
          - flag server pmodels_anim_active:<-:<[root_entity]>
          - if <[lerp_in].is_truthy>:
            - run pmodels_animate def.root_entity:<[root_entity]> def.animation:<[animation]> def.lerp_in:false def.reset:false
    - define yaw_mod <[root_entity].location.yaw.add[180].to_radians>
    - define parentage <map>
    - define anim_parts <[root_entity].flag[pmodel_anim_part]||<list>>
    - foreach <[animation_data.animators]> key:part_id as:animator:
      - define framedata.position 0,0,0
      - define framedata.rotation 0,0,0
      - foreach position|rotation as:channel:
        - define relevant_frames <[animator.frames.<[channel]>]||null>
        - if <[relevant_frames]> == null:
          - foreach next
        - define framedata.<[channel]> <[relevant_frames].proc[pmodels_interpolation_data].context[<[timespot]>|<[animation_data.loop]>]>
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
      - if <[anim_parts.<[part_id]>].exists>:
        - define anim_data.<[part_id]>.position:<[new_pos]>
        - define anim_data.<[part_id]>.rotation:<[new_rot]>
    - foreach <[anim_data]||<map>> key:part_id as:data:
      - define ents <[anim_parts.<[part_id]>]||null>
      - if <[ents]> == null:
        - foreach next
      - foreach <[ents]> as:ent:
        - define radian_rot <[data.rotation].as[location].xyz.split[,]>
        - define pose <[radian_rot].get[1]>,<[radian_rot].get[2]>,<[radian_rot].get[3]>
        - adjust <[ent]> reset_client_location
        - choose <[ent].flag[pmodel_def_type]>:
          - case default:
            - define center <[root_entity].location.with_pitch[0].below[1.379].relative[0.32,0,0]>
            - teleport <[ent]> <[center].add[<[data.position].div[15.98].rotate_around_y[<[yaw_mod].mul[-1]>]>]>
            - adjust <[ent]> armor_pose:[right_arm=<[pose]>]
          - case external:
            - define center <[root_entity].location.with_pitch[0].below[0.7]>
            - teleport <[ent]> <[center].add[<[data.position].div[15.98].rotate_around_y[<[yaw_mod].mul[-1]>]>]>
            - adjust <[ent]> armor_pose:[head=<[pose]>]
        - adjust <[ent]> send_update_packets
    - if <[animators_changed]||false>:
      - define lerp_animation.contains_before_frames true
      - flag <[root_entity]> pmodels_animation_to_interpolate:<[lerp_animation]>
      - flag <[root_entity]> pmodels_get_before_lerp:!

# Returns the interpolated data for a given time spot
pmodels_interpolation_data:
    type: procedure
    description: Returns the interpolated data for a given time spot
    debug: false
    definitions: relevant_frames[(MapTag) - The frames that are relevant to the current channel] | timespot[(Tick) - The timespot of the animation] | loop[(ElementTag) - The loop state of the animation]
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
    description: Rotates a location around the origin by a given rotation
    debug: false
    definitions: loc[(LocationTag) - The location to rotate]|rot[(LocationTag) - The angles in radians to rotate the vector]
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
    description: Catmullrom interpolation for animations
    debug: false
    definitions: p0[Before Extra Frame] | p1[Before Frame] | p2[After Frame] | p3[After Extra Frame] | t[Time Percent]
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

pmodels_events:
    type: world
    description: Event handler for Denizen Player Models
    debug: false
    events:
        on tick server_flagged:pmodels_anim_active:
        - foreach <server.flag[pmodels_anim_active]> as:root:
          - if <[root].is_spawned||false>:
            - run pmodels_move_to_frame def.root_entity:<[root]> def.animation:<[root].flag[pmodels_animation_id]||null> def.timespot:<[root].flag[pmodels_anim_time].div[20]>
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
        after server start:
        - if <script[pmodel_config].data_key[config].get[load_on_start].if_null[false].equals[true]>:
          - run pmodels_load_bbmodel
#================================================================================

#================================================================================================
