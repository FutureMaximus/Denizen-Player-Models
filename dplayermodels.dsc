###############################
# +---------------------------
# |
# | D e n i z e n   P l a y e r   M o d e l s
# |
# | Animated players in Java Minecraft!
# |
# +---------------------------
##Player Models
# @Contributors Max^, mcmonkey
# @Special thanks to mcmonkey for creating dmodels and making this possible for everyone!
# @date 2022/06/03
# @updated 2022/06/03
# @denizen-build REL-1771
# @script-version 1.0
# @Github https://github.com/FutureMaximus/Denizen-Player-Models
##NOTICE: This will not work on minecraft versions below 1.17 and will not work with any other rendertype_entity_translucent core shader file it must be the one provided by mccosmetics or here.
##Description:

# Denizen Player Models allows you to take the texture of any player or npc and animate them with a model of the player!
#For more control over the player models there is an API as well.

#####################
##Info:
#
#Uses elements from dmodels by mcmonkey https://github.com/mcmonkeyprojects/DenizenModels and requires the bbmodel converter by dmodels for the animations.
#
#For player emotes made by other people https://mcmodels.net/?product_cat=&post_type=product&s=Emote (Must be for the mccosmetics plugin not IA).
#
#Player models allows the use of player model animations useful for emotes or cutscenes as a per player showing task is available.
#
#There is an emote command you can use /emote wave and you can modify each emote in the emote configuration below.
##How to get started:

##Notice: If you have the mccosmetics core shader file you can skip this part
#Put the core shader files provided in your resource pack minecraft folder "minecraft/shaders/core/rendertype_entity_translucent.vsh"
#, "minecraft/shaders/core/rendertype_entity_translucent.fsh" and "minecraft/shaders/core/rendertype_entity_translucent.json"

#Put the player model template files in "Denizen/player_models/templates/player_model_template_norm.yml" and "Denizen/player_models/templates/player_model_template_slim.yml"

##Notice: You need DenizenModelsConverter for this to work which can be found at https://github.com/mcmonkeyprojects/DenizenModels
#To use your animations you need to generate a dmodel file with your animated player bbmodel file or the bbmodel template provided and get the dmodel file generated by the DenizenModelsConverter
#afterwards put the file in "Denizen/player_models/animations/my_animation.dmodel.yml"

#####################
##Config (Stuff you can modify):
#Configurations for emotes and setting permissions for them
pmodel_config:
  type: data
  #message config for emote command
  config:
    #loads the animations on server start
    load_on_start: true
    #whether it shows the player's display name when doing an emote
    show_display_name: true
    #prefix for emote command
    prefix: "[Denizen Player Models]"
    #prefix color
    prefix_color: "white"
    #message color
    message_color: "white"
    no_emote: " Specify an emote"
    no_exist: " That emote does not exist!"
    no_perm: " You do not seem to have access to that emote!"
  general:
    #max_range: 8 "Maximum range the third person camera can go."
    #min_range: 2 "Minimum range"
    max_range: 6
    min_range: 2

  #emotes configuration
  #INFO:
  # speed: 0.2 "Speed allows you to move during the emote at a set speed setting this to 0 prevents that."
  # turn_rate: 6.0 "Determine how fast you will turn while moving in the emote higher values result in a faster turn rate setting this to 0 prevents turning."
  # perm: emote.wave "Perm allows you to set a permission for this emote to disable this set it to 'none'."
  #here you can set the emotes for players and permissions required for them
  emotes:
    hop:
      speed: 0.09
      turn_rate: 7.0
      perm: emote.hop
    crawl:
      speed: 0.05
      turn_rate: 7.0
      perm: emote.crawl
    slowmorun:
      speed: 0.1
      turn_rate: 7.0
      perm: emote.slowmo
    moonwalk:
      speed: 0.1
      turn_rate: 6.0
      perm: emote.moonwalk
    sad:
      speed: 0.05
      turn_rate: 4.0
      perm: emote.sad
    superman:
      speed: 0.1
      turn_rate: 7.0
      perm: emote.superman
    yes:
      speed: 0.0
      turn_rate: 1.2
      perm: emote.yes
    no:
      speed: 0.0
      turn_rate: 1.2
      perm: emote.no
    sit:
      speed: 0.0
      turn_rate: 0.0
      perm: emote.sit

##Emote Command:
#Example: /emote wave /emote my_animation
pmodel_emote_command:
  type: command
  debug: false
  name: emote
  usage: /emote
  aliases:
  - gesture
  description: Emote command for player models that plays an animation
  #permission: op.op
  script:
  - define a_1 <context.args.get[1].if_null[n]>
  - define script <script[pmodel_config].data_key[config]>
  #arg 1 null
  - if <[a_1].equals[n]>:
    - narrate <&color[<[script.prefix_color]>]><[script.prefix]><&color[<[script.message_color]>]><[script.no_emote]>
  - else:
    - if !<player.is_op>:
      #emote list for non op players
      - define script_emotes <script[pmodel_config].data_key[emotes]>
      #check permission for emote
      - define perm <[script_emotes.<[a_1]>.perm].if_null[n]>
      - if <[perm].equals[n]>:
        - narrate <&color[<[script.prefix_color]>]><[script.prefix]><&color[<[script.message_color]>]><[script.no_exist]>
        - stop
      - if !<player.has_permission[<[perm]>]>:
        - narrate <&color[<[script.prefix_color]>]><[script.prefix]><&color[<[script.message_color]>]><[script.no_perm]>
        - stop
    #should the player have the player model spawned already it will move to the emote instead
    - if <player.has_flag[emote_ent]> && <player.flag[emote_ent].is_spawned>:
      - run pmodel_emote_task_passive def:<player>|<[a_1]>
      - stop
    - run pmodel_emote_task def:<player>|<[a_1]>

#command for ops only (here you can reload the animations)
pmodel_base_command:
  type: command
  debug: false
  name: denizenplayermodel
  usage: /denizenplayermodel
  aliases:
  - pmodel
  description: Pmodel command
  permission: op.op
  script:
  - if <context.args.get[1]> == reload && <player.is_op>:
    - ~run pmodels_load_animation def:classic
    - ~run pmodels_load_animation def:slim
    - narrate "[Denizen Player Models] Reloaded animations."

#############################
##API Usage
# # To spawn the player model
# - run pmodels_spawn_model def.location:<player.location> def.player:<player[FutureMaximus]> save:spawned
# - define root <entry[spawned].created_queue.determination.first>
# # To spawn the player model that only shows for one player (useful for cutscenes)
# - run pmodels_spawn_model def.location:<player.location> def.player:<player[FutureMaximus> def.show_to:<player[FutureMaximus]> save:spawned
# - define root <entry[spawned].created_queue.determination.first>
# # To move the whole player model
# - teleport <[root]> <player.location>
# - run pmodels_reset_model_position def.root_entity:<[root]>
# # To start an automatic animation
# - run pmodels_animate def.root_entity:<[root]> def.animation:idle
# # To end an automatic animation
# - run pmodels_end_animation def.root_entity:<[root]>
# # To move the entity to a single frame of an animation (timespot is a decimal number of seconds from the start of the animation)
# - run pmodels_move_to_frame def.root_entity:<[root]> def.animation:idle def.timespot:0.5
# # To remove the player model
# - run pmodels_remove_model def.root_entity:<[root]>
# # To begin an emote
# - run pmodel_emote_task def.player:<player[FutureMaximus]> def.emote:wave
###############################
# Todo:
# - Add third person perspective for emote command
# - Add a way to determine if the player has the slim skin or not
# - Ensure third person camera does not go inside blocks
# - Add support for external bones like a sword or car
# - Add animation to animation transitions and transition to normal state when ending emote
# - Add support for hand/offhand items
##Try not to touch the stuff below here unless you know what your doing ;).

pmodel_emote_task:
  type: task
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
    - adjust <[player]> hide_from_players
    - cast INVISIBILITY <[player]> duration:100000000s hide_particles no_ambient no_icon
    - flag <[player]> emote:<[emote]>
    - flag <[player]> emote_ent:<[root]>
    - flag <[player]> emote_yaw:<[player].location.yaw>
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
    - define script <script[pmodel_config].data_key[config]>
    - define check <[script].get[show_display_name]>
    - if <[script].get[show_display_name].equals[true]>:
      - spawn armor_stand[custom_name_visible=true;custom_name=<[player].display_name>;visible=false;gravity=false;marker=true] <[vehicle].location.above[1]> save:display
      - flag <[player]> emote_display:<entry[display].spawned_entity>
  - run pmodels_animate def.root_entity:<[root]> def.animation:<[emote]>

#should the player model be spawned already in the emote
pmodel_emote_task_passive:
  type: task
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
  - run pmodels_animate def.root_entity:<[root]> def.animation:<[emote]>

pmodel_emote_task_remove:
  type: task
  definitions: player
  script:
  - define player <player[<[player]>].if_null[n]>
  - if <[player].equals[n]>:
    - define player <player>
  - else:
    - run pmodels_remove_model def.root_entity:<[player].flag[emote_ent]>
    - mount cancel <[player]>
    - teleport <[player]> <[player].flag[emote_vehicle].location>
    - remove <[player].flag[emote_vehicle]>
    - if <[player].has_flag[emote_display]>:
      - remove <[player].flag[emote_display]>
      - flag <[player]> emote_display:!
    - remove <[player].flag[pmodel_collide_box]>
    - remove <[player].flag[emote_mount]>
    - flag <[player]> pmodel_collide_box:!
    - flag <[player]> emote_vehicle:!
    - flag <[player]> emote_mount:!
    - flag <[player]> emote:!
    - adjust <[player]> show_to_players
    - wait 2t
    - cast INVISIBILITY remove <[player]>

pmodel_emote_vehicle_task:
    type: task
    debug: false
    definitions: f|s
    script:
    - define vehicle <player.flag[emote_vehicle]>
    - define mount <player.flag[emote_mount]>
    - define emote_yaw <player.flag[emote_yaw]>
    - define emote <player.flag[emote]>
    - define emote_ent <player.flag[emote_ent]>
    - define script <script[pmodel_config].data_key[emotes]>
    #abs in case you for some reason set it to negative...weirdo
    - define speed <[script.<[emote]>.speed].abs.if_null[0.0]>
    - define turn_rate <[script.<[emote]>.turn_rate].abs.if_null[0.0]>
    #f = forward/back s = left or right
    #left or right movement
    - if <[s]> != 0:
      #forward
      - if <[f]> > 0:
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
      #backward
      - else if <[f]> < 0:
        #right
        - if <[s]> > 0:
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
        - else if <[s]> < 0:
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
    - teleport <[mount]> <[vehicle].location.with_yaw[<player.location.yaw>].with_pitch[<player.location.pitch>].relative[<location[0,0,-6].rotate_around_z[<player.location.yaw.to_radians>]>]>
    - teleport <player.flag[pmodel_collide_box]> <[vehicle].location.with_yaw[<[emote_yaw]>]>
    - if <player.has_flag[emote_display]>:
      - teleport <player.flag[emote_display]> <[vehicle].location.above[1.8]>
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

pmodel_part_stand:
    type: entity
    debug: false
    entity_type: armor_stand
    mechanisms:
        marker: true
        gravity: false
        visible: false
        is_small: false

pmodel_vehicle_stand:
    type: entity
    debug: false
    entity_type: armor_stand
    mechanisms:
        marker: false
        gravity: true
        visible: false
        is_small: false

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

pmodels_load_event:
    type: world
    events:
      after server start:
      - if <script[pmodel_config].data_key[config].get[load_on_start].equals[true]>:
        - ~run pmodels_load_animation def:classic
        - ~run pmodels_load_animation def:slim

pmodels_skin_type:
    type: procedure
    debug: true
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

pmodels_load_animation:
    type: task
    definitions: type
    debug: false
    script:
    - define yamlid pmodels_player_template
    - choose <[type]>:
      - case classic:
        - define filename player_models/templates/player_model_template_norm.pmodel.yml
      - case slim:
        - define filename player_models/templates/player_model_template_slim.pmodel.yml
      - default:
        - debug error "[Denizen Player Models] Must specify classic or slim model type."
        - stop
    - ~yaml id:<[yamlid]> load:<[filename]>
    - define order <yaml[<[yamlid]>].read[order]>
    - define parts <yaml[<[yamlid]>].read[models]>
    - yaml unload id:<[yamlid]>
    - foreach <[order]> as:id:
        - define raw_parts.<[id]> <[parts.<[id]>]>
    - define animation_files <server.list_files[player_models/animations]>
    - if <[animation_files].is_empty>:
      - debug error "[Denizen Player Models] There are no animations in "player_models/animations""
      - narrate "[Denizen Player Models] <red>No animations found in playermodels/animations"
      - stop
    #gather animations from the animation files
    - foreach <[animation_files]> as:anim_file:
      - yaml create id:file_<[anim_file]>
      - ~yaml id:file_<[anim_file]> load:player_models/animations/<[anim_file]>
      - define animations <yaml[file_<[anim_file]>].read[animations]||<map>>
      #stores the animations for use
      - foreach <[animations]> key:name as:anim:
        - foreach <[order]> as:id:
            - if <[anim.animators].contains[<[id]>]>:
                - define raw_animators.<[id]>.frames <[anim.animators.<[id]>.frames].sort_by_value[get[time]]>
            - else:
                - define raw_animators.<[id]> <map[frames=<list>]>
        - define anim.animators <[raw_animators]>
        - define raw_animations.<[name]> <[anim]>
      - yaml unload id:file_<[anim_file]>
    #new path for texture on player model (doing it in the template file caused the head to be underneath the model a big no no)
    - define load_order <list[player_root|head|hip|waist|chest|right_arm|right_forearm|left_arm|left_forearm|right_leg|right_foreleg|left_leg|left_foreleg]>
    - foreach <[load_order]> as:tex_name:
        - foreach <[raw_parts]> key:id as:part:
            - define name <[part.name]>
            - if <[tex_name]> == <[name]>:
              - define new_list.<[id]> <[parts.<[id]>]>
              - foreach stop
    - define raw_parts <[new_list]>
    - choose <[type]>:
      - case classic:
        - flag server pmodels_data.model_player_model_template_norm:<[raw_parts]>
        - flag server pmodels_data.animations_player_model_template_norm:<[raw_animations]>
      - case slim:
        - flag server pmodels_data.model_player_model_template_slim:<[raw_parts]>
        - flag server pmodels_data.animations_player_model_template_slim:<[raw_animations]>

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
    - if !<[npc].equals[n]> && <[player].equals[n]>:
      - define player <[npc]>
    - if <[player].is_npc>:
      - define skin_type <proc[pmodels_skin_type].context[<[player]>]>
    - else:
      - define skin_type <[player].flag[pmodels_skin_type]>
    - choose <[skin_type]>:
      - case classic:
        - announce CLASSIC
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
    - flag <entry[root].spawned_entity> pmodel_model_id:<[model_name]>
    #if show_to is being utilized determine if it is a player
    - define show_to <player[<[show_to]>].if_null[n]>
    - foreach <server.flag[pmodels_data.model_<[model_name]>]> key:id as:part:
        - if !<[part.item].exists>:
            - foreach next
        #15.98 has been the best number for the player model based on multiple tests
        - define offset <location[<[part.origin]>].div[15.98]>
        - define rots <[part.rotation].split[,].parse[to_radians]>
        - define pose <[rots].get[1].mul[-1]>,<[rots].get[2].mul[-1]>,<[rots].get[3]>
        - spawn pmodel_part_stand[armor_pose=[right_arm=<[pose]>]] <[center].add[<[offset].rotate_around_y[<[yaw_mod].mul[-1]>]>]> save:spawned
        - adjust <item[<[part.item]>]> skull_skin:<[player].skull_skin> save:item
        - define part.item <entry[item].result>
        #fakeequip if show_to is being used
        - if !<[show_to].equals[n]>:
          - fakeequip <entry[spawned].spawned_entity> right_arm:<[part.item]> for:<[show_to]>
        - else:
          - equip <entry[spawned].spawned_entity> right_arm:<[part.item]>
        #when going too far from the player model the textures get messed up this fixes that issue
        - adjust <entry[spawned].spawned_entity> tracking_range:256
        - flag <entry[spawned].spawned_entity> pmodel_def_pose:<[pose]>
        - define name <[part].get[name]>
        - flag <entry[spawned].spawned_entity> pmodel_def_name:<[name]>
        - flag <entry[spawned].spawned_entity> pmodel_def_item:<item[<[part.item]>]>
        - flag <entry[spawned].spawned_entity> pmodel_def_offset:<[offset]>
        - flag <entry[spawned].spawned_entity> pmodel_root:<entry[root].spawned_entity>
        - flag <entry[root].spawned_entity> pmodel_parts:->:<entry[spawned].spawned_entity>
        - flag <entry[root].spawned_entity> pmodel_anim_part.<[id]>:->:<entry[spawned].spawned_entity>
    - define root_entity <entry[root].spawned_entity>
    - determine <[root_entity]>

pmodels_remove_model:
    type: task
    debug: false
    definitions: root_entity
    script:
    - remove <[root_entity].flag[pmodel_parts]>
    - remove <[root_entity]>

pmodels_reset_model_position:
    type: task
    debug: false
    definitions: root_entity
    script:
    - define center <[root_entity].location.with_pitch[0].below[1.379].relative[0.32,0,0]>
    - define yaw_mod <[root_entity].location.yaw.add[180].to_radians>
    - foreach <[root_entity].flag[pmodel_parts]> as:part:
        - adjust <[part]> armor_pose:[right_arm=<[part].flag[pmodel_def_pose]>]
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

pmodels_animate:
    type: task
    debug: false
    definitions: root_entity|animation
    script:
    - run pmodels_reset_model_position def.root_entity:<[root_entity]>
    - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]||null>
    - if <[animation_data]> == null:
        - debug error "[Denizen Player Models] <red>Cannot animate entity <[root_entity].uuid> due to model <[root_entity].flag[pmodel_model_id]> not having an animation named <[animation]>."
        - stop
    - flag <[root_entity]> pmodels_animation_id:<[animation]>
    - flag <[root_entity]> pmodels_anim_time:0
    - flag server pmodels_anim_active.<[root_entity].uuid>

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
    - define center <[root_entity].location.with_pitch[0].below[1.379].relative[0.32,0,0]>
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
            #15.98 offset for player model
            - teleport <[ent]> <[center].add[<[new_pos].div[15.98].rotate_around_y[<[yaw_mod].mul[-1]>]>]>
            #- adjust <[ent]> reset_client_location
            - define radian_rot <[new_rot].xyz.split[,]>
            - define pose <[radian_rot].get[1]>,<[radian_rot].get[2]>,<[radian_rot].get[3]>
            - adjust <[ent]> armor_pose:[right_arm=<[pose]>]
            #- adjust <[ent]> send_update_packets

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
    # TODO: Validate this mess
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

pmodels_emote_events:
    type: world
    debug: false
    events:
        after player steers entity flagged:emote:
        - ratelimit <player> 1t
        - ~run pmodel_emote_vehicle_task def:<context.forward>|<context.sideways>
        after player exits vehicle flagged:emote:
        - ratelimit <player> 1t
        - run pmodel_emote_task_remove def:<player>
        on player quits:
        - run pmodel_emote_task_remove def:<player>

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
