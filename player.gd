extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -320.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_interactable: Area2D = null
var is_attacking: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Kunci input dan pasang pose diam jika dialog atau ending aktif
	if GameState.dialogue_active or GameState.ending_started:
		velocity.x = 0
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		anim.play("idle")
		return

	# Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta

	# Tombol Serang (J)
	if Input.is_action_just_pressed("attack") and not is_attacking and is_on_floor():
		perform_attack()

	# Tombol Lompat (Space)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Tombol Interaksi (E)
	if Input.is_action_just_pressed("interact") and current_interactable != null:
		current_interactable.trigger_interaction()

	# Gerak Horizontal (A / D)
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0 and not is_attacking:
		velocity.x = direction * SPEED
		# Membalik arah hadap sprite (kiri/kanan)
		anim.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# Jalankan pengecekan animasi jika sedang tidak menyerang
	if not is_attacking:
		update_animation(direction)

func update_animation(direction: float) -> void:
	if not is_on_floor():
		anim.play("jump")
	elif direction != 0:
		anim.play("walk")
	else:
		anim.play("idle")

func perform_attack() -> void:
	is_attacking = true
	velocity.x = 0
	anim.play("attack")
	
	# Tunggu hingga animasi serangan selesai diputar
	await anim.animation_finished
	is_attacking = false
