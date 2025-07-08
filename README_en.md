# Eisenhower Matrix Todo App

A beautiful, modern Eisenhower Matrix todo app built with Flutter.

---

## Features

- Four-quadrant todo list (Eisenhower Matrix)
- Tap any quadrant to quickly add a new task
- Each task supports custom "Importance" and "Urgency" weights, with auto-limited range by quadrant
- Visualize all tasks on a 2D plane by (importance, urgency) coordinates
- Theme switching: Light, Dark, System, Cyberpunk 2077 (neon yellow/blue/purple)
- Instantly switch between Traditional Chinese and English UI
- Responsive UI: quadrants auto-fit the available screen space
- BottomNavigationBar (dock) for page switching, colors auto-sync with theme
- All theme colors, axis, points, and labels auto-sync with current theme

---

## Screenshots

> Please add your own app screenshots here

---

## How to Run

1. Install [Flutter](https://flutter.dev/docs/get-started/install)
2. Download this project
3. In the project folder, run:
   ```bash
   flutter pub get
   flutter run
   ```

---

## Main Files

- `lib/main.dart`: Main app logic, UI, theme, and language switching
- `assets/`: App icon and static resources

---

## Language

- Switch between Traditional Chinese and English in the settings page
- All UI text will update instantly when you change the language

---

## Theme

- Four built-in themes:
  - Light
  - Dark
  - System
  - Cyberpunk (neon yellow/blue/purple)
- BottomNavigationBar, axis, points, and labels will auto-sync with the current theme

---

## License

MIT
