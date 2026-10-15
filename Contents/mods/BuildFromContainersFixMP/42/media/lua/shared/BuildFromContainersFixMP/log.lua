local function log(...)
	local count = select("#", ...)
	local args = {}

	for i = 1, count do
		args[i] = tostring(select(i, ...))
	end

	local where = "client"
	if(isServer()) then where = "server" end

	DebugLog.log("[BuildFromContainersFixMP (" .. where .. ")] " .. table.concat(args, " "))
end

return log
