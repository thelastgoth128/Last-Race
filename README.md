# 🏎️ The Last Race – AI Racing Project

**The Last Race** is a racing simulation built with **Godot 4** and powered by the **Godot Steering AI (GSAI) framework**.  
It features AI‑controlled cars that can follow paths, avoid collisions, overtake opponents, and dynamically choose branching track sections.

---

## ✨ Features
- **AI Steering Behaviors**
  - Path following (`GSAIFollowPath`)
  - Collision avoidance (`GSAIAvoidCollisions`)
  - Orientation alignment (`GSAILookWhereYouGo`)
  - Priority and blended steering combinations
- **Branching System**
  - Cars can choose between multiple track branches (A/B) and rejoin the main path.
- **AI State Machine**
  - States: `IDLE`, `FOLLOW`, `RECOVER`, `OVERTAKE`, `CORNER`, `AVOID`, `BRANCH`
- **Physics Parameters**
  - Adjustable speed, acceleration, angular limits, traction, drift mechanics, and gravity
- **Race Management**
  - Checkpoint tracking and respawn system
  - Global signals for race start and branch entry/exit
- **Visual Effects**
  - Rain particle system (`CPUParticles3D`)
  - Fog and environment effects for atmosphere

---

## 📂 Project Structure
res:// ├── scenes/ # Main scenes (tracks, cars, UI) ├── scripts/ # AI and gameplay scripts ├── assets/ # Models, textures, sounds ├── addons/gsai/ # Godot Steering AI framework ├── Global.gd # Global settings and track selection └── SignalBus.gd # Centralized signal management

Code

---

## ⚙️ Setup
1. Install **Godot 4.x**.
2. Clone this repository:
   ```bash
   git clone https://github.com/your-username/the-last-race.git
Open the project in Godot.

Ensure the GSAI framework is included in your project (addons/gsai).

Run the main scene to start the race.

🚗 AI Car Configuration
Each AI car is a CharacterBody3D with:

A GSAICharacterBody3DAgent steering agent

Path references (Path3D nodes for main and branch tracks)

Configurable physics parameters:

speed_max, acceleration_max, angular_speed_max

traction_slow, traction_fast, slip_speed

gravity

🧠 Steering Behaviors
Priority Steering
Ensures collision avoidance overrides path following:

gdscript
var priority = GSAIPriority.new(agent)
priority.add(avoid)   # highest priority
priority.add(follow_behavior)
priority.add(look)
agent.steering_behavior = priority
Blend Steering
Smoothly combines multiple behaviors:

gdscript
var blend = GSAIBlend.new(agent)
blend.add(follow_behavior, 0.8)
blend.add(avoid, 0.6)
blend.add(look, 0.3)
agent.steering_behavior = blend
Hybrid Setup
Priority at the top level, with blended path + look behaviors as fallback:

gdscript
var blend = GSAIBlend.new(agent)
blend.add(follow_behavior, 0.8)
blend.add(look, 0.4)

var priority = GSAIPriority.new(agent)
priority.add(avoid)   # override if collision detected
priority.add(blend)   # otherwise blend path + look
agent.steering_behavior = priority
🎮 Controls
Player cars can be added with manual input.

AI cars run automatically once the race starts (SignalBus.Go).

🔮 Roadmap
Add ground splash particles for rain effects.

Improve overtaking logic with dynamic lane changes.

Integrate network multiplayer with AI opponents.

Expand track branching system with more complex paths.

📜 License
MIT License – free to use, modify, and distribute.

👨‍💻 Author
Developed by Cyrus Thindwa Final‑year Computer Science student, University of Malawi Backend/frontend developer at Primechase Studios

Code


