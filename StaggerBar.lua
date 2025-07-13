if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local player_class, class_id = UnitClassBase("player")
if player_class ~= "MONK" then
	return
end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_StaggerBar requires PitBull4")
end

-- CONSTANTS
local EXAMPLE_VALUE = 0.55
local DEFAULT_LIGHT_STAGGER_THRESHHOLD = 30
local DEFAULT_MODERATE_STAGGER_THRESHHOLD = 60
local DEFAULT_NO_STAGGER_COLOR = { 0.7, 0.7, 0.6 }
local DEFAULT_LIGHT_STAGGER_COLOR = {0,1,0}
local DEFAULT_MODERATE_STAGGER_COLOR = {1,1,0}
local DEFAULT_HEAVY_STAGGER_COLOR = {1,0,0}

local THRESHHOLD_NONE = 0
local THRESHHOLD_LIGHT = 1
local THRESHHOLD_MODERATE = 2
local THRESHHOLD_HEAVY = 3

-- state
local current_threshhold = THRESHHOLD_NONE
local player_stagger_percent = 0

local L = PitBull4.L

local PitBull4_StaggerBar = PitBull4:NewModule("StaggerBar", "AceEvent-3.0")

local ChatFrame = getfenv(0)["DEFAULT_CHAT_FRAME"]
--ChatFrame:AddMessage("-Initialized-")

PitBull4_StaggerBar:SetModuleType("bar")
PitBull4_StaggerBar:SetName(L["Stagger bar"])
PitBull4_StaggerBar:SetDescription(L["Show a bar for the current stagger amount for Brewmaster Monks."])
PitBull4_StaggerBar.allow_animations = true
PitBull4_StaggerBar:SetDefaults({
	position = 4,
	light_stagger_threshhold = DEFAULT_LIGHT_STAGGER_THRESHHOLD,
	moderate_stagger_threshhold = DEFAULT_MODERATE_STAGGER_THRESHHOLD,
	no_stagger_color = DEFAULT_NO_STAGGER_COLOR,
	light_stagger_color = DEFAULT_LIGHT_STAGGER_COLOR,
	moderate_stagger_color = DEFAULT_MODERATE_STAGGER_COLOR,
	heavy_stagger_color = DEFAULT_HEAVY_STAGGER_COLOR,
})

function PitBull4_StaggerBar:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAll")
	self:RegisterEvent("UNIT_HEALTH_FREQUENT")
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH_FREQUENT")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

	if nil == self.db.profile.global.light_stagger_threshhold then
		self.db.profile.global.light_stagger_threshhold = DEFAULT_LIGHT_STAGGER_THRESHHOLD
	end
	if nil == self.db.profile.global.moderate_stagger_threshhold then
		self.db.profile.global.moderate_stagger_threshhold = DEFAULT_MODERATE_STAGGER_THRESHHOLD
	end

	if nil == self.db.profile.global.no_stagger_color then
		self.db.profile.global.no_stagger_color = DEFAULT_NO_STAGGER_COLOR
	end
	if nil == self.db.profile.global.light_stagger_color then
		self.db.profile.global.light_stagger_color = DEFAULT_LIGHT_STAGGER_COLOR
	end
	if nil == self.db.profile.global.moderate_stagger_color then
		self.db.profile.global.moderate_stagger_color = DEFAULT_MODERATE_STAGGER_COLOR
	end
	if nil == self.db.profile.global.heavy_stagger_color then
		self.db.profile.global.heavy_stagger_color = DEFAULT_HEAVY_STAGGER_COLOR
	end
end

function PitBull4_StaggerBar:GetValue(frame)
	local spec = C_SpecializationInfo.GetSpecialization();
	local visible = frame.unit == "player" and spec == SPEC_MONK_BREWMASTER;

	if not visible then
		return nil
	end

	return player_stagger_percent
end

function PitBull4_StaggerBar:GetExampleValue(frame)
	return EXAMPLE_VALUE
end

function PitBull4_StaggerBar:GetColor(frame, value)
	local color = self.db.profile.global.no_stagger_color
	if current_threshhold == THRESHHOLD_LIGHT then
		color = self.db.profile.global.light_stagger_color
	elseif current_threshhold == THRESHHOLD_MODERATE then
		color = self.db.profile.global.moderate_stagger_color
	elseif current_threshhold == THRESHHOLD_HEAVY then
		color = self.db.profile.global.heavy_stagger_color
	end
	return unpack(color)
end

function PitBull4_StaggerBar:GetExampleColor(frame, value)
	return self.db.profile.global.moderate_stagger_color
end

function PitBull4_StaggerBar:UNIT_HEALTH_FREQUENT(_, unit)
	if unit == "player" then
		self:UpdatePlayerStaggerPercent()
		self:UpdateForUnitID(unit)
	end
end

function PitBull4_StaggerBar:ACTIVE_TALENT_GROUP_CHANGED()
	self:UpdateAll()
end

function PitBull4_StaggerBar:UpdateThreshhold()
	local value = player_stagger_percent * 100
	local newThreshhold = THRESHHOLD_NONE

	if value == nil or value <= 0 then
		newThreshhold = THRESHHOLD_NONE
	elseif value <= self.db.profile.global.light_stagger_threshhold then
		newThreshhold = THRESHHOLD_LIGHT
	elseif value <= self.db.profile.global.moderate_stagger_threshhold then
		newThreshhold = THRESHHOLD_MODERATE
	else
		newThreshhold = THRESHHOLD_HEAVY
	end

	if newThreshhold ~= current_threshhold then
		current_threshhold = newThreshhold
		self:UpdateAll()
	end
end

function PitBull4_StaggerBar:UpdatePlayerStaggerPercent()
	local stagger = UnitStagger("Player")
	local health = UnitHealthMax("Player")
	if stagger > health then
		stagger = health
	end

	player_stagger_percent = 1 - ((health - stagger) / health)
	self:UpdateThreshhold()
end

PitBull4_StaggerBar:SetGlobalOptionsFunction(function(self)
	return 'div', {
		type='header',
		name = '',
		desc = '',
	}, 'light_stagger_threshhold', {
		type = 'range',
		width = 'double',
		name = 'Light Stagger Threshhold',
		desc = 'Upper percentage bound for light stagger amount.',
		min = 1,
		max = 100,
		step = 1,
		get = function(info)
			return self.db.profile.global.light_stagger_threshhold
		end,
		set = function(info, value)
			self.db.profile.global.light_stagger_threshhold = value
		end,
	},
	'moderate_stagger_threshhold', {
			type = 'range',
			width = 'double',
			name = 'Moderate Stagger Threshhold',
			desc = 'Upper percentage bound for moderate stagger amount.',
			min = 1,
			max = 100,
			step = 1,
			get = function(info)
				return self.db.profile.global.moderate_stagger_threshhold
			end,
			set = function(info, value)
				self.db.profile.global.moderate_stagger_threshhold = value
			end,
		}
end);

PitBull4_StaggerBar:SetColorOptionsFunction(function(self)
	return 'no_stagger_color', {
		type = 'color',
		name = 'No Stagger Color',
		desc = 'Sets which color the bar should use when there is no stagger damage.',
		get = function(info)
			return unpack(self.db.profile.global.no_stagger_color)
		end,
		set = function(info, r, g, b)
			self.db.profile.global.no_stagger_color = {r, g, b}
			self:UpdateAll()
		end
	},
	'light_stagger_color', {
		type = 'color',
		name = 'Light Stagger Color',
		desc = 'Sets which color the bar should use when there is light stagger damage.',
		get = function(info)
			return unpack(self.db.profile.global.light_stagger_color)
		end,
		set = function(info, r, g, b)
			self.db.profile.global.light_stagger_color = {r, g, b}
			self:UpdateAll()
		end
	},
	'moderate_stagger_color', {
		type = 'color',
		name = 'Moderate Stagger Color',
		desc = 'Sets which color the bar should use when there is moderate stagger damage.',
		get = function(info)
			return unpack(self.db.profile.global.moderate_stagger_color)
		end, 
		set = function(info, r, g, b)
			self.db.profile.global.moderate_stagger_color = {r, g, b}
			self:UpdateAll()
		end
	},
	'heavy_stagger_color', {
		type = 'color',
		name = 'Heavy Stagger Color',
		desc = 'Sets which color the bar should use when there is heavy stagger damage.',
		get = function(info)
			return unpack(self.db.profile.global.heavy_stagger_color)
		end,
		set = function(info, r, g, b)
			self.db.profile.global.heavy_stagger_color = {r, g, b}
			self:UpdateAll()
		end
	},
	function(info)
		self.db.profile.global.no_stagger_color = DEFAULT_NO_STAGGER_COLOR
		self.db.profile.global.light_stagger_color = DEFAULT_LIGHT_STAGGER_COLOR
		self.db.profile.global.moderate_stagger_color = DEFAULT_MODERATE_STAGGER_COLOR
		self.db.profile.global.heavy_stagger_color = DEFAULT_HEAVY_STAGGER_COLOR
	end
end)
