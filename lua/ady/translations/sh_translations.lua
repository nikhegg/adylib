ADYLIB = ADYLIB or {}

local allowed_langs = {
    "bg",    -- Bulgarian
    "cs",    -- Czech
    "da",    -- Danish
    "de",    -- German
    "el",    -- Greek
    "en",    -- English
    "en-PT", -- Pirate English AHOY
    "es-ES", -- Spanish
    "et",    -- Estonian
    "fi",    -- Finnish
    "fr",    -- French
    "he",    -- Hebrew
    "hr",    -- Croatian
    "hu",    -- Hungarian
    "it",    -- Italian
    "ja",    -- Japanese
    "ko",    -- Korean
    "lt",    -- Lithuanian
    "nl",    -- Dutch
    "no",    -- Norwegian
    "pl",    -- Polish
    "pt-BR", -- Portuguese (Brazil)
    "pt-PT", -- Portuguese (Portugal)
    "ru",    -- Russian
    "sk",    -- Slovak
    "sv-SE", -- Swedish
    "th",    -- Thai
    "tr",    -- Turkish
    "uk",    -- Ukrainian
    "vi",    -- Vietnamese
    "zh-CN", -- Chinese Simplified
    "zh-TW"  -- Chinese Traditional
}
local configPath = "ady/locales/sha.json"

---@class Translator
ADYLIB.Translator = ADYLIB.Translator or {}
ADYLIB.Translator.__lang = GetConVar("gmod_language"):GetString() or "en"
ADYLIB.Translator.__addons = ADYLIB.Translator.__addons or {"base"}
ADYLIB.Translator.__sources = ADYLIB.Translator.__sources or {}
ADYLIB.Translator.__cache = ADYLIB.Translator.__cache or {}
ADYLIB.Translator.__config = ADYLIB.Translator.__config or {}
ADYLIB.Translator.__targets = ADYLIB.Translator.__targets or {}



local function MaintainLocalesFolder()
    if not file.Exists("ady", "DATA") then
    file.CreateDir("ady")
    end
    if not file.Exists("ady/locales", "DATA") then
        file.CreateDir("ady/locales")
    end
end

--- TBD
---@param translations table
---@return table
local function RecursiveGetTranslation(translations, depth)
    local result = {}

    for key, value in pairs(translations) do
        if type(value) == "table" then
            local recursiveResult = RecursiveGetTranslation(value, depth + 1)
            for modKey, translation in pairs(recursiveResult) do
                result[key .. "." .. modKey] = translation
            end
        elseif type(value) == "string" then
            result[key] = value
        end
    end

    return result
end
--- TBD
---@param translations table|string|nil
local function LoadTranslation(translations)
    if type(translations) == "string" then
        translations = util.JSONToTable(translations)
    end
    if not translations then return end

    local result = RecursiveGetTranslation(translations, 0)
    for name, translation in pairs(result) do
        ADYLIB.Translator.__cache[name] = translation
    end

    ADYLIB.Translator:InvalidateTranslation()
end

--- TBD
---@param language string
function ADYLIB.Translator:SetLanguage(language)
    language = string.lower(language)
    if not table.HasValue(allowed_langs, language) then return end
    self.__lang = language
    self:Update()
end
function ADYLIB.Translator:GetLanguage()
    return self.__lang
end


function ADYLIB.Translator:Register(translation_name)
    translation_name = string.lower(translation_name)
    if table.HasValue(self.__addons, translation_name) then return end
    table.insert(self.__addons, translation_name)
end
function ADYLIB.Translator:Unregister(tranlsation_name)
    if not table.HasValue(self.__addons, tranlsation_name) then return end
    table.RemoveByValue(self.__addons, tranlsation_name)
end
--- TBD
---@param language? string
function ADYLIB.Translator:Update(language)
    MaintainLocalesFolder()
    local targetLang = language or self.__lang
    local configExists = file.Exists(configPath, "DATA")

    if configExists and #self.__config == 0 then
        local configContent = file.Read(configPath, "DATA")
        self.__config = util.JSONToTable(configContent)
    end

    local requests = 0
    for i, addon in ipairs(self.__addons) do
        for j, source in ipairs(self.__sources) do
            if not source.tree then continue end
            for _, node in ipairs(source.tree) do
                if not node.path then continue end
                local path = string.lower(node.path)
                local starts = string.StartsWith(path, addon)
                local ends = string.EndsWith(path, targetLang .. ".json")
                if starts and ends then
                    local sha = node.sha
                    local filename = string.Replace(node.path, "/", ".")
                    local filepath = "ady/locales/" .. filename
                    if file.Exists(filepath, "DATA") and configExists then
                        -- Compare with saved SHA
                        local savedSha = self.__config[filename]
                        if not savedSha then savedSha = "NONE" end
                        ADYLIB:LogDebug("SHA for " .. filename .. " translation\n\tSaved: " .. savedSha .. "\n\tLatest: " .. sha)
                        if savedSha == sha then
                            local content = file.Read(filepath, "DATA")
                            LoadTranslation(util.JSONToTable(content))
                            continue -- Do nothing cause SHA is the same
                        end
                        ADYLIB:LogDebug("Locale update required for " .. filename)
                    end

                    -- Download the file
                    requests = requests + 1
                    http.Fetch(node.url, function(body, size, headers, code)
                        -- Save SHA if we got the last HTTP request
                        requests = requests - 1
                        self.__config[filename] = sha
                        if requests == 0 then
                            ADYLIB:LogDebug("Saving Translator SHAs")
                            local json = util.TableToJSON(ADYLIB.Translator.__config)
                            file.Write(configPath, json)
                        end

                        local data = util.JSONToTable(body)
                        if not data or not data.content then return end
                        local encoded_content = string.gsub(data.content, "[\n\r\t ]", "")
                        local decoded_content = util.Base64Decode(encoded_content)
                        if not decoded_content or decoded_content == "" then return end

                        local tbl = util.JSONToTable(decoded_content)
                        if tbl then LoadTranslation(tbl) end
                        file.Write(filepath, decoded_content)
                    end)
                end
            end
        end
    end
end

--- TBD
---@param str string
---@param regex table
local function GetRegexedString(str, regex)
    for target, value in pairs(regex) do
        str = string.Replace(str, target, value)
    end
    return str
end

function ADYLIB.Translator:InvalidateTranslation()
    for i, data in pairs(self.__targets) do
        if not data.target or not IsValid(data.target) then
            table.remove(self.__targets, i)
            continue
        end
        local str = self.__cache[data.name]
        if data.regex then
            str = GetRegexedString(str, data.regex)
        end

        if type(data.method) == "string" then
            PrintTable(data)
            data.target[data.method](data.target, str)
        else
            data.method(data.target, str)
        end
    end
end

---@class TargetConfig
---@field panel Panel
---@field method string|function

--- TBD
---@param name string
---@param target TargetConfig|Panel
---@param regex? table
---@return string|boolean
---@diagnostic disable-next-line: lowercase-global
function t(name, target, regex)
    local str = ADYLIB.Translator.__cache[name] or name
    if regex then
        str = GetRegexedString(str, regex)
    end
    if not str then
        return false
    end

    if not target then
        return str
    end
    local method = "SetText"
    if target.panel and target.method then
        target = target.panel
        method = target.method or method
    end

    target:SetText(str)
    local data = {
        name = name,
        target = target,
        method = method
    }
    table.insert(ADYLIB.Translator.__targets, data)
    return true
end

ADYLIB.Translator.Translate = t