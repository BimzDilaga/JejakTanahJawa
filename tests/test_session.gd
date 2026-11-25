extends RefCounted
## Tests never replace a player's real campaign slot or inherit another suite's save.
static func isolate(name: String) -> void:
	GameState.save_path = "user://qa/"+name.get_basename()+"/campaign.json"
	GameState.reset_campaign(true)
	AudioPrefs.isolate_test("user://qa/"+name.get_basename()+"/audio.cfg")
