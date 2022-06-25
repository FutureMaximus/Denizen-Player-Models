# Denizen-Player-Models
Animated Player Models in Java Minecraft!

With Denizen Player Models you can animate a player model to do anything you want whether it'd be emotes, a third person perspective type of gamemode, or a cutscene the choice is yours!

Required resources:
- rendertype_entity_translucent core shader files
- DenizenModelsConverter by dmodels
- Custom player heads provided

Info:
The core shader will mess up placed player heads due to the texture uv coordinates
being changed by calculating vertex ids (amount of player heads present in player's view in simpler terms) no one has been able to 
find a solution to the placed player head problem and it's unlikely it will be solved but who knows.

![image](https://user-images.githubusercontent.com/97306922/175753617-7e7b8bcb-2106-4498-9cd6-9d74103daf29.png)


Does it work with optifine?
If your just using optifine then yes but if it's with a shader pack like BSL that will mess up the texturing.

The texture path for each bone in order is "head|hip|waist|chest|right_arm|right_forearm|left_arm|left_forearm|right_leg|right_foreleg|left_leg|left_foreleg"
if you want to make your own player model for some reason.

This uses elements from dmodels by mcmonkey to animate the player model. https://github.com/mcmonkeyprojects/DenizenModels
and has been modified here for use in the player model.

There are run tasks available for controlling the player model and a method of showing it to one player only.

Note: This is in beta so it's likely stuff will change.

Tested Denizen Version: REL-1771

Tested Minecraft Version: 1.18.2 (Might work with 1.17 since Tixco updated the shader file ask him not me I haven't been able to test it on 1.17 since I have some shader stuff of my own that don't work on 1.17.)

Compatible with the mccosmetics plugin https://mythiccraft.io/index.php?resources/mccosmetics-the-ultimate-cosmetics-plugin.818/

Warning: Please do not change the player model bone names as the script relies on them for data gathering and external bones are fine of course.
