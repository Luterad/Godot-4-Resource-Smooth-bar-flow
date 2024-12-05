class_name FlowBar extends Resource

## Smooth range bar flow resource.
## 
## This resource allows you to smoothly (in fact anyway how you'll want) degrees [code]value[/code] of your [member bar_flow] by [member curve].

@export var curve: Curve

@export_group("Nodes")
@export_subgroup("Timers", "timer_")
@onready var timer_await: Timer ## When runs out [member bar_flow]'s [code]value[/code] starts to degrees according to [member curve].
@onready var timer_flow: Timer ## While runs sets [member bar_flow]'s [code]value[/code] according to [member curve]'s [code]X[/code].

@export_subgroup("Bars", "bar_")
@onready var bar_basic: Range ## Bar for basic changing of it's value.
@onready var bar_flow: Range ## Bar for smooth changing of it's value.

var value: int = 100: set = set_new_value
var incurve: Curve

func _enter_tree() -> void: timer_await.timeout.connect(_start_flow)

func set_new_value(new_v) -> void:
	if value > clampi(new_v, 0, 100):
		if timer_await.time_left:
			timer_await.stop()
			await get_tree().process_frame
		else:
			var buf: float = bar_flow.value
			timer_flow.stop()
			bar_flow.value = buf
	timer_await.start()
	value = clampi(new_v, 0, 100)
	if bar_basic != null: bar_basic.value = value

## Set's curve specificly for current amount of degreesed value.
func set_curve() -> void:
	incurve = Curve.new()
	incurve.max_value = bar_flow.value
	incurve.min_value = value
	for p in range(0, curve.point_count):
		incurve.add_point(Vector2(curve.get_point_position(p).x, curve.get_point_position(p).y * (incurve.max_value - incurve.min_value) + incurve.min_value), curve.get_point_left_tangent(p), curve.get_point_right_tangent(p), Curve.TANGENT_FREE, Curve.TANGENT_FREE)

func _start_flow() -> void: ## Emits when [member timer_await] runs out.
	set_curve()
	await get_tree().process_frame
	timer_flow.start()
	while timer_flow.time_left:
		bar_flow.value = incurve.sample((timer_flow.wait_time - timer_flow.time_left)/timer_flow.wait_time)
		await get_tree().process_frame
