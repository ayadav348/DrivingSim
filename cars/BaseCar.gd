extends VehicleBody3D

@export var STEER_SPEED = 1.5
@export var STEER_LIMIT = 0.6
var steer_target = 0
@export var engine_force_value = 40

var turbo_boost = 1

# Reference to the shader material so we can change the "blur_strength"
# Adjust the path "PostProcess/SpeedLines" to match your scene tree
@onready var speed_fx = $CanvasLayer/Speed.material # <--- ADD THIS

func _physics_process(delta):
	var speed = linear_velocity.length()*Engine.get_frames_per_second()*delta
	traction(speed)
	$Hud/speed.text=str(round(speed*3.8 * 0.62137119 * turbo_boost))+ "  MPH"

	var fwd_mps = transform.basis.x.x
	steer_target = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	steer_target *= STEER_LIMIT
	
	if Input.is_action_just_pressed("ui_turbo"):
		$Hud/TurboLabel.set_visible(true)
		turbo_boost = 342 
		$TubroTimer.start()
		
		# --- SMOOTH CAMERA & EFFECT TWEENS ---
		var tween = create_tween().set_parallel(true)
		# Smoothly zoom FOV to 90 over 0.2 seconds
		tween.tween_property($look/Camera3D, "fov", 110, 0.2)
		tween.tween_property($InsideCamera, "fov", 110, 0.2)
		# Ramp up the warp shader strength
		tween.tween_property(speed_fx, "shader_parameter/blur_strength", 0.05, 0.3)
		# -------------------------------------

	if Input.is_action_just_pressed("ui_end"):
		if find_child("InsideCamera").is_current():
			find_child("look").find_child("Camera3D").make_current()
		else:
			find_child("InsideCamera").make_current()
			
	# ... (Keep your engine/brake logic here exactly as it was) ...
	
	if Input.is_action_pressed("ui_down"):
		if speed < 20 and speed != 0:
			engine_force = clamp(engine_force_value * 3 / speed, 0, 300)
		else:
			engine_force = engine_force_value
	else:
		engine_force = 0
		
	if Input.is_action_pressed("ui_up"):
		if fwd_mps >= -1:
			if speed < 30 and speed != 0:
				engine_force = -clamp(engine_force_value * 10 / speed, 0, 300)
			else:
				engine_force = -engine_force_value
		else:
			brake = 1
	else:
		brake = 0.0
		
	if Input.is_action_pressed("ui_select"):
		brake=3
		$wheal2.wheel_friction_slip=0.8
		$wheal3.wheel_friction_slip=0.8
	else:
		$wheal2.wheel_friction_slip=3
		$wheal3.wheel_friction_slip=3
		
	steering = move_toward(steering, steer_target, STEER_SPEED * delta)

func traction(speed):
	apply_central_force(Vector3.DOWN*speed)

func _on_tubro_timer_timeout() -> void:
	turbo_boost = 1
	$Hud/TurboLabel.set_visible(false)
	
	# --- SMOOTH RESET ---
	var tween = create_tween().set_parallel(true)
	# Reset FOV
	tween.tween_property($look/Camera3D, "fov", 75, 0.5)
	tween.tween_property($InsideCamera, "fov", 95, 0.5)
	# Turn off the warp shader
	tween.tween_property(speed_fx, "shader_parameter/blur_strength", 0.0, 0.5)
	# --------------------
