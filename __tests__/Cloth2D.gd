extends RigidBody2D
#texture to be used as cloth
export(Texture) var cloth_texture
export(int) var rows = 10
export(int) var columns = 10

export(int) var iterations = 3
export(float) var pointRadius = 3.0

export(float) var springConstant = 80.0
export(float) var dampingConstant = 10.0

#point Grid.
var points = []
#constraint Array
var constraints = []

#physicsBody
var bodyShape
var shape
var shapeArray = []


#dragging
var pressed = false
var previousMass
var movingPoint

#wind
var time = 0

#PointMass class
class PointMass:
	#A point with mass, using Verlet integration
	var previousPosition = Vector2()
	var position = Vector2()
	var mass = 1
	var inv_mass = 1
	var force = Vector2()

	func _init(position, mass):
		setup(position,mass)

	func setup(position,mass):
		self.position = position
		self.previousPosition = position
		set_mass(mass)

	func set_mass(mass):
		self.mass = mass
		self.inv_mass = mass
		if(mass != 0):
			self.inv_mass = 1/mass

	# Verlet integration
	func move(delta):
		var lp = position
		if mass != 0 and force != Vector2(0,0):
			position += lp - previousPosition + force * inv_mass * delta * delta
		previousPosition = lp


#Constraint class
class Constraint:
	#The 2 point mass objects connected by this constraint
	var pointA
	var pointB
	var restLength
	var springConstant = 0.0
	var dampingConstant = 0.0

	func _init(A,B,_springConstant = 0.0, _dampingConstant = 0.0, restLength = null):
		pointA = A
		pointB = B
		if(restLength == null):
			self.restLength = (A.position - B.position).length()
		else:
			self.restLength = restLength
		springConstant = _springConstant
		dampingConstant = _dampingConstant

	func satisfy(delta):
		var diff = pointA.position - pointB.position
		var currentLength = diff.length()
		var extension = currentLength - restLength

		#spring force
		var force = springConstant * extension * diff.normalized()
		pointA.force = -force; pointB.force = force;

		#damping force/viscous drag
		var velA = (pointA.position - pointA.previousPosition)/delta
		var velB = (pointB.position - pointB.previousPosition)/delta
		force = dampingConstant * (velA - velB)
		pointA.force -= force; pointB.force += force

		# apply the forces
		pointA.move(delta); pointB.move(delta)

		#adjust point pos for realism
		if pointA.mass > 0 and pointB.mass > 0:
			diff = pointB.position - pointA.position
			var diffUnitVec = diff.normalized()
			currentLength = diff.length()
			extension = currentLength - restLength
			if abs(extension/restLength) > 0.1:
				#snap the points so the constraint do not overextend/overcontract
				var correctionLength = currentLength - restLength * (1 + 0.1 * sign(extension))
				#print("currentLength: "+str(currentLength)+"--snapped->> " + str(restLength * (1 + 0.1 * sign(extension))))

				pointA.position += diffUnitVec * correctionLength/2.0
				pointA.previousPosition += diffUnitVec * correctionLength/2.0

				pointB.position -= diffUnitVec * correctionLength/2.0
				pointB.previousPosition -= diffUnitVec * correctionLength/2.0

func _input(event):
	if(event is InputEventKey and event.scancode == KEY_R and event.pressed == true):
		get_tree().reload_current_scene()
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		#check if a pointMass is being pressed
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			for point in points:
				var vecDiff = get_local_mouse_position() - point.position
				if vecDiff.length() < pointRadius*4 :
					pressed = event.pressed
					movingPoint = point
					previousMass = movingPoint.mass
		elif pressed:
			pressed = false
			movingPoint.set_mass(previousMass)
			print("released")

	if pressed:
		if event is InputEventMouseMotion:
			movingPoint.position = get_local_mouse_position()
			movingPoint.set_mass(0)


func _ready():
	create_grid()
	set_process_input(true)

	#initialize its collision body structure
	shape = ConvexPolygonShape2D.new()
	bodyShape = CollisionShape2D.new()
	bodyShape.shape = shape
	#add_child(bodyShape)


func _physics_process(delta):
	#recenter
	var offset = Vector2(0,0)
	for p in points:
		offset += p.position
	offset /= points.size()
	position += offset
	for i in range(points.size()):
		points[i].position -= offset
		points[i].previousPosition -= offset
		# refresh the point collision shapes
		shapeArray[i].position = points[i].position
	update()

func _integrate_forces(state):
	#satisfy constraints
	for i in iterations:
		for constraint in constraints:
			constraint.satisfy(1.0/60.0)

	#add gravity
	for point in points:
		point.force = Vector2(0,9.8*10)

	for i in range(state.get_contact_count()-1):
		var collider = state.get_contact_collider_object(i)

		var shapeIndex = state.get_contact_local_shape(i)
		var ownerIndex = shape_find_owner(shapeIndex)

		var pointVel = (points[ownerIndex].position - points[ownerIndex].previousPosition) * 60.0
		var colliderVel = state.get_contact_collider_velocity_at_position(i)

#
		if state.get_contact_collider_object(i) is StaticBody2D:
			var normalVec = state.get_contact_local_normal(i)

			#negative velocity on normal
			var velOnNormal = normalVec.dot(pointVel) * normalVec
			points[ownerIndex].position = points[ownerIndex].position - 2 * velOnNormal * (1.0/60.0)

			#0 force on normal
			var pointForce = points[ownerIndex].force
			var pointForceOnNormal = normalVec.dot(pointForce) * normalVec

			points[ownerIndex].force -= pointForceOnNormal

		else:
			var newV = (pointVel * (points[ownerIndex].mass * mass - collider.mass) + (2 * collider.mass * colliderVel)) / (points[ownerIndex].mass * mass + collider.mass)
			#points[ownerIndex].previousPosition = points[ownerIndex].position
			points[ownerIndex].position = points[ownerIndex].previousPosition + newV * (1.0/60.0)

			#A.v = (A.u * (A.m - B.m) + (2 * B.m * B.u)) / (A.m + B.m)


	for point in points:
		point.move(1.0/60.0)
	update()

func _index_to_pos(i):
	return Vector2( i % columns, int(i / columns) )
func get_point(x,y):
	return points[y * columns + x]
func set_point(x,y,p):
	points[y * columns + x] = p

func create_grid():
	# build the grid by suppling the points
	var grid = Vector2(columns,rows)
	#size is the distance bewteen points/ size of each cell
	var size = Vector2(8,8)
	if(cloth_texture):
		size = cloth_texture.get_size() / grid

	points.resize(rows*columns)
	shapeArray.resize(rows*columns)
	contacts_reported = points.size()

	for i in range(points.size()):
		var mass = 1.0
		var pos = _index_to_pos(i)
		if pos.y == 0 and (pos.x == 0 or pos.x == columns -1) :
			mass = 0.0
		var newPoint = PointMass.new(Vector2(pos.x,pos.y)*size, mass)
		points[i] = newPoint
		var _bodyShape = CollisionShape2D.new()
		var _shape = CircleShape2D.new(); _shape.set_radius(4);
		_bodyShape.set_shape(_shape)
		shapeArray[i] = _bodyShape
		add_child(_bodyShape)

	#connect the points with constraints and add them to the constraints array
	for y in rows:
		for x in columns:
			#if it isnt in the last column
			#then connect it to the point in the next column
			var thisPoint = get_point(x,y)
			if x < columns-1:
				var newConstraint = Constraint.new(thisPoint,get_point(x+1,y), springConstant, dampingConstant)
				constraints.append(newConstraint)

			#if it isnt the last row
			#then connect it to the point in the next row
			if y < rows-1:
				var newConstraint = Constraint.new(thisPoint, get_point(x,y+1), springConstant, dampingConstant)
				constraints.append(newConstraint)

func _draw():
	draw_circle(Vector2(0,0),5,Color(1,0,0))
	#draw each point
	for point in points:
		draw_point(point)
	#draw each constraint
	for constraint in constraints:
		draw_constraint(constraint)

func draw_point(point):
	 draw_circle(point.position, pointRadius, Color(point.mass,point.mass,point.mass,1) )



func draw_constraint(constraint):
	#var absFracExten = clamp(abs(_constraint.extension/(3*spacing)),0,1)
	#var thisColor = Color.from_hsv(absFracExten,absFracExten,absFracExten)
	draw_line(constraint.pointA.position, constraint.pointB.position,ColorN("red"))
	pass
