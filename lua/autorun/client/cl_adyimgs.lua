ADYLIB = ADYLIB or {}

local ImageCache = {}
ImageCache.Materials = {}
---@param url string
---@param filePath string
---@return IMaterial
function ImageCache:CacheMaterial(url, filePath)
    local material = Material("data/" .. filePath)
    self.Materials[url] = material
    return material
end
---@param url string
---@return boolean
function ImageCache:HasMaterial(url)
    return self.Materials[url] ~= nil
end
---@param url string
---@return IMaterial|nil
function ImageCache:GetMaterial(url)
    return self.Materials[url] -- !!! Can be nil !!!
end

-- Download image destination can be changed
local ImageDestination

--- **[Client]** Resets path to the folder where all downloaded images will be stored to default (`/data/ady/images/`)
function ADYLIB:ResetImageDestination()
    ImageDestination = "ady/images/"
end
--- **[Client]** Changes the destination folder for all images that will be downloaded.
---
--- `destination` should be specified relative to Garry's Mod `/data/` folder (e.g. `/ady/images/banners/`)
--- 
--- v1 - specified path should exist. This method doesn't create a folder
---@param destination any
---@return boolean
function ADYLIB:SetImageDestination(destination)
    if not file.IsDir(destination, "DATA") then
        -- TODO Create script to make a destination
        return false
    end
    ImageDestination = destination
    return true
end
--- **[Client]** Returns the path to the folder where all downloaded images will be stored
---@return string
function ADYLIB:GetImageDestination()
    return ImageDestination
end
ADYLIB:ResetImageDestination()

local function GetFileNameFromURL(url)
    local name = string.match(url, "([^/]+)$")
    local ext = string.match(url, "%.([^.]+)$") or "png"
    
    if not name or not string.find(name, "%.") then
        repeat
            --name = GenerateRandomString(10) .. "." .. ext
            name = ADYLIB.Random:GetRandomString(10) .. "." .. ext
        until not file.Exists("ady/images/" .. name, "DATA")
    end
    return name
end

--- **[Client]** Downloads an image to player's `data` folder and allows to use it as a `Material`.
--- 
--- Remember that Garry's Mod can display only images using `.png` and `.jpg` extensions.
---@param url string
---@param callback? fun(material: IMaterial, path: string)
---@return string
function ADYLIB:DownloadImage(url, callback)
    local fileName = GetFileNameFromURL(url)
    local filePath = ImageDestination .. fileName
    
    if not file.IsDir("ady", "DATA") then file.CreateDir("ady") end
    if not file.IsDir("ady/images", "DATA") then file.CreateDir("ady/images") end

    if file.Exists(filePath, "DATA") then
        if not ImageCache:HasMaterial(url) then ImageCache:CacheMaterial(url, filePath) end
        local material = ImageCache:GetMaterial(url)
        if callback ~= nil and material then callback(material, "data/" .. filePath) end
    else
        http.Fetch(url, function(body, size, headers, code)
            if code == 200 and body and body ~= "" then
                file.Write(filePath, body)
                local material = ImageCache:CacheMaterial(url, filePath)
                if callback ~= nil then callback(material, "data/" .. filePath) end
            else
                print("Ошибка загрузки изображения. Код: " .. code)
            end
        end, function(error)
            print("Ошибка HTTP: " .. error)
        end)
    end
    return filePath
end

--- **[Client]** Allows you to preload the image for future use.
--- 
--- Remember that Garry's Mod can display only images using `.png` and `.jpg` extensions.
---@param url string
function ADYLIB:PreloadImage(url)
    -- In case you don't need to have a callback
    ADYLIB:DownloadImage(url, nil)
end