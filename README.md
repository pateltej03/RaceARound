# 🏁 RaceARound

**RaceARound** is an augmented reality (AR) racing game for iOS that brings tabletop racing into the real world. Built as a final project entirely from scratch, this app showcases interactive AR gameplay, physics-based driving, track placement, lap validation, and leaderboard tracking — all running locally on-device with Swift, ARKit, RealityKit, CoreMotion, and SwiftUI.

> ✨ This was my own idea and independent final project — no templates, no teams — just design, code, iteration, and fun.

---

## 🚗 Gameplay Overview

- **Choose Your Car & Track**: Select from 3 custom-modeled cars and 3 handcrafted AR tracks.
- **Place in Real World**: Place your chosen track and car onto any flat surface using your iPhone or iPad.
- **Race with Motion Controls**: Use tilt-based steering and two-finger controls to throttle and brake.
- **Checkpoint Logic**: Progress through checkpoints in sequence — laps are only valid if you follow the correct path.
- **Leaderboard System**: Automatically record your best lap to a local leaderboard with timestamp, username, car, and track.

---

## 🛠 Tech Stack

- **Language**: Swift 5
- **Frameworks**: 
  - `RealityKit` for 3D models, physics, and scene handling  
  - `ARKit` for plane detection and AR anchoring  
  - `CoreMotion` for tilt steering  
  - `SwiftUI` for all UI and screen transitions  
  - `JSON` for saving leaderboard, car, and track data

---

## 🎮 Features

### 🚙 Cars
Each car has its own:
- 3D AR model + thumbnail image
- Acceleration profile
- Coasting and braking logic
- Maximum speed limit

### 🛣️ Tracks
Each track:
- Is placed in AR on flat surfaces
- Contains visible checkpoints and logic zones for lap validation
- Is uniquely shaped (short circuit, long straight, curvy maze)

### 🧠 Driving Physics
- Speed control via throttle, coasting, and brake
- Motion-based steering adjusts rotation using device orientation
- Realistic deceleration for speed management

### 🏆 Leaderboard
- Stores top 10 fastest laps
- Displays player name, date, car, track, and time
- Saves to disk using `Codable` and `JSONEncoder`

---

## 📦 Assets

- Cars from **BlenderKit** and other open 3D repositories
- Tracks created by modifying Blender circuits
- Models optimized and exported to `.usdz` for Apple AR compatibility

---

## 💡 Inspiration

As a lifelong racing enthusiast, I wanted to create something that combines my love for cars, gaming, and AR. This project was my way of experimenting with immersive technology while still thinking about gameplay, physics, and user experience.

---

## 🔚 Final Thoughts

**RaceARound** isn't just a project — it's a statement of what one person can build when given the tools and a blank canvas.

---

### 🧠 Author

**Tej Jaideep Patel**  
B.S. Computer Engineering  
📍 Penn State University  
✉️ tejpatelce@gmail.com  
📞 814-826-5544

---


