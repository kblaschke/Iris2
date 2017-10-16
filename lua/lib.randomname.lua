-- based on http://www.gamedev.net/reference/articles/article2016.asp

-- the grammar consists of a list of tripels containing a pattern, a replacement and the probability to apply this rule
gRndNameGrammar = {
	-- initial part
	{"S","<Vow><A>",0.5},
	{"S","<Con><B>",0.5},
	{"A","<Con><B>",1.0},
	{"B","<Vow><A>",1.0},
	-- vow
	{"Vow","a",0.335},
	{"Vow","e",0.305},
	{"Vow","i",0.22},
	{"Vow","o",0.10},
	{"Vow","u",0.04},
	-- con
	{"Con","b",0.087},
	{"Con","c",0.047},
	{"Con","d",0.087},
	{"Con","f",0.057},
	{"Con","g",0.057},
	{"Con","h",0.047},
	{"Con","j",0.027},
	{"Con","k",0.047},
	{"Con","l",0.057},
	{"Con","m",0.067},
	{"Con","n",0.057},
	{"Con","p",0.027},
	{"Con","q",0.017},
	{"Con","r",0.047},
	{"Con","s",0.057},
	{"Con","t",0.057},
	{"Con","v",0.047},
	{"Con","w",0.047},
	{"Con","x",0.017},
	{"Con","y",0.017},
	{"Con","z",0.017},
}

-- replace every occurance of a patter one time
-- apply this multiple times to "recursivly" replace patterns
-- if grammar is nil all then each pattern is replace by a empty string
function RndNameApplyRule(s,grammar)
	return string.gsub(s,"<([^>]+)>",function(s)
		local r = math.random()
		
		if grammar then
			for k,o in pairs(grammar) do
				local pat = o[1]
				local repl = o[2]
				local p = o[3]
				if pat == s then
					-- print("DEBUG trip",pat,repl,p,r)
					if r < p then
						-- found a matching rule
						-- print("MATCH",repl)
						return repl
					end
					r = r - p
				end
			end
		end
		-- no rule found so remove the pattern
		return ""
	end)
end

-- generates a random name between min and max size
function RndNameGenerate(minsize,maxsize,grammar)
	minsize = minsize or 4
	maxsize = maxsize or 8
	grammar = grammar or gRndNameGrammar
	local size = math.random(minsize,maxsize)
	local s = "<S>"
	while string.len(RndNameApplyRule(s,nil)) < size do
		s = RndNameApplyRule(s,grammar)
		-- print("POST",s)
	end
	s = RndNameApplyRule(s,nil)
	return s
end

function GenerateRandomName_Pilot () return CapitalizeName(RndNameGenerate()) end
function GenerateRandomName_Pirate () return GenerateRandomName_Pilot() end

gRandomNames = {
	"Goodman",
	"Muldoon",
	"Celine",
	"Mocenigo",
	"Pearson",
	"Dorn",
	"Sullivan",
	"Malik",
	"Cartwright",
	"Coin",
	"Moon",
	"Dillinger",
	"Maldonado",
}

-- changes the first letter to uppercase
function CapitalizeName (name) return string.upper(string.sub(name,1,1))..string.sub(name,2,string.len(name)) end

function MissionGetRandomName () 
	local name = (math.random() < 0.2) and gRandomNames[math.random(table.getn(gRandomNames))] or RndNameGenerate()
	local prefix = ((math.random() < 0.2) and "Dr.") or ((math.random() < 0.5) and "Mr." or "Mrs.")
	return prefix .. " " .. CapitalizeName(name)
end


