extends RigidBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var time = 0

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here.
	pass

func _process(delta):
	time += delta
	pass
func _integrate_forces(state):
	linear_velocity = Vector2(1,0) * sin(time*PI/2) * 500


func _draw():
	draw_circle(Vector2(0,0),25,ColorN("purple"))