import json
import math

def refactor_game_data():
    with open('data/game_data.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    unit_types = data.get('UNIT_TYPES', {})

    # Fields to move to levels
    level_fields = ['damage', 'hp', 'cost', 'desc']

    for key, unit in unit_types.items():
        print(f"Refactoring {key}...")

        # Base values (Lv1)
        base_stats = {}
        for field in level_fields:
            if field in unit:
                base_stats[field] = unit[field]

        # Create levels dict
        levels = {}

        # Level 1
        levels["1"] = base_stats.copy()
        levels["1"]["mechanics"] = {}

        # Level 2
        lv2_stats = base_stats.copy()
        if 'damage' in lv2_stats:
            lv2_stats['damage'] = math.floor(lv2_stats['damage'] * 1.5)
        if 'hp' in lv2_stats:
            lv2_stats['hp'] = math.floor(lv2_stats['hp'] * 1.5)
        if 'cost' in lv2_stats:
            lv2_stats['cost'] = lv2_stats['cost'] * 2

        # Update desc for Lv2
        if 'desc' in lv2_stats:
             # Just appending a generic string for now as automated desc update is hard
             # But the prompt example shows: "Lv2: 伤害提升，暴击率增加"
             # I'll preserve the original desc and prepend Level info?
             # Or just leave it as is for now and let the loop handle values.
             # The example changed the text. I can't easily generate meaningful text for all.
             # I will just append " (Lv2)" to the name or desc?
             # The prompt example: "Lv2: 伤害提升，暴击率增加".
             # I will just keep the original desc for Lv2/3 but maybe append "++"?
             # Actually, the user might want to manually edit descriptions later.
             # I will just copy the desc.
             pass

        lv2_stats["mechanics"] = {"crit_rate_bonus": 0.1}
        levels["2"] = lv2_stats

        # Level 3
        lv3_stats = lv2_stats.copy()
        if 'damage' in lv3_stats:
            lv3_stats['damage'] = math.floor(lv3_stats['damage'] * 1.5)
        if 'hp' in lv3_stats:
            lv3_stats['hp'] = math.floor(lv3_stats['hp'] * 1.5)
        if 'cost' in lv3_stats:
            # Lv3 cost is 2 * Lv2 cost = 4 * Lv1 cost
            # But wait, lv3_stats is copy of lv2_stats, so doubling it means 4x base. Correct.
            lv3_stats['cost'] = lv3_stats['cost'] * 2

        lv3_stats["mechanics"] = {"crit_rate_bonus": 0.2, "multi_shot_chance": 0.3 if unit.get("attackType") == "ranged" else 0.0}
        # Only add multi_shot_chance if ranged? The example had it. I'll add it if ranged.
        if unit.get("attackType") != "ranged":
            if "multi_shot_chance" in lv3_stats["mechanics"]:
                del lv3_stats["mechanics"]["multi_shot_chance"]

        levels["3"] = lv3_stats

        # Remove moved fields from root
        for field in level_fields:
            if field in unit:
                del unit[field]

        # Add levels to unit
        unit['levels'] = levels

        # Ensure type_key exists (prompt example has it)
        if 'type_key' not in unit:
            unit['type_key'] = key

    data['UNIT_TYPES'] = unit_types

    with open('data/game_data.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

if __name__ == "__main__":
    refactor_game_data()
