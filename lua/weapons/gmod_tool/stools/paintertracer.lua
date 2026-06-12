TOOL.Category = "Render"
TOOL.Name = "#tool.paintertracer.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["key"] = 0
TOOL.ClientConVar["toggle"] = 1
TOOL.ClientConVar["starton"] = 1

TOOL.ClientConVar["rate"] = 0
TOOL.ClientConVar["scale"] = 1
TOOL.ClientConVar["starton"] = "1"
TOOL.ClientConVar["material"] = ""
TOOL.ClientConVar["r"] = 255
TOOL.ClientConVar["g"] = 255
TOOL.ClientConVar["b"] = 255
TOOL.ClientConVar["a"] = 255

local firstReload = true
function TOOL:Think()
	if CLIENT and firstReload then
		self:RebuildControlPanel()
		firstReload = false
	end
end

function TOOL:Holster()
	self:ClearObjects()
end

---Add a force field  or update an existing one
---@param tr table|TraceResult
---@return boolean
function TOOL:LeftClick(tr)
	if tr.HitSky then
		return false
	end
	if CLIENT then
		return true
	end

	-- TODO: Add CanTool methods for prop protection
	-- Add sandbox limits for paintertracer entities

	local painterTracer = IsValid(tr.Entity) and tr.Entity:GetClass() == "painter_tracer" and tr.Entity
	---@cast painterTracer painter_tracer
	if not IsValid(painterTracer) then
		painterTracer = ents.Create("painter_tracer")
		---@cast painterTracer painter_tracer
		painterTracer:SetPos(tr.HitPos + vector_up * 10)
		painterTracer:Spawn()

		undo.Create("Painter Tracer")
		undo.AddEntity(painterTracer)
		undo.SetPlayer(self:GetOwner())
		undo.Finish("Painter Tracer")
	end

	painterTracer:SetPaintScale(self:GetClientNumber("scale"))
	painterTracer:SetPaintRate(self:GetClientNumber("rate"))
	painterTracer:SetPaintMaterial(self:GetClientInfo("material"))
	painterTracer:SetPaintColor(
		Vector(self:GetClientNumber("r") / 255, self:GetClientNumber("g") / 255, self:GetClientNumber("b") / 255)
	)
	painterTracer:SetPaintEnabled(tobool(self:GetClientBool("starton")))

	-- numpad.OnDown(ply, params.key, "forcefield_press", forcefield)
	-- numpad.OnUp(ply, params.key, "forcefield_release", forcefield)

	return true
end

---Copy a painter's parameters
---@param tr table|TraceResult
---@return boolean
function TOOL:RightClick(tr)
	if CLIENT then
		return true
	end

	local painterTracer = IsValid(tr.Entity) and tr.Entity:GetClass() == "painter_tracer" and tr.Entity
	---@cast painterTracer painter_tracer

	local ply = self:GetOwner()

	if IsValid(painterTracer) then
		ply:ConCommand("paintertracer_rate" .. painterTracer:GetPaintRate())
		ply:ConCommand("paintertracer_scale " .. painterTracer:GetPaintScale())
		ply:ConCommand("paintertracer_material " .. painterTracer:GetPaintMaterial())

		local color = painterTracer:GetPaintColor() * 255
		ply:ConCommand("paintertracer_r " .. color.x)
		ply:ConCommand("paintertracer_g " .. color.y)
		ply:ConCommand("paintertracer_b " .. color.z)
	end

	return true
end

if SERVER then
	return
end

local cvarList = TOOL:BuildConVarList()

---Helper for DForm
---@param cPanel ControlPanel|DForm
---@param name string
---@param type "ControlPanel"|"DForm"
---@return ControlPanel|DForm
local function makeCategory(cPanel, name, type)
	---@type DForm|ControlPanel
	local category = vgui.Create(type, cPanel)

	category:SetLabel(name)
	cPanel:AddItem(category)
	return category
end

---@param cPanel ControlPanel|DForm
---@return PainterTracerList
local function paintList(cPanel)
	local Options = {}
	for id, str in ipairs(list.Get("PaintMaterials")) do
		if not table.HasValue(Options, str) then
			table.insert(Options, str)
		end
	end

	table.sort(Options)

	---@class PainterTracerList: DListView
	local listbox = vgui.Create("DListView")
	listbox:SetMultiSelect(false)
	listbox:AddColumn("#tool.paintertracer.texture")
	listbox:SetTall(17 + table.Count(Options) * 17)
	listbox:SortByColumn(1, false)
	for k, decal in ipairs(Options) do
		---@class PainterTracerLine: DListView_Line
		local line = listbox:AddLine(decal)
		line.data = util.DecalMaterial(decal)
		line:SetTooltip(line.data)
	end

	---@param id integer
	---@param line PainterTracerLine
	function listbox:OnRowSelected(id, line) end
	cPanel:AddItem(listbox)

	return listbox
end

---@param cPanel ControlPanel|DForm
function TOOL.BuildCPanel(cPanel)
	cPanel:ToolPresets("paintertracer", cvarList)

	local parametersCategory = makeCategory(cPanel, "#tool.paintertracer.parameters", "ControlPanel")
	parametersCategory:SetExpanded(true)

	parametersCategory:ColorPicker(
		"#tool.paintertracer.color",
		"paintertracer_r",
		"paintertracer_g",
		"paintertracer_b",
		"paintertracer_a"
	)
	parametersCategory
		:NumSlider("#tool.paintertracer.scale", "paintertracer_scale", 1, 20, 3)
		:SetTooltip("#tool.paintertracer.scale.tooltip")
	parametersCategory
		:NumSlider("#tool.paintertracer.rate", "paintertracer_rate", 0.001, 100, 3)
		:SetTooltip("#tool.paintertracer.rate.tooltip")

	local materialsCategory = makeCategory(cPanel, "#tool.paintertracer.materials", "ControlPanel")
	---@class PainterTracerEntry: DTextEntry
	local materialEntry = materialsCategory:TextEntry("#tool.paintertracer.material", "paintertracer_material")

	materialEntry:SetTooltip("#tool.paintertracer.material.tooltip")

	local listbox = paintList(materialsCategory)
	function listbox:OnRowSelected(_, line)
		RunConsoleCommand("paintertracer_material", line.data)
	end

	local controlCategory = makeCategory(cPanel, "#tool.paintertracer.control", "ControlPanel")
	-- controlCategory:KeyBinder("#tool.paintertracer.key", "paintertracer_key"):SetTooltip("#tool.paintertracer.key.tooltip")
	-- controlCategory:CheckBox("#tool.paintertracer.toggle", "paintertracer_toggle")
	controlCategory:CheckBox("#tool.paintertracer.starton", "paintertracer_starton")
end

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "right", stage = 0 },
}
