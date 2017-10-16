-- xml based registry
-- advantage : config file is human readable 
-- disadvantag : writing/reading/updating is too slow for heavy/realtime use
-- good for config and remember last settings etc

gRegistrySlow = {}
function gRegistrySlow:Set (key,val) self.data[key] = val   self:Save() end
function gRegistrySlow:Get (key) return self.data[key] end
function gRegistrySlow:GetFilePath () return gConfigPath.."registry.xml" end
function gRegistrySlow:Load () self.data =	SimpleXMLLoad(self:GetFilePath()) or {} end
function gRegistrySlow:Save () 				SimpleXMLSave(self:GetFilePath(),self.data) end
