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
