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
# @updated 2022/06/29
# @denizen-build REL-1772
# @script-version 1.2 BETA
# @Github https://github.com/FutureMaximus/Denizen-Player-Models
##Note: This will not work Denizen release version 1771 or below.
##Update 1.2 Info:
    # You can now simply drop your animation block bench file in the animations folder
    # Any external bones inside the animation will be put into a resource pack
    # Changed template files and file paths

##NOTICE: This will not work on minecraft versions below 1.17 and will not work with any other
##rendertype_entity_translucent core shader files it must be the one provided by mccosmetics or here.
##Tested Minecraft Version: 1.18.2
##Description:

# Denizen Player Models allows you to take the texture of any player or npc and animate them with a model of the player!
# For more control over the player models there is an API as well.
# I plan on adding more features such as mobility tasks in the future.

#####################
##Info:

#Uses elements from dmodels by mcmonkey https://github.com/mcmonkeyprojects/DenizenModels.

#For player emotes made by other people https://mcmodels.net/?product_cat=&post_type=product&s=Emote (Must be for the mccosmetics plugin not IA).

#Denizen Player Models allows the use of player model animations useful for emotes or cutscenes as a per player showing task is available.

#Compatible with the mccosmetics plugin

##How to get started:

##Notice: If you have the mccosmetics core shader file and player_animator folder you can skip this part
#Put the core shader files provided in your resource pack minecraft folder "minecraft/shaders/core/rendertype_entity_translucent.vsh"
#, "minecraft/shaders/core/rendertype_entity_translucent.fsh" and "minecraft/shaders/core/rendertype_entity_translucent.json"

#Put the player_animator folder inside your resource pack assets "resource_pack/assets/player_animator"

#Put the player_head.json model item file in your minecraft resource pack folder "minecraft/models/item/player_head.json"

##########################

#Put the player model template files in "Denizen/data/pmodels/templates/player_model_template_norm.json" and "Denizen/data/pmodels/templates/player_model_template_slim.json"

##External Bone Usage:
#Things to know:
# - External bones must be in a single bbmodel file
# - You can have multiple animations using the same external bone(s)
# - You can attach external bones to the player model's bones such as the right forearm if you want to
##How to use:
#Put your animated file with external bones in "Denizen/data/pmodels/animations"
#then run the command /pmodel reload
#Take the contents of "Denizen/data/pmodels/external_bones_res_pack" and put
#them in your resource pack assets.
#Zip your resource pack and enjoy.

#####################
##Config:
pmodel_config:
  type: data
  config:
    #load animations on server start this should generally be kept true
    load_on_start: true
    #reload scripts on player model reload (Should only be true when debugging)
    reload_scripts: true
    #item to use for external bones
    item: potion

#command for ops only (here you can reload the animations)
#/pmodel reload or /denizenplayermodels reload
pmodel_base_command:
  type: command
  debug: false
  name: denizenplayermodels
  usage: /denizenplayermodels
  aliases:
  - pmodel
  description: Pmodel command
  permission: op.op
  script:
  - if <context.args.get[1]> == reload && <player.is_op> || <context.source_type> == SERVER:
    - if <script[pmodel_config].data_key[config].get[reload_scripts].equals[true]>:
      - reload
    - ~run pmodels_load_bbmodel
    - narrate "[Denizen Player Models] Reloaded animations."

#############################
##API Usage
# # To spawn the player model
# - run pmodels_spawn_model def.location:<player.location> def.player:<player[FutureMaximus]> save:spawned
# - define root <entry[spawned].created_queue.determination.first>
# # To spawn the player model that only shows for one player (useful for cutscenes)
# - run pmodels_spawn_model def.location:<player.location> def.player:<player[FutureMaximus]> def.show_to:<player[FutureMaximus]> save:spawned
# - define root <entry[spawned].created_queue.determination.first>
# # To move the whole player model
# - teleport <[root]> <player.location>
# - run pmodels_reset_model_position def.root_entity:<[root]>
# # To start an automatic animation
# - run pmodels_animate def.root_entity:<[root]> def.animation:idle
# # To end an automatic animation
# - run pmodels_end_animation def.root_entity:<[root]>
# # To move the player model to a single frame of an animation (timespot is a decimal number of seconds from the start of the animation)
# - run pmodels_move_to_frame def.root_entity:<[root]> def.animation:idle def.timespot:0.5
# # To remove the player model
# - run pmodels_remove_model def.root_entity:<[root]>
# # To remove external parts of player model
# - run pmodels_remove_external_parts def.root_entity:<[root]>
###############################

# TODO:
# - Create utility tasks players can use for the player models such as the third person camera or moving
# - Add support for hand/offhand items with the ability to turn this off for certain animations
# - Add animation to animation transitions and ability to transition to default state 0,0,0
