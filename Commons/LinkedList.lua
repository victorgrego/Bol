class 'ListNode'

function ListNode:__init(o)
	self.value = nil
	self.next = nil
	self.prev = nil
end

function ListNode:__eq(o, p)
	if(o == nil or p == nil) then return false end
	if(o.value == p.value and o.next == p.next and o.prev == p.prev) then return true end
	return false
end

function ListNode:print()
	if self.value == nil then 
		print("Root or nil") 
		return
	end
	
	print(self.value)
end

class 'List'

function List:__init(o)
	self.root = ListNode()
	
	self.root.next = self.root
	self.root.prev = self.root
	self.root.value = -1
	self.len = 0
end

function List:__len()
	return self.len
end

function List:iterate()
	local i = self.root
	return function()
		i = i.next
		if i ~= self.root then return i.value end 
	end
end

function List:getFirst()
	return self.root.next.value
end

function List:getLast()
	return self.root.prev.value
end

function List:isEmpty()
	return self.root.next == self.root
end

function List:insertLast(o)
	element = ListNode()
	element.value = o
	
	element.prev = self.root.prev
	self.root.prev = element
	element.next = self.root
	element.prev.next = element
	self.len = self.len + 1
end

function List:insertFirst(o)
	element = ListNode()
	element.value = o
	
	element.next = self.root.next
	self.root.next = element
	element.prev = self.root
	element.next.prev = element
	self.len = self.len + 1
end

function List:removeElement(o)
    local i = self.root.next
    if(i == self.root) then return nil end
    while i ~= self.root do
        if(i.value == o) then
            i.prev.next = i.next
            i.next.prev = i.prev
			self.len = self.len - 1
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
	self.len = self.len - 1
	
	return result.value
end

function List:removeLast()

	result = self.root.prev
	if(result == nil) then return nil end
	
	self.root.prev = self.root.prev.prev
	self.root.prev.next = self.root
	self.len = self.len - 1
	
	return result
end

function List:print()	
	local i = self.root.next
	
	while i ~= self.root do
		i:print()
		i = i.next
	end
end