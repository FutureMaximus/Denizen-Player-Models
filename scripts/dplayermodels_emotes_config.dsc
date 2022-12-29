# Emotes configuration for Denizen Player Models
# This is safe to remove

#== API Usage ====================
## Begin an emote
# - run pmodel_emote_task def.player:<player[bob]> def.emote:wave
## Begin an emote without respawning the player model
# - run pmodel_emote_task_passive def.player:<player[bob]> def.emote:wave
## Stop an emote from playing
# - run pmodel_emote_task_stop def.player:<player[FutureMaximus]>
## Flags:
## Prevents the player from moving the player model
# - flag <player> pmodel_no_move
#==================================

#=== Emotes Config ================

pmodel_emote_config:
  type: data
  config:
    # Determine if the player's display name is shown during the emote
    show_display_name: false
    # The command prefix
    prefix: &b[Denizen Player Models]
    # The message if no emote is specified
    no_emote_message: Specify an emote
    # The message if the emote does not exist
    emote_nonexistent_message: That emote does not exist!
    # The message if the player does not have permission for the emote
    no_permission_message:  You do not seem to have access to that emote!
    # Maximum range the third person camera can go
    camera_max_range: 5
    # Ratelimit the player can use the emote command
    command_ratelimit: 0.5s

#==================================

#=== Per Emote Configuration Options ===

  # Per Emote configuration options:
  #-  speed: 0.2
  # "Speed allows you to move during the emote at a set speed setting this to 0 prevents that."
  # Default: 0
  #-  turn_rate: 6.0
  # "Determine how fast you will turn while moving in the emote higher values result in a faster turn rate setting this to 0 prevents turning." 
  # Default: 0
  #-  cam_range: 5
  # "How far the camera can go from the player"
  # Default: Camera max range in config
  #-  cam_offset: -1,0,0
  # "The camera offset relative to the player"
  # Default: 0,0,0
  #-  time_to_next_animation: 1s (Planned)
  # "The time it takes for the model to transition to the next animation making it look smoother instead of doing it instantly"
  # Default: 0s
  #-  permission: emote.wave
  # "The permission to use this emote set to none to disable"
  # Default: none

#========================================

#=== Emotes =============================

  emotes:
    my_example_emote:
      speed: 0.2
      turn_rate: 6.0
      cam_range: 5
      cam_offset: 0,0,0
      permission: emote.my_example_emote
    my_example_emote2:
      speed: 0.6
      turn_rate: 0.2
      cam_range: 2
      cam_offset: 0,0,0

#========================================

#===== Emote Command ====================

# Example: /emote wave /emote my_animation
# To reload emotes: /emote reload

pmodel_emote_command:
  type: command
  debug: false
  name: emote
  usage: /emote
  aliases:
  - emotes
  - gesture
  tab completions:
    1: <player.proc[pmodel_emote_list]>
  description: Emote command for player models
  #=== End of config ===
  script:
  - define config <script[pmodel_emote_config].data_key[config]>
  - ratelimit <player> <[config.command_ratelimit]>
  - define arg1 <context.args.get[1]||null>
  - if <[arg1]> == null:
    - narrate <[config.prefix].parse_color><[config.no_emote_message].parse_color>
  - else if <player.is_op> && <[arg1]> == reload:
    - narrate "<[config.prefix].parse_color> Emotes reloaded."
    - reload
    - stop
  - else if !<player.is_op>:
    - define emotes <script[pmodel_emote_config].data_key[emotes]>
    - define permission <[emotes.<[arg1]>.perm]||<[emotes.<[arg1]>.permission]>.if_null[null]>
    - if <[permission]> == null:
      - narrate <[config.prefix].parse_color><[config.emote_nonexistent_message].parse_color>
      - stop
    - else if !<player.has_permission[<[permission]>]>:
      - narrate <[config.prefix].parse_color><[config.no_permission_message].parse_color>
      - stop
  # Should the player have the player model spawned already it will move to the emote instead of spawning a new player model
  - if <player.has_flag[emote_ent]> && <player.flag[emote_ent].is_spawned>:
    - run pmodel_emote_task_passive def.player:<player> def.emote:<[arg1]>
    - stop
  - run pmodel_emote_task def.player:<player> def.emote:<[arg1]>

#========================================

#===== Emote list procedure =====

pmodel_emote_list:
  type: procedure
  definitions: player
  debug: false
  script:
  - define emotes <script[pmodel_emote_config].data_key[emotes]||null>
  - if <[emotes]> == null:
    - determine <empty>
  - else:
    - foreach <[emotes]> key:emote_name as:emote:
      - define perm <[emote.permission]||null>
      - if <[perm]> == null:
        - foreach next
      - else if <[player].has_permission[<[perm]>]> || <[player].is_op>:
        - define e_list:->:<[emote_name]>
    - determine <[e_list]||<empty>>

#================================
