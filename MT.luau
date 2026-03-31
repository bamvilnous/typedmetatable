--	@bamvilnous
--	3/30/26

--!strict

type function metatablebuilder(T: type, MT: type)
	assert(T:is("table"), "T must be of type table!")
	assert(MT:is("table"), "MT must be of type table!")
	
	--> operators
	local OperatorNames = {
		types.singleton("__lt"),
		types.singleton("__le"),
		types.singleton("__len"),
		types.singleton("__iter"),
		types.singleton("__concat"),
		types.singleton("__unm"),
		types.singleton("__add"),
		types.singleton("__sub"),
		types.singleton("__mul"),
		types.singleton("__div"),
		types.singleton("__idiv"),
		types.singleton("__mod"),
		types.singleton("__pow"),
		types.singleton("__tostring"),
		types.singleton("__eq"),
	} :: {type}
	
	local Metadata = types.newtable()
	for _, OperatorNameSingleton in OperatorNames do
		local Operator = MT:readproperty(OperatorNameSingleton)
		if not Operator then continue end
		
		local Key = OperatorNameSingleton:value()
		if type(Key) ~= "string" then continue end
		
		assert(Operator.tag == "function", Key .. " must be of type function!")
		
		local Returns = Operator:returns()
		local Parameters = Operator:parameters()
		if Parameters and Parameters.head then
			Parameters.head[1] = T
		end
		
		local TypeFunction = types.newfunction(Parameters, Returns)
		
		Metadata:setproperty(OperatorNameSingleton, TypeFunction)
	end
	
	T:setmetatable(Metadata)
	
	--> properties
	local __metatable = MT:readproperty(types.singleton("__metatable"))
	local __mode = MT:readproperty(types.singleton("__mode"))
	
	if __metatable then
		T:setproperty(types.singleton("__metatable"), __metatable)
	end
	if __mode then
		T:setproperty(types.singleton("__mode"), __mode)
	end
	
	--> indexing
	local Intersection = T
	
	local __index = MT:readproperty(types.singleton("__index"))
	if __index and __index:is("table") then
		local IndexIntersection = types.newtable()
		for property, mapping in __index:properties() do
			if T:readproperty(property) then continue end
			if mapping.read then
				IndexIntersection:setreadproperty(property, mapping.read)
			end
			if mapping.write then
				IndexIntersection:setwriteproperty(property, mapping.write)
			end
		end

		Intersection = types.intersectionof(Intersection, IndexIntersection)
	end
	
	--> __call
	local __call = MT:readproperty(types.singleton("__call"))
	if __call and __call:is("function") then -- trim first parameter (self) and intersect T & __call
		local Params = __call:parameters()
		local Returns = __call:returns()
		
		local NewHead = {}
		if Params.head then
			for i = 2, #Params.head do
				table.insert(NewHead, Params.head[i])
			end
		end

		local StrippedCall = types.newfunction(
			{head = NewHead, tail = Params.tail},
			Returns
		)

		Intersection = types.intersectionof(Intersection, StrippedCall)
	end
	
	return Intersection
end

function build<T, MT>(Table: T, Metatable: MT): metatablebuilder<T, MT>
	return setmetatable(Table, Metatable :: any) :: any
end

-- unfortunately the typechecker implodes when MT is intersected with anything
-- and you cant constrain generics yet ^^
-- but anyways heres a metadata type if you want to use it
export type Metadata = {
	__add: ((any, any) -> (...any))?,
	__sub: ((any, any) -> (...any))?,
	__mul: ((any, any) -> (...any))?,
	__div: ((any, any) -> (...any))?,
	__mod: ((any, any) -> (...any))?,
	__pow: ((any, any) -> (...any))?,
	__unm: ((any) -> (...any))?,

	__concat: ((any, any) -> (...any))?,
	__len: ((any) -> number)?,
	__tostring: ((any) -> string)?,
	__eq: ((any, any) -> boolean)?,
	__lt: ((any, any) -> boolean)?,
	__le: ((any, any) -> boolean)?,

	__index: (((any, any) -> (...any)) | {[any]: any})?,
	__newindex: (((any, any, any) -> (...any)) | {[any]: any})?,

	__call: ((any, ...any) -> ...any)?,
	__iter: ((any) -> (...any))?,

	__metatable: any?,
	__mode: string?,
}

return build
