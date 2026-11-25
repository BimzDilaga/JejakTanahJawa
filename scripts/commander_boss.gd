extends "res://scripts/urban_boss.gd"
## Three distinct chains; staged shots and exposed reload windows, no hitscan.
var shots_since_reload := 0

func _physics_process(delta: float) -> void:
	if state=="reload" and not dead:
		if GameState.dialogue_active or GameState.ending_started or not target.controls_enabled: return
		state_time += delta
		var duration := float(tuning.reload_time)/tempo()
		_pose("reload",state_time/duration)
		velocity.x = 0
		if state_time>=duration:
			shots_since_reload = 0
			super._set_state("idle")
		return
	if state=="idle" and active and target.controls_enabled and not GameState.dialogue_active and not GameState.ending_started:
		if absf(target.position.x-position.x)>300 and state_time>0.6/tempo(): start_combo(2)
	super._physics_process(delta)

func _set_state(value: String) -> void:
	if value=="recovery" and shots_since_reload>=6: value = "reload"
	super._set_state(value)

func _choose_attack() -> void:
	var patterns := [1,2,1,3] if phase==1 else [3,2,1,3,2]
	start_combo(patterns[sequence%patterns.size()])
	sequence += 1

func start_combo(number: int) -> void:
	current_combo = number
	combo.clear()
	var effects: Array = ["melee","melee","flintshot","melee","melee"] if number==1 else (["melee","flintshot","rapid","melee"] if number==2 else ["flintshot","brace","rapid","finalsalvo","melee"])
	for index in range(effects.size()):
		var heavy := index==effects.size()-1
		var ranged: bool = effects[index] in ["rapid","flintshot","finalsalvo"]
		combo.append({"animation":"combo_%d_%d" % [number,index+1],"effect":effects[index],"heavy":heavy,"lunge":number==2 and index==0,"lunge_speed":480.0,"duration":0.85 if effects[index]=="finalsalvo" else (0.6 if ranged or (number==2 and index==0) else 0.32),"range":205.0 if heavy else 175.0})
	combo_index = 0
	_begin_strike()

func _strike() -> void:
	if attack.effect=="brace":
		target.effects.impact(position+Vector2(0,-90),Color("eac980"),0.6)
	elif attack.effect in ["rapid","flintshot","finalsalvo"]:
		shots_since_reload += 3 if attack.effect=="rapid" else (5 if attack.effect=="finalsalvo" else 1)
		arena.emit_boss_attack(self,attack.effect)
	else: super._strike()
