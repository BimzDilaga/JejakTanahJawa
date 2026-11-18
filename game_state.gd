extends Node

signal objective_updated(text: String)
signal dialogue_started
signal dialogue_ended

var start_on_load: bool = false
var dialogue_active: bool = false
var ending_started: bool = false
var objective_completed: bool = false
var supply_checked: int = 0
var enemies_defeated: int = 0
var objective: String = ""
var heal_stock := 0
var defeats_toward_heal := 0
var aid_heal_claimed := false

func claim_aid_heal() -> bool:
	if aid_heal_claimed:
		return false
	aid_heal_claimed = true
	heal_stock += 1
	return true

func award_patrol_defeat() -> bool:
	defeats_toward_heal += 1
	if defeats_toward_heal < 7:
		return false
	defeats_toward_heal = 0
	heal_stock += 1
	return true

func reset_campaign() -> void:
	heal_stock = 0
	defeats_toward_heal = 0
	aid_heal_claimed = false

func set_objective(text: String, is_done: bool = false) -> void:
	objective = text
	objective_completed = is_done
	objective_updated.emit(text)

func add_supply_check() -> void:
	supply_checked += 1
	set_objective("Periksa perbekalan (%d/2)" % supply_checked)

func add_enemy_defeated(target_total: int = 2) -> void:
	enemies_defeated = mini(enemies_defeated + 1, target_total)
	if enemies_defeated < target_total:
		set_objective("Hadapi tentara Belanda (%d/%d)" % [enemies_defeated, target_total])
	else:
		set_objective("Jalur terbuka. Cari jalan keluar!", true)

func reset_stage() -> void:
	dialogue_active = false
	ending_started = false
	objective_completed = false
	supply_checked = 0
	enemies_defeated = 0
	objective = ""
