--[[
List Class by ViktorGrego

I've implemented a simple data structure for personal use, but I've decided to share in case of study or personal use. Any Questions just pm me.

-----

ListNode Class
Properties:
+ value: any element to be stored in the list

Methods:
+print: prints the value contained in the list node

-----

List Class
Properties:
-None

Methods:
+iterate: Iterates through the List
Complexity: O(n)
Example Code:
for v in myList:iterate() do
	v:print()
end

+getFirst(): Returns the FIRST element from the list.
Complexity: O(1)
Example: from 1>5>6>7 it will return 1

+getLast(): Returns the LAST element from the list
Complexity: O(1)
Example: from 1>5>6>7 it will return 7

+insertFirst(o): inserts the a element in the FIRST position of the list
Complexity: O(1)
Example: if list is 1>5>6>7 and we run insertFirst(0) the final list is: 0>1>5>6>7

+insertLast(o): inserts the a element in the LAST position of the list
Complexity: O(1)
Example: if list is 1>5>6>7 and we run insertFirst(0) the final list is: 1>5>6>7>0

+isEmpty(): returns true if the list has no elements
Complexity: O(1)

+removeElement(o): removes the element from the list if it exists, if not returns nil
Complexity: O(n)
Example: if list is 1>5>6>7 and we run removeElement(6) the final list is: 1>5>7

+removeFirst(): removes the FIRST element from list
Complexity: O(1)
if list is 1>5>6>7 and we run removeFirst() the final list is: 5>6>7

+removeLast(): removes the LAST element from list
Complexity: O(1)
if list is 1>5>6>7 and we run removeLast() the final list is: 1>5>6

+contains(o): returns true if element o exists in the list
Complexity: O(n)

+print(): prints the list
Complexity: O(n)
]]

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