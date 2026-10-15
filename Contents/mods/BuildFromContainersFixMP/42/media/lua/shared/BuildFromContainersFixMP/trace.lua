local log = require "BuildFromContainersFixMP/log"

local function trace()
	local trace = getLuaStackTrace()

	log("---- Trace Start ----")
	for i = 0, trace:size() - 1 do
		log(trace:get(i))
	end
	log("---- Trace End ----")
end

return trace
