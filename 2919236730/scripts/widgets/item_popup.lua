--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local RecipePopup = require "widgets/recipepopup"
local Spinner = require "widgets/spinner"
local TextIcon = require "widgets/text_icon"
local ALIGN_L = 1
local ALIGN_C = 0
local ALIGN_R = -1

local TEASER_SCALE_TEXT = 1
local TEASER_SCALE_BTN = 1.5
local TEASER_TEXT_WIDTH = 64 * 3 + 24
local TEASER_BTN_WIDTH = TEASER_TEXT_WIDTH / TEASER_SCALE_BTN
local TEXT_WIDTH = 64 * 3 + 30

--local recipe_desc_fontSize = PLATFORM ~= "WIN32_RAIL" and 33 or 30
local recipe_desc_fontSize = 20

local function MakeSpinner(labeltext, min_num, max_num, onchanged_fn, opts)
	local width_label = 150
	local width_spinner = opts and opts.width or 150
	local height = opts and opts.height or 40
	local spacing = opts and opts.spacing or 5
	local font = opts and opts.font or HEADERFONT
	local font_size = opts and opts.font_size or 40

	local labeltext = labeltext or ""
	local min_num = min_num or 1
	local max_num = max_num or 10
	--[[
	local total_width = width_label + width_spinner + spacing
	local wdg = Widget("labelspinner")
	wdg.label = wdg:AddChild( Text(font, font_size, labeltext) )
	wdg.label:SetPosition( (-total_width/2)+(width_label/2), 0 )
	wdg.label:SetRegionSize( width_label, height )
	wdg.label:SetHAlign( ANCHOR_RIGHT )
	wdg.label:SetColour(UICOLOURS.BROWN_DARK)--]]

	local spinner_data = {}
	for i = min_num, max_num, 1 do
		local current_data = {text = tostring(i), data = i}
		spinner_data[i] = current_data
		--table.insert(spinner_data, )
	end

	local lean = true
	local spinner = Spinner(spinner_data, width_spinner, height, {font = font, size = font_size}, nil, "images/quagmire_recipebook.xml", nil, lean)
	spinner:SetTextColour(UICOLOURS.BROWN_DARK)
	spinner:SetOnChangedFn(onchanged_fn)
	--spinner:SetPosition((total_width/2)-(width_spinner/2), 0)

	spinner:SetSelected(min_num)

	--return wdg
	return spinner
end

local ItemPopup = Class(RecipePopup, function(self, horizontal)
    --RecipePopup._ctor(self, horizontal)
    Widget._ctor(self, "ItemPopup")
    self.smallfonts = JapaneseOnPS4()
    self.horizontal = horizontal
    self:BuildNoSpinner(horizontal)
end)

function ItemPopup:BuildNoSpinner(horizontal)
    self:KillAllChildren()

    self.skins_spinner = nil

    local hud_atlas = GetGameModeProperty("hud_atlas") or resolvefilepath(HUD_ATLAS)

    self.bg = self:AddChild(Image())
    local img = horizontal and "craftingsubmenu_fullvertical.tex" or "craftingsubmenu_fullhorizontal.tex"

    if horizontal then
        self.bg:SetPosition(240,40,0)
    else
        self.bg:SetPosition(210,16,0)
    end
    self.bg:SetTexture(hud_atlas, img)
	--self.bg:SetSize(500,500)

    if horizontal then
        self.bg.light_box = self.bg:AddChild(Image(hud_atlas, "craftingsubmenu_litehorizontal.tex"))
        self.bg.light_box:SetPosition(0, -50)
    else
        self.bg.light_box = self.bg:AddChild(Image(hud_atlas, "craftingsubmenu_litevertical.tex"))
        self.bg.light_box:SetPosition(30, -22)
    end

    --

    self.contents = self:AddChild(Widget(""))
    self.contents:SetPosition(-75,0,0)

    if self.smallfonts then
        self.name = self.contents:AddChild(Text(UIFONT, 40 * 0.8))
        self.desc = self.contents:AddChild(Text(BODYTEXTFONT, 33 * 0.8))
        self.desc:SetPosition(320, -10, 0)
    else
        self.name = self.contents:AddChild(Text(UIFONT, 40))
        self.desc = self.contents:AddChild(Text(BODYTEXTFONT, recipe_desc_fontSize))
        self.desc:SetPosition(320, -5, 0)
    end
    self.name:SetPosition(320, 142, 0)
    self.name:SetHAlign(ANCHOR_MIDDLE)

	-- Stats
	--[[
	Enemy: Health, Damage, Speed
	Weap: Damage, Element
	Helm: phys dmg increase, magic dmg increase, speed increase, cooldown increase
	Armor: Armor, knockback resistance, speed, phys dmg increase, cooldown increase
	stats: Armor, Cooldown, Health, Damage: (Physical Damage, Magic Damage), Element, Knockback Resistance, Speed
	--]]
	self.buttons = {}
	self.spinners = {}
	self.text_icons = {}
end

function ItemPopup:Refresh()
	local owner = self.owner
    if owner == nil then
        return false
    end
	local category = self.item.type

    self.name:SetTruncatedString(STRINGS.REFORGED[category] and STRINGS.REFORGED[category][string.upper(self.item.name)] and STRINGS.REFORGED[category][string.upper(self.item.name)].NAME or STRINGS.REFORGED.MUTATORS[self.item.name] and STRINGS.REFORGED.MUTATORS[self.item.name].name or STRINGS.NAMES[self.item.name] or self.item.name or STRINGS.MVP_LOADING_WIDGET.LAVAARENA.DESCRIPTIONS.unknown, TEXT_WIDTH, self.smallfonts and 51 or 41, true, true)

    -- Hide all widgets
	for _,text_icon in pairs(self.text_icons) do
		text_icon:Hide()
	end
	for _,button in pairs(self.buttons) do
		button:Hide()
	end
	for _,spinner in pairs(self.spinners) do
		spinner:Hide()
	end

	-- TODO create a generic layout of no refresh fn?
	if self.item.menu_refresh_fn then
		self.item.menu_refresh_fn(self)
	end

	self.desc:SetMultilineTruncatedString(STRINGS.REFORGED[category] and STRINGS.REFORGED[category][string.upper(self.item.name)] and STRINGS.REFORGED[category][string.upper(self.item.name)].DESC or STRINGS.REFORGED.MUTATORS[self.item.name] and STRINGS.REFORGED.MUTATORS[self.item.name].desc or tostring(self.item.name), 4, TEXT_WIDTH, self.smallfonts and 40 or 33, true, true)
    self.desc:SetHAlign(ANCHOR_LEFT)
end

function ItemPopup:SetItem(item, owner)
	if self.item and item and self.item.name ~= item.name or self.item == nil then
	    self.item = item
	    self.owner = owner
	end
	self:Refresh()
end

function ItemPopup:HideReset()
	if self.spinner_ents and self.highlight and self.has_ents then
		local selected = self.spinner_ents:GetSelectedData()
		if selected:HasTag("inspectable") then
			selected.AnimState:SetHighlightColour()
			self.highlight = false
			self.has_ents = false
		end
	end
	if self.item and self.item.menu_reset_fn then
		self.item.menu_reset_fn(self)
	end
end

function ItemPopup:AddTextIcon(name, text, custom_text_opts, custom_icon_info)
	if not self.text_icons[name] then
		local text_opts = {
			pos = {x = 350, y = 110, z = 0},
			--font = , -- TODO figure out what font to use
			font_size = 25,
			h_alignment = ALIGN_L,
			icon_after_text = false,
		}
		local icon_info = {
			source = "inventoryimages.xml",
			tex = "default.tex",
			opts = {
				key = "stat",
				icon_size = {25, 25},
				pos_offset = {x = 0, y = 0, z = 0},
				hovertext = "",
			},
		}
		for opt,val in pairs(custom_text_opts) do
			text_opts[opt] = val
		end
		for opt,val in pairs(custom_icon_info) do
			icon_info[opt] = val
		end

		self.text_icons[name] = self.contents:AddChild( TextIcon(text, {icon_info}, text_opts) )
	end
end

function ItemPopup:AddButton()
	local button = self.contents:AddChild(ImageButton())
	button:Hide()
	table.insert(self.buttons, button)
end

function ItemPopup:AddSpinner()
	table.insert(self.spinners, self.contents:AddChild(MakeSpinner()))
end

-- Check that there are enough buttons, if not then create as many buttons that are needed.
function ItemPopup:EnsureButtonsExist(count)
	local button_difference = count - #self.buttons
	if button_difference > 0 then
		for i = 1,button_difference do
			self:AddButton()
		end
	end
end

-- Check that there are enough spinners, if not then create as many spinners that are needed.
function ItemPopup:EnsureSpinnersExist(count)
	local spinner_difference = count - #self.spinners
	if spinner_difference > 0 then
		for i = 1,spinner_difference do
			self:AddSpinner()
		end
	end
end

return ItemPopup
