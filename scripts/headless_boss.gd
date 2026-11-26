extends "res://scripts/urban_boss.gd"
## Distinct saber chains, a visible smoke step and a delayed landing strike.
var smoke_step_active := false

func _choose_attack() -> void:
	if absf(target.position.x-position.x)>350: start_combo(2)
	else:
		start_combo(([3,2,1,3] if phase>=2 else [1,2,1,3])[sequence%4])
		sequence += 1

func start_combo(number: int) -> void:
	current_combo = number
	combo.clear()
	var effects: Array = ["melee","melee","melee","melee","melee"] if number==1 else (["melee","melee","low_sweep","melee"] if number==2 else ["smoke_step","leap_slam","melee","low_sweep","melee"])
	for index in range(effects.size()):
		var heavy: bool = index==effects.size()-1 or effects[index]=="leap_slam"
		combo.append({"animation":"combo_%d_%d" % [number,index+1],"effect":effects[index],"heavy":heavy,"lunge":number==2 and index==0,"lunge_speed":420.0,"duration":0.78 if effects[index]=="leap_slam" else (0.52 if effects[index]=="smoke_step" or (number==2 and index==0) else 0.32),"contact":0.56 if effects[index]=="leap_slam" else (0.26 if number==2 and index==0 else 0.09),"range":195.0 if heavy or effects[index]=="low_sweep" else 165.0,"hit_height":70.0 if effects[index]=="low_sweep" else 140.0})
	combo_index = 0
	for strike in combo:
		strike["range"] = 140.0 if strike.heavy or strike.effect=="low_sweep" else 120.0
		strike["hit_height"] = 55.0 if strike.effect=="low_sweep" else 112.0
	_begin_strike()

func _begin_strike() -> void:
	super._begin_strike()
	if attack.effect=="smoke_step":
		smoke_step_active = true
		invulnerable = true
		target.effects.burst(position+Vector2(0,-60),14,Color("9962aa"),1.0)
	elif attack.heavy: arena.play_headless_sound("windup",position)

func _set_state(value: String) -> void:
	if value=="phase_rise": sequence = 0
	if smoke_step_active and value!="attack":
		smoke_step_active = false
		invulnerable = false
	super._set_state(value)
	if value=="attack" and attack.get("effect","")=="leap_slam": velocity.y = -400

func _strike() -> void:
	if attack.effect=="smoke_step":
		arena.play_headless_sound("smoke",position)
		var aim: Vector2 = attack.aim_point
		position.x = clampf(aim.x+facing*155,70,arena.ground_boss_limit())
		facing = 1 if target.position.x>=position.x else -1
		target.effects.burst(position+Vector2(0,-60),20,Color("b77fc4"),1.0)
		return
	var effect: String = attack.effect
	attack.effect = "melee"
	arena.play_headless_sound("slam" if attack.heavy else ("swing_a" if combo_index%2==0 else "swing_b"),position)
	super._strike()
	attack.effect = effect
	target.effects.burst(position+Vector2(facing*80,-45),7,Color("d39bc7"),0.7)
