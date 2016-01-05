local LuaUnit = require('luaunit')
local lu = LuaUnit.LuaUnit

local function getAddonName()
	local name
	for line in io.lines(".project") do
		name = line:match("^\t<name>(.+)</name>")
		if(name) then
			return name
		end
	end
	print("Could not find addon name.")
	return nil
end

local function importAddonFiles()
	for line in io.lines("src/" .. getAddonName() .. ".txt") do
		if(not line:find("^%s*##") and line:find("\.lua")) then
			require(line:match("^%s*(.+)\.lua"))
		end
	end
end

local function mockGlobals()
	function GetWindowManager()
		return {}
	end
	function GetAnimationManager()
		return {}
	end
	function GetEventManager()
		return { RegisterForEvent = function() end }
	end
end

--mockGlobals()
--require('esoui.libraries.globals.globalvars')
--require('esoui.libraries.globals.globalapi')
--require('esoui.libraries.utility.baseobject')
--require('esoui.libraries.utility.zo_tableutils')
--require('esoui.ingamelocalization.localizegeneratedstrings')
importAddonFiles()

require('LibTextFilterTest')

---- Control test output:
-- lu:setOutputType( "NIL" )
-- lu:setOutputType( "TAP" )
-- lu:setVerbosity( LuaUnit.VERBOSITY_LOW )
os.exit( lu:run() )
