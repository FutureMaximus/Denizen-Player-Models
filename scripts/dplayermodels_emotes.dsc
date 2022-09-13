#Emotes for Denizen Player Models
#This is purely optional but this works quite well with Denizen Player Models for the use of emotes
#if you don't want this script it is safe to remove it.

##Emote tasks ################################
pmodel_emote_list:
  type: procedure
  definitions: player
  debug: false
  script:
  - define emotes <script[pmodel_emote_config].data_key[emotes].if_null[n]>
  - if <[emotes]> != n:
    - define e_list <list>
    - foreach <[emotes]> key:e_name as:emote:
      - define perm <[emote.perm].if_null[n]>
      - if <[perm].equals[n]>:
        - foreach next
      - if <[player].has_permission[<[perm]>]> || <[player].is_op>:
        - define e_list:->:<[e_name]>
    - if <[e_list].is_empty>:
      - define e_List <empty>
    - determine <[e_list]>
  - else:
    - determine <empty>

pmodel_emote_task:
  type: task
  debug: false
  definitions: player|emote
  script:
  - define npc <npc[<[player]>].if_null[n]>
  - define player <player[<[player]>].if_null[n]>
  - if <[player].equals[n]> && <[npc].equals[n]>:
    - debug error "[Denizen Player Models] Must specify a player."
    - stop
  - if !<[npc].equals[n]> && <[player].equals[n]>:
    - define player <[npc]>
  - run pmodels_spawn_model def.location:<player.location> def.player:<[player]> save:spawned
  - define root <entry[spawned].created_queue.determination.first>
  - if <[player].is_player>:
    - adjust <[player]> invulnerable:true
    - cast INVISIBILITY <[player]> duration:100000000s hide_particles no_ambient no_icon
    - flag <[player]> emote:<[emote]>
    - flag <[player]> emote_ent:<[root]>
    - flag <[player]> emote_yaw:<[player].location.yaw>
    #raycast entity used for camera collision detection
    - spawn pmodel_ray_ent <[player].location.above[0.5].with_yaw[<[player].location.yaw>]> save:ray
    - define ray_ent <entry[ray].spawned_entity>
    - flag <[player]> pmodel_ray_ent:<[ray_ent]>
    #vehicle
    - spawn pmodel_vehicle_stand <[player].location.above[0.5].with_yaw[<[player].location.yaw>]> save:vehicle
    - define vehicle <entry[vehicle].spawned_entity>
    - flag <[player]> emote_vehicle:<[vehicle]>
    #mount
    - spawn pmodel_mount_stand <[player].location.above[0.5]> save:mount
    - define mount <entry[mount].spawned_entity>
    - flag <[mount]> emote
    - flag <[player]> emote_mount:<[mount]>
    - mount <[player]>|<[mount]>
    #collision box to ensure players dont go inside model
    - spawn pmodel_collision_box <[player].location.with_y[-72]> save:box
    - define box <entry[box].spawned_entity>
    - invisible <[box]> state:true
    - teleport <[box]> <[player].location>
    - flag <[player]> pmodel_collide_box:<[box]>
    #display name showing
    - define script <script[pmodel_emote_config].data_key[config]>
    - define check <[script].get[show_display_name]>
    - if <[script].get[show_display_name].equals[true]>:
      - spawn armor_stand[custom_name_visible=true;custom_name=<[player].display_name>;visible=false;gravity=false;marker=true] <[vehicle].location.above[1]> save:display
      - flag <[player]> emote_display:<entry[display].spawned_entity>
  - run pmodels_animate def.root_entity:<[root]> def.animation:<[emote]>

#should the player model be spawned already in the emote
pmodel_emote_task_passive:
  type: task
  debug: false
  definitions: player|emote
  script:
  - define npc <npc[<[player]>].if_null[n]>
  - define player <player[<[player]>].if_null[n]>
  - if <[player].equals[n]> && <[npc].equals[n]>:
    - debug error "[Denizen Player Models] Must specify a player."
    - stop
  - if !<[npc].equals[n]> && <[player].equals[n]>:
    - define player <[npc]>
  - flag <[player]> emote:<[emote]>
  - define root <[player].flag[emote_ent]>
  - if <[root].has_flag[pmodel_external_parts]>:
    - run pmodels_remove_external_parts def:<[root]>
  - run pmodels_animate def.root_entity:<[root]> def.animation:<[emote]>

pmodel_emote_task_stop:
  type: task
  debug: false
  definitions: player
  script:
  - define player <player[<[player]>].if_null[n]>
  - if <[player].equals[n]>:
    - define player <player>
  - else:
    - run pmodels_remove_model def.root_entity:<[player].flag[emote_ent]>
    - mount cancel <[player]>
    - teleport <[player]> <[player].flag[emote_vehicle].location>
    - adjust <[player]> invulnerable:false
    - remove <[player].flag[emote_vehicle]>
    - if <[player].has_flag[emote_display]>:
      - remove <[player].flag[emote_display]>
      - flag <[player]> emote_display:!
    - remove <[player].flag[pmodel_collide_box]>
    - remove <[player].flag[emote_mount]>
    - remove <[player].flag[pmodel_ray_ent]>
    - flag <[player]> pmodel_collide_box:!
    - flag <[player]> emote_vehicle:!
    - flag <[player]> emote_mount:!
    - flag <[player]> emote:!
    - adjust <[player]> show_to_players
    - wait 2t
    - cast INVISIBILITY remove <[player]>

#TODO:
#- Fix issue where model stops at space that should allow passage
#- Fix issue where player model goes up a wall infinitely
#- Fix issue where player model stops at carpet
pmodel_emote_vehicle_task:
    type: task
    debug: false
    definitions: f|s
    script:
    - if !<player.has_flag[pmodel_no_move]>:
      - define vehicle <player.flag[emote_vehicle]>
      - define mount <player.flag[emote_mount]>
      - define emote_yaw <player.flag[emote_yaw]>
      - define emote <player.flag[emote]>
      - define emote_ent <player.flag[emote_ent]>
      - define script <script[pmodel_emote_config]>
      - define script_e <[script].data_key[emotes]>
      - define script_c <[script].data_key[config]>
      #abs in case you for some reason set it to negative...weirdo
      - define speed <[script_e.<[emote]>.speed].abs.if_null[0.0]>
      - define cam_offset <[script_e.<[emote]>.cam_offset].if_null[0,0,0]>
      - define turn_rate <[script_e.<[emote]>.turn_rate].abs.if_null[0.0]>
      #f = forward/back s = left or right
      #left or right movement
      - if !<player.has_flag[emote_yaw]>:
        - define yaw <[mount].location.yaw>
        - flag <player> emote_yaw:<[yaw]>
        - define emote_yaw <[yaw]>
      - if <[s]> != 0:
        #forward
        - if <[f]> > 0:
          #right
          - if <[s]> < 0:
              - define yaw <player.flag[emote_yaw].add[<[turn_rate]>]>
              - if <[yaw]> > 359:
                - define yaw 1
              - flag <player> emote_yaw:<[yaw]>
              - define emote_yaw <[yaw]>
          #left
          - else if <[s]> > 0:
              - define yaw <player.flag[emote_yaw].sub[<[turn_rate]>]>
              - if <[yaw]> < 2:
                - define yaw 360
              - flag <player> emote_yaw:<[yaw]>
              - define emote_yaw <[yaw]>
        #backward
        - else if <[f]> < 0:
          #right
          - if <[s]> > 0:
              - define yaw <player.flag[emote_yaw].add[<[turn_rate]>]>
              - if <[yaw]> > 359:
                - define yaw 1
              - flag <player> emote_yaw:<[yaw]>
              - define emote_yaw <[yaw]>
          #left
          - else if <[s]> < 0:
              - define yaw <player.flag[emote_yaw].sub[<[turn_rate]>]>
              - if <[yaw]> < 2:
                - define yaw 360
              - flag <player> emote_yaw:<[yaw]>
              - define emote_yaw <[yaw]>
        #idle
        - else:
          #right
          - if <[s]> < 0:
            - if !<player.has_flag[emote_yaw]>:
              - define yaw <[mount].location.yaw>
              - flag <player> emote_yaw:<[yaw]>
              - define emote_yaw <[yaw]>
            - else:
              - define yaw <player.flag[emote_yaw].add[<[turn_rate]>]>
              - if <[yaw]> > 359:
                - define yaw 1
              - flag <player> emote_yaw:<[yaw]>
              - define emote_yaw <[yaw]>
          #left
          - else if <[s]> > 0:
            - if !<player.has_flag[emote_yaw]>:
              - define yaw <[mount].location.yaw>
              - flag <player> emote_yaw:<[yaw]>
              - define emote_yaw <[yaw]>
            - else:
              - define yaw <player.flag[emote_yaw].sub[<[turn_rate]>]>
              - if <[yaw]> < 2:
                - define yaw 360
              - flag <player> emote_yaw:<[yaw]>
              - define emote_yaw <[yaw]>
      #forward
      - if <[f]> > 0:
        #collision detection
        - define b_1 <[vehicle].location.with_pitch[0].above[2.2].forward[1]>
        - define b_list <list[<[b_1]>]>
        - define collision <proc[pmodel_collision_detect].context[<[b_list]>]>
        #falling
        - define l_1 <[vehicle].location.with_pitch[0].below[0.1]>
        - define l_1 <list[<[l_1]>]>
        - define fall <proc[pmodel_falling].context[<[l_1]>]>
        #whether to go up a block
        - define u_1 <[vehicle].location.with_pitch[0].forward[1]>
        - define up_l <list[<[u_1]>]>
        - define up <proc[pmodel_up_block].context[<[up_l]>]>
        #normal
        - if <[collision]> == go && <[fall]> != fall && <[up]> == stay:
            - teleport <[vehicle]> <[vehicle].location.with_yaw[<[emote_yaw]>]>
            - adjust <[vehicle]> velocity:<[vehicle].location.with_pitch[0].direction.vector.mul[<[speed]>]>
        #going up a block
        - else if <[collision]> == go && <[up]> == up:
            - define vel 0.5
            - adjust <[vehicle]> velocity:<[vehicle].location.with_pitch[-45].direction.vector.mul[<[vel]>]>
        #falling
        - else if <[fall]> == fall:
            - define vel <[speed].mul[2.5]>
            - adjust <[vehicle]> velocity:<[vehicle].location.with_pitch[45].direction.vector.mul[<[vel]>]>
      #backward
      - else if <[f]> < 0:
          #collision detection
        - define b_1 <[vehicle].location.with_pitch[0].above[2].backward[1.2]>
        - define b_list <list[<[b_1]>]>
        - define collision <proc[pmodel_collision_detect].context[<[b_list]>]>
        #falling
        - define l_1 <[vehicle].location.with_pitch[0].below[0.1]>
        - define l_1 <list[<[l_1]>]>
        - define fall <proc[pmodel_falling].context[<[l_1]>]>
        #whether to go up a block
        - define u_1 <[vehicle].location.with_pitch[0].backward[1]>
        - define up_l <list[<[u_1]>]>
        - define up <proc[pmodel_up_block].context[<[up_l]>]>
        #normal
        - if <[collision]> == go && <[fall]> != fall && <[up]> == stay:
            - teleport <[vehicle]> <[vehicle].location.with_yaw[<[emote_yaw]>]>
            - adjust <[vehicle]> velocity:<[vehicle].location.with_pitch[0].rotate_yaw[180].direction.vector.mul[<[speed]>]>
        #going up a block
        - else if <[collision]> == go && <[up]> == up:
            - define vel 0.5
            - adjust <[vehicle]> velocity:<[vehicle].location.with_pitch[-45].rotate_yaw[180].direction.vector.mul[<[vel]>]>
        #falling
        - else if <[fall]> == fall:
            - define vel <[speed].mul[2.5]>
            - adjust <[vehicle]> velocity:<[vehicle].location.with_pitch[45].rotate_yaw[180].direction.vector.mul[<[vel]>]>
      #idle
      - else:
        #falling (reason for being here is to ensure should there be an external event it will fall assuming there is no block below)
        - define l_1 <[vehicle].location.with_pitch[0].below[0.1]>
        - define l_1 <list[<[l_1]>]>
        - define fall <proc[pmodel_falling].context[<[l_1]>]>
        - if <[fall]> != fall:
          - teleport <[vehicle]> <[vehicle].location.with_yaw[<[emote_yaw]>]>
      - teleport <player.flag[pmodel_collide_box]> <[vehicle].location.with_yaw[<[emote_yaw]>]>
      - if <player.has_flag[emote_display]>:
        - teleport <player.flag[emote_display]> <[vehicle].location.above[1.8]>
      #camera collide detection
      - define max_r <[script_e.<[emote]>.cam_range].if_null[<[script_c.cam_max_range]>]>
      - define rot_loc <[vehicle].location.with_yaw[<player.location.yaw>].with_pitch[<player.location.pitch>].relative[<location[0,0,-<[max_r]>].rotate_around_z[<player.location.yaw.to_radians>]>].relative[<[cam_offset]>]>
      - define ray_ent <player.flag[pmodel_ray_ent]>
      - teleport <[ray_ent]> <[vehicle].location.above[1]>
      - look <[ray_ent]> <[rot_loc].above[1]> duration:1t
      - define ray <[ray_ent].location.ray_trace[range=<[max_r].add[1]>;return=precise;nonsolids=false;fluids=true].if_null[n]>
      - define impact <[ray_ent].location.ray_trace[range=<[max_r].add[1]>;return=normal;nonsolids=false;fluids=true].if_null[n]>
      - if !<[ray].equals[n]> && !<[impact].equals[n]>:
        - define yaw <player.location.yaw>
        - choose <[impact].simple>:
          #ceiling
          - case 0,-1,0:
            - define rot_loc <[ray].below[1.5].with_yaw[<player.location.yaw>].forward[1].relative[<[cam_offset]>]>
          #floor
          - case 0,1,0:
            - define rot_loc <[ray].below[2.3].forward[1.3].relative[<[cam_offset]>]>
          #walls
          - default:
            - define rot_loc <[ray].below[1.1].with_yaw[<player.location.yaw>].forward[1.3].relative[<[cam_offset]>]>
      - teleport <[mount]> <[rot_loc]>
      #the player model
      - teleport <[emote_ent]> <[vehicle].location.with_pitch[0]>

pmodel_up_block:
  type: procedure
  debug: false
  definitions: loc
  script:
  - foreach <[loc]>:
    - if <[value].material.is_solid>:
      - determine up
    - else:
      - determine stay

pmodel_collision_detect:
     type: procedure
     debug: false
     definitions: loc
     script:
     - foreach <[loc]>:
        - if <[value].material> != <material[air]>:
            - determine stop
            - stop
        - else:
            - determine go

pmodel_falling:
    type: procedure
    debug: false
    definitions: loc
    script:
    - foreach <[loc]>:
      - if !<[value].material.is_solid>:
        - determine fall
        - stop
      - else:
        - determine s
############################

##Entities ######################

pmodel_ray_ent:
    type: entity
    debug: false
    entity_type: armor_stand
    mechanisms:
        marker: true
        gravity: false
        visible: false
        is_small: true
        silent: true

pmodel_vehicle_stand:
    type: entity
    debug: false
    entity_type: armor_stand
    mechanisms:
        marker: false
        gravity: true
        visible: false
        is_small: false
        silent: true

pmodel_collision_box:
    type: entity
    debug: false
    entity_type: slime
    mechanisms:
      size: 3
      has_ai: false
      invulnerable: true
      silent: true

pmodel_mount_stand:
    type: entity
    debug: false
    entity_type: armor_stand
    mechanisms:
        marker: true
        gravity: false
        visible: false
        is_small: false
        silent: true
#####################################

##events
pmodels_emote_events:
    type: world
    debug: false
    events:
        after player steers entity flagged:emote:
        - ratelimit <player> 1t
        - if <context.entity.has_flag[emote]>:
          - ~run pmodel_emote_vehicle_task def:<context.forward>|<context.sideways>
        after player exits vehicle flagged:emote:
        - ratelimit <player> 1t
        - if <player.has_flag[emote_ent]> && <player.flag[emote_ent].is_spawned>:
          - run pmodel_emote_task_stop def:<player>
        on player quits:
        - if <player.has_flag[emote_ent]> && <player.flag[emote_ent].is_spawned>:
          - run pmodel_emote_task_stop def:<player>
