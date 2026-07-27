-- Eloquence: chat bubbles.
--
-- The bubble above someone's head is drawn by the client straight from the chat
-- event. It never goes through ChatFrame_AddMessageEventFilter, so the chat
-- frame can show a full dialect while the bubble still shows the original text.
-- They are genuinely two separate render paths and need two mechanisms.
--
-- There is no hook for bubble text, so the only approach available is:
--
--   1. when the chat filter rewrites a line, remember original -> rewritten
--   2. wait for the client to actually create the bubble, which happens a frame
--      or two later
--   3. find the bubble whose FontString still holds the original text, and
--      replace it
--
-- Matching on text is what makes this work without any identifying handle on the
-- bubble. Two people saying the same thing at the same moment will both get the
-- same (correct) replacement, so the ambiguity is harmless.
--
-- Bubbles the client marks as forbidden cannot be touched at all; those are
-- skipped. GetAllChatBubbles() already excludes them unless asked otherwise.
local ADDON, E = ...

local Bubbles = {}
E.Bubbles = Bubbles

-- Only these produce a bubble. Whispers, guild, party and channels never do.
local BUBBLE_EVENTS = {
	CHAT_MSG_SAY = true,
	CHAT_MSG_YELL = true,
	CHAT_MSG_MONSTER_SAY = true,
	CHAT_MSG_MONSTER_YELL = true,
	CHAT_MSG_MONSTER_PARTY = true,
}

local pending = {}       -- original text -> { text = replacement, expires = n }
local ticker
local PENDING_TTL = 8    -- seconds a rewrite stays claimable
local SCAN_INTERVAL = 0.05
local SCAN_WINDOW = 2    -- stop looking this long after the last message

Bubbles.rewritten = 0
Bubbles.supported = nil

local function Now()
	return (GetTime and GetTime()) or 0
end

-- Dig out the FontString holding the bubble's text. Layouts have moved around
-- between expansions, so try the direct field first and fall back to walking the
-- regions. Every frame is checked for being forbidden before it is touched.
local function BubbleText(bubble)
	if not bubble or (bubble.IsForbidden and bubble:IsForbidden()) then return nil end

	if bubble.String and bubble.String.GetText then
		return bubble.String
	end

	local children = { bubble:GetChildren() }
	for _, child in ipairs(children) do
		if child and not (child.IsForbidden and child:IsForbidden()) then
			if child.String and child.String.GetText then
				return child.String
			end
			if child.GetRegions then
				local regions = { child:GetRegions() }
				for _, region in ipairs(regions) do
					if region and not (region.IsForbidden and region:IsForbidden())
						and region.GetObjectType and region:GetObjectType() == "FontString" then
						return region
					end
				end
			end
		end
	end

	if bubble.GetRegions then
		local regions = { bubble:GetRegions() }
		for _, region in ipairs(regions) do
			if region and not (region.IsForbidden and region:IsForbidden())
				and region.GetObjectType and region:GetObjectType() == "FontString" then
				return region
			end
		end
	end
	return nil
end

local function Scan()
	if not (C_ChatBubbles and C_ChatBubbles.GetAllChatBubbles) then return end
	local ok, bubbles = pcall(C_ChatBubbles.GetAllChatBubbles)
	if not ok or type(bubbles) ~= "table" then return end

	for _, bubble in ipairs(bubbles) do
		local fontString = BubbleText(bubble)
		if fontString then
			local okText, current = pcall(fontString.GetText, fontString)
			if okText and current then
				local entry = pending[current]
				if entry then
					pcall(fontString.SetText, fontString, entry.text)
					Bubbles.rewritten = Bubbles.rewritten + 1
					-- Keep the entry: the same line can be re-rendered, and the
					-- TTL will clear it shortly.
				end
			end
		end
	end
end

local function Expire()
	local now = Now()
	for text, entry in pairs(pending) do
		if entry.expires <= now then pending[text] = nil end
	end
end

local function StartTicker()
	if ticker or not (C_Timer and C_Timer.NewTicker) then return end
	local elapsed = 0
	local ok, handle = pcall(C_Timer.NewTicker, SCAN_INTERVAL, function(self)
		elapsed = elapsed + SCAN_INTERVAL
		Scan()
		if elapsed >= SCAN_WINDOW then
			Expire()
			if not next(pending) or elapsed >= SCAN_WINDOW then
				if self and self.Cancel then self:Cancel() end
				ticker = nil
			end
		end
	end)
	if ok then ticker = handle end
end

-- Called by the chat filter when it has rewritten a line. `original` is what the
-- bubble will be created with.
function Bubbles.Queue(event, original, replacement)
	-- Drop anything past its TTL first, so the table stays bounded even if the
	-- ticker never gets a chance to run.
	Expire()

	if not BUBBLE_EVENTS[event] then return end
	if not E.db or not E.db.incoming.bubbles then return end
	if not original or not replacement or original == replacement then return end

	pending[original] = { text = replacement, expires = Now() + PENDING_TTL }
	-- Catch the common case immediately, then poll for the rest.
	Scan()
	StartTicker()
end

function Bubbles.PendingCount()
	local n = 0
	for _ in pairs(pending) do n = n + 1 end
	return n
end

-- Exposed for the test harness.
Bubbles.Scan = Scan
Bubbles.BubbleText = BubbleText

E.OnLogin("Bubbles", function()
	Bubbles.supported = (C_ChatBubbles ~= nil and C_ChatBubbles.GetAllChatBubbles ~= nil
		and C_Timer ~= nil and C_Timer.NewTicker ~= nil) and true or false
end)
