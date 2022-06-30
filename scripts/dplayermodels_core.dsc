#Core Tasks of Denizen Player Models
#This is required to spawn and animate the player models.
##Core tasks #########################
#Determine if player has classic skin or slim skin this also works on npcs
pmodels_skin_type:
    type: procedure
    debug: false
    definitions: player
    script:
    - define npc <npc[<[player]>].if_null[n]>
    - define player <player[<[player]>].if_null[n]>
    - if !<[player].equals[n]>:
      - if <[player].is_online>:
        - determine <util.parse_yaml[<player[<[player]>].skin_blob.before[;].base64_to_binary.utf8_decode>].deep_get[textures.skin.metadata.model]||classic>
      - else:
        - determine null
    - else if !<[npc].equals[n]>:
      - determine <util.parse_yaml[<npc[<[npc]>].skin_blob.before[;].base64_to_binary.utf8_decode>].deep_get[textures.skin.metadata.model]||classic>
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
        is_small: false
        invulnerable: true

pmodel_part_stand_small:
    type: entity
    debug: false
    entity_type: armor_stand
    mechanisms:
        marker: true
        gravity: false
        visible: false
        is_small: true
        invulnerable: true

pmodels_spawn_model:
    type: task
    debug: false
    definitions: location|player|show_to
    script:
    - define npc <npc[<[player]>].if_null[n]>
    - define player <player[<[player]>].if_null[n]>
    - if <[player].equals[n]> && <[npc].equals[n]>:
      - debug error "[Denizen Player Models] Must specify a player."
      - stop
    #determine skin type
    - if !<[npc].equals[n]> && <[player].equals[n]>:
      - define player <[npc]>
    - if <[player].is_npc>:
      - define skin_type <proc[pmodels_skin_type].context[<[player]>]>
    - else:
      - define skin_type <[player].flag[pmodels_skin_type]>
    - choose <[skin_type]>:
      - case classic:
        - define model_name player_model_template_norm
      - case slim:
        - define model_name player_model_template_slim
      - default:
        - debug error "[Denizen Player Models] Something went wrong in pmodels_spawn_model invalid skin type."
        - stop
    - if !<server.has_flag[pmodels_data.model_<[model_name]>]>:
        - debug error "[Denizen Player Models] <red>Cannot spawn model <[model_name]>, model not loaded"
        - stop
    #1.379 seems to be the best for the player model and the .relative tag centers the location
    - define center <[location].with_pitch[0].below[1.379].relative[0.32,0,0]>
    - define yaw_mod <[location].yaw.add[180].to_radians>
    - spawn pmodel_part_stand <[location]> save:root
    - define root_entity <entry[root].spawned_entity>
    - flag <entry[root].spawned_entity> pmodel_model_id:<[model_name]>
    #if show_to is being utilized determine if it is a player
    - define show_to <player[<[show_to]>].if_null[n]>
    - foreach <server.flag[pmodels_data.model_<[model_name]>]> key:id as:part:
        - if !<[part.item].exists>:
            - foreach next
        #if the part is external skip it and store it as data to use later
        - else if <[part.type]> == external:
            - define external_parts.<[id]> <[part]>
            - foreach next
        #15.98 has been the best number for the player model based on multiple tests
        - define offset <location[<[part.origin]>].div[15.98]>
        - define rots <[part.rotation].split[,].parse[to_radians]>
        - define pose <[rots].get[1].mul[-1]>,<[rots].get[2].mul[-1]>,<[rots].get[3]>
        #when going too far from the player model textures can get messed up setting the tracking range to 256 fixes the issue
        - spawn pmodel_part_stand[armor_pose=[right_arm=<[pose]>];tracking_range=256] <[center].add[<[offset].rotate_around_y[<[yaw_mod].mul[-1]>]>]> save:spawned
        - adjust <item[<[part.item]>]> skull_skin:<[player].skull_skin> save:item
        - define part.item <entry[item].result>
        #fakeequip if show_to is being used
        - if !<[show_to].equals[n]>:
          - fakeequip <entry[spawned].spawned_entity> for:<[show_to]> hand:<[part.item]>
        - else:
          - equip <entry[spawned].spawned_entity> right_arm:<[part.item]>
        - flag <entry[spawned].spawned_entity> pmodel_def_pose:<[pose]>
        - define name <[part.name]>
        - flag <entry[spawned].spawned_entity> pmodel_def_name:<[name]>
        - flag <entry[spawned].spawned_entity> pmodel_def_item:<item[<[part.item]>]>
        - flag <entry[spawned].spawned_entity> pmodel_def_offset:<[offset]>
        - flag <entry[spawned].spawned_entity> pmodel_root:<entry[root].spawned_entity>
        - flag <entry[spawned].spawned_entity> pmodel_def_type:default
        - flag <entry[root].spawned_entity> pmodel_parts:->:<entry[spawned].spawned_entity>
        - flag <entry[root].spawned_entity> pmodel_anim_part.<[id]>:->:<entry[spawned].spawned_entity>
    - flag <[root_entity]> skin_type:<[skin_type]>
    - define external_parts <[external_parts]||null>
    - if <[external_parts]> != null:
      - flag <[root_entity]> external_parts:<[external_parts]>
    - determine <[root_entity]>

pmodels_animate:
    type: task
    debug: false
    definitions: root_entity|animation|show_to
    script:
    - run pmodels_reset_model_position def.root_entity:<[root_entity]>
    - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]||null>
    - ~filewrite path:data/pmodels/debug_data/animation_data.json data:<[animation_data].to_json[native_types=true;indent=4].utf8_encode>
    - if <[animation_data]> == null:
        - debug error "[Denizen Player Models] <red>Cannot animate entity <[root_entity].uuid> due to model <[root_entity].flag[pmodel_model_id]> not having an animation named <[animation]>."
        - stop
    #spawn external bones if they exist in the animation
    - if <[root_entity].has_flag[external_parts]>:
      - define center <[root_entity].location.with_pitch[0].below[0.7]>
      - define yaw_mod <[root_entity].location.yaw.add[180].to_radians>
      - foreach <[root_entity].flag[external_parts]> key:id as:part:
        #Look for external bones in the animation
        - define anim_part_look <[animation_data.animators.<[id]>]||null>
        #if the animation uses the external bone
        - if <[anim_part_look]> != null:
          - if !<[part.item].exists>:
              - foreach next
          #15.98 div offset
          - define offset <location[<[part.origin]>].div[15.98]>
          - define rots <[part.rotation].split[,].parse[to_radians]>
          - define pose <[rots].get[1].mul[-1]>,<[rots].get[2].mul[-1]>,<[rots].get[3]>
          - spawn pmodel_part_stand_small[armor_pose=[head=<[pose]>];tracking_range=256] <[center].add[<[offset].rotate_around_y[<[yaw_mod].mul[-1]>]>]> save:spawned
          #fakeequip if show_to is being used
          - define show_to <player[<[show_to]>].if_null[n]>
          - if !<[show_to].equals[n]>:
            - fakeequip <entry[spawned].spawned_entity> for:<[show_to]> head:<item[<[part.item]>]>
          - else:
            - equip <entry[spawned].spawned_entity> head:<item[<[part.item]>]>
          - flag <entry[spawned].spawned_entity> pmodel_def_pose:<[pose]>
          - define name <[part.name]>
          - flag <entry[spawned].spawned_entity> pmodel_def_name:<[name]>
          - flag <entry[spawned].spawned_entity> pmodel_def_item:<item[<[part.item]>]>
          - flag <entry[spawned].spawned_entity> pmodel_def_offset:<[offset]>
          - flag <entry[spawned].spawned_entity> pmodel_root:<[root_entity]>
          - flag <entry[spawned].spawned_entity> pmodel_def_type:external
          - flag <[root_entity]> pmodel_parts:->:<entry[spawned].spawned_entity>
          - flag <[root_entity]> pmodel_external_parts:->:<entry[spawned].spawned_entity>
          - flag <[root_entity]> pmodel_anim_part.<[id]>:->:<entry[spawned].spawned_entity>
    - flag <[root_entity]> pmodels_animation_id:<[animation]>
    - flag <[root_entity]> pmodels_anim_time:0
    - flag server pmodels_anim_active.<[root_entity].uuid>

pmodels_remove_model:
    type: task
    debug: false
    definitions: root_entity
    script:
    - remove <[root_entity].flag[pmodel_parts]>
    - remove <[root_entity]>
    - flag <[root_entity]> pmodel_external_parts:!

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

pmodels_end_animation:
    type: task
    debug: false
    definitions: root_entity
    script:
    - flag <[root_entity]> pmodels_animation_id:!
    - flag <[root_entity]> pmodels_anim_time:0
    - flag server pmodels_anim_active.<[root_entity].uuid>:!
    - run pmodels_reset_model_position def.root_entity:<[root_entity]>

pmodels_move_to_frame:
    type: task
    debug: false
    definitions: root_entity|animation|timespot
    script:
    - define model_data <server.flag[pmodels_data.model_<[root_entity].flag[pmodel_model_id]>]>
    - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]>
    - if <[timespot]> > <[animation_data.length]>:
        - choose <[animation_data.loop]>:
            - case loop:
                - define timespot <[timespot].mod[<[animation_data.length]>]>
            - case once:
                - flag server pmodels_anim_active.<[root_entity].uuid>:!
                - if <[root_entity].has_flag[pmodels_default_animation]>:
                    - run pmodels_animate def.root_entity:<[root_entity]> def.animation:<[root_entity].flag[pmodels_default_animation]>
                - else:
                    - run pmodels_reset_model_position def.root_entity:<[root_entity]>
                - stop
            - case hold:
                - define timespot <[animation_data.length]>
                - flag server pmodels_anim_active.<[root_entity].uuid>:!
    - define yaw_mod <[root_entity].location.yaw.add[180].to_radians>
    - define parentage <map>
    - foreach <[animation_data.animators]> key:part_id as:animator:
        - define framedata.position 0,0,0
        - define framedata.rotation 0,0,0
        - foreach position|rotation as:channel:
            - define relevant_frames <[animator.frames].filter[get[channel].equals[<[channel]>]]>
            - define before_frame <[relevant_frames].filter[get[time].is_less_than_or_equal_to[<[timespot]>]].last||null>
            - define after_frame <[relevant_frames].filter[get[time].is_more_than_or_equal_to[<[timespot]>]].first||null>
            - if <[before_frame]> == null:
                - define before_frame <[after_frame]>
            - if <[after_frame]> == null:
                - define after_frame <[before_frame]>
            - if <[before_frame]> == null:
                - define data 0,0,0
            - else:
                - define time_range <[after_frame.time].sub[<[before_frame.time]>]>
                - if <[time_range]> == 0:
                    - define time_percent 0
                - else:
                    - define time_percent <[timespot].sub[<[before_frame.time]>].div[<[time_range]>]>
                - choose <[before_frame.interpolation]>:
                    - case catmullrom:
                        - define before_extra <[relevant_frames].filter[get[time].is_less_than[<[before_frame.time]>]].last||null>
                        - if <[before_extra]> == null:
                            - define before_extra <[animation_data.loop].equals[loop].if_true[<[relevant_frames].last>].if_false[<[before_frame]>]>
                        - define after_extra <[relevant_frames].filter[get[time].is_more_than[<[after_frame.time]>]].first||null>
                        - if <[after_extra]> == null:
                            - define after_extra <[animation_data.loop].equals[loop].if_true[<[relevant_frames].first>].if_false[<[after_frame]>]>
                        - define p0 <[before_extra.data].as_location>
                        - define p1 <[before_frame.data].as_location>
                        - define p2 <[after_frame.data].as_location>
                        - define p3 <[after_extra.data].as_location>
                        - define data <proc[pmodels_catmullrom_proc].context[<[p0]>|<[p1]>|<[p2]>|<[p3]>|<[time_percent]>]>
                    - case linear:
                        - define data <[after_frame.data].as_location.sub[<[before_frame.data]>].mul[<[time_percent]>].add[<[before_frame.data]>].xyz>
                    - case step:
                        - define data <[before_frame.data]>
            - define framedata.<[channel]> <[data]>
        - define this_part <[model_data.<[part_id]>]>
        - define this_rots <[this_part.rotation].split[,].parse[to_radians]>
        - define pose <[this_rots].get[1].mul[-1]>,<[this_rots].get[2].mul[-1]>,<[this_rots].get[3]>
        - define parent_id <[this_part.parent]>
        - define parent_pos <location[<[parentage.<[parent_id]>.position]||0,0,0>]>
        - define parent_rot <location[<[parentage.<[parent_id]>.rotation]||0,0,0>]>
        - define parent_offset <location[<[parentage.<[parent_id]>.offset]||0,0,0>]>
        - define parent_raw_offset <[model_data.<[parent_id]>.origin]||0,0,0>
        - define rel_offset <location[<[this_part.origin]>].sub[<[parent_raw_offset]>]>
        - define rot_offset <[rel_offset].proc[pmodels_rot_proc].context[<[parent_rot]>]>
        - define new_pos <[framedata.position].as_location.proc[pmodels_rot_proc].context[<[parent_rot]>].add[<[rot_offset]>].add[<[parent_pos]>]>
        - define new_rot <[framedata.rotation].as_location.add[<[parent_rot]>].add[<[pose]>]>
        - define parentage.<[part_id]>.position:<[new_pos]>
        - define parentage.<[part_id]>.rotation:<[new_rot]>
        - define parentage.<[part_id]>.offset:<[rot_offset].add[<[parent_offset]>]>
        - foreach <[root_entity].flag[pmodel_anim_part.<[part_id]>]||<list>> as:ent:
            - choose <[ent].flag[pmodel_def_type]>:
              - case default:
                - define center <[root_entity].location.with_pitch[0].below[1.379].relative[0.32,0,0]>
                - teleport <[ent]> <[center].add[<[new_pos].div[15.98].rotate_around_y[<[yaw_mod].mul[-1]>]>]>
              - case external:
                - define center <[root_entity].location.with_pitch[0].below[0.7]>
                - teleport <[ent]> <[center].add[<[new_pos].div[15.98].rotate_around_y[<[yaw_mod].mul[-1]>]>]>
            - adjust <[ent]> reset_client_location
            - define radian_rot <[new_rot].xyz.split[,]>
            - define pose <[radian_rot].get[1]>,<[radian_rot].get[2]>,<[radian_rot].get[3]>
            - choose <[ent].flag[pmodel_def_type]>:
              - case default:
                - adjust <[ent]> armor_pose:[right_arm=<[pose]>]
              - case external:
                - adjust <[ent]> armor_pose:[head=<[pose]>]
            - adjust <[ent]> send_update_packets

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
#############################

##Events ########################
pmodels_load_event:
    type: world
    debug: false
    events:
      after server start:
      - if <script[pmodel_config].data_key[config].get[load_on_start].equals[true]>:
        - ~run pmodels_load_bbmodel

pmodels_animator:
    type: world
    debug: false
    events:
        on server start priority:-1000:
        # Cleanup
        - flag server pmodels_data:!
        - flag server pmodels_anim_active:!
        on tick server_flagged:pmodels_anim_active:
        - foreach <server.flag[pmodels_anim_active]> key:root_id:
            - define root <entity[<[root_id]>]||null>
            - if <[root].is_spawned||false>:
                - run pmodels_move_to_frame def.root_entity:<[root]> def.animation:<[root].flag[pmodels_animation_id]> def.timespot:<[root].flag[pmodels_anim_time].div[20]>
                - flag <[root]> pmodels_anim_time:++
        #skin type
        after player joins:
        - wait 1t
        - define skin_type <proc[pmodels_skin_type].context[<player>]>
        - flag <player> pmodels_skin_type:<[skin_type]>
####################################
