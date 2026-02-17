# Core Ranch: Ultimate Battle - Automated Testing Framework

This project includes an automated testing framework designed to facilitate debugging of new units, verifying game mechanics, and ensuring stability in headless environments (CI/CD).

## How to Debug New Units

When you add a new unit to the game, you can create a specific test case to verify its behavior, interactions, and stats without manually playing through the game.

### 1. Define a Test Case

Open `src/Scripts/Tests/TestSuite.gd` and add a new case to the `get_test_config` function.

**Example Configuration:**

```gdscript
"test_new_unit":
    return {
        "id": "test_new_unit",
        "core_type": "cornucopia", # Choose a core type
        "initial_gold": 1000,
        "start_wave_index": 1,
        "duration": 10.0, # Test duration in seconds
        # Place your new unit and any necessary support units
        "units": [
            {"id": "new_unit_id", "x": 0, "y": 1},
            {"id": "tank_unit", "x": 0, "y": -1} # Optional: Add a tank to protect it
        ],
        # Optional: Schedule actions like skill usage
        "scheduled_actions": [
            {
                "time": 2.0,
                "type": "skill",
                "source": "new_unit_id",
                "target": {"x": 2, "y": 2}
            }
        ]
    }
```

### 2. Run in GUI Mode (Visual Inspection)

Use this mode to watch the unit's animations, projectile behavior, and visual effects.

```bash
godot --path . -- --run-test=test_new_unit
```

*   The game will launch directly into the test scenario.
*   Units will be placed automatically.
*   The wave will start immediately.
*   The game will verify visuals and close automatically after the duration.

### 3. Run in Headless Mode (Data Verification)

Use this mode to verify damage numbers, stat calculations, and stability without rendering graphics. This is ideal for CI pipelines or quick logic checks.

```bash
godot --path . --headless -- --run-test=test_new_unit
```

### 4. Analyze Test Logs

After the test completes (in either mode), a detailed JSON log is generated in the user data directory.

**Log Location:**
*   **Windows:** `%APPDATA%\Godot\app_userdata\Core Ranch_ Ultimate Battle\test_logs\`
*   **macOS:** `~/Library/Application Support/Godot/app_userdata/Core Ranch_ Ultimate Battle/test_logs/`
*   **Linux:** `~/.local/share/godot/app_userdata/Core Ranch_ Ultimate Battle/test_logs/`

**Log Structure:**
The log file (`test_new_unit.json`) contains an array of frame snapshots. Each entry includes:
*   `frame`: Frame number.
*   `time`: Elapsed time since test start.
*   `core_health`, `gold`, `mana`: Global resources.
*   `units`: List of all placed units with their current stats (damage, level, position).
*   `enemies`: List of all active enemies with their HP and position.
*   `events`: A list of events that occurred in this frame:
    *   `type: "spawn"`: Enemy spawned.
    *   `type: "hit"`: Enemy took damage (includes source unit and damage amount).

**Example Log Entry:**
```json
{
    "frame": 60,
    "time": 1.0,
    "events": [
        {
            "type": "hit",
            "target_id": 12345,
            "source": "new_unit_id",
            "damage": 50,
            "target_hp_after": 100
        }
    ]
}
```

By analyzing these logs, you can verify if your new unit is dealing the expected damage, targeting the correct enemies, and triggering skills at the right time.
