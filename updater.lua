--Github: https://github.com/Kasra-G/ReactorController/#readme
--pastebin run w6vVtrLb

fs.makeDir("/usr")
fs.makeDir("/usr/apis")

--Overwrite startup file
local file = fs.open("startup", "w")
file.writeLine("shell.run(\"pastebin run w6vVtrLb\")")
file.writeLine("while (true) do")
file.writeLine("	shell.run(\"reactorController.lua\")")
file.writeLine("	sleep(2)")
file.writeLine("end")
file.close()


local filesToUpdate = {
	["/reactorController.lua"] = "b17hfTqe",
    ["/usr/apis/touchpoint.lua"] = "nx9pkLbJ",
}
-- Table for files/pastebin codes

function getFile(fileName, link)
  
  local file = http.get("http://pastebin.com/raw.php?i=" .. textutils.urlEncode(link))
  
  if file then
    
     local out = file.readAll()
     file.close()
     return out
     -- Returning contents of the pastebin file
  else
    
     return false
     -- Returning false if the link is invalid
  end
end
-- Function for downloading the files from pastebin, needs HTTP to run

function getVersion(fileContents)
  
  if fileContents then
    local _, numberChars = fileContents:lower():find('version = "')
    local fileVersion = ""
    local char = ""
    -- Declaring variables aswell as finding where in the fileContents argument is 'version = "'
  
    if numberChars then
      while char ~= '"' do
      
        numberChars = numberChars + 1
        char = fileContents:sub(numberChars,numberChars)
        fileVersion = fileVersion .. char
      end
      -- Making the version variable by putting every character from 'version = "' to '"'
    
      fileVersion = fileVersion:sub(1,#fileVersion-1)
      return fileVersion
    else
    
      return false
      -- If the function didn't find 'version = "' in the fileContents then it returns false
    end
  else
    
    return ""
  end
end
-- Finding the version number



for file, url in pairs(filesToUpdate) do
  
  if not fs.isDir(file) then
    
    local pastebinContents = getFile(file,url)
    -- Getting the pastebin file's contents
    
    if pastebinContents then
      if fs.exists(file) then
        
        local localFile = fs.open(file,"r")
        localContents = localFile.readAll()
        localFile.close()
        -- Getting the local file's contents
      end
      
      local pastebinVersion = getVersion(pastebinContents)
      local localVersion = getVersion(localContents)
      -- Defining version variables for each of the file's contents
      
      if not pastebinVersion then
        
        print("[Error  ] the pastebin code for " .. file .. " does not have a version variable")
        -- Tests if the pastebin code's contents has a version variable or not
        
      elseif not localVersion then
        
        print("[Error  ] " .. file .. " does not have a version variable")
        -- Tests if the local file doesn't have the version variable
        
      elseif pastebinVersion == localVersion then
        
        print("[Success] " .. file .. " is already the latest version")
        -- If the pastebin file's version is equal to the local file's version then it does nothing
      else
        
        endFile = fs.open(file,"w")
        endFile.write(pastebinContents)
        endFile.close()
        
        print("[Success] " .. file .. " has been updated to version " .. pastebinVersion)
        -- If the versions are not the same then it will write over the current local file to update it to the pastebin version
      end
    else
      
      print("[Error  ] " .. file .. " has an invalid link")
     end
  else
    
    print("[Error  ] " .. file .. " is a directory")
  end
end
-- Error messages catching different errors
