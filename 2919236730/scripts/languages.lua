local RF_DATA = _G.REFORGED_DATA
RF_DATA.languages = {}
_G.require("translator")
local _oldLoadPOFile = _G.LanguageTranslator.LoadPOFile
_G.LanguageTranslator.LoadPOFile = function(self, fname, lang)
    if self.languages and self.languages[lang] then
        local temp_lang = lang .. "_temp"
        _oldLoadPOFile(self, fname, temp_lang)
        _G.MergeTable(self.languages[lang], self.languages[temp_lang], true)
        self.languages[temp_lang] = nil
        self.defaultlang = lang
    else
        _oldLoadPOFile(self, fname, lang)
        for _,file in pairs(RF_DATA.languages[lang] or {}) do
            LoadPOFile(file, lang)
        end
    end
end
local function DoesFileExistAlready(file_path, lang)
    for _,file in pairs(RF_DATA.languages[lang]) do
        if file == file_path then
            return true
        end
    end
    return false
end
function AddLanguageFile(file_path, lang)
    if RF_DATA.languages[lang] and DoesFileExistAlready(file_path, lang) then
        Debug:Print("Attempted to add the language file '" .. tostring(name) .."', but it already exists.", "error")
        return
    end
    if not RF_DATA.languages[lang] then RF_DATA.languages[lang] = {} end
    table.insert(RF_DATA.languages[lang], file_path)
    -- Load Language file initially if language is active
    local current_loc = _G.LOC.GetLocale()
    if current_loc and current_loc.code == lang then
        LoadPOFile(file_path, lang)
    end
end
_G.AddLanguageFile = AddLanguageFile
local language_file_path = "scripts/languages/"
AddLanguageFile(language_file_path .. "chinese_s_reforged.po", "zh")
AddLanguageFile(language_file_path .. "chinese_t_reforged.po", "zh")
AddLanguageFile(language_file_path .. "korean_reforged.po", "ko")
-- LanguageTranslator:LoadPOFile("scripts/languages/chinese_s_reforged.po", "zh")
-- LanguageTranslator:LoadPOFile("scripts/languages/korean_reforged.po", "ko")
-- LanguageTranslator:GetTranslatedString("STRINGS.LAVAARENA_CHARACTER_DESCRIPTIONS.winona", "ab")
