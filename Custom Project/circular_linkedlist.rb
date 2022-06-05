class Node
	attr_accessor :data,:next,:prev
	def initialize(data)
			@data = data
			@next = nil
			@prev = nil
	end
end

class CircularLinkedList
	attr_accessor :head
	def initialize
			@head = nil
	end
end

def insert_at_end(head,val)
	if head == nil
			head = Node.new(val)
			head.next = head
			head.prev = head
			return head
	end
	itr = head
	while itr.next != head
			itr = itr.next
	end
	node = Node.new(val)
	itr.next = node
	node.next = head
	node.prev = itr
	head.prev = node
	return head
end

def get_length(head)
	count  = 1
	itr = head
	while itr.next != head
		count +=1
		itr = itr.next
	end
	return count
end

def get_index(head,node)
	loc  = 1
	itr = head
	while itr.next != head
		if itr == node
			return loc
		end
		loc +=1
		itr = itr.next
	end
	return loc
end