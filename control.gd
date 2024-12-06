extends Control

@export var curve: Curve

@export_group("Nodes")
@export_subgroup("Timers", "timer_")
@export var timer_await: Timer
@export var timer_flow: Timer

@export_subgroup("Bars", "bar_")
@export var bar_hp: Range
@export var bar_flow_hp: Range

var hp: int = 100: set = set_hp
var incurve: Curve

func set_hp(new_hp) -> void:
	if hp > clampi(new_hp, 0, 100): got_hit()
	hp = clampi(new_hp, 0, 100)
	%HPBar.value = hp

func got_hit() -> void:
	if timer_await.time_left:
		timer_await.stop()
		await get_tree().process_frame
	else:
		var buf: float = bar_flow_hp.value
		timer_flow.stop()
		bar_flow_hp.value = buf
	timer_await.start()

func set_curve() -> void:
	incurve = Curve.new()#curve
	incurve.max_value = bar_flow_hp.value
	incurve.min_value = hp
	for p in range(0, curve.point_count):
		incurve.add_point(Vector2(curve.get_point_position(p).x, curve.get_point_position(p).y * (incurve.max_value - incurve.min_value) + incurve.min_value), rad_to_deg(atan(curve.get_point_left_tangent(p))), rad_to_deg(atan(curve.get_point_right_tangent(p))))
	incurve.bake()

func start_flow() -> void:
	set_curve()
	await get_tree().process_frame
	timer_flow.start()
	while timer_flow.time_left:
		bar_flow_hp.value = incurve.sample_baked((timer_flow.wait_time - timer_flow.time_left)/timer_flow.wait_time)
		await get_tree().process_frame

#region Scene's junk
func _on_hit_button_pressed() -> void: hp -= $HitXontainer/TextEdit.text.to_int()
