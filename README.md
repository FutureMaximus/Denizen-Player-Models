# Denizen Player Models
Animated Player Models in Java Minecraft!

![dplayermodels_gif_3](https://user-images.githubusercontent.com/97306922/175800382-ceec984e-1fc7-469e-be00-0aecfd0153f3.gif)

# Wiki
https://github.com/FutureMaximus/Denizen-Player-Models/wiki

# Info
This requires Denizen Models by mcmonkey https://github.com/mcmonkeyprojects/DenizenModels

With Denizen Player Models you can animate a player model to do anything you want whether it'd be emotes, a third person perspective type of gamemode, or a cutscene the choice is yours!

Required resources:
- rendertype_entity_translucent core shader files
- DenizenModelsConverter by dmodels
- Custom player heads provided

Info:
The core shader will mess up placed player heads due to the texture uv coordinates
being changed by calculating vertex ids (amount of player heads present in player's view in simpler terms) no one has been able to 
find a solution to the placed player head problem and it's unlikely it will be solved but who knows.


Does it work with optifine?
If your just using optifine then yes but if it's with a shader pack like BSL that will mess up the texturing.

The texture path for each bone in order is "head|hip|waist|chest|right_arm|right_forearm|left_arm|left_forearm|right_leg|right_foreleg|left_leg|left_foreleg"
if you want to make your own player model for some reason.

This uses elements from dmodels by mcmonkey to animate the player model. https://github.com/mcmonkeyprojects/DenizenModels
and has been modified here for use in the player model.

There are run tasks available for controlling the player model and a method of showing it to one player only.

Note: This is in beta so it's likely stuff will change.

Warning: Please do not change the player model bone names as the script relies on them for data gathering and external bones are fine of course.
