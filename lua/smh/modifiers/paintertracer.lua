MOD.Name = "Painter Tracer"

local validClasses = {
	painter_tracer = true,
}

function MOD:IsEditor(entity)
	return validClasses[entity:GetClass()]
end

function MOD:Save(entity)
	if not self:IsEditor(entity) then
		return nil
	end

	local data = {
		PaintEnabled = entity:GetPaintEnabled(),
		PaintRate = entity:GetPaintRate(),
		PaintScale = entity:GetPaintScale(),
		PaintMaterial = entity:GetPaintMaterial(),
		PaintColor = entity:GetPaintColor(),
	}

	return data
end

function MOD:Load(entity, data)
	if not self:IsEditor(entity) then
		return
	end -- can never be too sure?

	entity:SetPaintEnabled(data.PaintEnabled)
	entity:SetPaintRate(data.PaintRate)
	entity:SetPaintScale(data.PaintScale)
	entity:SetPaintMaterial(data.PaintMaterial)
	entity:SetPaintColor(data.PaintColor)
end

function MOD:LoadBetween(entity, data1, data2, percentage)
	if not self:IsEditor(entity) then
		return
	end -- can never be too sure?

	entity:SetPaintEnabled(data1.PaintEnabled)
	entity:SetPaintMaterial(data1.PaintMaterial)
	entity:SetPaintRate(SMH.LerpLinear(data1.PaintRate, data2.PaintRate, percentage))
	entity:SetPaintScale(SMH.LerpLinear(data1.PaintScale, data2.PaintScale, percentage))
	entity:SetPaintColor(SMH.LerpLinearVector(data1.PaintColor, data2.PaintColor, percentage))
end
