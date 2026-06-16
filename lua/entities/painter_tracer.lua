AddCSLuaFile()

---@class painter_tracer: ENT
---@field GetPaintEnabled fun(self: painter_tracer): paintEnabled: boolean
---@field SetPaintEnabled fun(self: painter_tracer, paintEnabled: boolean)
---@field GetPaintRate fun(self: painter_tracer): paintRate: number
---@field SetPaintRate fun(self: painter_tracer, paintRate: number)
---@field GetPaintScale fun(self: painter_tracer): paintScale: number
---@field SetPaintScale fun(self: painter_tracer, paintScale: number)
---@field GetPaintMaterial fun(self: painter_tracer): paintMaterial: string
---@field SetPaintMaterial fun(self: painter_tracer, paintMaterial: string)
---@field GetPaintColor fun(self: painter_tracer): paintColor: Vector
---@field SetPaintColor fun(self: painter_tracer, paintColor: Vector)
local ENT = ENT

ENT.Type = "anim"

ENT.PrintName = "Painter Tracer"
ENT.Author = "vlazed"

ENT.Purpose = "Paint decals remotely"
ENT.Instructions = "Spawn this entity with the Painter Tracer tool"

ENT.Editable = true

local function networkEdit(type, order, editProps)
	local edit = { type = type, order = order }
	for key, val in pairs(editProps) do
		edit[key] = val
	end
	return edit
end

---@param ent ENT
---@param type string
---@param order integer
---@param name string
---@param editProps table
local function networkVar(ent, type, order, name, editProps)
	ent:NetworkVar(type ~= "Combo" and type or "String", order, name, {
		KeyName = string.lower(name),
		Edit = networkEdit(type, order, editProps),
	})
end

---@param slot integer?
---@return fun(): integer
local function orderer(slot)
	slot = slot or 32
	local i = -1
	return function()
		i = i + 1
		if i < slot then
			return i
		else
			error("Went beyond slot")
		end
	end
end

function ENT:SetupDataTables()
	local floatSlot = orderer()
	local boolSlot = orderer()
	local stringSlot = orderer(4)
	local vectorSlot = orderer()

	-- Technically, this is interval, not rate ☝🤓
	networkVar(self, "Float", floatSlot(), "PaintRate", { category = "General", min = 1, max = 100 })
	networkVar(self, "Float", floatSlot(), "PaintScale", { category = "General", min = 0.1, max = 1000 })
	networkVar(self, "Bool", boolSlot(), "PaintEnabled", { category = "General" })
	networkVar(self, "String", stringSlot(), "PaintMaterial", { category = "General" })
	networkVar(self, "Vector", vectorSlot(), "PaintColor", { category = "General" })

	self:NetworkVarNotify("PaintMaterial", function(entity, name, old, new)
		if CLIENT then
			self.PaintMaterial = Material(new)
		end
	end)

	self:NetworkVarNotify("PaintColor", function(entity, name, old, new)
		self.PaintColor = new:ToColor()
	end)

	self:NetworkVarNotify("PaintEnabled", function(entity, name, old, new)
		-- Why -self:GetPaintRate()? This is so that
		-- `now - self.NextTime > self:GetPaintRate()` evaluates to `now > 0`,
		-- which is always true
		-- That means the paint always applies whenever we set this on
		self.NextTime = -self:GetPaintRate()
	end)
end

---Most code comes from
---https://github.com/Facepunch/garrysmod/blob/5536088d22b8c079102cfafed1a81f26050701c0/garrysmod/gamemodes/base/entities/entities/prop_effect.lua#L12
function ENT:Initialize()
	local Radius = 6
	local mins = Vector(1, 1, 1) * Radius * -0.5
	local maxs = Vector(1, 1, 1) * Radius * 0.5

	self.NextTime = CurTime()

	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	if SERVER then
		self:SetModel("models/props_junk/watermelon01.mdl")

		-- Don't use the model's physics - create a box instead
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)

		-- Set up our physics object here
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableGravity(false)
			phys:EnableDrag(false)
			phys:EnableCollisions(false)
		end
	else
		---@type TraceResult
		self.TraceOutput = {}
		---@type Trace
		self.TraceInput = {
			output = self.TraceOutput,
			filter = self,
		}

		-- So addons can override this
		self.GripMaterial = Material("sprites/grip")
		self.GripMaterialHover = Material("sprites/grip_hover")

		self:DrawShadow(false)
	end

	-- Set collision bounds exactly
	self:SetCollisionBounds(mins, maxs)
end

function ENT:Think()
	if CLIENT and self:GetPaintMaterial()[1] and not self.PaintMaterial then
		self.PaintMaterial = Material(self:GetPaintMaterial())
	end

	local now = CurTime()
	if self:GetPaintEnabled() and now - self.NextTime > self:GetPaintRate() then
		self.NextTime = now

		if CLIENT then
			local start = self:GetPos()
			self.TraceInput.start = start
			self.TraceInput.endpos = start + self:GetForward() * 10000
			local tr = util.TraceLine(self.TraceInput)
			if tr.HitPos and self.PaintMaterial and tr.Entity ~= NULL then
				util.DecalEx(
					self.PaintMaterial,
					tr.Entity,
					tr.HitPos,
					tr.HitNormal,
					self.PaintColor,
					self:GetPaintScale(),
					self:GetPaintScale()
				)
			end
		end
	end

	self:NextThink(now)
	return true
end

-- Copied from base_gmodentity.lua
ENT.MaxWorldTipDistance = 256
function ENT:BeingLookedAtByLocalPlayer()
	local ply = LocalPlayer()
	if not IsValid(ply) then
		return false
	end

	local view = ply:GetViewEntity()
	local dist = self.MaxWorldTipDistance
	dist = dist * dist

	-- If we're spectating a player, perform an eye trace
	if view:IsPlayer() then
		---@diagnostic disable-next-line: undefined-field
		return view:EyePos():DistToSqr(self:GetPos()) <= dist and view:GetEyeTrace().Entity == self
	end

	-- If we're not spectating a player, perform a manual trace from the entity's position
	local pos = view:GetPos()

	if pos:DistToSqr(self:GetPos()) <= dist then
		return util.TraceLine({
			start = pos,
			endpos = pos + (view:GetAngles():Forward() * dist),
			filter = view,
		}).Entity == self
	end

	return false
end

if CLIENT then
	local BLUE = Color(0, 0, 255)
	function ENT:Draw()
		---@diagnostic disable-next-line: deprecated
		if GetConVarNumber("cl_draweffectrings") == 0 then
			return
		end

		-- Don't draw the grip if there's no chance of us picking it up
		local ply = LocalPlayer()
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) then
			return
		end

		local weapon_name = wep:GetClass()

		if weapon_name ~= "weapon_physgun" and weapon_name ~= "gmod_tool" then
			return
		end

		if self:BeingLookedAtByLocalPlayer() then
			render.SetMaterial(self.GripMaterialHover)
		else
			render.SetMaterial(self.GripMaterial)
		end

		render.DrawSprite(self:GetPos(), 16, 16, color_white)
		if self.TraceOutput and self.TraceOutput.HitPos then
			-- print(self.TraceOutput.HitPos, self.TraceOutput.StartPos, self.TraceOutput.Entity)
			render.DrawLine(self.TraceOutput.StartPos, self.TraceOutput.HitPos, BLUE, true)
		end
	end
end
