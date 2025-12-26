util.AddNetworkString("AdyLib/Translations")

ADYLIB = ADYLIB or {}
ADYLIB.Translator = ADYLIB.Translator or {}
ADYLIB.Translator.__last_source_refresh = 0

--- TBD
---@param source_url string
---@param origin? string
---@return boolean
function ADYLIB.Translator:AddSource(source_url, origin)
    for _, url in ipairs(self.__sources) do
        if source_url == url then
            return false
        end
    end

    local data = {
        url = source_url,
        origin = source_url
    }
    if origin then
        data.origin = origin
    end
    table.insert(self.__sources, data)
    ADYLIB:LogDebug("Added " .. source_url .. " to Translator")
    return true
end

function ADYLIB.Translator:HasSource(source_url)
    for _, source in ipairs(self.__sources) do
        if source.origin == source_url then
            return true
        end
    end
    return false
end

--- TBD
---@param source_url string
---@return boolean
function ADYLIB.Translator:RemoveSource(source_url)
    for i, source in ipairs(self.__sources) do
        if source.origin == source_url then
            table.remove(self.__sources, i)
            return true
        end
    end

    return false
end

function ADYLIB.Translator:GetSources()
    return self.__sources
end

function ADYLIB.Translator:ShareTranslations()
    net.Start("AdyLib/Translations")
    net.WriteTable(self.__sources)
    net.Broadcast()
end

--- **[Server]** Fetches all translation sources that are added by checking their SHA
function ADYLIB.Translator:RefreshSources()
    local now = os.time()
    if self.__last_source_refresh and self.__last_source_refresh - now >= 0 then
        self:ShareTranslations()
        return
    end
    self.__last_source_refresh = now + 900 -- GitHub Pages has 15m timeout

    for i, sourceData in ipairs(self.__sources) do
        local sourceSha = sourceData.sha
        http.Fetch(sourceData.url, function(body, size, headers, code)
            local data = util.JSONToTable(body)
            if not data then
                -- ERROR LOL
                return
            end
            if data.sha ~= sourceSha then
                -- Manifest was updated
                data.url = sourceData.url
                data.origin = sourceData.origin
                self.__sources[i] = data
            else return end

            data.truncated = nil
            if data.tree then
                for j=#data.tree,1,-1 do
                    local node = data.tree[j]
                    if node.type == "tree" then
                        table.remove(data.tree, j)
                    else
                        node.type = nil
                        node.size = nil
                        node.mode = nil
                    end
                end
            end

            if i == #self.__sources then
                net.Start("AdyLib/Translations")
                net.WriteTable(self.__sources)
                net.Broadcast()
            end
        end)
    end
end

-- Register Default AdyLib translations
if #ADYLIB.Translator:GetSources() == 0 then
    local OWNER = "nikhegg"
    local REPO = "adylib"
    local BRANCH = "main"

    local ROOT_TREE_URL = string.format("https://api.github.com/repos/%s/%s/git/trees/%s", OWNER, REPO, BRANCH)

    http.Fetch(ROOT_TREE_URL, function(body, _, headers, code)
        if code == 403 then
            local now = os.time()
            local remaining = headers["x-ratelimit-reset"] - now
            ADYLIB:LogWarning("You are rate-limited by GitHub. Try again in " .. remaining .. "s")
            return
        end
        local data = util.JSONToTable(body)
        if not data or not data.tree then
            ADYLIB:LogWarning("Cannot access GitHub tree of translation files. Trying to use the local ones...")
            return
        end

        local sha
        for _, item in ipairs(data.tree) do
            if item.path == "lang" and item.type == "tree" and item.sha then
                sha = item.sha
                break
            end
        end

        if not sha then return end
        local target_url = string.format("https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1", OWNER, REPO, sha)
        ADYLIB.Translator:AddSource(target_url, ROOT_TREE_URL)
    end)
end

hook.Add("PlayerInitialSpawn", "AdyLib/ShareTranslations", function(ply)
    ADYLIB.Translator:RefreshSources()
end)