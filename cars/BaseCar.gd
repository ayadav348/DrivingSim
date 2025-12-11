extends VehicleBody3D

@export var STEER_SPEED = 1.5
@export var STEER_LIMIT = 0.6
var steer_target = 0
@export var engine_force_value = 40

var turbo_boost = 1

@onready var speed_fx = $CanvasLayer/Speed.material 

func _physics_process(delta):
	var speed = linear_velocity.length() * Engine.get_frames_per_second() * delta
	traction(speed)
	$Hud/speed.text = str(round(speed * 3.8 * 0.62137119 * turbo_boost)) + " MPH"

	# --- STEERING ---
	var steer_input = Input.get_axis("steer_right", "steer_left")
	steer_target = steer_input * STEER_LIMIT
	steering = move_toward(steering, steer_target, STEER_SPEED * delta)

	# --- INPUTS ---
	var throttle_input = Input.get_action_strength("throttle") # Gas Pedal / W
	var brake_input = Input.get_action_strength("brake")       # Brake Pedal / S
	var is_shifter_reverse = Input.is_action_pressed("shifter_reverse") # Gear Knob
	
	engine_force = 0.0
	brake = 0.0
	
	

	# --- 1. REVERSE GEAR LOGIC (Shifter Active) ---
	if is_shifter_reverse:
		
		if throttle_input > 0:
			
			engine_force = clamp(engine_force_value * throttle_input, 0, 300)
		
		if brake_input > 0:
			brake = brake_input * 10.0

	# --- 2. FORWARD GEAR / KEYBOARD LOGIC (Shifter Inactive) ---
	else:
	
		if throttle_input > 0:
			if speed < 30 and speed != 0:
				engine_force = -clamp(engine_force_value * 10 / speed, 0, 300) * throttle_input
			else:
				engine_force = -engine_force_value * throttle_input

		
		if brake_input > 0:
			# If we are using a keyboard  AND moving slow/stopped, allow Reverse.
			# We check if input is exactly 1 (Key press) vs Analog (Pedal).
			var is_keyboard_input = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
			
			if is_keyboard_input:
			
				engine_force = clamp(engine_force_value * 3 / (speed + 0.1), 0, 300)
			else:
				# Wheel Logic: Brake pedal is strictly BRAKE. 
				# You must use the Shifter to go in reverse.
				brake = brake_input * 5.0

	if Input.is_action_pressed("ui_select"): # Handbrake for drifting
		brake = 3
		$wheal2.wheel_friction_slip = 0.8
		$wheal3.wheel_friction_slip = 0.8
	else:
		$wheal2.wheel_friction_slip = 3
		$wheal3.wheel_friction_slip = 3

	if Input.is_action_just_pressed("ui_turbo"):
		activate_turbo()
		
	if Input.is_action_just_pressed("ui_end"):
		toggle_camera()

func traction(speed):
	apply_central_force(Vector3.DOWN * speed)

func activate_turbo():
	$Hud/TurboLabel.set_visible(true)
	turbo_boost = 342 #Chose an Arbitrary Number (Speed Doesnt Actually Change, Just Want Player to see a bigger number)
	$TubroTimer.start()
	var tween = create_tween().set_parallel(true)
	tween.tween_property($look/Camera3D, "fov", 110, 0.2)
	tween.tween_property($InsideCamera, "fov", 110, 0.2)
	tween.tween_property(speed_fx, "shader_parameter/blur_strength", 0.05, 0.3)

func toggle_camera():
	if find_child("InsideCamera").is_current():
		find_child("look").find_child("Camera3D").make_current()
	else:
		find_child("InsideCamera").make_current()

func _on_tubro_timer_timeout() -> void:
	turbo_boost = 1
	$Hud/TurboLabel.set_visible(false)
	var tween = create_tween().set_parallel(true)
	tween.tween_property($look/Camera3D, "fov", 75, 0.5)
	tween.tween_property($InsideCamera, "fov", 95, 0.5)
	tween.tween_property(speed_fx, "shader_parameter/blur_strength", 0.0, 0.5)
