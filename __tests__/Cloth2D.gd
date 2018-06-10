extends RigidBody2D
#texture to be used as cloth
export(Texture) var ClothTexture 
export(int) var rows
export(int) var coloumns 
export(float) var spacing = 50.0
export(float) var precision = 5.0
export(float) var pointRadius = 3.0
export(int) var rigidity = 1

#point Grid.
var pointGrid = []
#This must be a grid so that constraints can easily be configured
#an implementation that doesnt use a grid matrix would be better so as to allow for other shapes
#however that makes attaching contraints harder

#constraint Array
var constraintArray = []

#physicsBody
var bodyShape
var shape
var pointCloud = []

#dragging
var pressed = false
var prevWeight
var movingPoint

func _ready():
	createSystem (rows, coloumns)
	set_process_input(true)
	
	#initialize its collision body structure
	shape = ConvexPolygonShape2D.new()
	bodyShape = CollisionShape2D.new()
	bodyShape.shape = shape
	add_child(bodyShape)

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		#check if a pointMass is being pressed
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			for rows in pointGrid:
				for point in rows:
					var vecDiff = get_local_mouse_position() - point.position
					if vecDiff.length() < pointRadius*4 :
						pressed = event.pressed
						movingPoint = point
						prevWeight = movingPoint.weight
		elif pressed:
			pressed = false
			movingPoint.weight = prevWeight
			print("released")
		
	if pressed:
		if event is InputEventMouseMotion:
			movingPoint.position = get_local_mouse_position()
			movingPoint.weight = 10000000

func _physics_process(delta):
	# refresh the point cloud
	pointCloud = []
	for rows in pointGrid:
		for point in rows:
			pointCloud.append(point.position)
	shape.set_point_cloud(pointCloud)
			
	# >>>>>>calculate how much we will shorten each constraint by<<<<<< #
	for i in range(rigidity):
		for _constraint in constraintArray:
			_constraint.adjustTo(spacing)
	update()
	

func createSystem (rows, cols):
	# build the grid by suppling the points
	for y in rows:
		
		var thisRow = []
		
		for x in cols: 
			var newPoint = pointMass.new()
			
			var _weight = 0.5
			if (x == 0 or x == cols-1) and y == 0:
				_weight = 5000
			randomize()
			rand_seed(randi())
			newPoint.setup(Vector2(x,y)*(randi()%50-25), _weight)
			thisRow.append(newPoint)
			
		pointGrid.append(thisRow)
	
	#connect the points with constraints and add them to the constraints array
	for y in rows:
		for x in cols:
			#if it isnt in the last column
			#then connect it to the point in the next column
			if x < cols-1: 
				var newConstraint = constraint.new()
				newConstraint.setup(pointGrid[y][x],pointGrid[y][x+1],spacing)
				constraintArray.append(newConstraint)
			
			#if it isnt the last row
			#then connect it to the point in the next row
			if y < rows-1: 
				var newConstraint = constraint.new()
				newConstraint.setup(pointGrid[y][x],pointGrid[y+1][x],spacing)
				constraintArray.append(newConstraint)

func _draw():
	draw_circle(Vector2(0,0),5,Color(1,0,0))
	#draw each point
	for rows in pointGrid:
		for point in rows:
			drawPoint(point)
	#draw each constraint
	for _constraint in constraintArray:
		drawConstraint(_constraint)

#Point mass class
class pointMass:
	var weight = 0 #from 0 to 1 (to make it easy to map to colors for debugging)
	var position = Vector2()
	
	#configure this point
	func setup(p, w):
		weight = w
		position = p

func drawPoint(_pointMass):
	 draw_circle(_pointMass.position, pointRadius, Color(_pointMass.weight,_pointMass.weight,_pointMass.weight,1) )

#Constraint class
class constraint:
	#The 2 point mass objects connected by this constraint
	var pointA
	var pointB
	var length
	var extension
	
	#configure this constraint
	func setup(A, B, spacing):
		pointA = A
		pointB = B
		length = getLength() 
		extension = length - spacing
	
	#spacing is a scalar that determines how close the constraint wants the points to be
	func adjustTo(spacing):
		#calculate the direction vector
		var AtoB_UnitVec = (pointB.position - pointA.position).normalized()
		
		#current constraint length
		length = getLength() 
		
		#calculate the extension from how long it should be
		extension = length - spacing
		
		#if the length doesnt fall within range of precision
		#then adjust it
#		if !(-precision < extension and extension < precision) : 
#			var speed = sign(extension) * maxUnsignedSpeed
		
		#calculate who gets moved more
		#the bigger the point's fractional weight, the less it moves
		# the longer the extension the faster it moves
		var A_distanceMultiplier = 1 - pointA.weight/(pointA.weight + pointB.weight)
		A_distanceMultiplier *= extension #*10/spacing
		var B_distanceMultiplier = 1 - pointB.weight/(pointA.weight + pointB.weight)
		B_distanceMultiplier *= extension #*10/spacing
		
		#find its new position
		var newPointAPos = pointA.position + AtoB_UnitVec * A_distanceMultiplier 
		var newPointBPos = pointB.position - AtoB_UnitVec * B_distanceMultiplier 
		var newLength = (newPointBPos-newPointAPos).length()
		
		#move the point
		if newLength < length or newLength < spacing*2 :
			pointA.position = newPointAPos
			pointB.position = newPointBPos
	
	# calculate the length of the constraint
	func getLength():
		return (pointB.position - pointA.position).length()
		
	
func drawConstraint(_constraint):
	var absFracExten = clamp(abs(_constraint.extension/(3*spacing)),0,1)
	var thisColor = Color.from_hsv(absFracExten,absFracExten,absFracExten)
	draw_line(_constraint.pointA.position, _constraint.pointB.position,thisColor)