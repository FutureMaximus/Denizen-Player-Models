#Emotes for Denizen Player Models
#This is purely optional but this works quite well with Denizen Player Models for the use of emotes
#if you don't want this script it is safe to remove it.

#config
pmodel_emote_config:
  type: data
  config:
    #whether it shows the player's display name when doing an emote
    show_display_name: false
    #prefix for emote command
    prefix: "[Denizen Player Models]"
    #prefix color
    prefix_color: "white"
    #message color
    message_color: "white"
    #did not specify an emote to use
    no_emote: " Specify an emote"
    #emote does not exist message
    no_exist: " That emote does not exist!"
    #no permission for that emote
    no_perm: " You do not seem to have access to that emote!"
    #max_range: 8 "Maximum range the third person camera can go."
    cam_max_range: 5
    #min_range: 2 "Minimum range the third person camera can go"
    cam_min_range: 2
  #emotes configuration
  #INFO:
  # speed: 0.2 "Speed allows you to move during the emote at a set speed setting this to 0 prevents that."
  # turn_rate: 6.0 "Determine how fast you will turn while moving in the emote higher values result in a faster turn rate setting this to 0 prevents turning."
  # perm: emote.wave "Perm allows you to set a permission for this emote to disable this set it to 'none'."
  #here you can set the emotes for players and permissions required for them
  emotes:
    pirate_run:
      speed: 0.2
      turn_rate: 9
      perm: emote.pirate_run
    chicken:
      speed: 0.2
      turn_rate: 8.0
      perm: emote.chicken
    hop:
      speed: 0.09
      turn_rate: 7.0
      perm: emote.hop
    crawl:
      speed: 0.05
      turn_rate: 7.0
      perm: emote.crawl
    mime:
      speed: 0.1
      turn_rate: 5.0
      perm: emote.mime
    disco:
      speed: 0.7
      turn_rate: 20.0
      perm: emote.disco
    slowmorun:
      speed: 0.3
      turn_rate: 8.0
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
      speed: 0.3
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
      turn_rate: 20.0
      perm: emote.sit
    meditate:
      speed: 0.1
      turn_rate: 7.0
      perm: emote.meditate

##API Usage #########################
# # To begin an emote
# - run pmodel_emote_task def.player:<player[FutureMaximus]> def.emote:wave
# # To begin an emote without respawning the player model
# - run pmodel_emote_task_passive def.player:<player[FutureMaximus]> def.emote:wave
# # To stop an emote
# - run pmodel_emote_task_stop def.player:<player[FutureMaximus]>
# # Useful flags:
# # To prevent the player from moving the player model
# - flag <player> pmodel_no_move
##################################

##Emote Command:
#Example: /emote wave /emote my_animation
#To reload emotes /emote reload
pmodel_emote_command:
  type: command
  debug: false
  name: emote
  usage: /emote
  aliases:
  - emotes
  - gesture
  tab completions:
    1: <proc[pmodel_emote_list].context[<player>]>
  description: Emote command for player models that plays an animation
  #permission: op.op
  script:
  - define a_1 <context.args.get[1].if_null[n]>
  - define script <script[pmodel_emote_config].data_key[config]>
  #arg 1 null
  - if <[a_1].equals[n]>:
    - narrate <&color[<[script.prefix_color]>]><[script.prefix]><&color[<[script.message_color]>]><[script.no_emote]>
  - else:
    - if !<player.is_op>:
      #emote list for non op players
      - define script_emotes <script[pmodel_emote_config].data_key[emotes]>
      #check permission for emote
      - define perm <[script_emotes.<[a_1]>.perm].if_null[n]>
      - if <[perm].equals[n]>:
        - narrate <&color[<[script.prefix_color]>]><[script.prefix]><&color[<[script.message_color]>]><[script.no_exist]>
        - stop
      - if !<player.has_permission[<[perm]>]>:
        - narrate <&color[<[script.prefix_color]>]><[script.prefix]><&color[<[script.message_color]>]><[script.no_perm]>
        - stop
    - else if <player.is_op> && <[a_1]> == reload:
        - ~run pmodel_emote_list
        - narrate "<&color[<[script.prefix_color]>]><[script.prefix]> Emotes reloaded."
        - reload
        - stop
    #should the player have the player model spawned already it will move to the emote instead
    - if <player.has_flag[emote_ent]> && <player.flag[emote_ent].is_spawned>:
      - run pmodel_emote_task_passive def:<player>|<[a_1]>
      - stop
    - run pmodel_emote_task def:<player>|<[a_1]>