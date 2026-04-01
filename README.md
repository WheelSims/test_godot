# wheelsims

This is a work in progress. The information below is outdated. The most up-to-date info is [here](https://github.com/WheelSims/wheelsims_doc/blob/main/README.md)

---

This is the main repository for the WheelSims project. It contains [Godot](https://godotengine.org/) code and assets that implement the VR portion of the IRGLM Simulator in Montreal. This code should be eventually extensible to other wheelchair simulators.

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

---

# 🏁 Race System – Overview & Implementation Guide

## 📐 Architecture

The race system is built around a unified class: `Race`.  
This class defines the core structure and behavior of all race modes with the following methods:

- `update()`
- `is_finished()`

These functions are executed by the `race_manager`, which also communicates with the UI.  
The system is designed to be **scalable**, allowing the user to easily choose and switch between different race modes.

---

## 🏎️ Available Race Modes

### 🟢 Distance Challenge
- **Goal**: Go as far as possible within a defined time limit.
- **End Condition**: Automatically ends when the timer runs out.

### 🔵 Time Trial
- **Goal**: Reach the finish line as fast as possible.
- **End Condition**: Race ends when the player travelled the setted distance.

---

## ✨ Race Features

### ➤ Arrows On Path
- Uses a **path** to draw **directional arrows** on the track.
- The arrow resolution can be customized to change the visual density.

### 👏 Crowd Interaction
- **Crowd zones** can be placed in the environment.
- If the player passes nearby **while a race is active**, the crowd reacts with **cheers and applause**!
- Must be **linked to a specific `race_manager`** to track race state.

---

## 🔓 Player Freedom

Unlike traditional racing games, **no hard constraints are placed on the player's movement** during the race lifecycle.

For example:
- Players can move **during the countdown** before a race starts.

This design choice ensures compatibility with simulation environments, avoiding unintended restrictions or conflicts.

---

## 🧩 PrefabScenes Overview

### 🏁 RaceScene
Includes:
- UI Canvas for the race
- `race_manager`
- Path for arrows

### 👥 CrowdScene
Includes:
- A group of animated human characters (the crowd)
- A trigger area to detect the player's presence

🛠️ **Note**:  
Make sure to **link the CrowdPrefab to the appropriate `race_manager`** so it knows when the race is active.

---

# 🚦 Traffic Light System – Overview & Implementation Guide

## 🎨 Visual Components
### ➤ Light Materials
- **Lights ON**: Materials with **emission enabled** for glowing effect
- **Lights OFF**: Other materials almost similar but with **emission disabled**
- **Pedestrian Symbols**: Two sprites for the orange hand and the character sprite
- **Pedestrian Counter**: implemented using a MeshInstance3D to display the countdown.
---

## ⚙️ Script Architecture
### 🚦 Traffic Light Behavior (`traffic_light` script)
Each individual traffic light includes:
- **State Management**: Controls light sequence using `LightState` enum: `{ RED, GREEN, YELLOW }`
- **Virtual Obstacle**: Movable collision object that **blocks or allows** car passage
- **Direction Property**: Defines orientation (`NS` or `EW`)

### 🚶 Pedestrian Traffic Light Behavior (`pedestrian_traffic_light` script)
Each individual traffic light includes:
- **Timer Node**: `blink_timer` controls the blinking of the orange hand symbol.
- **Virtual Obstacle**: Movable collision object that **blocks or allows** pedestrian passage
- **Direction Property**: Defines orientation (`NS` or `EW`)

### 🏘️ Intersection Controller (`traffic_light_manager` script)
- **Centralized Control**: Manages multiple traffic lights (both types) at an intersection
- **Direction-Based Logic**: Activates lights based on their **direction property**
- **Automatic Cycling**: Switches active direction every `green_light_duration` + `yellow_light_duration` seconds
- **Pedestrian light handling**: `walk_man_ratio` defines the duration of the walking symbol relative to the cycle.
- **Configurable Timing**: `green_light_duration` can be **adjusted in the Inspector**

---

## 🔄 System Flow
1. `traffic_light_manager` determines which direction should have car traffic lights and pedestrian traffic lights
4. Individual `traffic_light` and  `pedestrian_traffic_light` scripts respond by:
  - Changing light colors
  - Moving virtual obstacles to block/unblock traffic
5. Process repeats every `green_light_duration` + `yellow_light_duration` seconds

---

# 🚗 Moving Objects System

This system handles the behavior of moving entities such as **cars** and **pedestrians**. Both use path3d and pathFollow with different scripts.

### Movement

- Cars and pedestrians follow **Path3D** (predefined paths).
- Once a car reaches the end of the path, it **respawns** at the beginning.

### Triggers 

Cars use several triggers placed in front of them to observe their environment. These triggers:

- Are positioned using their **Node’s Transform**.
- Can **follow the path** or **stay in front** of the object.
- Pedestrians only use one in front of them..

#### Car Triggers Path Following Behavior

- If the Trigger is in the list `TriggersOnCurve`, it **follows the path** and its position adjusts based on car speed.
- If the Trigger is in **neither list**, it remains fixed relative to the car and **is not influenced** by speed

### Vertical Position Correction

- Two raycasts up and down are used to ajdust the vertical position of moving objects. 
