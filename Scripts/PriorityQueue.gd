extends Reference
class_name PriorityQueue

# Priority Queue implementation with binary heap
var heap
var current_size

class HeapData:
	var priority = 0.0
	var data
	var index

func _init():
	heap = [HeapData.new()]
	current_size = 0

func _percUp(i):
	while floor(i / 2) > 0:
		if heap[i].priority < heap[floor(i / 2)].priority:
			var tmp = heap[floor(i / 2)]
			heap[floor(i / 2)] = heap[i]
			heap[i] = tmp
			heap[i].index = tmp.index
			tmp.index = i
		i = floor(i / 2)

func insert(priority, data):
	var heap_data = HeapData.new()
	heap.append(heap_data)
	current_size += 1
	heap_data.priority = priority
	heap_data.data = data
	heap_data.index = current_size
	_percUp(current_size)
	return heap_data

func _percDown(i):
	while (i * 2) <= current_size:
		var mc = _minChild(i)
		if heap[i].priority > heap[mc].priority:
			var tmp = heap[i]
			heap[i] = heap[mc]
			heap[mc] = tmp
			heap[mc].index = tmp.index
			tmp.index = mc
		i = mc

func _minChild(i):
	if i * 2 + 1 > current_size:
		return i * 2
	else:
		if heap[i*2].priority < heap[i*2+1].priority:
			return i * 2
		else:
			return i * 2 + 1

func pop_front():
	var retval = heap[1].data
	heap[1] = heap[current_size]
	heap[1].index = 1
	heap.pop_back()
	current_size -= 1
	_percDown(1)
	return retval

func pop_back():
	return heap.pop_back().data

func empty():
	return current_size < 1
