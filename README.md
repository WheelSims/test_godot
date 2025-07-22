# test_godot: Wheelchair simulator VR

```{warning}
This is a work in progress.
```

This is a repository of [Godot](https://godotengine.org/) code and assets that implement the VR portion of the IRGLM Simulator in Montreal. This code should be eventually extensible to other wheelchair simulators.

## File structure

All the code is in the `src` folder.

The toplevel scenes to be loaded on the simulator (file ends with `_on_simulator.tscn`) and on a computer for programming and debugging (file ends with `_on_keyboard.tscn`) are in the toplevel `src` folder. They all consist of two units:

- An instance of something a navigate into, be it an environment or a game;
- An instance of a player (either PlayerOnSimulator or PlayerOnKeyboard).

Environments are assemblies of terrain and objects, including NPCs such as pedestrians and cars. Each environment is a `tscn` scene saved in the `Environments` folder.

Games generally include an instance of an environment, accompanied with game logic and assets. Each game is an `tscn` scene saved in the `Games` folder.

There are two types of player:

- Player on simulator;
- Player on keyboard.

The player on keyboard is built to develop the software on a standard computer. It has only one camera, is controlled only via the keyboard and does not attempt to connect to external components such as motors, motion platform, or motion capture. It is saved as `player_on_keyboard.tscn` in the `Player` folder.

The player on simulator has more components, such as multiple cameras, and communications nodes/scripts for the motion platform, motors and motion capture devices. It is saved as `player_on_simulator.tscn` in the `Player` folder.

## Naming conventions

We try to follow [Godot's guidelines](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).

