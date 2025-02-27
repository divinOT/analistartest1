analyzersWindow = nil
LOOT_ANALYZER_OPCODE = 120
EXP_ANALYZER_OPCODE = 121
storedExp = 0
storedLoot = 0
storedSupplies = 0
storedProfit = 0
startingTime = 0

EXP_REFRESH_SPEED = 5 * 500

function init()
	-- Main Window
	analyzersWindow = g_ui.loadUI('analyzers', modules.game_interface.getRightPanel())
	analyzersWindow:setup()
	analyzersWindow:setContentMinimumHeight(75)
	analyzersWindow:setContentMaximumHeight(85)
	
	-- 2nd analyzer: Loot Analyzer
	--lootAnalyzerWindow = g_ui.loadUI('analyzers/lootanalyzer', modules.game_interface.getRightPanel())
	--lootAnalyzerWindow:setup()
	--lootAnalyzerWindow:setContentMinimumHeight(110)
	
		--lootAmount = lootAnalyzerWindow:recursiveGetChildById('lootAmount')
		--lootAmount:setColor("green")
		--suppliesAmount = lootAnalyzerWindow:recursiveGetChildById('suppliesAmount')
		--suppliesAmount:setColor("yellow")
		--profitAmount = lootAnalyzerWindow:recursiveGetChildById('profitAmount')
	
	-- 5th analyzer: Exp Analyzer
	expAnalyzerWindow = g_ui.loadUI('analyzers/expanalyzer', modules.game_interface.getRightPanel())
	expAnalyzerWindow:setup()
	expAnalyzerWindow:setContentMinimumHeight(110)
	expAnalyzerWindow:setContentMaximumHeight(115)
	
		sessionAmount = expAnalyzerWindow:recursiveGetChildById('sessionAmount')
		expValueAmount = expAnalyzerWindow:recursiveGetChildById('expValueAmount')
		expValuePerHourAmount = expAnalyzerWindow:recursiveGetChildById('expValuePerHourAmount')
		nextLevelAmount = expAnalyzerWindow:recursiveGetChildById('nextLevelAmount')
		timetoLevelAmount = expAnalyzerWindow:recursiveGetChildById('timetoLevelAmount')
	
	-- Opcodes Registering
	--ProtocolGame.registerExtendedOpcode(LOOT_ANALYZER_OPCODE, onLootChange)
	ProtocolGame.registerExtendedOpcode(EXP_ANALYZER_OPCODE, onExperienceChange)
	
	-- Anti-steal code
  if (REGISTRATION_KEY ~= "AbcDeFgH") then
	g_logger.fatal("Invalid serial ID for the server, please contact julianandresbernalv@gmail.com or JulianBernalV#7033")
  end
	
	-- Extra tasks
	connect(LocalPlayer, {
		onLevelChange = onLevelChange,
	})
	
	connect(g_game, {
		onGameStart = refresh,
		onGameEnd = offline
	})
	
	if (g_game.isOnline()) then
		refresh()
	end
	
	setup()
	clean()
end

function terminate()
	analyzersWindow:destroy()
	--lootAnalyzerWindow:destroy()
	expAnalyzerWindow:destroy()
	
	disconnect(LocalPlayer, {
		onLevelChange = onLevelChange
	})
	
	disconnect(g_game, {
		onGameStart = refresh,
		onGameEnd = offline
	})
	

	-- Opcodes unRegistering
	--ProtocolGame.unregisterExtendedOpcode(LOOT_ANALYZER_OPCODE)
	ProtocolGame.unregisterExtendedOpcode(EXP_ANALYZER_OPCODE)
end

function refresh()
	analyzersWindow:close()
	--lootAnalyzerWindow:close()
	expAnalyzerWindow:close()
	
	local player = g_game.getLocalPlayer()
	if not player then return end
	
	startingTime = os.time()
	clean()
	startExpEvent()
	onLevelChange(player, player:getLevel(), player:getLevelPercent())
end

function getSessionTime(storedTime)
	local seconds = tonumber(os.time() - storedTime)

	if seconds <= 0 then
		return "00:00";
	else
		hours = string.format("%02.f", math.floor(seconds/3600));
		mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
		
    return ""..hours..":"..mins..""
	end
end

function startExpEvent()
	expSpeedEvent = addEvent(checkExpSpeed, EXP_REFRESH_SPEED)
end

function offline()
	removeEvent(expSpeedEvent)
	clean()
end

function toggle()
	if analyzersWindow:isVisible() then
		analyzersWindow:close()
	else
		analyzersWindow:open()
	end
end

function setup()
	--lootAmount:setText("000000000000000000000")
	--suppliesAmount:setText("000000000000000000000")
	--profitAmount:setText("000000000000000000000")
	
	sessionAmount:setText("00:00")
	expValueAmount:setText("000000000000000000000")
	expValuePerHourAmount:setText("000000000000000000000")
	nextLevelAmount:setText("000000000000000000000")
	timetoLevelAmount:setText("00000000000000:00000000000000")
end

function clean()
	storedExp = 0
	--storedLoot = 0
	storedSupplies = 0
	storedProfit = 0

	--lootAmount:setText("0")
	--suppliesAmount:setText("0")
	--profitAmount:setText("0")
	
	sessionAmount:setText("00:00")
	expValueAmount:setText("0")
	expValuePerHourAmount:setText("0")
	nextLevelAmount:setText("0")
	timetoLevelAmount:setText("00:00")
	
	if (g_game.isOnline()) then
		local localPlayer = g_game.getLocalPlayer()
		localPlayer.expSpeed = nil
		localPlayer.lastExps = nil
	end
end

function checkExpSpeed()
	local player = g_game.getLocalPlayer()
	if not player then return end

	local currentExp = player:getExperience()
	local currentTime = g_clock.seconds()
	if player.lastExps ~= nil then
		player.expSpeed = (currentExp - player.lastExps[1][1]) / (currentTime - player.lastExps[1][2])
	else
		player.lastExps = {}
	end
	
	table.insert(player.lastExps, {currentExp, currentTime})
	
	if #player.lastExps > 30 then
		table.remove(player.lastExps, 1)
	end
	
	changeExpSpeed(player)
	expSpeedEvent = scheduleEvent(checkExpSpeed, EXP_REFRESH_SPEED)
end

function expForLevel(level)
	return math.floor((50*level*level*level)/3 - 100*level*level + (850*level)/3 - 200)
end

function onLevelChange(localPlayer, value, percent)
	changeExpSpeed(localPlayer)
end

local function isNaN(v) return type(v) == "number" and v ~= v end
local function isInf(v) return v == math.huge end

function changeExpSpeed(localPlayer)
	if localPlayer.expSpeed ~= nil and localPlayer.lastExps ~= nil then
		expPerHour = math.floor(localPlayer.expSpeed * 3600)
		
		local nextLevelExp = expForLevel(localPlayer:getLevel()+1)
		local hoursLeft = (nextLevelExp - localPlayer:getExperience()) / expPerHour
		local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft))*60)
		hoursLeft = math.floor(hoursLeft)
		
		if not isInf(hoursLeft) then
			if hoursLeft == 0 then
				hoursLeft = "00"
			elseif hoursLeft < 10 then
				hoursLeft = "0"..hoursLeft..""
			end
		else
			hoursLeft = "00"
		end
		
		if not isNaN(minutesLeft) then
			if minutesLeft == 0 then
				minutesLeft = "00"
			elseif minutesLeft < 10 then
				minutesLeft = "0"..minutesLeft..""
			end
		else
			minutesLeft = "00"
		end
		
		sessionAmount:setText(getSessionTime(startingTime))
		expValuePerHourAmount:setText(expPerHour)
		nextLevelAmount:setText(nextLevelExp - localPlayer:getExperience())
		timetoLevelAmount:setText(hoursLeft..":"..minutesLeft)
	end
end

function onExperienceChange(protocol, opcode, buffer)
	if (buffer == nil) then return true end
	storedExp = storedExp + buffer[1]
	expValueAmount:setText(storedExp)
return true
end

function onLootChange(protocol, opcode, buffer)
	if (buffer == nil) then return true end
	
	if (buffer[1] == 1) then
		storedLoot = storedLoot + buffer[2]
		lootAmount:setText(storedLoot)
	elseif (buffer[1] == 2) then
		storedSupplies = storedSupplies + buffer[2]
		suppliesAmount:setText(storedSupplies)
	elseif (buffer[1] == 3) then
		storedProfit = storedProfit + buffer[2]
		profitAmount:setText(storedProfit)
		
		if storedLoot < 0 then
			profitAmount:setColor("#ff6767")
		else
			profitAmount:setColor("#d8ff00")
		end
	end
return true
end

function onMiniWindowClose()
	analyzersWindow:close()
end

function lootAnalyzerToggle()
	if lootAnalyzerWindow:isVisible() then
		lootAnalyzerWindow:close()
	else
		lootAnalyzerWindow:open()
	end
end

function expAnalyzerToggle()
	if expAnalyzerWindow:isVisible() then
		expAnalyzerWindow:close()
	else
		expAnalyzerWindow:open()
	end
end