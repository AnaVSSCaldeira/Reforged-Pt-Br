local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"

local function GetStringInfo(filename, server)
    local file_str = ""
    if server then
        TheSim:GetPersistentString(filename, function(load_success, file_info)
            if load_success and file_info then
                file_str = file_info
            else
                Debug:Print("Unable to open file " .. tostring(filename), "warning")
            end
        end)
    else
        local file = io.open(filename, "r")
        if file then
            file_str = file:read("*a")
            file:close()
        else
            Debug:Print("Unable to open file " .. tostring(filename), "warning")
        end
    end
    return file_str or ""
end

local NewsPanel = Class(Widget, function(self, options)
    ------------------ NO TOUCHY ------------------
    Widget._ctor(self, "NewsPanel")

    self.scroll_anims = {}
    self.scrolls = {}
    self.sync_anims = {}

    self.mod_root = MODS_ROOT .. (KnownModIndex:IsModEnabledAny("workshop-1938752683") and "workshop-1938752683" or KnownModIndex:IsModEnabledAny("forge") and "forge" or "reforged_private")
    -----------
    self.top_info_display = self:AddChild( self:BuildTopInfoDisplay() )
    self.top_info_display:SetPosition(0, 0)

    -- Place between these 2 widgets
    local line_break = self:AddChild(Image("images/lavaarena_unlocks.xml", "divider.tex"))
    local line_break_width, line_break_height = line_break:GetSize()
    line_break:SetPosition(0, -line_break_height/2 - 50)
    line_break:SetScale(.68)

    self.bottom_info_display = self:AddChild( self:BuildBottomInfoDisplay() )
    self.bottom_info_display:SetPosition(0, -300)

    local function UpdateScroll(world, data)
        self:UpdateScroll(data.source)
    end
    TheWorld:ListenForEvent("new_server_info", UpdateScroll)
    local function StartSync(world, data)
        self:StartSync(data.source)
    end
    TheWorld:ListenForEvent("syncing_server_info", StartSync)

    self.parent_default_focus = self

    local _oldKill = self.Kill
    self.Kill = function(...)
        TheWorld:RemoveEventCallback("new_server_info", UpdateScroll)
        TheWorld:RemoveEventCallback("syncing_server_info", StartSync)
        _oldKill(...)
    end
end)

-- Ensures that each line of text fits the max length. If it does not then it will spread the line over as many lines as it takes to fit.
-- If one string is longer than the max length then it will chop that string into pieces to fit and not preserve it.
local function OrganizeBodyText(body_text, max_width, font_opts, ignore_first_index)
    local font_options = {
        font = HEADERFONT,
        size = 25,
    }
    local link_button_size = 25
    local links = {
        ["discord:"] = "discord",
        ["steam:"]   = "steam",
        ["youtube:"] = "youtube",
    }
    MergeTable(font_options, font_opts, true)
    local text = Text(font_options.font, font_options.size, "")
    local body_info = {}
    for i,line in pairs(body_text) do
        if not ignore_first_index or i > 1 then
            local strings = ParseString(line, " ")
            local current_str = ""
            local current_links = {}
            for j,str in pairs(strings) do
                text:SetString(current_str)
                local current_width = text:GetRegionSize() + #current_links * link_button_size
                local link = links[string.sub(str, 1, 8)] or links[string.sub(str, 1, 6)]
                if not link then
                    text:SetString(str)
                end
                local str_width = link and link_button_size or text:GetRegionSize()
                if not link then
                    text:SetString(current_str .. " " .. str)
                end
                local next_str_width = text:GetRegionSize() + (link and link_button_size or 0)
                -- Check for string larger than the line itself
                if str_width > max_width then
                    -- Check to see if current string is a line by itself
                    if current_width == max_width then
                        table.insert(body_info, {str = current_str, links = current_links})
                        current_str = ""
                        current_links = {}
                    end
                    if link then
                        table.insert(current_links, {type = link, link = string.sub(str, link == "steam" and 7 or 9), x_offset = current_width})
                        if current_str ~= "" then
                            table.insert(body_info, {str = current_str, links = current_links})
                            current_links = {}
                        end
                    else
                        -- Cut the large string into pieces that fit the remaining space of the current line
                        current_str = current_str .. (current_str ~= "" and " " or "")
                        local index = 1
                        while(index <= string.len(str)) do
                            text:SetString(current_str .. string.sub(str,index,index))
                            current_width = text:GetRegionSize()
                            -- Max Width has been reached, add a new line and reset current string
                            if current_width > max_width then
                                table.insert(body_info, {str = current_str, links = current_links})
                                current_links = {}

                                -- Test remaining string to see if it will fit on a line
                                text:SetString(string.sub(str, index))
                                current_width = text:GetRegionSize()
                                if current_width > max_width then
                                    current_str = ""
                                else
                                    current_str = string.sub(str, index)
                                    index = string.len(str)
                                end
                            else
                                current_str = current_str .. string.sub(str,index,index)
                            end
                            index = index + 1
                        end
                    end
                elseif current_str == "" then
                    if link then
                        table.insert(current_links, {type = link, link = string.sub(str, link == "steam" and 7 or 9), x_offset = 0})
                    else
                        current_str = str
                    end
                -- New line
                elseif next_str_width > max_width then
                    table.insert(body_info, {str = current_str, links = current_links})
                    current_links = {}
                    if link then
                        table.insert(current_links, {type = link, link = string.sub(str, link == "steam" and 7 or 9), x_offset = current_width})
                        current_str = ""
                    else
                        current_str = str
                    end
                else
                    if link then
                        table.insert(current_links, {type = link, link = string.sub(str, link == "steam" and 7 or 9), x_offset = current_width})
                    else
                        current_str = current_str .. " " .. str
                    end
                end
            end
            if current_str ~= "" or #current_links > 0 then
                table.insert(body_info, {str = current_str, links = current_links})
            end
        end
    end
    text:Kill()
    return body_info
end

local scroll_opts = {
    body_font_size   = 12,
    title_y          = 195,
    spacing          = 0,
    max_rows         = 13,
    width            = 175,
    scrollbar_offset = {35, -10},
    scrollbar_height_offset = -30,
    title_bg = {atlas = "images/rf_panel_assets.xml", tex = "community_scroll.tex", scale = {-1,1}},
}
local scroll_font_opts = {
    size = scroll_opts.body_font_size,
    font = HEADERFONT,
}
-- Displays Server News/Info, Event News, ReForged News
function NewsPanel:BuildTopInfoDisplay()
    local top_root = Widget("top_root")

    local server_info = TheWorld.net.replica.serverinfomanager and TheWorld.net.replica.serverinfomanager:HasNews() and TheWorld.net.replica.serverinfomanager:GetNews() or {}
    local has_server = #server_info > 0
    top_root.server = top_root:AddChild(self:AddInfoPanel(server_info[1] ~= nil and tostring(server_info[1]) or TheNet:GetServerName(), OrganizeBodyText(has_server and server_info or ParseString(STRINGS.UI.NEWS_PANEL.SERVER.BODY, "\n"), scroll_opts.width, scroll_font_opts, has_server), scroll_opts, "news"))
    top_root.server:SetPosition(-275,0)
    self.scrolls.news.title = top_root.server.title
    self.scrolls.news.body = top_root.server.body
    self.scrolls.news:Disable()

    local event_info = TheWorld.net.replica.serverinfomanager and TheWorld.net.replica.serverinfomanager:HasEvent() and TheWorld.net.replica.serverinfomanager:GetEventInfo() or {}
    local has_event = #event_info > 0
    top_root.events = top_root:AddChild(self:AddInfoPanel(event_info[1] or STRINGS.UI.NEWS_PANEL.EVENTS.TITLE, OrganizeBodyText(has_event and event_info or ParseString(STRINGS.UI.NEWS_PANEL.EVENTS.BODY, "\n"), scroll_opts.width, scroll_font_opts, has_event), scroll_opts, "event"))
    top_root.events:SetPosition(0,0)
    self.scrolls.event.title = top_root.events.title
    self.scrolls.event.body = top_root.events.body
    self.scrolls.event:Disable()

    -- TODO for some reason these strings have a new line, not sure why. Forced the title to remove the last character for now. NEED TO FIX
    local news = ParseString(GetStringInfo(self.mod_root .. "/reforged_news.txt", false), "\n") or {}
    local has_news = #news > 0
    top_root.news = top_root:AddChild(self:AddInfoPanel(has_news and string.sub(news[1],1,#news[1]-1) or "", OrganizeBodyText(news, scroll_opts.width, scroll_font_opts, true), scroll_opts, "latest"))
    top_root.news:SetPosition(275,0)
    self.scrolls.latest.title = top_root.news.title
    self.scrolls.latest.body = top_root.news.body
    self.scrolls.latest:Disable()

    return top_root
end

function NewsPanel:UpdateScrollData(scroll, info)
    if #info > 0 then
        scroll.title:SetString(info[1])
        scroll:Enable()
        scroll.body:SetItemsData(OrganizeBodyText(info, scroll_opts.width, scroll_font_opts, true))
        scroll:Disable()
    end
end

function NewsPanel:UpdateScroll(source)
    local scroll = self.scrolls[source]
    if scroll == nil then return end
    local bg_width,bg_height = scroll:GetSize()
    if self.scroll_anims[source] then
        self.scroll_anims[source].reverse = true
        self.scroll_anims[source].y_final = scroll.y_offset + bg_height
    else
        self.scroll_anims[source] = {
            x_pos = 0,
            y_pos = scroll.y_offset,
            y_final = scroll.y_offset + bg_height,
            reverse = true,
        }
        scroll:Disable()
    end
end

function NewsPanel:StartSync(source)
    local scroll = self.scrolls[source]
    if scroll == nil then return end
    self.sync_anims[source] = true
    scroll.sync_icon:Show()
end

function NewsPanel:StopSync(source, failed)
    local scroll = self.scrolls[source]
    if scroll == nil then return end
    self.sync_anims[source] = nil
    scroll.sync_icon:Hide()
end

local note_opts = {
    title_y     = 190,
    bg_y_offset = 140,
    spacing     = -10,
    max_rows    = 7,
    width       = 300,
    scrollbar_offset = {35, 0},
    scrollbar_height_offset = -10,
    bg = {atlas = "images/rf_panel_assets.xml", tex = "community_note_bg.tex", scale = {-1,1}},
}
local note_font_opts = {
    size = 15,
    font = HEADERFONT,
}
-- Displays Server News/Info, Event News, ReForged News
function NewsPanel:BuildBottomInfoDisplay()
    local bottom_root = Widget("bottom_root")

    local mod_list = KnownModIndex:GetModsToLoad()
    local mod_strings = {}
    for _,name in pairs(mod_list) do
        local mod_info = KnownModIndex:GetModInfo(name)
        if mod_info.name then
            table.insert(mod_strings, mod_info.name)
        end
    end
    bottom_root.server = bottom_root:AddChild(self:AddInfoPanel(string.sub(STRINGS.UI.MAINSCREEN.MODTITLE, 1, -2), OrganizeBodyText(mod_strings, note_opts.width, note_font_opts), note_opts))
    bottom_root.server:SetPosition(-225,0)

    -- Media Icon Links
    local function CreateButton(atlas, tex, pos, hover_text, onclick_fn)
        local button = ImageButton(atlas, tex)
        button:ForceImageSize(50, 50)
        button:SetPosition(pos.x, pos.y)
        button:SetHoverText(hover_text)
        button:SetOnClick(onclick_fn)
        return button
    end
    local button_atlas = "images/rf_panel_assets.xml"
    bottom_root.discord_button = self:AddChild(CreateButton(button_atlas, "rf_discord.tex", {x = 0, y = -110}, nil, function() VisitURL("https://discord.com/invite/xkpsE8c") end))
    bottom_root.steam_button   = self:AddChild(CreateButton(button_atlas, "rf_steam.tex",   {x = 0, y = -160}, nil, function() VisitURL("https://steamcommunity.com/sharedfiles/filedetails/?id=1938752683") end))
    bottom_root.youtube_button = self:AddChild(CreateButton(button_atlas, "rf_youtube.tex", {x = 0, y = -210}, nil, function() VisitURL("http://youtube.com") end))

    note_opts.bg.scale = {1,1}
    local patch_notes = ParseString(GetStringInfo(self.mod_root .. "/patch_notes.txt", false), "\n")
    bottom_root.patch_notes = bottom_root:AddChild(self:AddInfoPanel(STRINGS.UI.NEWS_PANEL.PATCH_NOTES, OrganizeBodyText(patch_notes, note_opts.width, note_font_opts), note_opts))
    bottom_root.patch_notes:SetPosition(225,0)

    return bottom_root
end

function NewsPanel:AddInfoPanel(title, body_text, opts, source)
    local info_panel = Widget("info_panel")

    local options = {
        body_font_size   = 15,
        title_y          = 200,
        bg_y_offset      = 60,
        spacing          = 0,
        max_rows         = 15,
        width            = 50,
        scrollbar_offset = {0,0},
        scrollbar_height_offset = 0,
        bg = {atlas = "images/rf_panel_assets.xml", tex = "community_scroll_bg.tex", scale = {1, 1}},
    }
    MergeTable(options, opts, true)

    -- BG
    info_panel.bg = info_panel:AddChild(Image(options.bg.atlas, options.bg.tex))
    info_panel.bg:SetDisabledTexture(options.bg.atlas, options.bg.tex)
    info_panel.bg:SetPosition(0, options.bg_y_offset)
    info_panel.bg.y_offset = options.bg_y_offset
    info_panel.bg:SetScale(options.bg.scale[1], options.bg.scale[2])
    local bg_width,bg_height = info_panel.bg:GetSize()
    if options.title_bg then
        info_panel.title_bg = info_panel:AddChild(Image(options.title_bg.atlas, options.title_bg.tex))
        info_panel.title_bg:SetPosition(0, options.title_y)
        info_panel.title_bg:SetScale(options.bg.scale[1], options.bg.scale[2])
        self.scrolls[source] = info_panel.bg
        self.scroll_anims[source] = {
            x_pos = 0,
            y_pos = options.bg_y_offset + bg_height,
            y_final = options.bg_y_offset,
            reverse = false,
        }
        info_panel.bg:SetPosition(0, self.scroll_anims[source].y_pos)
        info_panel.bg:SetScissor(-bg_width*.5,-bg_height*.5, bg_width, 0*bg_height)

        info_panel.sync_icon = info_panel:AddChild(Image("images/reforged.xml", "p_unknown.tex"))
        info_panel.sync_icon:SetPosition(0, options.bg_y_offset)
        self.scrolls[source].sync_icon = info_panel.sync_icon
        if TheWorld.net.replica.serverinfomanager and TheWorld.net.replica.serverinfomanager:IsSyncing(source) then
            self.sync_anims[source] = true
        else
            info_panel.sync_icon:Hide()
        end
    end
    -- Title text
    info_panel.title = info_panel:AddChild(Text(HEADERFONT, 25, "", UICOLOURS.BROWN_DARK))
    info_panel.title:SetMultilineTruncatedString(string.sub(title,string.len(title)) == "\n" and string.sub(title,1,string.len(title) - 1) or title, 1, bg_width * 0.8, nil, nil, true)
    info_panel.title:SetPosition(0,options.title_y)

    -- Body text
    local body_font_size = 15
    local width_to_string_ratio = 5.6
    local body_width = options.width--*width_to_string_ratio
    local link_icon_size = 15
    local function InitializeBodyWidget(context, index)
        local body_widget = Widget("body")
        body_widget.data = {}
        body_widget.scroll_index = index

        body_widget.text = body_widget:AddChild(Text(HEADERFONT, options.body_font_size, "", UICOLOURS.BROWN_DARK))
        body_widget.text:SetRegionSize(body_width, body_font_size)
        body_widget.text:SetHAlign(ANCHOR_LEFT)

        body_widget.button_links = {}
        local discord_button = body_widget:AddChild(ImageButton("images/rf_panel_assets.xml", "rf_discord.tex"))
        discord_button:ScaleImage(link_icon_size, link_icon_size)
        discord_button:Hide()
        body_widget.button_links.discord = discord_button

        local steam_button = body_widget:AddChild(ImageButton("images/rf_panel_assets.xml", "rf_steam.tex"))
        steam_button:ScaleImage(link_icon_size, link_icon_size)
        steam_button:Hide()
        body_widget.button_links.steam = steam_button

        local youtube_button = body_widget:AddChild(ImageButton("images/rf_panel_assets.xml", "rf_youtube.tex"))
        youtube_button:ScaleImage(link_icon_size, link_icon_size)
        youtube_button:Hide()
        body_widget.button_links.youtube = youtube_button

        return body_widget
    end

    local url_links = {
        discord = "https://discord.com/invite/",
        steam   = "https://steamcommunity.com/sharedfiles/filedetails/?id=",
        youtube = "http://youtube.com/",
    }
    local url_types = {
        discord = "discord",
        steam   = "steam",
        youtube = "youtube",
    }
    local function UpdateBodyWidget(context, widget, data, index)
        if not widget then return end

        -- Hide all button links
        for _,button in pairs(widget.button_links) do
            button:Hide()
        end

        if data then
            widget.text:SetString(data.str)
            -- Display any button links
            for _,info in pairs(data.links) do
                local type = info.type
                local button = widget.button_links[type]
                if button then
                    button:SetOnClick(function()
                        VisitURL(url_links[type] .. info.link)
                    end)
                    button:SetPosition(info.x_offset and (info.x_offset - body_width/2 + link_icon_size/2) or 0, 0)
                    button:Show()
                end
            end
        else
            widget.text:SetString("")
        end
    end

    info_panel.body = info_panel.bg:AddChild(TEMPLATES.ScrollingGrid(body_text or {},{
        context = {},
        widget_width  = body_width,
        widget_height = body_font_size,
        num_visible_rows = options.max_rows,
        num_columns      = 1,
        item_ctor_fn     = InitializeBodyWidget,
        apply_fn         = UpdateBodyWidget,
        scrollbar_offset = opts.scrollbar_offset[1],
        scrollbar_height_offset = opts.scrollbar_height_offset,
        --scissor_pad = 100,--max_string_length*0.18,
        --peek_percent = 0.25,
    }))
    info_panel.body:SetPosition(0,options.spacing)

    info_panel.body.up_button:SetTextures("images/rf_panel_assets.xml", "scroll_bar_arrow.tex")
    info_panel.body.up_button:SetScale(0.3)

    info_panel.body.down_button:SetTextures("images/rf_panel_assets.xml", "scroll_bar_arrow.tex")
    info_panel.body.down_button:SetScale(-0.3)

    --info_panel.body.scroll_bar_line:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
    --info_panel.body.scroll_bar_line:SetScale(.2)

    info_panel.body.position_marker:SetTextures("images/rf_panel_assets.xml", "scroll_bar_box.tex")
    info_panel.body.position_marker.image:SetTexture("images/rf_panel_assets.xml", "scroll_bar_box.tex")
    info_panel.body.position_marker:SetScale(.4)

    info_panel.body:RefreshView()
    -- Prevent scrolling while disabled. TODO should this just be overwritten in general for all to use?
    local _oldScroll = info_panel.body.Scroll
    info_panel.body.Scroll = function(self, scroll_step)
        if self:IsEnabled() then
            _oldScroll(self, scroll_step)
        end
    end

    local pos = info_panel.body.scroll_bar_container:GetPosition()
    info_panel.body.scroll_bar_container:SetPosition(pos.x, pos.y + opts.scrollbar_offset[2])

    return info_panel
end

local Y_PER_TICK = 2
local ANGLE_PER_TICK = 1
function NewsPanel:OnUpdate(dt)
    if next(self.scroll_anims) ~= nil then
        local anims_complete = {}
        for name,info in pairs(self.scroll_anims) do
            local scroll = self.scrolls[name]
            info.y_pos = info.y_pos + (info.reverse and Y_PER_TICK or -Y_PER_TICK)
            info.y_pos = info.reverse and math.min(info.y_pos, info.y_final) or math.max(info.y_pos, info.y_final)
            local bg_width,bg_height = scroll:GetSize()
            local percent = math.clamp(math.abs((info.reverse and 0 or bg_height) - math.abs(info.y_pos - info.y_final)) / bg_height, 0, 1)
            scroll:SetPosition(info.x_pos, info.y_pos)
            if info.y_pos == info.y_final then
                if info.reverse then
                    info.reverse = false
                    info.y_final = info.y_final - bg_height
                    self:UpdateScrollData(scroll, TheWorld.net.replica.serverinfomanager and TheWorld.net.replica.serverinfomanager:HasInfo(name) and TheWorld.net.replica.serverinfomanager:GetInfo(name) or {})
                else
                    table.insert(anims_complete, name)
                    --info.reverse = true
                    --info.y_final = info.y_final + bg_height
                end
            end
            scroll:SetScissor(-bg_width*.5,-bg_height*.5, bg_width + 100, percent*bg_height) -- + 100 width to ensure nothing gets cutoff
            -- Reapply Body's scissor so no text is out of bounds
            local body_width = scroll.body.scissor_width
            local body_height = scroll.body.scissor_height
            scroll.body.scissored_root:SetScissor(-body_width/2, -body_height/2, body_width, percent*body_height)
        end
        for _,name in pairs(anims_complete) do
            self.scroll_anims[name] = nil
            self.scrolls[name]:Enable()
        end
    end
    if next(self.sync_anims) ~= nil then
        local remove_sync = {}
        for source,_ in pairs(self.sync_anims) do
            if TheWorld.net.replica.serverinfomanager and TheWorld.net.replica.serverinfomanager:IsSyncing(source) then
                local scroll = self.scrolls[source]
                scroll.sync_icon:SetRotation(scroll.sync_icon.inst.UITransform:GetRotation() + ANGLE_PER_TICK)
            else
                remove_sync[source] = true
            end
        end
        for source,_ in pairs(remove_sync) do
            self:StopSync(source)
        end
    end
end

return NewsPanel
