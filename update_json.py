import json

def update_json():
    with open('data/game_data.json', 'r') as f:
        data = json.load(f)

    unit_types = data.get('UNIT_TYPES', {})

    # Define mappings based on task description and logical deduction
    faction_map = {
        # Wolf Totem
        "tiger": "wolf_totem",
        "dog": "wolf_totem",
        "lion": "wolf_totem",
        "bear": "wolf_totem",

        # Viper Totem
        "scorpion": "viper_totem",
        "viper": "viper_totem",
        "arrow_frog": "viper_totem",
        "lure_snake": "viper_totem",
        "medusa": "viper_totem",
        "plague_spreader": "viper_totem",
        "spider": "viper_totem",

        # Bat Totem
        "mosquito": "bat_totem",
        "vampire_bat": "bat_totem",
        "blood_mage": "bat_totem",
        "blood_ancestor": "bat_totem",

        # Butterfly Totem
        "butterfly": "butterfly_totem",
        "phoenix": "butterfly_totem",
        "fairy_dragon": "butterfly_totem",
        "dragon": "butterfly_totem",
        "bee": "butterfly_totem",
        "octopus": "butterfly_totem",

        # Eagle Totem
        "kestrel": "eagle_totem",
        "owl": "eagle_totem",
        "magpie": "eagle_totem",
        "pigeon": "eagle_totem",
        "eagle": "eagle_totem",
        "storm_eagle": "eagle_totem",
        "gale_eagle": "eagle_totem",
        "harpy_eagle": "eagle_totem",
        "vulture": "eagle_totem",
        "woodpecker": "eagle_totem",
        "parrot": "eagle_totem",
        "peacock": "eagle_totem",

        # Cow Totem
        "cow": "cow_totem",
        "yak_guardian": "cow_totem",
        "iron_turtle": "cow_totem",
        "hedgehog": "cow_totem",
        "rock_armor_cow": "cow_totem",
        "mushroom_healer": "cow_totem",
        "oxpecker": "cow_totem",
        "plant": "cow_totem",
        "cow_golem": "cow_totem",
        "snowman": "cow_totem",

        # Universal (Explicit or inferred)
        "meat": "universal",
        "spiderling": "universal",
        "enemy_clone": "universal",
        "torch": "universal",
        "cauldron": "universal",
        "drum": "universal",
        "mirror": "universal",
        "splitter": "universal",
        "rabbit": "universal",
        "squirrel": "universal",
        "lucky_cat": "universal",
        "eel": "universal",
    }

    for key, unit in unit_types.items():
        if key in faction_map:
            unit['faction'] = faction_map[key]
        else:
            # Default to universal if not mapped
            unit['faction'] = "universal"
            print(f"Warning: Unit '{key}' not explicitly mapped. Defaulting to 'universal'.")

    # Update valid factions from task description to ensure consistency
    # core_types = data.get('CORE_TYPES', {}).keys()
    # for key, unit in unit_types.items():
    #     if unit['faction'] not in core_types and unit['faction'] != 'universal':
    #          print(f"Warning: Unit '{key}' has invalid faction '{unit['faction']}'")

    with open('data/game_data.json', 'w') as f:
        json.dump(data, f, indent='\t', ensure_ascii=False)

if __name__ == "__main__":
    update_json()
