--lune/base/Parser.lns
local moduleObj = {}
local function createReserveInfo( luaMode )
  local keywordSet = {}
  local typeSet = {}
  local builtInSet = {}
  keywordSet["let"] = true
  keywordSet["if"] = true
  keywordSet["else"] = true
  keywordSet["elseif"] = true
  keywordSet["while"] = true
  keywordSet["for"] = true
  keywordSet["in"] = true
  keywordSet["return"] = true
  keywordSet["break"] = true
  keywordSet["nil"] = true
  keywordSet["true"] = true
  keywordSet["false"] = true
  keywordSet["{"] = true
  keywordSet["}"] = true
  builtInSet["require"] = true
  if luaMode then
    keywordSet["function"] = true
    keywordSet["then"] = true
    keywordSet["do"] = true
    keywordSet["until"] = true
  else 
    keywordSet["let"] = true
    keywordSet["mut"] = true
    keywordSet["pub"] = true
    keywordSet["pro"] = true
    keywordSet["pri"] = true
    keywordSet["fn"] = true
    keywordSet["each"] = true
    keywordSet["form"] = true
    keywordSet["class"] = true
    builtInSet["super"] = true
    keywordSet["static"] = true
    keywordSet["advertise"] = true
    keywordSet["as"] = true
    keywordSet["import"] = true
    keywordSet["new"] = true
    keywordSet["!"] = true
    typeSet["int"] = true
    typeSet["real"] = true
    typeSet["stem"] = true
    typeSet["str"] = true
    typeSet["Map"] = true
    typeSet["bool"] = true
  end
  local multiCharDelimitMap = {}
  multiCharDelimitMap["="] = {"=="}
  multiCharDelimitMap["~"] = {"~="}
  multiCharDelimitMap["<"] = {"<="}
  multiCharDelimitMap[">"] = {">="}
  multiCharDelimitMap["."] = {".."}
  multiCharDelimitMap["@"] = {"@@"}
  multiCharDelimitMap["@@"] = {"@@?"}
  multiCharDelimitMap[".."] = {"..."}
  return keywordSet, typeSet, builtInSet, multiCharDelimitMap
end

local Stream = {}
-- none
function Stream.new(  )
  local obj = {}
  setmetatable( obj, { __index = Stream } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function Stream:__init(  )
            
end

local Position = {}
moduleObj.Position = Position
function Position.new( lineNo, column )
  local obj = {}
  setmetatable( obj, { __index = Position } )
  if obj.__init then
    obj:__init( lineNo, column )
  end
  return obj
end
function Position:__init( lineNo, column )
            
self.lineNo = lineNo
  self.column = column
  end

local Token = {}
moduleObj.Token = Token
function Token.new( kind, txt, pos )
  local obj = {}
  setmetatable( obj, { __index = Token } )
  if obj.__init then
    obj:__init( kind, txt, pos )
  end
  return obj
end
function Token:__init( kind, txt, pos )
            
self.kind = kind
  self.txt = txt
  self.pos = pos
  end

local Parser = {}
moduleObj.Parser = Parser
function Parser.new( stream, name, luaMode )
  local obj = {}
  setmetatable( obj, { __index = Parser } )
  if obj.__init then obj:__init( stream, name, luaMode ); end
return obj
end
function Parser:__init(stream, name, luaMode) 
  self.stream = stream
  self.streamName = name
  self.lineNo = 0
  self.pos = 1
  self.lineTokenList = {}
  local keywordSet, typeSet, builtInSet, multiCharDelimitMap = createReserveInfo( luaMode )
  self.keywordSet = keywordSet
  self.typeSet = typeSet
  self.builtInSet = builtInSet
  self.multiCharDelimitMap = multiCharDelimitMap
end
function Parser:getStreamName(  )
  return self.streamName
end
function Parser.create( path, luaMode )
  local stream = io.open( path, "r" )
  if not stream then
    return nil
  end
  return Parser.new(stream, path, luaMode or string.find( path, "%.lua$" ))
end

local kind = {}
moduleObj.kind = kind

local kindSeed = 0
local kind2Txt = {}
local function regKind( name )
  local assignKind = kindSeed
  kindSeed = kindSeed + 1
  kind2Txt[assignKind] = name
  kind[name] = assignKind
  return assignKind
end

local kindCmnt = regKind( "Cmnt" )
local kindStr = regKind( "Str" )
local kindInt = regKind( "Int" )
local kindReal = regKind( "Real" )
local kindChar = regKind( "Char" )
local kindSymb = regKind( "Symb" )
local kindDlmt = regKind( "Dlmt" )
local kindKywd = regKind( "Kywd" )
local kindOpe = regKind( "Ope" )
local kindType = regKind( "Type" )
local kindEof = regKind( "Eof" )
local quotedCharSet = {}
quotedCharSet['a'] = true
quotedCharSet['b'] = true
quotedCharSet['f'] = true
quotedCharSet['n'] = true
quotedCharSet['r'] = true
quotedCharSet['t'] = true
quotedCharSet['v'] = true
quotedCharSet['\\'] = true
quotedCharSet['"'] = true
quotedCharSet["'"] = true
local op2Set = {}
op2Set['+'] = true
op2Set['-'] = true
op2Set['*'] = true
op2Set['/'] = true
op2Set['//'] = true
op2Set['^'] = true
op2Set['%'] = true
op2Set['&'] = true
op2Set['~'] = true
op2Set['|'] = true
op2Set['>>'] = true
op2Set['<<'] = true
op2Set['..'] = true
op2Set['<'] = true
op2Set['<='] = true
op2Set['>'] = true
op2Set['>='] = true
op2Set['=='] = true
op2Set['~='] = true
op2Set['and'] = true
op2Set['or'] = true
op2Set['@'] = true
op2Set['='] = true
local op1Set = {}
op1Set['-'] = true
op1Set['not'] = true
op1Set['#'] = true
op1Set['~'] = true
op1Set['*'] = true
local function getKindTxt( kind )
  return kind2Txt[kind]
end
moduleObj.getKindTxt = getKindTxt
local function isOp2( ope )
  return op2Set[ope]
end
moduleObj.isOp2 = isOp2
local function isOp1( ope )
  return op1Set[ope]
end
moduleObj.isOp1 = isOp1
function Parser:parse(  )
  local function readLine(  )
    self.lineNo = self.lineNo + 1
    return self.stream:read( '*l' )
  end
  
  local rawLine = readLine(  )
  if not rawLine then
    return nil
  end
  local list = {}
  local startIndex = 1
  local multiComment = function ( comIndex, termStr )
    local searchIndex = comIndex
    local comment = ""
    while true do
      local termIndex, termEndIndex = string.find( rawLine, termStr, searchIndex, true )
      if termIndex then
        comment = comment .. rawLine:sub( searchIndex, termEndIndex )
        return comment, termEndIndex + 1
      end
      comment = comment .. rawLine:sub( searchIndex ) .. "\n"
      searchIndex = 1
      rawLine = readLine(  )
      if not rawLine then
        error( "illegal comment" )
      end
    end
  end
  
  local addVal = function ( kind, val, column )
    local function createInfo( tokenKind, token, tokenColumn )
      if tokenKind == kindSymb then
        if self.keywordSet[token] then
          tokenKind = kindKywd
        elseif self.typeSet[token] then
          tokenKind = kindType
        elseif op2Set[token] or op1Set[token] then
          tokenKind = kindOpe
        end
      end
      return {["kind"] = tokenKind, ["txt"] = token, ["pos"] = {["lineNo"] = self.lineNo, ["column"] = tokenColumn}}
    end
    
    local function analyzeNumber( token, startIndex )
      local nonNumIndex = token:find( '[^%d]', startIndex )
      if not nonNumIndex then
        return #token, true
      end
      local intFlag = true
      local nonNumChar = token:byte( nonNumIndex )
      if nonNumChar == 46 then
        intFlag = false
        nonNumIndex = token:find( '[^%d]', nonNumIndex + 1 )
        nonNumChar = token:byte( nonNumIndex )
      end
      if nonNumChar == 120 or nonNumChar == 88 then
        nonNumIndex = token:find( '[^%d]', nonNumIndex + 1 )
        nonNumChar = token:byte( nonNumIndex )
      end
      if nonNumChar == 101 or nonNumChar == 69 then
        intFlag = false
        local nextChar = token:byte( nonNumIndex + 1 )
        if nextChar == 45 or nextChar == 43 then
          nonNumIndex = token:find( '[^%d]', nonNumIndex + 2 )
        else 
          nonNumIndex = token:find( '[^%d]', nonNumIndex + 1 )
        end
      end
      if not nonNumIndex then
        return #token, intFlag
      end
      return nonNumIndex - 1, intFlag
    end
    
    if kind == kindSymb then
      local searchIndex = 1
      while true do
        local tokenIndex, tokenEndIndex = string.find( val, "[%g]+", searchIndex )
        if not tokenIndex then
          break
        end
        local columnIndex = column + tokenIndex - 2
        searchIndex = tokenEndIndex + 1
        local token = val:sub( tokenIndex, tokenEndIndex )
        local startIndex = 1
        while true do
          if token:find( '^[%d]', startIndex ) then
            local endIndex, intFlag = analyzeNumber( token, startIndex )
            local info = createInfo( intFlag and kindInt or kindReal, token:sub( startIndex, endIndex ), columnIndex + startIndex )
            table.insert( list, info )
            startIndex = endIndex + 1
          else 
            local index = string.find( token, '[^%w_]', startIndex )
            if index then
              if index > startIndex then
                local info = createInfo( kindSymb, token:sub( startIndex, index - 1 ), columnIndex + startIndex )
                table.insert( list, info )
              end
              local delimit = token:sub( index, index )
              local candidateList = self.multiCharDelimitMap[delimit]
              while candidateList do
                local findFlag = false
                for __index, candidate in pairs( candidateList ) do
                  if candidate == token:sub( index, index + #candidate - 1 ) then
                    delimit = candidate
                    candidateList = self.multiCharDelimitMap[delimit]
                    findFlag = true
                    break
                  end
                end
                if not findFlag then
                  break
                end
              end
              startIndex = index + #delimit
              local workKind = kindDlmt
              if op2Set[delimit] or op1Set[delimit] then
                workKind = kindOpe
              end
              if delimit == "?" then
                local nextChar = token:sub( index, startIndex )
                table.insert( list, createInfo( kindChar, nextChar, columnIndex + startIndex ) )
                startIndex = startIndex + 1
              else 
                table.insert( list, createInfo( workKind, delimit, columnIndex + index ) )
              end
            else 
              if startIndex <= #token then
                table.insert( list, createInfo( kindSymb, token:sub( startIndex ), columnIndex + startIndex ) )
              end
              break
            end
          end
        end
      end
    else 
      table.insert( list, createInfo( kind, val, column ) )
    end
  end
  
  local searchIndex = startIndex
  while true do
    local syncIndexFlag = true
    local pattern = [==[[%-%?"%'%`%[].]==]
    local index = string.find( rawLine, pattern, searchIndex )
    if not index then
      addVal( kindSymb, rawLine:sub( startIndex ), startIndex )
      return list
    end
    local findChar = string.byte( rawLine, index )
    local nextChar = string.byte( rawLine, index + 1 )
    if findChar == 45 and nextChar ~= 45 then
      searchIndex = index + 1
      syncIndexFlag = false
    else 
      if startIndex < index then
        addVal( kindSymb, rawLine:sub( startIndex, index - 1 ), startIndex )
      end
      if findChar == 39 and nextChar == 39 then
        if string.byte( rawLine, index + 2 ) == 39 then
          local comment, nextIndex = multiComment( index + 3, "'''" )
          addVal( kindCmnt, "'''" .. comment, index )
          searchIndex = nextIndex
        else 
          addVal( kindCmnt, rawLine:sub( index ), index )
          searchIndex = #rawLine + 1
        end
      elseif findChar == 91 then
        if nextChar == 64 then
          addVal( kindDlmt, "[@", index )
          searchIndex = index + 2
        else 
          addVal( kindDlmt, "[", index )
          searchIndex = index + 1
        end
      elseif findChar == 39 or findChar == 34 then
        local workIndex = index + 1
        local pattern = '["\'\\]'
        while true do
          local endIndex = string.find( rawLine, pattern, workIndex )
          if not endIndex then
            error( string.format( "illegal string: %d: %s", index, rawLine ) )
          end
          local workChar = string.byte( rawLine, endIndex )
          if workChar == findChar then
            addVal( kindStr, rawLine:sub( index, endIndex ), index )
            searchIndex = endIndex + 1
            break
          elseif workChar == 92 then
            workIndex = workIndex + 2
          else 
            workIndex = workIndex + 1
          end
        end
      elseif findChar == 96 then
        if (nextChar == findChar and string.byte( rawLine, index + 2 ) == 96 ) then
          local str, nextIndex = multiComment( index + 3, '```' )
          addVal( kindStr, '```' .. str, index )
          searchIndex = nextIndex
        else 
          addVal( kindDlmt, '`', index )
        end
      elseif findChar == 63 then
        local codeChar = rawLine:sub( index + 1, index + 1 )
        if nextChar == 92 then
          local quoted = rawLine:sub( index + 2, index + 2 )
          if quotedCharSet[quoted] then
            codeChar = rawLine:sub( index + 1, index + 2 )
          else 
            codeChar = quoted
          end
          searchIndex = index + 3
        else 
          searchIndex = index + 2
        end
        addVal( kindChar, codeChar, index )
      else 
        error( string.format( "illegal syntax:%s:%s", self.lineNo, rawLine:sub( index ) ) )
      end
    end
    if syncIndexFlag then
      startIndex = searchIndex
    end
  end
end

function Parser:getToken(  )
  if not self.lineTokenList then
    return nil
  end
  if #self.lineTokenList < self.pos then
    self.pos = 1
    self.lineTokenList = {}
    while #self.lineTokenList == 0 do
      self.lineTokenList = self:parse(  )
      if not self.lineTokenList then
        return nil
      end
    end
  end
  local token = self.lineTokenList[self.pos]
  self.pos = self.pos + 1
  return token
end

local eofToken = {["kind"] = kindEof, ["txt"] = "", ["pos"] = {["lineNo"] = 0, ["column"] = 0}}
local function getEofToken(  )
  return eofToken
end
moduleObj.getEofToken = getEofToken
----- meta -----
local _className2InfoMap = {}
moduleObj._className2InfoMap = _className2InfoMap
local _classInfoParser = {}
_className2InfoMap.Parser = _classInfoParser
local _classInfoPosition = {}
_className2InfoMap.Position = _classInfoPosition
_classInfoPosition.lineNo = {
  name='lineNo', staticFlag = false, accessMode = 'pub', methodFlag = false, typeId = 12 }
_classInfoPosition.column = {
  name='column', staticFlag = false, accessMode = 'pub', methodFlag = false, typeId = 12 }
local _classInfoToken = {}
_className2InfoMap.Token = _classInfoToken
_classInfoToken.kind = {
  name='kind', staticFlag = false, accessMode = 'pub', methodFlag = false, typeId = 12 }
_classInfoToken.txt = {
  name='txt', staticFlag = false, accessMode = 'pub', methodFlag = false, typeId = 18 }
_classInfoToken.pos = {
  name='pos', staticFlag = false, accessMode = 'pub', methodFlag = false, typeId = 132 }
local _varName2InfoMap = {}
moduleObj._varName2InfoMap = _varName2InfoMap
_varName2InfoMap.kind = {
  name='kind', accessMode = 'pub', typeId = 170 }
local _funcName2InfoMap = {}
moduleObj._funcName2InfoMap = _funcName2InfoMap
moduleObj._typeInfoList = {}
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 132, baseId = 1, txt = 'Position',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 134, baseId = 1, txt = 'Token',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 136, baseId = 1, txt = 'Parser',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {154, 156, 212}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 158, baseId = 1, txt = 'Stream',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 170, baseId = 1, txt = 'Map',
staticFlag = false, accessMode = 'pub', kind = 4, itemTypeId = {18, 12}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 184, baseId = 1, txt = 'getKindTxt',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {12}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 186, baseId = 1, txt = 'isOp2',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 188, baseId = 1, txt = 'isOp1',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 220, baseId = 1, txt = 'getEofToken',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {6}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 136, typeId = 154, baseId = 1, txt = 'getStreamName',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 136, typeId = 156, baseId = 1, txt = 'create',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {136}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 136, typeId = 212, baseId = 1, txt = 'getToken',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
----- meta -----
return moduleObj
