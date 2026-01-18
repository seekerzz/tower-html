extends Button

signal card_selected(key: String)

const EMOJI_MAP = {
	"MECHANIC": "⚙️",
	"NATURE": "🌿",
	"MAGIC": "✨",
	"ELEMENTAL": "🔥",
	"UNDEAD": "💀",
	"DIVINE": "☀️",
	"DEMONIC": "😈",
	"BEAST": "🐾"
}
const DEFAULT_EMOJI = "❓"

@onready var icon_rect: TextureRect = $VBoxContainer/Icon
@onready var emoji_label: Label = $VBoxContainer/EmojiLabel
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var desc_label: Label = $VBoxContainer/DescLabel

var core_key: String = ""

func _ready():
	pressed.connect(_on_pressed)

func setup(key: String, data: Dictionary):
	core_key = key
	title_label.text = data.get("name", key)
	desc_label.text = data.get("desc", "No description")

	# Image loading logic
	var image_path = "res://assets/images/cores/%s.png" % key.to_lower()
	if FileAccess.file_exists(image_path):
		var texture = load(image_path)
		if texture:
			icon_rect.texture = texture
			icon_rect.show()
			emoji_label.hide()
		else:
			_show_emoji(key)
	else:
		_show_emoji(key)

func _show_emoji(key: String):
	icon_rect.hide()
	emoji_label.show()
	if EMOJI_MAP.has(key):
		emoji_label.text = EMOJI_MAP[key]
	else:
		emoji_label.text = DEFAULT_EMOJI

func _on_pressed():
	card_selected.emit(core_key)
