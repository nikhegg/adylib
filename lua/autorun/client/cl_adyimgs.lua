ADYLIB = ADYLIB or {}

local ImageCache = {}
ImageCache.Materials = {}
function ImageCache:CacheMaterial(url, filePath)
    local material = Material("data/" .. filePath)
    self.Materials[url] = material
    return material
end
function ImageCache:HasMaterial(url)
    return self.Materials[url] ~= nil
end
function ImageCache:GetMaterial(url)
    return self.Materials[url] -- !!! Can be nil !!!
end

-- Download image destination can be changed
local ImageDestination
function ADYLIB:ResetImageDestination()
    ImageDestination = "ady/images/"
end
function ADYLIB:SetImageDestination(destination)
    if not file.IsDir(destination, "DATA") then
        -- TODO Create script to make a destination
        return false
    end
    ImageDestination = destination
    return true
end
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

-- Callback won't be used if client can't download an image
-- Returns image path string
-- callback(Material) {...}
function ADYLIB:DownloadImage(url, callback)
    local fileName = GetFileNameFromURL(url)
    local filePath = ImageDestination .. fileName
    
    if not file.IsDir("ady", "DATA") then file.CreateDir("ady") end
    if not file.IsDir("ady/images", "DATA") then file.CreateDir("ady/images") end

    if file.Exists(filePath, "DATA") then
        if not ImageCache:HasMaterial(url) then ImageCache:CacheMaterial(url, filePath) end
        local material = ImageCache:GetMaterial(url)
        if callback ~= nil then callback(material) end
    else
        http.Fetch(url, function(body, size, headers, code)
            if code == 200 and body and body ~= "" then
                file.Write(filePath, body)
                local material = ImageCache:CacheMaterial(url, filePath)
                print(material)
                if callback ~= nil then callback(material) end
            else
                print("Ошибка загрузки изображения. Код: " .. code)
            end
        end, function(error)
            print("Ошибка HTTP: " .. error)
        end)
    end
    return filePath
end

function ADYLIB:PreloadImage(url)
    -- In case you don't need to have a callback
    ADYLIB:DownloadImage(url, nil)
end