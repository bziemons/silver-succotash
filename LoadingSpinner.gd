extends Control


func _draw():
	var center = rect_size / 2.0
	var radius = min(center.x, center.y) - 8
	var angle_from = 0.0
	var angle_to = PI / 2
	var point_count = 8
	var color = Color(1.0, 1.0, 1.0)
	var thickness = 3
	var antialiased = true
	draw_arc(center, radius, angle_from, angle_to, point_count, color, thickness, antialiased)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.visible:
		self.set_rotation(self.get_rotation() + (delta * 8))
