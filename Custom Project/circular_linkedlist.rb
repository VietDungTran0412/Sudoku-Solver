# Circular Linked List Implementation

# Node of each record
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

# Insert new node at the end of list
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

# Get the length of linked list
def get_length(head)
	count  = 1
	itr = head
	while itr.next != head
		count +=1
		itr = itr.next
	end
	return count
end

# Get specific index
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