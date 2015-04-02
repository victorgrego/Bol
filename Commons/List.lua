class 'Node'

function Node:__init(o)
	self.next = o.next or nil
	self.prev = o.prev or nil
	self.value = o.value or nil
	return o
end

function Node:print()
	if self.value == nil then 
		print("Root or nil") 
		return
	end
	
	print(self.value)
end

class 'List'

function List:__init(o)
	self.root = Node()
	
	self.root.next = self.root
	self.root.prev = self.root
	return o
end

function List:getFirst()
	return root.next
end

function List:getLast()
	return root.prev
end

function List:insertLast(o)
	element = Node()
	element.value = o
	
	element.prev = self.root.prev
	self.root.prev = element
	element.next = self.root
	element.prev.next = element
end

function List:insertFirst(o)
	element = Node()
	element.value = o
	
	element.next = self.root.next
	self.root.next = element
	element.prev = self.root
	element.next.prev = element
end

function List:removeElement(o)
    local i = self.root.next
    if(i == self.root) then return nil end
    while i ~= self.root do
        if(i.value == o) then
            i.prev.next = i.next
            i.next.prev = i.prev
            return i.value
        end
        i = i.next
    end
    return nil
end

function List:contains(o)
    local i = self.root.next
    if (i == self.root) then return false end
    
    while i ~= self.root do
        if(i.value == o) then return true end
        
        i = i.next
    end
    return false
end

function List:removeFirst()
	result = self.root.next
	if(result == nil) then return nil end
	
	self.root.next = self.root.next.next
	self.root.next.prev = self.root
	
	return result.value
end

function List:removeLast()
	result = self.root.prev
	if(result == nil) then return nil end
	
	self.root.prev = self.root.prev.prev
	self.root.prev.next = self.root
	
	return result
end

function List:print()
	i = self.root.next
	while i ~= self.root do
		i:print()
		i = i.next
	end
end
