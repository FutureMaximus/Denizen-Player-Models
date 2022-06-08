# Denizen-Player-Models
Animated Player Models in Java Minecraft!

With Denizen Player Models you can animate the player model to do anything you want whether it'd be emotes, a third person perspective type of game, or a cutscene the choice is yours!

Required resources:
- rendertype_entity_translucent core shader files
- DenizenModelsConverter by dmodels
- Custom player heads provided

Info:
The core shader will mess up placed player heads due to the texture uv coordinates
being changed by calculating vertex ids (amount of player heads present in player's view) no one has been able to 
find a solution to the placed player head problem and it's unlikely it will be solved but who knows.

The texture path for each bone in order is "head|hip|waist|chest|right_arm|right_forearm|left_arm|left_forearm|right_leg|right_foreleg|left_leg|left_foreleg"
if you want to make your own player model for some reason.

This uses elements from dmodels by mcmonkey to animate the player model. https://github.com/mcmonkeyprojects/DenizenModels
and has been modified here for use in the player model.

There are run tasks available for controlling the player models and a method of showing it to one player only.

Note: This is in beta so it's likely stuff will change.

Tested Denizen Version: REL-1771

Tested Minecraft Version: 1.18.2 (Might work with 1.17 since Tixco updated the shader file ask him not me I haven't been able to test it on 1.17 since I have some shader stuff of my own that don't work on 1.17.)
