extends Resource
class_name Graph

export var edges = {}
export var neighbor_connections = {}

func _init(name = ""):
	resource_name = name

func make_edge(from,to,weight:float = 1.0, bi_directional = true):
	if neighbor_connections.has(from):
		if neighbor_connections[from].has(to) == false:
			neighbor_connections[from].append(to)
	else:
		neighbor_connections[from] = [to]

	edges[[from,to]] = weight
	if bi_directional:
		make_edge(to,from,weight,false)

func remove_edge(from,to,bi_directional = true):
	if neighbor_connections.has(from):
		if neighbor_connections[from].has(to):
			neighbor_connections[from].erase(to)
		if neighbor_connections[from].size() == 0:
			neighbor_connections.erase(from)

	edges.erase([from,to])
	if bi_directional:
		remove_edge(to,from,false)

func add_weight_to_edge(from, to, weight: float, bi_directional = true, remove_if_zero = false):
	if edges.has([from,to]):
		edges[[from,to]] += weight
		if remove_if_zero and edges[[from,to]] == 0:
			remove_edge(from,to,false)
	elif remove_if_zero == false or weight != 0:
		make_edge(from,to,weight,false)

	if bi_directional:
		add_weight_to_edge(to,from,weight,false, remove_if_zero)

func has_edge(from,to) -> bool:
	if edges.has([from,to]):
		return true
	return false

func add_weight_from_graph(graph : Graph):
	for edge in graph.edges:
		add_weight_to_edge(edge[0],edge[1],graph.edges[edge],false)
	pass

func cost(from, to):
	if edges.has([from,to]):
		return edges[[from,to]]
	return INF

func average_neighbor_cost(from):
	var c = 0
	var size = 0
	var all_inf = true
	var n = neighbors(from)
	for to in n:
		var to_c = cost(from,to)
		if to_c != INF:
			size += 1
			all_inf = false
			c += to_c
	if all_inf:
		return INF
	if size:
		c /= size
	return c

func neighbors(from):
	if(neighbor_connections.has(from)):
		return neighbor_connections[from]
	return []

func clear():
	edges = {}
	neighbor_connections = {}


func dijkstra(goals: Array, maximum_distance = INF,early_exit = null,custom_cost:FuncRef = null, custom_cost_func_extra_arg = null):
	var frontier = PriorityQueue.new()
	var came_from = {}
	var cost_so_far = {}
	var distance_so_far = {}

	for goal in goals:
		#goal is expected to be an array [PRIORITY, from]
		came_from[goal[1]] = null
		cost_so_far[goal[1]] = goal[0]
		distance_so_far[goal[1]] = 0
		frontier.insert(goal[0],goal[1])


	while frontier.empty() == false:
		var current = frontier.pop_front()

		if distance_so_far[current] >= maximum_distance or distance_so_far[current] <= -maximum_distance:
			continue

		if early_exit != null :
			if early_exit is FuncRef and early_exit.call_func(cost_so_far) == true:
				break
			elif early_exit is Array and early_exit.has(current):
				break

		for next in self.neighbors(current):

			var new_cost = cost_so_far[current] + self.cost(next,current)
			if custom_cost != null:
				new_cost = custom_cost.call_func(self,current,next,cost_so_far[current],custom_cost_func_extra_arg)

			if not cost_so_far.has(next) or new_cost < cost_so_far[next]:
				distance_so_far[next] = 1+distance_so_far[current]
				cost_so_far[next] = new_cost
				frontier.insert(new_cost,next)
				came_from[next] = current

	return {
		from = came_from,
		cost = cost_so_far
	}

func hash():
	return hash([edges.hash(),neighbor_connections.hash()])

func clone(other, deep = false):
	self.edges = other.edges.duplicate(deep)
	self.neighbor_connections = other.neighbor_connections.duplicate(deep)
