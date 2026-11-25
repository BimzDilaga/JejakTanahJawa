extends SceneTree
func _initialize() -> void:
	var art := preload("res://tools/combat_art.gd")
	art.prepare_jaka()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/boss_assets.json"))
	art.prepare_buto(manifest)
	var file := FileAccess.open("res://data/boss_assets.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	print("COMBAT_POLISH_ART_PREPARED")
	quit()
