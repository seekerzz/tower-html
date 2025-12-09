extends Node

var gold: int = 100
var grid_manager = null
var main_game = null
var is_wave_active: bool = false
var ui_manager = null

signal wave_started
signal wave_ended

func _ready():
	pass
