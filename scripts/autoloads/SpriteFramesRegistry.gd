extends Node

const FRAMES = {
	"arrow": preload("res://sprite_frames/projectiles/arrow.tres"),
	"boulder": preload("res://sprite_frames/projectiles/boulder.tres"),
	"slime_arrow": preload("res://sprite_frames/projectiles/slime_arrow.tres"),
	"green_slime": preload("res://sprite_frames/green_slime.tres"),
	"mole_boss": preload("res://sprite_frames/mole_boss.tres"),
	"player": preload("res://sprite_frames/player.tres")
}

func get_frames(id):
	return FRAMES.get(id, FRAMES["mole_boss"])
