# typedmetatable
wrapper for creating a metatable that provides typing. made this just for fun, the only new functionality provided by this is typing for __call.

# example
```luau
local buildmt = require("@self/MT")

function tween_model(Model: Model, ...)
	--...
end
function tween_object(_, Instance: Instance, ...)
	--...
end
local TweenModule = buildmt({model = tween_model}, {__call = tween_object)
TweenModule() -- autocompletes parameters
TweenModule.model() -- autocompletes parameters
```
