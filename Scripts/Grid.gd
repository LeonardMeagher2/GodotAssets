extends Graph
class_name GraphGrid

export var diagonals = false
export var bounds = AABB()

func _init(diagonals = false,name=""):
	._init(name)
	self.diagonals = diagonals

func simple_neighbors(from :Vector3, in_bounds = true, two_d = false):
	var my_neighbors
	if diagonals == false:
		if two_d:
			my_neighbors = [
				from + Vector3( 1, 0, 0),
				from + Vector3(-1, 0, 0),
				from + Vector3( 0, 0, 1),
				from + Vector3( 0, 0, -1),
			]
		else:
			my_neighbors = [
				from + Vector3( 1, 0, 0),
				from + Vector3(-1, 0, 0),
				from + Vector3( 0,-1, 0),
				from + Vector3( 0, 1, 0),
				from + Vector3( 0, 0, 1),
				from + Vector3( 0, 0, -1)
			]
	else :
		if two_d:
			my_neighbors = [
				from + Vector3( 1, 0, 0),
				from + Vector3( 0, 1, 0),
				from + Vector3(-1, 0, 0),
				from + Vector3( 0, 0, 1),
				from + Vector3( 1, 0, 1),
				from + Vector3(-1, 0, 1),
				from + Vector3( 0, 0, -1),
				from + Vector3( 1, 0, -1),
				from + Vector3(-1, 0, -1),
			]
		else:
			my_neighbors = [
				from + Vector3( 0,-1, 0),
				from + Vector3( 1,-1, 0),
				from + Vector3( 1, 0, 0),
				from + Vector3( 1, 1, 0),
				from + Vector3( 0, 1, 0),
				from + Vector3(-1, 1, 0),
				from + Vector3(-1, 0, 0),
				from + Vector3(-1, -1, 0),

				from + Vector3( 0, 0, 1),
				from + Vector3( 0,-1, 1),
				from + Vector3( 1,-1, 1),
				from + Vector3( 1, 0, 1),
				from + Vector3( 1, 1, 1),
				from + Vector3( 0, 1, 1),
				from + Vector3(-1, 1, 1),
				from + Vector3(-1, 0, 1),
				from + Vector3(-1, -1, 1),

				from + Vector3( 0, 0, -1),
				from + Vector3( 0,-1, -1),
				from + Vector3( 1,-1, -1),
				from + Vector3( 1, 0, -1),
				from + Vector3( 1, 1, -1),
				from + Vector3( 0, 1, -1),
				from + Vector3(-1, 1, -1),
				from + Vector3(-1, 0, -1),
				from + Vector3(-1, -1, -1),
			]
	if in_bounds:
		for i in range(my_neighbors.size()-1,-1,-1):
			if bounds.has_point(my_neighbors[i]) == false:
				my_neighbors.remove(i)
	return my_neighbors

func neighbors(from : Vector3, two_d = false):
	var my_neighbors = simple_neighbors(from,true,two_d)
	if(neighbor_connections.has(from)):
		for neighbor in neighbor_connections[from]:
			if two_d:
				if neighbor.y == from.y and my_neighbors.has(neighbor) == false:
					my_neighbors.append(neighbor)
			elif my_neighbors.has(neighbor) == false:
				my_neighbors.append(neighbor)
	my_neighbors.shuffle()
	return my_neighbors

func cost(from: Vector3, to: Vector3):
	if edges.has([from,to]):
		return edges[[from,to]]
	elif neighbors(from).has(to):
		return 1.0
	return INF

func average_neighbor_cost(from,two_d = false):
	var c = 0
	var all_inf = true
	var size = 0
	var n = neighbors(from,two_d)
	for to in n:
		var to_c = cost(from,to)
		if to_c != INF:
			size += 1
			all_inf = false
			c += to_c
		else:
			c += c
	if all_inf:
		return INF
	if size:
		c /= size
	return c

func make_edges_to_neighbors(from,weight:float = 1.0, bi_directional = true):
	for to in simple_neighbors(from,false):
		self.make_edge(from,to,weight,bi_directional)

func make_edges_from_neighbors(to,weight:float = 1.0, bi_directional = true):
	for from in simple_neighbors(to,false):
		self.make_edge(from,to,weight,bi_directional)

func add_weight_to_neighbors_edges(from,weight:float, bi_directional = true):
	for to in simple_neighbors(from,false):
		self.add_weight_to_edge(from,to,weight,bi_directional,true)

func add_weight_from_neighbors_edges(to,weight:float, bi_directional = true):
	for from in simple_neighbors(to,false):
		self.add_weight_to_edge(from,to,weight,bi_directional,true)

func remove_edges_to_neighbors(from,bi_directional = true):
	for to in simple_neighbors(from,false):
		self.remove_edge(from,to,bi_directional)

func remove_edges_from_neighbors(to,bi_directional = true):
	for from in simple_neighbors(to,false):
		self.remove_edge(from,to,bi_directional)


func _has_line_of_sight(from:Vector3,to:Vector3, grid: Dictionary):
	if grid.has(from) == false:
		grid[from] = 0.0

	var has_los = grid[from]

	var diff = (to - from).floor()
	var abs_diff = Vector3(abs(diff.x), abs(diff.y), abs(diff.z))
	var sign_diff = Vector3(sign(diff.x),sign(diff.y), sign(diff.z))
	var dx = Vector3(from.x + sign_diff.x, from.y, from.z)
	var dy = Vector3(from.x, from.y + sign_diff.y, from.z)
	var dz = Vector3(from.x, from.y, from.z + sign_diff.z)

	if grid.has(dx) == false:
		#_has_line_of_sight(dx,to,grid)
		grid[dx] = 0.0
	if grid.has(dy) == false:
		#_has_line_of_sight(dy,to,grid)
		grid[dy] = 0.0
	if grid.has(dz) == false:
		#_has_line_of_sight(dy,to,grid)
		grid[dz] = 0.0

	if grid.has(from + sign_diff) == false:
		#_has_line_of_sight(from + sign_diff,to,grid)
		grid[from + sign_diff] = 0.0

	if abs_diff.x >= abs_diff.y and abs_diff.x >= abs_diff.z:
		if grid[dx] and cost(from,dx) != INF:
			has_los = grid[dx]

	if abs_diff.y >= abs_diff.x and abs_diff.y >= abs_diff.z:
		if grid[dy] and cost(from,dy) != INF:
			has_los = grid[dy]

	if abs_diff.z >= abs_diff.x and abs_diff.z >= abs_diff.y:
		if grid[dz] and cost(from,dz) != INF:
			has_los = grid[dz]

	if abs_diff.x > 0.0 and abs_diff.y > 0.0 or abs_diff.x > 0.0 and abs_diff.z > 0.0 or abs_diff.y > 0.0 and abs_diff.z > 0.0:
		if grid[from + sign_diff] < 1.0:
			has_los = grid[from + sign_diff]
			grid[from] = has_los

	if has_los > grid[from]:
		grid[from] = has_los

	return grid[from]

func line_of_sight(goals : Array, max_distance = INF, early_exit:Array = [], los_grid_seed:Dictionary = {}):
	var frontier = PriorityQueue.new()
	var came_from = {}
	var cost_so_far = {}
	var los_grids = {}
	var sight = {}

	for goal in goals:
		#goal is expected to be an array [PRIORITY, from]
		came_from[goal[1]] = null
		cost_so_far[goal[1]] = goal[0]
		los_grids[goal] = los_grid_seed.duplicate()
		los_grids[goal][goal[1]] = 1.0
		sight[goal[1]] = 1.0
		frontier.insert(goal[0],goal[1])


	while frontier.empty() == false:
		var current = frontier.pop_front()

		if cost_so_far[current] >= max_distance:
			continue

		if early_exit.size() and early_exit.has(current):
			break

		for next in self.neighbors(current):

			if sight.has(next) == false and (came_from.has(next) == false or came_from[next] != null):
				sight[next] = 0.0
				for goal in goals:
					sight[next] += _has_line_of_sight(next,goal[1],los_grids[goal])
				sight[next] = clamp(sight[next],0.0,1.0)

			var new_cost = 1.0 + cost_so_far[current] + (1.0 - sight[next])
			if not cost_so_far.has(next) or new_cost < cost_so_far[next]:
				cost_so_far[next] = new_cost
				frontier.insert(new_cost,next)
				came_from[next] = current


	return {
		cost = sight,
		from = came_from,
		distance = cost_so_far
	}

func line(from:Vector3, to: Vector3, exit: FuncRef = null) -> Array:
	var ray = (to-from).normalized()
	var step = Vector3(sign(ray.x),sign(ray.y),sign(ray.z))
	var tmax = Vector3(INF,INF,INF)
	var delta = Vector3(INF,INF,INF)
	var visited = [from]

	var was_negative = false
	if ray.x != 0.0 :
		tmax.x = (from.x + step.x - ray.x)/ray.x
		delta.x = 1.0/ray.x*step.x
		if from.x != to.x and ray.x < 0.0:
			from.x -= 1.0
			was_negative = true
	if ray.y != 0.0 :
		tmax.y = (from.y + step.y - ray.y)/ray.y
		delta.y = 1.0/ray.y*step.y
		if from.y != to.y and ray.y < 0.0:
			from.y -= 1.0
			was_negative = true
	if ray.z != 0.0 :
		tmax.z = (from.z + step.z - ray.z)/ray.z
		delta.y = 1.0/ray.z*step.z
		if from.z != to.z and ray.z < 0.0:
			from.z -= 1.0
			was_negative = true

	if was_negative == true:
		visited.push_back(from)

	while from != to:
		if tmax.x < tmax.y:
			if tmax.x < tmax.z:
				from.x += step.x
				tmax.x += delta.x
			else:
				from.z += step.z
				tmax.z += delta.z
		else:
			if tmax.y < tmax.z:
				from.y += step.y
				tmax.y += delta.y
			else:
				from.z += step.z
				tmax.z += delta.z
		if exit != null and exit.call_func(self,visited[visited.size()-1],from,visited.size()) == true:
			break
		visited.push_back(from)
	return visited

func clone(other, deep = false):
	.clone(other,deep)
	self.bounds = AABB(other.bounds.position, other.bounds.size)
	self.diagonals = other.diagonals
