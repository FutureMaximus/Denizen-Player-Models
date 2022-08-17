###########################
# This loads animations for Denizen Player Models including any external bones utilized
# in the animations which are then put into a resource pack
###########################

pmodels_load_bbmodel:
    type: task
    debug: false
    script:
    # =============== Clear out pre-existing data ===============
    - flag server pmodels_data.model_player_model_template_norm:!
    - flag server pmodels_data.model_player_model_template_slim:!
    - flag server pmodels_data.animations_player_model_template_norm:!
    - flag server pmodels_data.animations_player_model_template_slim:!
    # ============== Animation Gathering ===============
    - define animation_files <util.list_files[data/pmodels/animations]||null>
    - if <[animation_files]> == null:
      - debug error "[Denizen Player Models] Could not find animations folder in data/pmodels"
    - else if <[animation_files].is_empty>:
      - debug error "[Denizen Player Models] Could not find player model animations in data/pmodels/animations"
    - else:
      - foreach <[animation_files]> as:anim_file_raw:
        - define check <[anim_file_raw].split[.]>
        - if <[check].contains[bbmodel]>:
            - define animation_file <[anim_file_raw].replace[.bbmodel].with[<empty>]>
        - else:
            - debug error "[Denizen Player Models] There is an invalid file in data/pmodels/animations <[anim_file_raw]> is it a block bench file?"
            - foreach next
        # =============== Prep ===============
        - define pack_root data/pmodels/external_bones_res_pack
        - define models_root <[pack_root]>/assets/minecraft/models/item/pmodels/<[animation_file]>
        - define textures_root <[pack_root]>/assets/minecraft/textures/pmodels/<[animation_file]>
        - define item_validate <item[<script[pmodel_config].data_key[config].get[item]>]||null>
        - if <[item_validate]> == null:
          - debug error "[Denizen Player Models] Warning: The item specified in the config is an invalid item external bones will not generate"
        - define override_item_filepath <[pack_root]>/assets/minecraft/models/item/<script[pmodel_config].data_key[config].get[item]>.json
        - define file data/pmodels/animations/<[animation_file]>.bbmodel
        - define scale_factor <element[2.285].div[4]>
        - define mc_texture_data <map>
        - flag server pmodels_data.temp_<[animation_file]>:!
        # =============== BBModel loading and validation ===============
        - if !<util.has_file[<[file]>]>:
            - debug error "[Denizen Player Models] Cannot load model '<[animation_file]>' because file '<[file]>' does not exist."
            - stop
        - ~fileread path:<[file]> save:filedata
        - define data <util.parse_yaml[<entry[filedata].data.utf8_decode||>]||>
        - if !<[data].is_truthy>:
            - debug error "[Denizen Player Models] Something went wrong trying to load BBModel data for model '<[animation_file]>' - fileread invalid."
            - stop
        - define meta <[data.meta]||>
        - define resolution <[data.resolution]||>
        - if !<[meta].is_truthy> || !<[resolution].is_truthy>:
            - debug error "[Denizen Player Models] Something went wrong trying to load BBModel data for model '<[animation_file]>' - possibly not a valid BBModel file?"
            - stop
        - if !<[data.elements].exists>:
            - debug error "[Denizen Player Models] Can't load bbmodel for '<[animation_file]>' - file has no elements?"
            - stop
        # =============== Pack validation ===============
        - if <[item_validate]> != null:
            - if !<server.has_flag[data/pmodels/external_bones_res_pack/pack.mcmeta]>:
                - filewrite path:data/pmodels/external_bones_res_pack/pack.mcmeta data:<map.with[pack].as[<map[pack_format=8;description=denizen_player_models_pack]>].to_json[native_types=true;indent=4].utf8_encode>
        # =============== Elements loading ===============
        #Reason for loading elements before is to skip the player model texture
        - foreach <[data.elements]> as:element:
            - if <[element.type]> != cube:
                - foreach next
            - define name <[element.name]>
            #Excluded player model texture id
            - choose <[name]>:
                - case skin:
                    - define texture_exclude_id <[element.faces.north.texture]>
                - case hat:
                    - define texture_exclude_id <[element.faces.north.texture]>
            - define element.origin <[element.origin].separated_by[,]||0,0,0>
            - define element.rotation <[element.rotation].separated_by[,]||0,0,0>
            - define flagname pmodels_data.model_<[animation_file]>.namecounter_element.<[element.name]>
            - flag server <[flagname]>:++
            - if <server.flag[<[flagname]>]> > 1:
                - define element.name <[element.name]><server.flag[<[flagname]>]>
            - flag server pmodels_data.temp_<[animation_file]>.raw_elements.<[element.uuid]>:<[element]>
        # =============== Textures loading ===============
        - define tex_id 0
        - foreach <[data.textures]||<list>> as:texture:
            - define texname <[texture.name]>
            - if <[texname].ends_with[.png]>:
                - define texname <[texname].before[.png]>
            - define raw_source <[texture.source]||>
            - if !<[raw_source].starts_with[data:image/png;base64,]>:
                - debug error "Can't load bbmodel for '<[animation_file]>': invalid texture source data."
                - stop
            - define texture_exclude_id <[texture_exclude_id]||null>
            #If the texture equals the excluded texture skip it
            - if <[texture_exclude_id]> != null:
                - if <[tex_id]> == <[texture_exclude_id]>:
                    - define tex_id:++
                    - foreach next
            - define texture_output_path <[textures_root]>/<[texname]>.png
            - if <[item_validate]> != null:
              - ~filewrite path:<[texture_output_path]> data:<[raw_source].after[,].base64_to_binary>
            - define proper_path pmodels/<[animation_file]>/<[texname]>
            - define mc_texture_data.<[tex_id]> <[proper_path]>
            - if <[texture.particle]||false>:
                - define mc_texture_data.particle <[proper_path]>
            - define tex_id:++
        # =============== Outlines loading ===============
        - define root_outline null
        - foreach <[data.outliner]||<list>> as:outliner:
            - if <[outliner].matches_character_set[abcdef0123456789-]>:
                - if <[root_outline]> == null:
                    - definemap root_outline name:__root__ origin:0,0,0 rotation:0,0,0 uuid:<util.random_uuid>
                    - flag server pmodels_data.temp_<[animation_file]>.raw_outlines.<[root_outline.uuid]>:<[root_outline]>
                - run pmodels_loader_addchild def.animation_file:<[animation_file]> def.parent:<[root_outline]> def.child:<[outliner]>
            - else:
                - define outliner.parent:none
                - run pmodels_loader_readoutline def.animation_file:<[animation_file]> def.outline:<[outliner]>
        # =============== Animations loading ===============
        - foreach <[data.animations]||<list>> as:animation:
            - define anim_count:++
            - define animation_list.<[animation.name]>.loop <[animation.loop]>
            - define animation_list.<[animation.name]>.length <[animation.length]>
            - define animator_data <[animation.animators]||<list>>
            # If the animation contains the outliners gather the data otherwise make an empty frame
            - if !<server.has_flag[pmodels_data.temp_<[animation_file]>.raw_outlines]>:
              - foreach next
            - foreach <server.flag[pmodels_data.temp_<[animation_file]>.raw_outlines]> key:o_uuid as:outline_data:
              - define animator <[animator_data.<[o_uuid]>]||null>
              - if <[animator]> == null:
                - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames <list>
              - else:
                - define keyframes <[animator.keyframes]>
                - foreach <[keyframes]> as:keyframe:
                    - define channel <[keyframe.channel]>
                    - definemap anim_map channel:<[channel]> time:<[keyframe.time]> interpolation:<[keyframe.interpolation]>
                    - define data_points <[keyframe.data_points].first>
                    - if <[channel]> == rotation:
                        - define anim_map.data <[data_points.x].trim.to_radians>,<[data_points.y].trim.to_radians>,<[data_points.z].trim.to_radians>
                    - else:
                        - define anim_map.data <[data_points.x].trim>,<[data_points.y].trim>,<[data_points.z].trim>
                    - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.<[channel]>:->:<[anim_map]>
                #Time sort
                - if <[animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.position]||null> != null:
                    - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.position <[animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.position].sort_by_value[get[time]]>
                - if <[animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.rotation]||null> != null:
                    - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.rotation <[animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.rotation].sort_by_value[get[time]]>
            #Set before and after data based on interpolation methods
            - foreach <[animation_list.<[animation.name]>.animators]> key:a_uuid as:keyframe:
              - foreach position|rotation as:channel:
                - define new_frame_list:!
                - define frame_list <[keyframe.frames.<[channel]>]||null>
                - if <[frame_list]> == null:
                  - foreach next
                - foreach <[frame_list]> as:frame:
                    - define time <[frame.time]>
                    - define new_frame <[frame]>
                    - define after <[frame_list].filter[get[time].is_more_than[<[time]>]].first||<[frame]>>
                    - define new_frame.after <[after]>
                    - if <[frame.interpolation]> == catmullrom:
                        - define before_extra <[frame_list].filter[get[time].is_less_than[<[time]>]].last||<[frame]>>
                        - define new_frame.before_extra <[before_extra]>
                        - define after_extra <[frame_list].filter[get[time].is_more_than[<[after.time]>]].first||<[after]>>
                        - define new_frame.after_extra <[after_extra]>
                    - define new_frame_list:->:<[new_frame]>
                - define animation_list.<[animation.name]>.animators.<[a_uuid]>.frames.<[channel]>:<[new_frame_list]||<list>>
            #- ~filewrite path:data/pmodels/debug/<[animation.name]>.json data:<[animation_list.<[animation.name]>.animators].to_json[native_types=true;indent=4].utf8_encode>
        # =============== Item model file generation ===============
        - if <util.has_file[<[override_item_filepath]>]>:
            - ~fileread path:<[override_item_filepath]> save:override_item
            - define override_item_data <util.parse_yaml[<entry[override_item].data.utf8_decode>]>
        - else:
            - definemap override_item_data parent:minecraft:item/generated textures:<map[layer0=minecraft:item/<script[pmodel_config].data_key[config].get[item]||splash_potion>]>
        - define overrides_changed false
        - foreach <server.flag[pmodels_data.temp_<[animation_file]>.raw_outlines]> as:outline:
            - define outline_origin <location[<[outline.origin]>]>
            - define model_json.textures <[mc_texture_data]>
            - define model_json.elements <list>
            - define child_count 0
            #### Element building
            - foreach <server.flag[pmodels_data.temp_<[animation_file]>.raw_elements]> as:element:
                - if <[outline.children].contains[<[element.uuid]>]||false>:
                    - define child_count:++
                    - define jsonelement.name <[element.name]>
                    - define rot <location[<[element.rotation]>]>
                    - define jsonelement.from <location[<[element.from].separated_by[,]>].sub[<[outline_origin]>].mul[<[scale_factor]>].xyz.split[,]>
                    - define jsonelement.to <location[<[element.to].separated_by[,]>].sub[<[outline_origin]>].mul[<[scale_factor]>].xyz.split[,]>
                    - define jsonelement.rotation.origin <location[<[element.origin]>].sub[<[outline_origin]>].mul[<[scale_factor]>].xyz.split[,]>
                    - if <[rot].x> != 0:
                        - define jsonelement.rotation.axis x
                        - define jsonelement.rotation.angle <[rot].x>
                    - else if <[rot].z> != 0:
                        - define jsonelement.rotation.axis z
                        - define jsonelement.rotation.angle <[rot].z>
                    - else:
                        - define jsonelement.rotation.axis y
                        - define jsonelement.rotation.angle <[rot].y>
                    - foreach <[element.faces]> key:faceid as:face:
                        - define jsonelement.faces.<[faceid]> <[face].proc[pmodels_facefix].context[<[resolution]>]>
                    - define model_json.elements:->:<[jsonelement]>
            - define outline.children:!
            - if <[child_count]> > 0:
                #### Item override building
                # Check for player model bones if they are there do not generate the item file
                - define find <script[pmodels_excluded_bones].data_key[bones].find[<[outline.name]>]>
                - if <[find]> == -1:
                    - definemap json_group name:<[outline.name]> color:0 children:<util.list_numbers[from=0;to=<[child_count]>]> origin:<[outline_origin].mul[<[scale_factor]>].xyz.split[,]>
                    - define model_json.groups <list[<[json_group]>]>
                    - define model_json.display.head.translation <list[32|25|32]>
                    - define model_json.display.head.scale <list[4|4|4]>
                    - define modelpath item/pmodels/<[animation_file]>/<[outline.name]>
                    - if <[item_validate]> != null:
                      - ~filewrite path:<[models_root]>/<[outline.name]>.json data:<[model_json].to_json[native_types=true;indent=4].utf8_encode>
                    - define cmd 0
                    - define min_cmd 1000
                    - foreach <[override_item_data.overrides]||<list>> as:override:
                        - if <[override.model]> == <[modelpath]>:
                            - define cmd <[override.predicate.custom_model_data]>
                        - define min_cmd <[min_cmd].max[<[override.predicate.custom_model_data].add[1]||1000>]>
                    - if <[cmd]> == 0:
                        - define cmd <[min_cmd]>
                        - define override_item_data.overrides:->:<map[predicate=<map[custom_model_data=<[cmd]>]>].with[model].as[<[modelpath]>]>
                        - define overrides_changed true
                    - define outline.item <script[pmodel_config].data_key[config].get[item]>[custom_model_data=<[cmd]>]
                    # Identifier for external bone
                    - define outline.type external
            # Exclude player model bones
            - define find <script[pmodels_excluded_bones].data_key[bones].find[<[outline.name]>]>
            - if <[find]> == -1:
                - define external_count:++
                ## This sets the actual live usage flag data for external bones should they exist
                - flag server pmodels_data.model_player_model_template_norm.<[outline.uuid]>:<[outline]>
                - flag server pmodels_data.model_player_model_template_slim.<[outline.uuid]>:<[outline]>
        - if <[item_validate]> != null:
            - if <[overrides_changed]>:
                - ~filewrite path:<[override_item_filepath]> data:<[override_item_data].to_json[native_types=true;indent=4].utf8_encode>
        # Final clear of temp data
        - flag server pmodels_data.temp_<[animation_file]>:!
    # Set the animations
    - if <[animation_list].any||false>:
        - flag server pmodels_data.animations_player_model_template_norm:<[animation_list]>
        - flag server pmodels_data.animations_player_model_template_slim:<[animation_list]>
    # ============= Template Loading ===============
    #TODO:
    #- No longer need the json files and give ability to customize custom model data in pmodels config
    - define norm_path data/pmodels/templates
    - define slim_path data/pmodels/templates
    - ~fileread path:<[norm_path]>/player_model_template_norm.json save:norm_read
    - ~fileread path:<[slim_path]>/player_model_template_slim.json save:slim_read
    - define norm_data <util.parse_yaml[<entry[norm_read].data.utf8_decode>]||null>
    - define slim_data <util.parse_yaml[<entry[slim_read].data.utf8_decode>]||null>
    - if <[norm_data]> == null || <[slim_data]> == null:
      - debug error "Could not find template files in data/pmodels/templates"
      - stop
    - flag server pmodels_data.template_data.norm:<[norm_data]>
    - flag server pmodels_data.template_data.slim:<[slim_data]>
    - define norm_models <[norm_data.models]>
    - define slim_models <[slim_data.models]>
    # Texture path for player model
    - define load_order <list[player_root|head|hip|waist|chest|right_arm|right_forearm|left_arm|left_forearm|right_leg|right_foreleg|left_leg|left_foreleg]>
    - foreach <[load_order]> as:tex_name:
      # Norm
      - foreach <[norm_models]> key:uuid as:model:
        - if <[model.name]> == <[tex_name]>:
          - define norm_models.<[uuid]>.type default
          - flag server pmodels_data.model_player_model_template_norm.<[uuid]>:<[norm_models.<[uuid]>]>
      # Slim
      - foreach <[slim_models]> key:uuid as:model:
        - if <[model.name]> == <[tex_name]>:
          - define slim_models.<[uuid]>.type default
          - flag server pmodels_data.model_player_model_template_slim.<[uuid]>:<[slim_models.<[uuid]>]>
    - announce to_console "[Denizen Player Models] <[anim_count]||0> Animations have been loaded."
    - define extern_count <[external_count]||null>
    - if <[extern_count]> != null:
      - announce to_console "[Denizen Player Models] <[external_count]> External bones have been loaded."
    ##Debug
    #- ~filewrite path:data/pmodels/debug_data/player_models_norm.json data:<server.flag[pmodels_data.model_player_model_template_norm].to_json[native_types=true;indent=4].utf8_encode>
    #- ~filewrite path:data/pmodels/debug_data/player_models_slim.json data:<server.flag[pmodels_data.model_player_model_template_slim].to_json[native_types=true;indent=4].utf8_encode>

# Bones that cannot be generated in the resource pack
pmodels_excluded_bones:
    type: data
    bones:
    - player_root
    - head
    - hip
    - waist
    - chest
    - right_arm
    - right_forearm
    - left_arm
    - left_forearm
    - right_leg
    - right_foreleg
    - left_leg
    - left_foreleg

pmodels_facefix:
    type: procedure
    debug: false
    definitions: facedata|resolution
    script:
    - define uv <[facedata.uv]>
    - define out.texture #<[facedata.texture]>
    - define mul_x <element[16].div[<[resolution.width]>]>
    - define mul_y <element[16].div[<[resolution.height]>]>
    - define out.uv <list[<[uv].get[1].mul[<[mul_x]>]>|<[uv].get[2].mul[<[mul_y]>]>|<[uv].get[3].mul[<[mul_x]>]>|<[uv].get[4].mul[<[mul_y]>]>]>
    - determine <[out]>

pmodels_loader_addchild:
    type: task
    debug: false
    definitions: animation_file|parent|child
    script:
    - if <[child].matches_character_set[abcdef0123456789-]>:
        - define elementflag pmodels_data.temp_<[animation_file]>.raw_elements.<[child]>
        - define element <server.flag[<[elementflag]>]||null>
        - if <[element]> == null:
            - stop
        - define valid_rots 0|22.5|45|-22.5|-45
        - define rot <location[<[element.rotation]>]>
        - define xz <[rot].x.equals[0].if_true[0].if_false[1]>
        - define yz <[rot].y.equals[0].if_true[0].if_false[1]>
        - define zz <[rot].z.equals[0].if_true[0].if_false[1]>
        - define count <[xz].add[<[yz]>].add[<[zz]>]>
        - if <[rot].x> in <[valid_rots]> && <[rot].y> in <[valid_rots]> && <[rot].z> in <[valid_rots]> && <[count]> < 2:
            - flag server pmodels_data.temp_<[animation_file]>.raw_outlines.<[parent.uuid]>.children:->:<[child]>
        - else:
            - definemap new_outline name:<[parent.name]>_auto_<[element.name]> origin:<[element.origin]> rotation:<[element.rotation]> uuid:<util.random_uuid> parent:<[parent.uuid]> children:<list[<[child]>]>
            - flag server pmodels_data.temp_<[animation_file]>.raw_outlines.<[new_outline.uuid]>:<[new_outline]>
            - flag server <[elementflag]>.rotation:0,0,0
            - flag server <[elementflag]>.origin:0,0,0
    - else:
        - define child.parent:<[parent.uuid]>
        - run pmodels_loader_readoutline def.animation_file:<[animation_file]> def.outline:<[child]>

pmodels_loader_readoutline:
    type: task
    debug: false
    definitions: animation_file|outline
    script:
    - definemap new_outline name:<[outline.name]> uuid:<[outline.uuid]> origin:<[outline.origin].separated_by[,]||0,0,0> rotation:<[outline.rotation].separated_by[,]||0,0,0> parent:<[outline.parent]||none>
    - define flagname pmodels_data.model_<[animation_file]>.namecounter_outline.<[outline.name]>
    - define raw_children <[outline.children]||<list>>
    - define outline.children:!
    - flag server pmodels_data.temp_<[animation_file]>.raw_outlines.<[new_outline.uuid]>:<[new_outline]>
    - foreach <[raw_children]> as:child:
        - run pmodels_loader_addchild def.animation_file:<[animation_file]> def.parent:<[outline]> def.child:<[child]>
