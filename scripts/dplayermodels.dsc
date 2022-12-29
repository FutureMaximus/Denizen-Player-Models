###############################
# +---------------------------
# |
# | D e n i z e n   P l a y e r   M o d e l s
# |
# | Animated players in Java Minecraft!
# |
# +---------------------------
###############################

# @Contributors Max^, mcmonkey
# @Special thanks to mcmonkey for creating dmodels and making this possible for everyone!
# @date 2022/06/03
# @updated 2022/12/28
# @denizen-build REL-1776
# @script-version 1.6 BETA
# @Github https://github.com/FutureMaximus/Denizen-Player-Models

#=== Changelog for 1.6 ===

# - Removed need for template files
# - Implemented atlas support for 1.19.3
# - Reworked emote system

#=========================

## NOTICE: This will not work on Minecraft versions below 1.19.3 due to the resource pack changes and will not work with any other
## rendertype_entity_translucent core shader files it must be the one provided by mccosmetics or here.
## Tested Minecraft Version: 1.19.3

## Description:
# Denizen Player Models allows you to take the texture of any player or npc and animate them with a model of the player!
# For more control over the player models there is an API as well.
# I plan on adding more features such as mobility tasks in the future.

#================================ Information ==================================

#Uses elements from dmodels by mcmonkey https://github.com/mcmonkeyprojects/DenizenModels.

#For player emotes made by other people https://mcmodels.net/?product_cat=&post_type=product&s=Emote (Must be for the mccosmetics plugin not IA).

#Denizen Player Models allows the use of player model animations useful for emotes or cutscenes as a per player showing task is available.

#Compatible with the mccosmetics plugin

#=================================================================================

#================================= Installation ==================================

##Notice: If you have the mccosmetics core shader file and player_animator folder you can skip this part
# Put the core shader files provided in your resource pack minecraft shader folder
# "minecraft/shaders/core/rendertype_entity_translucent.vsh" ,"minecraft/shaders/core/rendertype_entity_translucent.fsh"
# and "minecraft/shaders/core/rendertype_entity_translucent.json"

# Put the player_animator folder inside your resource pack assets "resource_pack/assets/player_animator"

# Put the player_head.json model item file in your minecraft resource pack folder "minecraft/models/item/player_head.json"

#=================================================================================

#=================== External Bones Usage ==================

# Things to know:
# - External bones must be in a single bbmodel file
# - You can have multiple animations using the same external bone(s)
# - You can attach external bones to the player model's bones such as the right forearm if you want to
##How to use:
# Put your animated file with external bones in "Denizen/data/pmodels/animations"
# then run the command /pmodel reload
# Take the contents of "Denizen/data/pmodels/external_bones_res_pack" and put
# them in your resource pack assets.
# Zip your resource pack and enjoy.

#==========================================================-

#===== API Usage ==================

# Spawn the player model
# - run pmodels_spawn_model def.location:<player.location> def.player:<player[FutureMaximus]> save:spawned
# - define root <entry[spawned].created_queue.determination.first>
# Spawn the player model that only shows for one player (useful for cutscenes)
# - run pmodels_spawn_model def.location:<player.location> def.player:<player[FutureMaximus]> def.fake_to:<player[FutureMaximus]> save:spawned
# - define root <entry[spawned].created_queue.determination.first>
# Change the skin of a spawned player model (Input for player can be an npc such as <npc[0]>)
# - run pmodels_change_skin def.player:<player[FutureMaximus]> def.root_entity:<[root]>
# Move the player model
# - teleport <[root]> <player.location>
# - run pmodels_reset_model_position def.root_entity:<[root]>
# Start an animation
# - run pmodels_animate def.root_entity:<[root]> def.animation:idle
# End an animation
# - run pmodels_end_animation def.root_entity:<[root]>
# Move the player model to a single frame of an animation (timespot is a decimal number of seconds from the start of the animation)
# - run pmodels_move_to_frame def.root_entity:<[root]> def.animation:idle def.timespot:0.5
# Remove the player model
# - run pmodels_remove_model def.root_entity:<[root]>
# Remove external parts of player model
# - run pmodels_remove_external_parts def.root_entity:<[root]>

#====================================

#=================================== Config =================================================

pmodel_config:
  type: data
  config:
    # Load animations on server start
    load_on_start: false
    # Reload scripts on /pmodel reload
    reload_scripts: false
    # Item to use for external bones
    item: arrow

  #-Player model templates this should stay as is but you can change the custom model data
  templates:
    classic:
      order:
      - 778fa89c-759a-8884-89d9-238c555d2dc1
      - 9dc65952-10a9-876f-bd47-d6a7e9ec6183
      - 7e8426f1-08b2-81a2-7703-cb76ff5e7003
      - 5ef5d225-d5ae-6787-8838-b75ccb7a7a81
      - e297aef6-7dfd-f100-2e7c-ab113699b922
      - a0c01522-9040-7533-fa11-f6a45d3d96ac
      - 34097e46-c233-c03c-d8b9-aee154c9946f
      - bfc2f156-b48b-dd08-1b9e-777d8ada16b2
      - b3135254-0351-3462-2479-e6a3286c89ff
      - cf1618da-24d8-aab8-eebc-128815c02d35
      - 1a9070b5-b8b6-b955-9f31-54f9625f8f3d
      - c6d9e946-1d10-482d-14b1-0766027adba8
      - 1b5cc202-c09e-faa0-5057-eb4ae60bf336
      models:
        778fa89c-759a-8884-89d9-238c555d2dc1:
          name: player_root
          origin: 0,0,0
          rotation: 0,0,0
          parent: none
        9dc65952-10a9-876f-bd47-d6a7e9ec6183:
          item: player_head[custom_model_data=8]
          name: hip
          origin: 0,11.25,0
          rotation: 0,0,0
          parent: 778fa89c-759a-8884-89d9-238c555d2dc1
        7e8426f1-08b2-81a2-7703-cb76ff5e7003:
          item: player_head[custom_model_data=9]
          name: right_leg
          origin: 1.875,11.25,0
          rotation: 0,0,0
          parent: 778fa89c-759a-8884-89d9-238c555d2dc1
        5ef5d225-d5ae-6787-8838-b75ccb7a7a81:
          item: player_head[custom_model_data=9]
          name: left_leg
          origin: -1.875,11.25,0
          rotation: 0,0,0
          parent: 778fa89c-759a-8884-89d9-238c555d2dc1
        e297aef6-7dfd-f100-2e7c-ab113699b922:
          item: player_head[custom_model_data=8]
          name: waist
          origin: 0,15,0
          rotation: 0,0,0
          parent: 9dc65952-10a9-876f-bd47-d6a7e9ec6183
        a0c01522-9040-7533-fa11-f6a45d3d96ac:
          item: player_head[custom_model_data=8]
          name: chest
          origin: 0,18.75,0
          rotation: 0,0,0
          parent: e297aef6-7dfd-f100-2e7c-ab113699b922
        34097e46-c233-c03c-d8b9-aee154c9946f:
          item: player_head[custom_model_data=1]
          name: head
          origin: 0,22.5,0
          rotation: 0,0,0
          parent: a0c01522-9040-7533-fa11-f6a45d3d96ac
        bfc2f156-b48b-dd08-1b9e-777d8ada16b2:
          item: player_head[custom_model_data=2]
          name: right_arm
          origin: 5,21,0
          rotation: 0,0,0
          parent: a0c01522-9040-7533-fa11-f6a45d3d96ac
        b3135254-0351-3462-2479-e6a3286c89ff:
          item: player_head[custom_model_data=3]
          name: left_arm
          origin: -5,21,0
          rotation: 0,0,0
          parent: a0c01522-9040-7533-fa11-f6a45d3d96ac
        cf1618da-24d8-aab8-eebc-128815c02d35:
          item: player_head[custom_model_data=4]
          name: right_forearm
          origin: 5.625,16.875,0
          rotation: 0,0,0
          parent: bfc2f156-b48b-dd08-1b9e-777d8ada16b2
        1a9070b5-b8b6-b955-9f31-54f9625f8f3d:
          item: player_head[custom_model_data=4]
          name: left_forearm
          origin: -5.625,16.875,0
          rotation: 0,0,0
          parent: b3135254-0351-3462-2479-e6a3286c89ff
        c6d9e946-1d10-482d-14b1-0766027adba8:
          item: player_head[custom_model_data=9]
          name: right_foreleg
          origin: 1.875,5.625,0
          rotation: 0,0,0
          parent: 7e8426f1-08b2-81a2-7703-cb76ff5e7003
        1b5cc202-c09e-faa0-5057-eb4ae60bf336:
          item: player_head[custom_model_data=9]
          name: left_foreleg
          origin: -1.875,5.625,0
          rotation: 0,0,0
          parent: 5ef5d225-d5ae-6787-8838-b75ccb7a7a81

    slim:
      order:
      - 778fa89c-759a-8884-89d9-238c555d2dc1
      - 9dc65952-10a9-876f-bd47-d6a7e9ec6183
      - 7e8426f1-08b2-81a2-7703-cb76ff5e7003
      - 5ef5d225-d5ae-6787-8838-b75ccb7a7a81
      - e297aef6-7dfd-f100-2e7c-ab113699b922
      - a0c01522-9040-7533-fa11-f6a45d3d96ac
      - 34097e46-c233-c03c-d8b9-aee154c9946f
      - bfc2f156-b48b-dd08-1b9e-777d8ada16b2
      - b3135254-0351-3462-2479-e6a3286c89ff
      - cf1618da-24d8-aab8-eebc-128815c02d35
      - 1a9070b5-b8b6-b955-9f31-54f9625f8f3d
      - c6d9e946-1d10-482d-14b1-0766027adba8
      - 1b5cc202-c09e-faa0-5057-eb4ae60bf336
      models:
        778fa89c-759a-8884-89d9-238c555d2dc1:
          name: player_root
          origin: 0,0,0
          rotation: 0,0,0
          parent: none
        9dc65952-10a9-876f-bd47-d6a7e9ec6183:
          item: player_head[custom_model_data=8]
          name: hip
          origin: 0,11.25,0
          rotation: 0,0,0
          parent: 778fa89c-759a-8884-89d9-238c555d2dc1
        7e8426f1-08b2-81a2-7703-cb76ff5e7003:
          item: player_head[custom_model_data=9]
          name: right_leg
          origin: 1.875,11.25,0
          rotation: 0,0,0
          parent: 778fa89c-759a-8884-89d9-238c555d2dc1
        5ef5d225-d5ae-6787-8838-b75ccb7a7a81:
          item: player_head[custom_model_data=9]
          name: left_leg
          origin: -1.875,11.25,0
          rotation: 0,0,0
          parent: 778fa89c-759a-8884-89d9-238c555d2dc1
        e297aef6-7dfd-f100-2e7c-ab113699b922:
          item: player_head[custom_model_data=8]
          name: waist
          origin: 0,15,0
          rotation: 0,0,0
          parent: 9dc65952-10a9-876f-bd47-d6a7e9ec6183
        a0c01522-9040-7533-fa11-f6a45d3d96ac:
          item: player_head[custom_model_data=8]
          name: chest
          origin: 0,18.75,0
          rotation: 0,0,0
          parent: e297aef6-7dfd-f100-2e7c-ab113699b922
        34097e46-c233-c03c-d8b9-aee154c9946f:
          item: player_head[custom_model_data=1]
          name: head
          origin: 0,22.5,0
          rotation: 0,0,0
          parent: a0c01522-9040-7533-fa11-f6a45d3d96ac
        bfc2f156-b48b-dd08-1b9e-777d8ada16b2:
          item: player_head[custom_model_data=5]
          name: right_arm
          origin: 4.74,21,0
          rotation: 0,0,0
          parent: a0c01522-9040-7533-fa11-f6a45d3d96ac
        b3135254-0351-3462-2479-e6a3286c89ff:
          item: player_head[custom_model_data=6]
          name: left_arm
          origin: -4.74,21,0
          rotation: 0,0,0
          parent: a0c01522-9040-7533-fa11-f6a45d3d96ac
        cf1618da-24d8-aab8-eebc-128815c02d35:
          item: player_head[custom_model_data=7]
          name: right_forearm
          origin: 5.15,16.875,0
          rotation: 0,0,0
          parent: bfc2f156-b48b-dd08-1b9e-777d8ada16b2
        1a9070b5-b8b6-b955-9f31-54f9625f8f3d:
          item: player_head[custom_model_data=7]
          name: left_forearm
          origin: -5.15,16.875,0
          rotation: 0,0,0
          parent: b3135254-0351-3462-2479-e6a3286c89ff
        c6d9e946-1d10-482d-14b1-0766027adba8:
          item: player_head[custom_model_data=9]
          name: right_foreleg
          origin: 1.875,5.625,0
          rotation: 0,0,0
          parent: 7e8426f1-08b2-81a2-7703-cb76ff5e7003
        1b5cc202-c09e-faa0-5057-eb4ae60bf336:
          item: player_head[custom_model_data=9]
          name: left_foreleg
          origin: -1.875,5.625,0
          rotation: 0,0,0
          parent: 5ef5d225-d5ae-6787-8838-b75ccb7a7a81

#====================================================================================================

#======= Main Command =================

# Executed with /denizenplayermodels or /pmodels
pmodel_base_command:
  type: command
  debug: false
  name: denizenplayermodels
  usage: /denizenplayermodels
  aliases:
  - pmodels
  description: Main command for Denizen Player Models
  permission: op.op
  script:
  - if <context.args.get[1]> == reload && <player.is_op> || <context.source_type> == SERVER:
    - if <script[pmodel_config].data_key[config].get[reload_scripts].equals[true]>:
      - reload
    - ~run pmodels_load_bbmodel save:result
    - define animation_count <entry[result].created_queue.determination.first>
    - narrate "[Denizen Player Models] Loaded <[animation_count]> animations."

#======================================
