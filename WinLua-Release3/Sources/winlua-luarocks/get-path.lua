--~ print(arg[-1])
print(arg[-1]:match("(.*\\)"))
local f = io.open('c:\\temp\\winlua-path.txt','w')
if f then
	f:write(arg[-1]:match("(.*\\)"))
	f:close()
else
	error('failed to find a writeable file.')
end

