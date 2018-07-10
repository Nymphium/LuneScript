--lune/base/TransUnit.lns
local moduleObj = {}
local Parser = require( 'lune.base.Parser' )

local function errorLog( message )
  (io ).stderr:write( message .. "\n" )
end
moduleObj.errorLog = errorLog
local function debugLog(  )
  local debugInfo1 = debug.getinfo( 2 )
  local debugInfo2 = debug.getinfo( 3 )
  local debugInfo3 = debug.getinfo( 4 )
  local debugInfo4 = debug.getinfo( 5 )
  errorLog( string.format( "-- %s %s", debugInfo1["short_src"], debugInfo1['currentline']) )
  errorLog( string.format( "-- %s %s", debugInfo2["short_src"], debugInfo2['currentline']) )
  errorLog( string.format( "-- %s %s", debugInfo3["short_src"], debugInfo3['currentline']) )
  errorLog( string.format( "-- %s %s", debugInfo4["short_src"], debugInfo4['currentline']) )
end
moduleObj.debugLog = debugLog
local rootTypeId = 1
moduleObj.rootTypeId = rootTypeId

local typeIdSeed = rootTypeId + 1
local rootTypeInfo = nil
local typeInfoKind = {}
moduleObj.typeInfoKind = typeInfoKind

local builtInTypeMap = {}
local builtInTypeIdSet = {}
local TypeInfoKindRoot = 0
moduleObj.TypeInfoKindRoot = TypeInfoKindRoot

local TypeInfoKindPrim = 1
moduleObj.TypeInfoKindPrim = TypeInfoKindPrim

local TypeInfoKindList = 2
moduleObj.TypeInfoKindList = TypeInfoKindList

local TypeInfoKindArray = 3
moduleObj.TypeInfoKindArray = TypeInfoKindArray

local TypeInfoKindMap = 4
moduleObj.TypeInfoKindMap = TypeInfoKindMap

local TypeInfoKindClass = 5
moduleObj.TypeInfoKindClass = TypeInfoKindClass

local TypeInfoKindFunc = 6
moduleObj.TypeInfoKindFunc = TypeInfoKindFunc

local TypeInfoKindNilable = 7
moduleObj.TypeInfoKindNilable = TypeInfoKindNilable

local function isBuiltin( typeId )
  return builtInTypeIdSet[typeId]
end
moduleObj.isBuiltin = isBuiltin
local OutStream = {}
-- none
function OutStream.new(  )
  local obj = {}
  setmetatable( obj, { __index = OutStream } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function OutStream:__init(  )
            
end

local TypeInfo = {}
moduleObj.TypeInfo = TypeInfo
function TypeInfo.new( baseTypeInfo, orgTypeInfo, autoFlag, externalFlag, staticFlag, accessMode, txt, parentInfo, typeId, kind, itemTypeInfoList, retTypeInfoList )
  local obj = {}
  setmetatable( obj, { __index = TypeInfo } )
  if obj.__init then obj:__init( baseTypeInfo, orgTypeInfo, autoFlag, externalFlag, staticFlag, accessMode, txt, parentInfo, typeId, kind, itemTypeInfoList, retTypeInfoList ); end
return obj
end
function TypeInfo:__init(baseTypeInfo, orgTypeInfo, autoFlag, externalFlag, staticFlag, accessMode, txt, parentInfo, typeId, kind, itemTypeInfoList, retTypeInfoList) 
  self.baseTypeInfo = baseTypeInfo
  self.autoFlag = autoFlag
  self.externalFlag = externalFlag
  self.staticFlag = staticFlag
  self.accessMode = accessMode
  self.txt = txt
  self.kind = kind
  self.itemTypeInfoList = itemTypeInfoList or {}
  self.retTypeInfoList = retTypeInfoList or {}
  self.orgTypeInfo = orgTypeInfo
  self.parentInfo = parentInfo
  self.children = {}
  if rootTypeInfo and not parentInfo then
    debugLog(  )
    error( "" )
  end
  if kind == TypeInfoKindRoot then
    self.typeId = typeId
    self.nilable = false
    rootTypeInfo = self
  elseif not orgTypeInfo then
    if parentInfo then
      table.insert( parentInfo.children, self )
    end
    self.typeId = typeId + 1
    self.nilable = false
    self.nilableTypeInfo = TypeInfo.new(baseTypeInfo, self, autoFlag, externalFlag, staticFlag, accessMode, "", parentInfo, typeIdSeed, TypeInfoKindNilable, itemTypeInfoList, retTypeInfoList)
    typeIdSeed = typeIdSeed + 1
  else 
    self.typeId = typeId
    self.nilable = true
    self.nilableTypeInfo = nil
  end
end
function TypeInfo:getParentId(  )
  return self.parentInfo and self.parentInfo.typeId or rootTypeId
end
function TypeInfo:get_baseId(  )
  return self.baseTypeInfo and self.baseTypeInfo.typeId or rootTypeId
end
function TypeInfo:addChild( child )
  table.insert( self.children, child )
end
function TypeInfo:serialize( stream )
  if self.typeId == rootTypeId then
    return nil
  end
  local parentId = self:getParentId(  )
  if self.orgTypeInfo then
    stream:write( string.format( '{ parentId = %d, typeId = %d, nilable = true, orgTypeId = %d }', parentId, self.typeId, self.orgTypeInfo.typeId) )
    return nil
  end
  local function serializeTypeInfoList( name, list, onlyPub )
    local work = name
    for __index, typeInfo in pairs( list ) do
      if not onlyPub or typeInfo.accessMode == "pub" then
        if #work ~= #name then
          work = work .. ", "
        end
        work = string.format( "%s%d", work, typeInfo.typeId)
      end
    end
    return work .. "}, "
  end
  
  local txt = string.format( [==[{ parentId = %d, typeId = %d, baseId = %d, txt = '%s',
staticFlag = %s, accessMode = '%s', kind = %d, ]==], parentId, self.typeId, self:get_baseId(  ), self.txt, self.staticFlag, self.accessMode, self.kind)
  stream:write( txt .. serializeTypeInfoList( "itemTypeId = {", self.itemTypeInfoList ) .. serializeTypeInfoList( "retTypeId = {", self.retTypeInfoList ) .. serializeTypeInfoList( "children = {", self.children, true ) .. "}\n" )
end
function TypeInfo:getTxt(  )
  if self.orgTypeInfo then
    return self.orgTypeInfo:getTxt(  ) .. "!"
  end
  if self.kind == TypeInfoKindArray then
    if not self.itemTypeInfoList[1] then
      return "[@]"
    end
    return self.itemTypeInfoList[1]:getTxt(  ) .. "[@]"
  end
  if self.kind == TypeInfoKindList then
    if not self.itemTypeInfoList[1] then
      return "[]"
    end
    return self.itemTypeInfoList[1]:getTxt(  ) .. "[]"
  end
  if self.itemTypeInfoList and #self.itemTypeInfoList > 0 then
    local txt = self.txt .. "<"
    for index, typeInfo in pairs( self.itemTypeInfoList ) do
      if index ~= 1 then
        txt = txt .. ","
      end
      txt = txt .. typeInfo:getTxt(  )
    end
    return txt .. ">"
  end
  if self.txt then
    return self.txt
  end
  return ""
end
function TypeInfo:equals( typeInfo, depth )
  if not typeInfo then
    return false
  end
  if not depth then
    depth = 1
  end
  if self.typeId == typeInfo.typeId then
    return true
  end
  if self.kind ~= typeInfo.kind or self.staticFlag ~= typeInfo.staticFlag or self.accessMode ~= typeInfo.accessMode or self.autoFlag ~= typeInfo.autoFlag or self.nilable ~= typeInfo.nilable then
    return false
  end
  if (not self.itemTypeInfoList and typeInfo.itemTypeInfoList or self.itemTypeInfoList and not typeInfo.itemTypeInfoList or not self.retTypeInfoList and typeInfo.retTypeInfoList or self.retTypeInfoList and not typeInfo.retTypeInfoList or not self.orgTypeInfo and typeInfo.orgTypeInfo or self.orgTypeInfo and not typeInfo.orgTypeInfo ) then
    errorLog( "%s, %s", self.itemTypeInfoList, typeInfo.itemTypeInfoList )
    errorLog( "%s, %s", self.retTypeInfoList, typeInfo.retTypeInfoList )
    errorLog( "%s, %s", self.orgTypeInfo, typeInfo.orgTypeInfo )
    return false
  end
  if self.itemTypeInfoList then
    if #self.itemTypeInfoList ~= #typeInfo.itemTypeInfoList then
      return false
    end
    for index, item in pairs( self.itemTypeInfoList ) do
      if not item:equals( typeInfo.itemTypeInfoList[index], depth + 1 ) then
        return false
      end
    end
  end
  if self.retTypeInfoList then
    if #self.retTypeInfoList ~= #typeInfo.retTypeInfoList then
      return false
    end
    for index, item in pairs( self.retTypeInfoList ) do
      if not item:equals( typeInfo.retTypeInfoList[index], depth + 1 ) then
        return false
      end
    end
  end
  if self.orgTypeInfo and not self.orgTypeInfo:equals( typeInfo.orgTypeInfo, depth + 1 ) then
    return false
  end
  return true
end
function TypeInfo.cloneToPublic( typeInfo )
  typeIdSeed = typeIdSeed + 1
  return TypeInfo.new(typeInfo.baseTypeInfo, nil, typeInfo.autoFlag, typeInfo.externalFlag, typeInfo.staticFlag, "pub", typeInfo.txt, typeInfo.parentInfo, typeIdSeed, typeInfo.kind, typeInfo.itemTypeInfoList, typeInfo.retTypeInfoList)
end
function TypeInfo.create( baseInfo, parentInfo, staticFlag, kind, txt, itemTypeInfo, retTypeInfoList )
  if kind == TypeInfoKindPrim then
    return builtInTypeMap[txt]
  end
  typeIdSeed = typeIdSeed + 1
  local info = TypeInfo.new(baseInfo, nil, false, true, staticFlag, "pub", txt, parentInfo, typeIdSeed, kind, itemTypeInfo, retTypeInfoList)
  return info
end
function TypeInfo.createBuiltin( idName, typeTxt, kind )
  local typeId = typeIdSeed + 1
  if kind == TypeInfoKindRoot then
    typeId = rootTypeId
  else 
    typeIdSeed = typeIdSeed + 1
  end
  local info = TypeInfo.new(nil, nil, false, false, false, "pub", typeTxt, rootTypeInfo, typeId, kind)
  typeInfoKind[idName] = info
  builtInTypeMap[typeTxt] = info
  builtInTypeIdSet[info.typeId] = true
  return info
end
function TypeInfo.createList( accessMode, parentInfo, itemTypeInfo )
  if not itemTypeInfo or #itemTypeInfo == 0 then
    error( string.format( "illegal list type: %s", itemTypeInfo) )
  end
  typeIdSeed = typeIdSeed + 1
  return TypeInfo.new(nil, nil, false, false, false, accessMode, "", rootTypeInfo, typeIdSeed, TypeInfoKindList, itemTypeInfo)
end
function TypeInfo.createArray( accessMode, parentInfo, itemTypeInfo )
  typeIdSeed = typeIdSeed + 1
  return TypeInfo.new(nil, nil, false, false, false, accessMode, "", rootTypeInfo, typeIdSeed, TypeInfoKindArray, itemTypeInfo)
end
function TypeInfo.createMap( accessMode, parentInfo, keyTypeInfo, valTypeInfo )
  typeIdSeed = typeIdSeed + 1
  return TypeInfo.new(nil, nil, false, false, false, accessMode, "Map", rootTypeInfo, typeIdSeed, TypeInfoKindMap, {keyTypeInfo, valTypeInfo})
end
function TypeInfo.createClass( baseInfo, parentInfo, externalFlag, accessMode, className )
  if className == "str" then
    return builtInTypeMap[className]
  end
  typeIdSeed = typeIdSeed + 1
  local info = TypeInfo.new(baseInfo, nil, false, externalFlag, false, accessMode, className, parentInfo, typeIdSeed, TypeInfoKindClass)
  return info
end
function TypeInfo.createFunc( parentInfo, autoFlag, externalFlag, staticFlag, accessMode, funcName, argTypeList, retTypeInfoList )
  typeIdSeed = typeIdSeed + 1
  local info = TypeInfo.new(nil, nil, autoFlag, externalFlag, staticFlag, accessMode, funcName, parentInfo, typeIdSeed, TypeInfoKindFunc, argTypeList or {}, retTypeInfoList or {})
  return info
end
function TypeInfo:get_itemTypeInfoList()
   return self.itemTypeInfoList
end
function TypeInfo:get_retTypeInfoList()
   return self.retTypeInfoList
end
function TypeInfo:get_parentInfo()
   return self.parentInfo
end
function TypeInfo:get_typeId()
   return self.typeId
end
function TypeInfo:get_kind()
   return self.kind
end
function TypeInfo:get_staticFlag()
   return self.staticFlag
end
function TypeInfo:get_accessMode()
   return self.accessMode
end
function TypeInfo:get_autoFlag()
   return self.autoFlag
end
function TypeInfo:get_orgTypeInfo()
   return self.orgTypeInfo
end
function TypeInfo:get_baseTypeInfo()
   return self.baseTypeInfo
end
function TypeInfo:get_nilable()
   return self.nilable
end
function TypeInfo:get_nilableTypeInfo()
   return self.nilableTypeInfo
end
function TypeInfo:get_children()
   return self.children
end

local typeInfoNone = TypeInfo.createBuiltin( "None", "", TypeInfoKindPrim )
local typeInfoRoot = TypeInfo.createBuiltin( "Root", ":", TypeInfoKindRoot )
local typeInfoStem = TypeInfo.createBuiltin( "Stem", "stem", TypeInfoKindPrim )
local typeInfoNil = TypeInfo.createBuiltin( "Nil", "nil", TypeInfoKindPrim )
local typeInfoBool = TypeInfo.createBuiltin( "Bool", "bool", TypeInfoKindPrim )
local typeInfoInt = TypeInfo.createBuiltin( "Int", "int", TypeInfoKindPrim )
local typeInfoReal = TypeInfo.createBuiltin( "Real", "real", TypeInfoKindPrim )
local typeInfoChar = TypeInfo.createBuiltin( "char", "char", TypeInfoKindPrim )
local typeInfoString = TypeInfo.createBuiltin( "String", "str", TypeInfoKindClass )
local typeInfoMap = TypeInfo.createBuiltin( "Map", "Map", TypeInfoKindMap )
local typeInfoList = TypeInfo.createBuiltin( "List", "List", TypeInfoKindList )
local typeInfoArray = TypeInfo.createBuiltin( "Array", "Array", TypeInfoKindArray )
local typeInfoForm = TypeInfo.createBuiltin( "Form", "form", TypeInfoKindFunc )
local Scope = {}
moduleObj.Scope = Scope
function Scope.new( parent, inheritList )
  local obj = {}
  setmetatable( obj, { __index = Scope } )
  if obj.__init then obj:__init( parent, inheritList ); end
return obj
end
function Scope:__init(parent, inheritList) 
  self.parent = parent
  self.symbol2TypeInfoMap = {}
  self.className2ScopeMap = {}
  self.inheritList = inheritList
end
function Scope:add( name, typeInfo )
  self.symbol2TypeInfoMap[name] = typeInfo
end
function Scope:addClass( name, typeInfo, scope )
  self:add( name, typeInfo )
  self.className2ScopeMap[name] = scope
end
function Scope:getClassScope( name )
  local scope = self.className2ScopeMap[name]
  if not scope and self.parent then
    scope = self.parent:getClassScope( name )
  end
  return scope
end
function Scope:getTypeInfoChild( name )
  return self.symbol2TypeInfoMap[name]
end
function Scope:getTypeInfo( name )
  local typeInfo = self.symbol2TypeInfoMap[name]
  if typeInfo then
    return typeInfo
  end
  if self.inheritList then
    for __index, scope in pairs( self.inheritList ) do
      typeInfo = scope:getTypeInfo( name )
      if typeInfo then
        return typeInfo
      end
    end
  end
  if self.parent then
    return self.parent:getTypeInfo( name )
  end
  return builtInTypeMap[name]
end
function Scope:get_parent()
   return self.parent
end
function Scope:get_symbol2TypeInfoMap()
   return self.symbol2TypeInfoMap
end
function Scope:get_className2ScopeMap()
   return self.className2ScopeMap
end

local NodePos = {}
moduleObj.NodePos = NodePos
function NodePos.new( lineNo, column )
  local obj = {}
  setmetatable( obj, { __index = NodePos } )
  if obj.__init then
    obj:__init( lineNo, column )
  end
  return obj
end
function NodePos:__init( lineNo, column )
            
self.lineNo = lineNo
  self.column = column
  end

local Node = {}
moduleObj.Node = Node
function Node.new( kind, pos, expType, expTypeList, info, filter )
  local obj = {}
  setmetatable( obj, { __index = Node } )
  if obj.__init then
    obj:__init( kind, pos, expType, expTypeList, info, filter )
  end
  return obj
end
function Node:__init( kind, pos, expType, expTypeList, info, filter )
            
self.kind = kind
  self.pos = pos
  self.expType = expType
  self.expTypeList = expTypeList
  self.info = info
  self.filter = filter
  end
function Node:get_kind()
   return self.kind
end
function Node:get_expType()
   return self.expType
end
function Node:get_info()
   return self.info
end

local ImportNode = {}
setmetatable( ImportNode, { __index = Node } )
moduleObj.ImportNode = ImportNode
function ImportNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ImportNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ImportNode:__init(  )
            
end

local RootNode = {}
setmetatable( RootNode, { __index = Node } )
moduleObj.RootNode = RootNode
function RootNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = RootNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function RootNode:__init(  )
            
end

local RefTypeNode = {}
setmetatable( RefTypeNode, { __index = Node } )
moduleObj.RefTypeNode = RefTypeNode
function RefTypeNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = RefTypeNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function RefTypeNode:__init(  )
            
end

local IfNode = {}
setmetatable( IfNode, { __index = Node } )
moduleObj.IfNode = IfNode
function IfNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = IfNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function IfNode:__init(  )
            
end

local SwitchNode = {}
setmetatable( SwitchNode, { __index = Node } )
moduleObj.SwitchNode = SwitchNode
function SwitchNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = SwitchNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function SwitchNode:__init(  )
            
end

local WhileNode = {}
setmetatable( WhileNode, { __index = Node } )
moduleObj.WhileNode = WhileNode
function WhileNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = WhileNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function WhileNode:__init(  )
            
end

local RepeatNode = {}
setmetatable( RepeatNode, { __index = Node } )
moduleObj.RepeatNode = RepeatNode
function RepeatNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = RepeatNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function RepeatNode:__init(  )
            
end

local ForNode = {}
setmetatable( ForNode, { __index = Node } )
moduleObj.ForNode = ForNode
function ForNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ForNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ForNode:__init(  )
            
end

local ApplyNode = {}
setmetatable( ApplyNode, { __index = Node } )
moduleObj.ApplyNode = ApplyNode
function ApplyNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ApplyNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ApplyNode:__init(  )
            
end

local ForeachNode = {}
setmetatable( ForeachNode, { __index = Node } )
moduleObj.ForeachNode = ForeachNode
function ForeachNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ForeachNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ForeachNode:__init(  )
            
end

local ForsortNode = {}
setmetatable( ForsortNode, { __index = Node } )
moduleObj.ForsortNode = ForsortNode
function ForsortNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ForsortNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ForsortNode:__init(  )
            
end

local ReturnNode = {}
setmetatable( ReturnNode, { __index = Node } )
moduleObj.ReturnNode = ReturnNode
function ReturnNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ReturnNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ReturnNode:__init(  )
            
end

local BreakNode = {}
setmetatable( BreakNode, { __index = Node } )
moduleObj.BreakNode = BreakNode
function BreakNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = BreakNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function BreakNode:__init(  )
            
end

local ExpNewNode = {}
setmetatable( ExpNewNode, { __index = Node } )
moduleObj.ExpNewNode = ExpNewNode
function ExpNewNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpNewNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpNewNode:__init(  )
            
end

local ExpListNode = {}
setmetatable( ExpListNode, { __index = Node } )
moduleObj.ExpListNode = ExpListNode
function ExpListNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpListNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpListNode:__init(  )
            
end

local ExpRefNode = {}
setmetatable( ExpRefNode, { __index = Node } )
moduleObj.ExpRefNode = ExpRefNode
function ExpRefNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpRefNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpRefNode:__init(  )
            
end

local ExpOp2Node = {}
setmetatable( ExpOp2Node, { __index = Node } )
moduleObj.ExpOp2Node = ExpOp2Node
function ExpOp2Node.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpOp2Node } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpOp2Node:__init(  )
            
end

local ExpCastNode = {}
setmetatable( ExpCastNode, { __index = Node } )
moduleObj.ExpCastNode = ExpCastNode
function ExpCastNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpCastNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpCastNode:__init(  )
            
end

local ExpOp1Node = {}
setmetatable( ExpOp1Node, { __index = Node } )
moduleObj.ExpOp1Node = ExpOp1Node
function ExpOp1Node.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpOp1Node } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpOp1Node:__init(  )
            
end

local ExpRefItemNode = {}
setmetatable( ExpRefItemNode, { __index = Node } )
moduleObj.ExpRefItemNode = ExpRefItemNode
function ExpRefItemNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpRefItemNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpRefItemNode:__init(  )
            
end

local ExpCallNode = {}
setmetatable( ExpCallNode, { __index = Node } )
moduleObj.ExpCallNode = ExpCallNode
function ExpCallNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpCallNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpCallNode:__init(  )
            
end

local ExpDDDNode = {}
setmetatable( ExpDDDNode, { __index = Node } )
moduleObj.ExpDDDNode = ExpDDDNode
function ExpDDDNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpDDDNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpDDDNode:__init(  )
            
end

local ExpParenNode = {}
setmetatable( ExpParenNode, { __index = Node } )
moduleObj.ExpParenNode = ExpParenNode
function ExpParenNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = ExpParenNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function ExpParenNode:__init(  )
            
end

local BlockNode = {}
setmetatable( BlockNode, { __index = Node } )
moduleObj.BlockNode = BlockNode
function BlockNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = BlockNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function BlockNode:__init(  )
            
end

local StmtExpNode = {}
setmetatable( StmtExpNode, { __index = Node } )
moduleObj.StmtExpNode = StmtExpNode
function StmtExpNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = StmtExpNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function StmtExpNode:__init(  )
            
end

local RefFieldNode = {}
setmetatable( RefFieldNode, { __index = Node } )
moduleObj.RefFieldNode = RefFieldNode
function RefFieldNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = RefFieldNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function RefFieldNode:__init(  )
            
end

local DeclVarNode = {}
setmetatable( DeclVarNode, { __index = Node } )
moduleObj.DeclVarNode = DeclVarNode
function DeclVarNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = DeclVarNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function DeclVarNode:__init(  )
            
end

local DeclFuncNode = {}
setmetatable( DeclFuncNode, { __index = Node } )
moduleObj.DeclFuncNode = DeclFuncNode
function DeclFuncNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = DeclFuncNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function DeclFuncNode:__init(  )
            
end

local DeclMethodNode = {}
setmetatable( DeclMethodNode, { __index = Node } )
moduleObj.DeclMethodNode = DeclMethodNode
function DeclMethodNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = DeclMethodNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function DeclMethodNode:__init(  )
            
end

local DeclConstrNode = {}
setmetatable( DeclConstrNode, { __index = Node } )
moduleObj.DeclConstrNode = DeclConstrNode
function DeclConstrNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = DeclConstrNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function DeclConstrNode:__init(  )
            
end

local DeclMemberNode = {}
setmetatable( DeclMemberNode, { __index = Node } )
moduleObj.DeclMemberNode = DeclMemberNode
function DeclMemberNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = DeclMemberNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function DeclMemberNode:__init(  )
            
end

local DeclArgNode = {}
setmetatable( DeclArgNode, { __index = Node } )
moduleObj.DeclArgNode = DeclArgNode
function DeclArgNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = DeclArgNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function DeclArgNode:__init(  )
            
end

local DeclArgDDDNode = {}
setmetatable( DeclArgDDDNode, { __index = Node } )
moduleObj.DeclArgDDDNode = DeclArgDDDNode
function DeclArgDDDNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = DeclArgDDDNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function DeclArgDDDNode:__init(  )
            
end

local DeclClassNode = {}
setmetatable( DeclClassNode, { __index = Node } )
moduleObj.DeclClassNode = DeclClassNode
function DeclClassNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = DeclClassNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function DeclClassNode:__init(  )
            
end

local LiteralNilNode = {}
setmetatable( LiteralNilNode, { __index = Node } )
moduleObj.LiteralNilNode = LiteralNilNode
function LiteralNilNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = LiteralNilNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function LiteralNilNode:__init(  )
            
end

local LiteralCharNode = {}
setmetatable( LiteralCharNode, { __index = Node } )
moduleObj.LiteralCharNode = LiteralCharNode
function LiteralCharNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = LiteralCharNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function LiteralCharNode:__init(  )
            
end

local LiteralIntNode = {}
setmetatable( LiteralIntNode, { __index = Node } )
moduleObj.LiteralIntNode = LiteralIntNode
function LiteralIntNode.new(  )
  local obj = {}
  setmetatable( obj, { __index = LiteralIntNode } )
  if obj.__init then
    obj:__init(  )
  end
  return obj
end
function LiteralIntNode:__init(  )
            
end

local NamespaceInfo = {}
function NamespaceInfo.new( name, scope, typeInfo )
  local obj = {}
  setmetatable( obj, { __index = NamespaceInfo } )
  if obj.__init then
    obj:__init( name, scope, typeInfo )
  end
  return obj
end
function NamespaceInfo:__init( name, scope, typeInfo )
            
self.name = name
  self.scope = scope
  self.typeInfo = typeInfo
  end

local TransUnit = {}
moduleObj.TransUnit = TransUnit
function TransUnit.new(  )
  local obj = {}
  setmetatable( obj, { __index = TransUnit } )
  if obj.__init then obj:__init(  ); end
return obj
end
function TransUnit:__init() 
  self.scope = Scope.new(nil)
  self.namespaceList = {typeInfoRoot}
  self.classList = {}
  self.typeId2Scope = {}
  self.typeInfo2ClassNode = {}
  self.currentToken = nil
  self.errMessList = {}
end
function TransUnit:addErrMess( pos, mess )
  table.insert( self.errMessList, string.format( "%s:%d:%d: %s", self.parser:getStreamName(  ), pos.lineNo, pos.column, mess) )
end
function TransUnit:pushScope( inheritList )
  self.scope = Scope.new(self.scope, inheritList)
  return self.scope
end
function TransUnit:popScope(  )
  self.scope = self.scope:get_parent(  )
end
function TransUnit:pushNamespace( name, typeInfo, scope )
  local namespace = NamespaceInfo.new(name, scope, typeInfo)
  table.insert( self.namespaceList, namespace )
end
function TransUnit:popNamespace(  )
  table.remove( self.namespaceList )
end
function TransUnit:getCurrentClass(  )
  if #self.classList == 0 then
    return rootTypeInfo
  end
  local classInfo = self.classList[#self.classList]
  return classInfo.typeInfo
end
function TransUnit:getCurrentNamespaceTypeInfo(  )
  return self.namespaceList[#self.namespaceList].typeInfo
end
function TransUnit:pushClass( baseInfo, externalFlag, name, accessMode )
  local typeInfo = self.scope:getTypeInfoChild( name )
  if not typeInfo then
    local parentInfo = self:getCurrentNamespaceTypeInfo(  )
    typeInfo = TypeInfo.createClass( baseInfo, parentInfo, externalFlag, accessMode, name )
    local inheritList = nil
    if baseInfo then
      inheritList = {self.typeId2Scope[baseInfo:get_typeId(  )]}
    end
    local scope = self:pushScope( inheritList )
    scope:get_parent(  ):addClass( name, typeInfo, scope )
  else 
    self.scope = self.scope:getClassScope( name )
  end
  local namespace = NamespaceInfo.new(name, self.scope, typeInfo)
  table.insert( self.namespaceList, namespace )
  table.insert( self.classList, namespace )
  self.typeId2Scope[typeInfo:get_typeId(  )] = self.scope
  return typeInfo
end
function TransUnit:popClass(  )
  self:popScope(  )
  table.remove( self.namespaceList )
  table.remove( self.classList )
end
function TransUnit:addMethod( className, methodNode )
  local classTypeInfo = self.scope:getTypeInfo( className )
  local classNodeInfo = self.typeInfo2ClassNode[classTypeInfo].info
  classNodeInfo.outerMethodSet[methodNode.info.name.txt] = true
  table.insert( classNodeInfo.fieldList, methodNode )
end
-- none
-- none
-- none
-- none
-- none
-- none
-- none
-- none
function TransUnit:get_errMessList()
   return self.errMessList
end

local opLevelBase = 0
local op2levelMap = {}
local op1levelMap = {}
local function regOpLevel( opnum, opList )
  opLevelBase = opLevelBase + 1
  if opnum == 1 then
    for __index, op in pairs( opList ) do
      op1levelMap[op] = opLevelBase
    end
  else 
    for __index, op in pairs( opList ) do
      op2levelMap[op] = opLevelBase
    end
  end
end

regOpLevel( 2, {"="} )
regOpLevel( 2, {"or"} )
regOpLevel( 2, {"and"} )
regOpLevel( 2, {"<", ">", "<=", ">=", "~=", "=="} )
regOpLevel( 2, {"|"} )
regOpLevel( 2, {"~"} )
regOpLevel( 2, {"&"} )
regOpLevel( 2, {"<<", ">>"} )
regOpLevel( 2, {".."} )
regOpLevel( 2, {"+", "-"} )
regOpLevel( 2, {"*", "/", "//", "%"} )
regOpLevel( 1, {"not", "#", "-", "~"} )
regOpLevel( 1, {"^"} )
local nodeKind2NameMap = {}
local nodeKindSeed = 1
local nodeKind = {}
moduleObj.nodeKind = nodeKind

local function regKind( name )
  local kind = nodeKindSeed
  nodeKindSeed = nodeKindSeed + 1
  nodeKind2NameMap[kind] = name
  nodeKind[name] = kind
  return kind
end

local nodeKindNone = regKind( 'None' )
local nodeKindImport = regKind( 'Import' )
local nodeKindRoot = regKind( 'Root' )
local nodeKindRefType = regKind( 'RefType' )
local nodeKindIf = regKind( 'If' )
local nodeKindSwitch = regKind( 'Switch' )
local nodeKindWhile = regKind( 'While' )
local nodeKindRepeat = regKind( 'Repeat' )
local nodeKindFor = regKind( 'For' )
local nodeKindApply = regKind( 'Apply' )
local nodeKindForeach = regKind( 'Foreach' )
local nodeKindForsort = regKind( 'Forsort' )
local nodeKindReturn = regKind( 'Return' )
local nodeKindBreak = regKind( 'Break' )
local nodeKindExpNew = regKind( 'ExpNew' )
local nodeKindExpList = regKind( 'ExpList' )
local nodeKindExpRef = regKind( 'ExpRef' )
local nodeKindExpOp2 = regKind( 'ExpOp2' )
local nodeKindExpCast = regKind( 'ExpCast' )
local nodeKindExpOp1 = regKind( 'ExpOp1' )
local nodeKindExpRefItem = regKind( 'ExpRefItem' )
local nodeKindExpCall = regKind( 'ExpCall' )
local nodeKindExpDDD = regKind( 'ExpDDD' )
local nodeKindExpParen = regKind( 'ExpParen' )
local nodeKindBlock = regKind( 'Block' )
local nodeKindStmtExp = regKind( 'StmtExp' )
local nodeKindRefField = regKind( 'RefField' )
local nodeKindDeclVar = regKind( 'DeclVar' )
local nodeKindDeclFunc = regKind( 'DeclFunc' )
local nodeKindDeclMethod = regKind( 'DeclMethod' )
local nodeKindDeclConstr = regKind( 'DeclConstr' )
local nodeKindDeclMember = regKind( 'DeclMember' )
local nodeKindDeclArg = regKind( 'DeclArg' )
local nodeKindDeclArgDDD = regKind( 'DeclArgDDD' )
local nodeKindDeclClass = regKind( 'DeclClass' )
local nodeKindLiteralNil = regKind( 'LiteralNil' )
local nodeKindLiteralChar = regKind( 'LiteralChar' )
local nodeKindLiteralInt = regKind( 'LiteralInt' )
local nodeKindLiteralReal = regKind( 'LiteralReal' )
local nodeKindLiteralArray = regKind( 'LiteralArray' )
local nodeKindLiteralList = regKind( 'LiteralList' )
local nodeKindLiteralMap = regKind( 'LiteralMap' )
local nodeKindLiteralString = regKind( 'LiteralString' )
local nodeKindLiteralBool = regKind( 'LiteralBool' )
local quotedChar2Code = {}
quotedChar2Code['a'] = 7
quotedChar2Code['b'] = 8
quotedChar2Code['t'] = 9
quotedChar2Code['n'] = 10
quotedChar2Code['v'] = 11
quotedChar2Code['f'] = 12
quotedChar2Code['r'] = 13
quotedChar2Code['\\'] = 92
quotedChar2Code['"'] = 34
quotedChar2Code["'"] = 39
local function getNodeKindName( kind )
  return nodeKind2NameMap[kind]
end
moduleObj.getNodeKindName = getNodeKindName
local function nodeFilter( node, filter, ... )
  if not filter[node.kind] then
    error( string.format( "none filter -- %s", getNodeKindName( node.kind ) ) )
  end
  return filter[node.kind]( filter, node, ... )
end
moduleObj.nodeFilter = nodeFilter
function TransUnit:registBuiltInScope(  )
  local builtInInfo = {[""] = {["type"] = {["ret"] = {"str"}}, ["error"] = {["ret"] = {}}, ["print"] = {["ret"] = {}}, ["tonumber"] = {["ret"] = {"int"}}}, ["io"] = {["open"] = {["ret"] = {"stem"}}}, ["string"] = {["find"] = {["ret"] = {"int", "int"}}, ["byte"] = {["ret"] = {"int"}}, ["format"] = {["ret"] = {"str"}}, ["rep"] = {["ret"] = {"str"}}, ["gmatch"] = {["ret"] = {"stem"}}, ["gsub"] = {["ret"] = {"str"}}, ["sub"] = {["ret"] = {"str"}}}, ["str"] = {["find"] = {["methodFlag"] = {}, ["ret"] = {"int", "int"}}, ["byte"] = {["methodFlag"] = {}, ["ret"] = {"int"}}, ["format"] = {["methodFlag"] = {}, ["ret"] = {"str"}}, ["rep"] = {["methodFlag"] = {}, ["ret"] = {"str"}}, ["gmatch"] = {["methodFlag"] = {}, ["ret"] = {"stem"}}, ["gsub"] = {["methodFlag"] = {}, ["ret"] = {"str"}}, ["sub"] = {["methodFlag"] = {}, ["ret"] = {"str"}}}, ["table"] = {["insert"] = {["ret"] = {""}}, ["remove"] = {["ret"] = {""}}}, ["debug"] = {["getinfo"] = {["ret"] = {"stem"}}}, ["_luneScript"] = {["loadModule"] = {["ret"] = {"stem"}}}}
  do
    local __sorted = {}
    local __map = builtInTypeMap
    for __key in pairs( __map ) do
      table.insert( __sorted, __key )
    end
    table.sort( __sorted )
    for __index, name in ipairs( __sorted ) do
      typeInfo = __map[ name ]
      do
        if typeInfo.kind == TypeInfoKindClass then
          local scope = self:pushScope(  )
          scope:get_parent(  ):addClass( name, typeInfo, scope )
          self:popScope(  )
        else 
          self.scope:add( name, typeInfo )
        end
      end
    end
  end
  
  do
    local __sorted = {}
    local __map = builtInInfo
    for __key in pairs( __map ) do
      table.insert( __sorted, __key )
    end
    table.sort( __sorted )
    for __index, name in ipairs( __sorted ) do
      name2FuncInfo = __map[ name ]
      do
        local parentInfo = typeInfoRoot
        if name ~= "" then
          local classTypeInfo = self:pushClass( nil, true, name, "pri" )
          parentInfo = classTypeInfo
          builtInTypeIdSet[classTypeInfo:get_typeId(  )] = true
        end
        if not parentInfo then
          error( "parentInfo is nil" )
        end
        do
          local __sorted = {}
          local __map = name2FuncInfo
          for __key in pairs( __map ) do
            table.insert( __sorted, __key )
          end
          table.sort( __sorted )
          for __index, funcName in ipairs( __sorted ) do
            info = __map[ funcName ]
            do
              local retTypeList = {}
              for __index, retType in pairs( info["ret"] ) do
                table.insert( retTypeList, builtInTypeMap[retType] )
              end
              local typeInfo = TypeInfo.createFunc( parentInfo, false, true, not info["methodFlag"], "pub", funcName, nil, retTypeList )
              builtInTypeIdSet[typeInfo:get_typeId(  )] = true
              self.scope:add( funcName, typeInfo )
            end
          end
        end
        
        if name ~= "" then
          self:popClass(  )
        end
      end
    end
  end
  
end

function TransUnit:createNode( kind, pos, expTypeList, info )
  if not getNodeKindName( kind ) then
    error( string.format( "%d:%d: not found nodeKind", pos.lineNo, pos.column ) )
  end
  return Node.new(kind, pos, expTypeList[1], expTypeList, info, nodeFilter)
end

function TransUnit:error( mess )
  local pos = {["lineNo"] = 0, ["column"] = 0}
  local txt = ""
  if self.currentToken then
    pos = self.currentToken.pos
    txt = self.currentToken.txt
  end
  error( string.format( "%d:%d:(%s) %s", pos.lineNo, pos.column, txt, mess ) )
end

function TransUnit:createNoneNode(  )
  return self:createNode( nodeKindNone, {["lineNo"] = 0, ["column"] = 0}, {typeInfoNone}, {} )
end

function TransUnit:getTokenNoErr(  )
  if self.pushbackToken then
    self.currentToken = self.pushbackToken
    self.pushbackToken = nil
    return self.currentToken
  end
  local commentList = {}
  local token = nil
  while true do
    token = self.parser:getToken(  )
    if not token then
      break
    end
    if token.kind ~= Parser.kind.Cmnt then
      break
    end
    table.insert( commentList, token )
  end
  if token then
    token.commentList = commentList
  end
  self.currentToken = token
  return token
end

function TransUnit:getToken( mess )
  local token = self:getTokenNoErr(  )
  if not token then
    return Parser.getEofToken(  )
  end
  self.currentToken = token
  return self.currentToken
end

function TransUnit:pushback(  )
  if self.pushbackToken then
    error( string.format( "multiple pushback:%d:%d: %s, %s", self.currentToken.pos.lineNo, self.currentToken.pos.column, self.pushbackToken.txt, self.currentToken.txt ) )
  end
  self.pushbackToken = self.currentToken
  self.currentToken = nil
end

function TransUnit:checkSymbol( token )
  if token.kind ~= Parser.kind.Symb and token.kind ~= Parser.kind.Kywd and token.kind ~= Parser.kind.Type then
    self:error( "illegal symbol" )
  end
  return token
end

function TransUnit:getSymbolToken(  )
  return self:checkSymbol( self:getToken(  ) )
end

function TransUnit:checkToken( token, txt )
  if not token or token.txt ~= txt then
    self:error( string.format( "not found -- %s", txt ) )
  end
  return token
end

function TransUnit:checkNextToken( txt )
  return self:checkToken( self:getToken(  ), txt )
end

function TransUnit:analyzeBlock( blockKind, scope )
  local token = self:checkNextToken( "{" )
  if not scope then
    self:pushScope(  )
  end
  local stmtList = {}
  self:analyzeStatement( stmtList, "}" )
  self:checkNextToken( "}" )
  if not scope then
    self:popScope(  )
  end
  local node = self:createNode( nodeKindBlock, token.pos, {typeInfoNone}, {["kind"] = blockKind, ["stmtList"] = stmtList} )
  return node
end

function TransUnit:analyzeDecl( accessMode, staticFlag, firstToken, token )
  local staticFlag = false
  if not staticFlag then
    if token.txt == "static" then
      staticFlag = true
      token = self:getToken(  )
    end
  end
  if token.txt == "let" then
    return self:analyzeDeclVar( accessMode, staticFlag, firstToken )
  elseif token.txt == "fn" then
    return self:analyzeDeclFunc( accessMode, staticFlag, nil, token, nil )
  elseif token.txt == "class" then
    return self:analyzeDeclClass( accessMode, token )
  end
  return nil
end

local _TypeInfo = {}
function _TypeInfo.new( baseId, itemTypeId, retTypeId, parentId, typeId, txt, kind, staticFlag, nilable, orgTypeId, children )
  local obj = {}
  setmetatable( obj, { __index = _TypeInfo } )
  if obj.__init then
    obj:__init( baseId, itemTypeId, retTypeId, parentId, typeId, txt, kind, staticFlag, nilable, orgTypeId, children )
  end
  return obj
end
function _TypeInfo:__init( baseId, itemTypeId, retTypeId, parentId, typeId, txt, kind, staticFlag, nilable, orgTypeId, children )
            
self.baseId = baseId
  self.itemTypeId = itemTypeId
  self.retTypeId = retTypeId
  self.parentId = parentId
  self.typeId = typeId
  self.txt = txt
  self.kind = kind
  self.staticFlag = staticFlag
  self.nilable = nilable
  self.orgTypeId = orgTypeId
  self.children = children
  end

local _ModuleInfo = {}
function _ModuleInfo.new( _className2InfoMap, _typeInfoList, _varName2InfoMap, _funcName2InfoMap )
  local obj = {}
  setmetatable( obj, { __index = _ModuleInfo } )
  if obj.__init then
    obj:__init( _className2InfoMap, _typeInfoList, _varName2InfoMap, _funcName2InfoMap )
  end
  return obj
end
function _ModuleInfo:__init( _className2InfoMap, _typeInfoList, _varName2InfoMap, _funcName2InfoMap )
            
self._className2InfoMap = _className2InfoMap
  self._typeInfoList = _typeInfoList
  self._varName2InfoMap = _varName2InfoMap
  self._funcName2InfoMap = _funcName2InfoMap
  end

function TransUnit:analyzeImport( token )
  local moduleToken = self:getToken(  )
  local modulePath = moduleToken.txt
  local nextToken = {}
  local nameList = {moduleToken.txt}
  while true do
    nextToken = self:getToken(  )
    if nextToken.txt == "." then
      nextToken = self:getToken(  )
      moduleToken = nextToken
      modulePath = string.format( "%s.%s", modulePath, moduleToken.txt)
      table.insert( nameList, moduleToken.txt )
    else 
      break
    end
  end
  local moduleTypeInfo = self:pushClass( nil, true, moduleToken.txt, "pub" )
  local moduleInfo = _luneScript.loadModule( modulePath )
  self.moduleName2Info[modulePath] = moduleInfo
  local typeId2TypeInfo = {}
  typeId2TypeInfo[rootTypeId] = typeInfoRoot
  for __index, typeInfo in pairs( builtInTypeMap ) do
    typeId2TypeInfo[typeInfo:get_typeId(  )] = typeInfo
  end
  local typeId2Scope = {}
  typeId2Scope[rootTypeId] = self.scope
  local function registTypeInfo( atomInfo )
    local newTypeInfo = nil
    if not builtInTypeIdSet[atomInfo.typeId] then
      if atomInfo.nilable then
        local orgTypeInfo = typeId2TypeInfo[atomInfo.orgTypeId]
        newTypeInfo = orgTypeInfo:get_nilableTypeInfo(  )
        typeId2TypeInfo[atomInfo.typeId] = newTypeInfo
      else 
        local itemTypeInfo = {}
        for __index, typeId in pairs( atomInfo.itemTypeId ) do
          table.insert( itemTypeInfo, typeId2TypeInfo[typeId] )
        end
        local retTypeInfo = {}
        for __index, typeId in pairs( atomInfo.retTypeId ) do
          table.insert( retTypeInfo, typeId2TypeInfo[typeId] )
        end
        local parentInfo = rootTypeInfo
        if atomInfo.parentId ~= rootTypeId then
          parentInfo = typeId2TypeInfo[atomInfo.parentId]
        end
        local baseInfo = typeId2TypeInfo[atomInfo.baseId]
        if atomInfo.kind == TypeInfoKindClass then
          local parentScope = typeId2Scope[atomInfo.parentId]
          local baseScope = typeId2Scope[atomInfo.baseId]
          local scope = Scope.new(parentScope, baseScope and {baseScope} or nil)
          newTypeInfo = TypeInfo.createClass( baseInfo, parentInfo, true, "pub", atomInfo.txt )
          typeId2Scope[atomInfo.typeId] = scope
          typeId2TypeInfo[atomInfo.typeId] = newTypeInfo
          parentScope:addClass( atomInfo.txt, newTypeInfo, scope )
        else 
          newTypeInfo = TypeInfo.create( baseInfo, parentInfo, atomInfo.staticFlag, atomInfo.kind, atomInfo.txt, itemTypeInfo, retTypeInfo )
          typeId2TypeInfo[atomInfo.typeId] = newTypeInfo
          if atomInfo.kind == TypeInfoKindFunc then
            typeId2Scope[atomInfo.parentId]:add( atomInfo.txt, newTypeInfo )
            local parentScope = typeId2Scope[atomInfo.parentId]
            local scope = Scope.new(parentScope)
            typeId2Scope[atomInfo.typeId] = scope
          end
        end
      end
    else 
      newTypeInfo = builtInTypeMap[atomInfo.txt]
      typeId2TypeInfo[atomInfo.typeId] = newTypeInfo
    end
    return newTypeInfo
  end
  
  for __index, atomInfo in pairs( moduleInfo._typeInfoList ) do
    registTypeInfo( atomInfo )
  end
  for __index, atomInfo in pairs( moduleInfo._typeInfoList ) do
    if #atomInfo.children > 0 then
      local scope = typeId2Scope[atomInfo.typeId]
      for __index, childId in pairs( atomInfo.children ) do
        local typeInfo = typeId2TypeInfo[childId]
        if typeInfo then
          scope:add( typeInfo:getTxt(  ), typeInfo )
        end
      end
    end
  end
  do
    local __sorted = {}
    local __map = moduleInfo._className2InfoMap
    for __key in pairs( __map ) do
      table.insert( __sorted, __key )
    end
    table.sort( __sorted )
    for __index, className in ipairs( __sorted ) do
      classInfo = __map[ className ]
      do
        self:pushClass( nil, true, className, "pub" )
        for fieldName, fieldInfo in pairs( classInfo ) do
          local fieldTypeInfo = nil
          local typeId = fieldInfo["typeId"]
          fieldTypeInfo = typeId2TypeInfo[typeId]
          self.scope:add( fieldName, fieldTypeInfo )
        end
        self:popClass(  )
      end
    end
  end
  
  for varName, varInfo in pairs( moduleInfo._varName2InfoMap ) do
    self.scope:add( varName, typeId2TypeInfo[varInfo["typeId"]] )
  end
  self:popClass(  )
  self:checkToken( nextToken, ";" )
  return self:createNode( nodeKindImport, token.pos, {typeInfoNone}, modulePath )
end

function TransUnit:analyzeIf( token )
  local list = {}
  table.insert( list, {["kind"] = "if", ["exp"] = self:analyzeExp(  ), ["block"] = self:analyzeBlock( "if" )} )
  local nextToken = self:getToken(  )
  if nextToken.txt == "elseif" then
    while nextToken.txt == "elseif" do
      table.insert( list, {["kind"] = "elseif", ["exp"] = self:analyzeExp(  ), ["block"] = self:analyzeBlock( "elseif" )} )
      nextToken = self:getToken(  )
    end
  end
  if nextToken.txt == "else" then
    table.insert( list, {["kind"] = "else", ["block"] = self:analyzeBlock( "else" )} )
  else 
    self:pushback(  )
  end
  return self:createNode( nodeKindIf, token.pos, {typeInfoNone}, list )
end

function TransUnit:analyzeSwitch( firstToken )
  local exp = self:analyzeExp(  )
  self:checkNextToken( "{" )
  local caseList = {}
  local nextToken = self:getToken(  )
  while (nextToken.txt == "case" ) do
    self:checkToken( nextToken, "case" )
    local condexpList = self:analyzeExpList(  )
    local condBock = self:analyzeBlock( "switch" )
    table.insert( caseList, {["expList"] = condexpList, ["block"] = condBock} )
    nextToken = self:getToken(  )
  end
  local defaultBlock = nil
  if nextToken.txt == "default" then
    defaultBlock = self:analyzeBlock( "default" )
  else 
    self:pushback(  )
  end
  self:checkNextToken( "}" )
  local info = {["exp"] = exp, ["caseList"] = caseList, ["default"] = defaultBlock}
  return self:createNode( nodeKindSwitch, firstToken.pos, {typeInfoNone}, info )
end

function TransUnit:analyzeWhile( token )
  local info = {["exp"] = self:analyzeExp(  ), ["block"] = self:analyzeBlock( "while" )}
  return self:createNode( nodeKindWhile, token.pos, {typeInfoNone}, info )
end

function TransUnit:analyzeRepeat( token )
  local scope = self:pushScope(  )
  local info = {["block"] = self:analyzeBlock( "repeat", scope ), ["exp"] = self:analyzeExp(  )}
  self:popScope(  )
  local node = self:createNode( nodeKindRepeat, token.pos, {typeInfoNone}, info )
  self:checkNextToken( ";" )
  return node
end

function TransUnit:analyzeFor( token )
  local scope = self:pushScope(  )
  local val = self:getToken(  )
  if val.kind ~= Parser.kind.Symb then
    self:error( "not symbol" )
  end
  self:checkNextToken( "=" )
  local exp1 = self:analyzeExp(  )
  self.scope:add( val.txt, exp1.expType )
  self:checkNextToken( "," )
  local exp2 = self:analyzeExp(  )
  local token = self:getToken(  )
  local exp3 = nil
  if token.txt == "," then
    exp3 = self:analyzeExp(  )
  else 
    self:pushback(  )
  end
  local info = {["block"] = self:analyzeBlock( "for", scope ), ["val"] = val, ["init"] = exp1, ["to"] = exp2, ["delta"] = exp3}
  self:popScope(  )
  local node = self:createNode( nodeKindFor, token.pos, {typeInfoNone}, info )
  return node
end

function TransUnit:analyzeApply( token )
  local scope = self:pushScope(  )
  local varList = {}
  local nextToken = nil
  repeat 
    local var = self:getToken(  )
    if var.kind ~= Parser.kind.Symb then
      self:error( "illegal symbol" )
    end
    table.insert( varList, var )
    nextToken = self:getToken(  )
  until nextToken.txt ~= ","
  self:checkToken( nextToken, "of" )
  local exp = self:analyzeExp(  )
  if exp.kind ~= nodeKindExpCall then
    self:error( "not call" )
  end
  local block = self:analyzeBlock( "apply", scope )
  self:popScope(  )
  local info = {["varList"] = varList, ["exp"] = exp, ["block"] = block}
  return self:createNode( nodeKindApply, token.pos, {typeInfoNone}, info )
end

function TransUnit:analyzeForeach( token, sortFlag )
  local scope = self:pushScope(  )
  local valSymbol = nil
  local keySymbol = nil
  local nextToken = nil
  for index = 1, 2 do
    local sym = self:getToken(  )
    if sym.kind ~= Parser.kind.Symb then
      self:error( "illegal symbol" )
    end
    if index == 1 then
      valSymbol = sym
    else 
      keySymbol = sym
    end
    nextToken = self:getToken(  )
    if nextToken.txt ~= "," then
      break
    end
  end
  self:checkToken( nextToken, "in" )
  local exp = self:analyzeExp(  )
  if not exp.expType then
    self:error( string.format( "unknown type of exp -- %d:%d", token.pos.lineNo, token.pos.column) )
  else 
    local itemTypeInfoList = exp.expType:get_itemTypeInfoList(  )
    if exp.expType:get_kind(  ) == TypeInfoKindMap then
      self.scope:add( valSymbol.txt, itemTypeInfoList[2] )
      if keySymbol then
        self.scope:add( keySymbol.txt, itemTypeInfoList[1] )
      end
    elseif exp.expType:get_kind(  ) == TypeInfoKindList or exp.expType:get_kind(  ) == TypeInfoKindArray then
      self.scope:add( valSymbol.txt, itemTypeInfoList[1] )
      if keySymbol then
        self.scope:add( keySymbol.txt, typeInfoInt )
      else 
        self.scope:add( "__index", typeInfoInt )
      end
    else 
      self:error( string.format( "unknown kind type of exp for foreach-- %d:%d", exp.pos.lineNo, exp.pos.column) )
    end
  end
  local block = self:analyzeBlock( "foreach", scope )
  self:popScope(  )
  local info = {["val"] = valSymbol, ["key"] = keySymbol, ["exp"] = exp, ["block"] = block, ["sort"] = sortFlag}
  return self:createNode( sortFlag and nodeKindForsort or nodeKindForeach, token.pos, {typeInfoNone}, info )
end

function TransUnit:analyzeRefType( accessMode )
  local firstToken = self:getToken(  )
  local token = firstToken
  local refFlag = false
  if token.txt == "&" then
    refFlag = true
    token = self:getToken(  )
  end
  local mutFlag = false
  if token.txt == "mut" then
    mutFlag = true
    token = self:getToken(  )
  end
  local name = nil
  local typeInfo = typeInfoStem
  if self:checkSymbol( token ) then
    name = self:analyzeExpSymbol( firstToken, token, "symbol", token, true )
    typeInfo = name.expType
  else 
    self:pushback(  )
  end
  token = self:getToken(  )
  if token.txt == "!" then
    typeInfo = typeInfo:get_nilableTypeInfo(  )
    token = self:getToken(  )
  end
  local arrayMode = "no"
  if token.txt == '[' or token.txt == '[@' then
    if token.txt == '[' then
      arrayMode = "list"
      typeInfo = TypeInfo.createList( accessMode, self:getCurrentClass(  ), {typeInfo} )
    else 
      arrayMode = "array"
      typeInfo = TypeInfo.createArray( accessMode, self:getCurrentClass(  ), {typeInfo} )
    end
    token = self:getToken(  )
    if token.txt ~= ']' then
      self:pushback(  )
      self:checkNextToken( ']' )
    end
  elseif token.txt == "<" then
    local genericList = {}
    local nextToken = nil
    repeat 
      local typeExp = self:analyzeRefType( accessMode )
      table.insert( genericList, typeExp.expType )
      nextToken = self:getToken(  )
    until nextToken.txt ~= ","
    self:checkToken( nextToken, '>' )
    if typeInfo.kind == TypeInfoKindMap then
      typeInfo = TypeInfo.createMap( accessMode, self:getCurrentClass(  ), genericList[1] or typeInfoStem, genericList[2] or typeInfoStem )
    else 
      self:error( string.format( "not support generic: %s", typeInfo:getTxt(  ) ) )
    end
  else 
    self:pushback(  )
  end
  return self:createNode( nodeKindRefType, firstToken.pos, {typeInfo}, {["name"] = name, ["refFlag"] = refFlag, ["mutFlag"] = mutFlag, ["array"] = arrayMode} )
end

function TransUnit:analyzeDeclMember( accessMode, staticFlag, firstToken )
  local varName = self:getSymbolToken(  )
  local token = self:getToken(  )
  local refType = self:analyzeRefType( accessMode )
  token = self:getToken(  )
  local getterMode = "none"
  local setterMode = "none"
  if token.txt == "{" then
    local nextToken = self:getToken(  )
    if nextToken.txt == "pub" or nextToken.txt == "pri" then
      getterMode = nextToken.txt
      nextToken = self:getToken(  )
      if nextToken.txt == "," then
        nextToken = self:getToken(  )
        if nextToken.txt == "pub" or nextToken.txt == "pri" then
          setterMode = nextToken.txt
          nextToken = self:getToken(  )
        end
      end
    end
    self:checkToken( nextToken, "}" )
    token = self:getToken(  )
  end
  self:checkToken( token, ";" )
  self.scope:add( varName.txt, refType.expType )
  local info = {["name"] = varName, ["refType"] = refType, ["staticFlag"] = staticFlag, ["accessMode"] = accessMode, ["getterMode"] = getterMode, ["setterMode"] = setterMode}
  return self:createNode( nodeKindDeclMember, firstToken.pos, refType.expTypeList, info )
end

function TransUnit:analyzeDeclMethod( accessMode, staticFlag, className, firstToken, name )
  local node = self:analyzeDeclFunc( accessMode, staticFlag, className, name, name )
  return node
end

function TransUnit:analyzeDeclClass( classAccessMode, classToken )
  local name = self:getToken(  )
  local nextToken = self:getToken(  )
  local baseRef = nil
  if nextToken.txt == "extend" then
    baseRef = self:analyzeRefType( classAccessMode )
    nextToken = self:getToken(  )
  end
  self:checkToken( nextToken, "{" )
  local classTypeInfo = self:pushClass( baseRef and baseRef:get_expType(  ) or nil, false, name.txt, classAccessMode )
  local fieldList = {}
  local memberList = {}
  local methodName2Node = {}
  local node = self:createNode( nodeKindDeclClass, classToken.pos, {classTypeInfo}, {["accessMode"] = classAccessMode, ["name"] = name, ["fieldList"] = fieldList, ["memberList"] = memberList, ["scope"] = self.scope, ["outerMethodSet"] = {}} )
  self.typeInfo2ClassNode[classTypeInfo] = node
  while true do
    local token = self:getToken(  )
    if token.txt == "}" then
      break
    end
    local accessMode = "pri"
    if token.txt == "pub" or token.txt == "pro" or token.txt == "pri" or token.txt == "global" then
      accessMode = token.txt
      token = self:getToken(  )
    end
    local staticFlag = false
    if token.txt == "static" then
      staticFlag = true
      token = self:getToken(  )
    end
    if token.txt == "let" then
      local memberNode = self:analyzeDeclMember( accessMode, staticFlag, token )
      table.insert( fieldList, memberNode )
      table.insert( memberList, memberNode )
    else 
      local methodNode = self:analyzeDeclMethod( accessMode, staticFlag, name, token, token )
      table.insert( fieldList, methodNode )
    end
  end
  local parentInfo = classTypeInfo
  for __index, memberNode in pairs( memberList ) do
    local memberType = memberNode.expType
    if memberNode.expType.accessMode ~= "pub" then
      memberType = TypeInfo.cloneToPublic( memberType )
    end
    local memberName = memberNode.info.name
    local getterName = "get_" .. memberName.txt
    local accessMode = memberNode.info.getterMode
    if accessMode ~= "none" and not self.scope:getTypeInfo( getterName ) then
      local retTypeInfo = TypeInfo.createFunc( parentInfo, true, false, false, "pub", getterName, nil, {memberType} )
      self.scope:add( getterName, retTypeInfo )
    end
    local setterName = "set_" .. memberName.txt
    local accessMode = memberNode.info.setterMode
    if memberNode.info.setterMode ~= "none" and not self.scope:getTypeInfo( setterName ) then
      self.scope:add( setterName, TypeInfo.createFunc( parentInfo, true, false, false, "pub", setterName, nil, {memberType} ) )
    end
  end
  self:popClass(  )
  return node
end

local DeclFuncInfo = {}
moduleObj.DeclFuncInfo = DeclFuncInfo
function DeclFuncInfo.new( className, name, argList, staticFlag, accessMode, body, retTypeList, retTypeInfoList )
  local obj = {}
  setmetatable( obj, { __index = DeclFuncInfo } )
  if obj.__init then
    obj:__init( className, name, argList, staticFlag, accessMode, body, retTypeList, retTypeInfoList )
  end
  return obj
end
function DeclFuncInfo:__init( className, name, argList, staticFlag, accessMode, body, retTypeList, retTypeInfoList )
            
self.className = className
  self.name = name
  self.argList = argList
  self.staticFlag = staticFlag
  self.accessMode = accessMode
  self.body = body
  self.retTypeList = retTypeList
  self.retTypeInfoList = retTypeInfoList
  end
function DeclFuncInfo:get_className()
   return self.className
end
function DeclFuncInfo:get_name()
   return self.name
end
function DeclFuncInfo:get_argList()
   return self.argList
end
function DeclFuncInfo:get_staticFlag()
   return self.staticFlag
end
function DeclFuncInfo:get_accessMode()
   return self.accessMode
end
function DeclFuncInfo:get_body()
   return self.body
end
function DeclFuncInfo:get_retTypeList()
   return self.retTypeList
end
function DeclFuncInfo:get_retTypeInfoList()
   return self.retTypeInfoList
end

function TransUnit:analyzeDeclFunc( accessMode, staticFlag, classNameToken, firstToken, name )
  local argList = {}
  local token = self:getToken(  )
  if not name then
    if token.txt ~= "(" then
      name = self:checkSymbol( token )
      token = self:getToken(  )
    end
  else 
    self:checkSymbol( name )
  end
  local needPopFlag = false
  if token.txt == "." then
    needPopFlag = true
    classNameToken = name
    self:pushClass( nil, false, name.txt, "pub" )
    name = self:getSymbolToken(  )
    token = self:getToken(  )
  end
  self:checkToken( "(" )
  local kind = nodeKindDeclConstr
  if classNameToken then
    if name.txt == "__init" then
      kind = nodeKindDeclConstr
    else 
      kind = nodeKindDeclMethod
    end
  else 
    kind = nodeKindDeclFunc
    if not staticFlag then
      staticFlag = true
    end
  end
  local scope = self:pushScope(  )
  repeat 
    local argName = self:getToken(  )
    if argName.txt == ")" then
      token = argName
      break
    elseif argName.txt == "..." then
      table.insert( argList, self:createNode( nodeKindDeclArgDDD, argName.pos, {typeInfoNone}, argName ) )
    else 
      self:checkSymbol( argName )
      self:checkNextToken( ":" )
      local refType = self:analyzeRefType( accessMode )
      local arg = self:createNode( nodeKindDeclArg, argName.pos, refType.expTypeList, {["name"] = argName, ["argType"] = refType} )
      self.scope:add( argName.txt, refType.expType )
      table.insert( argList, arg )
    end
    token = self:getToken(  )
  until token.txt ~= ","
  self:checkToken( token, ")" )
  token = self:getToken(  )
  local retTypeList = {}
  local retTypeInfoList = {}
  if token.txt == ":" then
    repeat 
      local refType = self:analyzeRefType( accessMode )
      table.insert( retTypeList, refType )
      table.insert( retTypeInfoList, refType.expType )
      token = self:getToken(  )
    until token.txt ~= ","
  end
  local typeInfo = TypeInfo.createFunc( self:getCurrentNamespaceTypeInfo(  ), false, false, staticFlag, accessMode, name and name.txt or "", nil, retTypeInfoList )
  if name then
    scope:get_parent(  ):add( name.txt, typeInfo )
  end
  if not needPopFlag then
    self:pushNamespace( name and name.txt or "", typeInfo, scope )
  end
  local node = nil
  local info = nil
  if token.txt == ";" then
    node = self:createNoneNode(  )
  else 
    self:pushback(  )
    local body = self:analyzeBlock( "func", scope )
    info = DeclFuncInfo.new(classNameToken, name, argList, staticFlag, accessMode, body, retTypeList, retTypeInfoList)
    node = self:createNode( kind, firstToken.pos, {typeInfo}, info )
  end
  if not needPopFlag then
    self:popNamespace(  )
  end
  self:popScope(  )
  if needPopFlag then
    self:addMethod( classNameToken.txt, node )
    self:popClass(  )
  end
  return node
end

function TransUnit:analyzeDeclVar( accessMode, staticFlag, firstToken )
  local unwrapFlag = false
  local token = self:getToken(  )
  if token.txt == "!" then
    unwrapFlag = true
  else 
    self:pushback(  )
  end
  local typeInfoList = {}
  local varList = {}
  repeat 
    local varName = self:getSymbolToken(  )
    token = self:getToken(  )
    local typeInfo = typeInfoNone
    local refType = nil
    if token.txt == ":" then
      refType = self:analyzeRefType( accessMode )
      typeInfo = refType.expType
      token = self:getToken(  )
    end
    table.insert( varList, {["name"] = varName, ["refType"] = refType} )
    table.insert( typeInfoList, typeInfo )
  until token.txt ~= ","
  local expList = nil
  if token.txt == "=" then
    expList = self:analyzeExpList(  )
    if not expList then
      self:error( "expList is nil" )
    end
  end
  if expList then
    local nodeList = expList.info
    for index, exp in pairs( nodeList ) do
      if not typeInfoList[index] or typeInfoList[index] == typeInfoNone then
        typeInfoList[index] = exp["expType"]
      end
    end
  end
  local unwrapBlock = nil
  if unwrapFlag then
    unwrapBlock = self:analyzeBlock( "let!" )
    for index, typeInfo in pairs( typeInfoList ) do
      if typeInfo:get_nilable(  ) then
        typeInfoList[index] = typeInfo:get_orgTypeInfo(  )
      end
    end
  end
  self:checkNextToken( ";" )
  local declVarInfo = {["accessMode"] = accessMode, ["varList"] = varList, ["expList"] = expList, ["typeInfoList"] = typeInfoList, ["unwrap"] = unwrapBlock}
  local node = self:createNode( nodeKindDeclVar, firstToken.pos, {typeInfoNone}, declVarInfo )
  for index, typeInfo in pairs( typeInfoList ) do
    self.scope:add( varList[index].name.txt, typeInfo )
  end
  return node
end

function TransUnit:analyzeExpList(  )
  local expList = {}
  local firstExp = nil
  repeat 
    local exp = self:analyzeExp(  )
    if not firstExp then
      firstExp = exp
    end
    table.insert( expList, exp )
    local token = self:getToken(  )
  until token.txt ~= ","
  self:pushback(  )
  return self:createNode( nodeKindExpList, firstExp.pos, {typeInfoNone}, expList )
end

function TransUnit:analyzeListConst( token )
  local nextToken = self:getToken(  )
  local expList = nil
  local itemTypeInfo = typeInfoNone
  if nextToken.txt ~= "]" then
    self:pushback(  )
    expList = self:analyzeExpList(  )
    self:checkNextToken( "]" )
    local nodeList = expList.info
    for __index, exp in pairs( nodeList ) do
      if itemTypeInfo == typeInfoNone then
        itemTypeInfo = exp["expType"]
      elseif itemTypeInfo ~= exp["expType"] then
        itemTypeInfo = typeInfoStem
      end
    end
  end
  local kind = nodeKindLiteralArray
  local typeInfo = typeInfoNone
  if token.txt == '[' then
    kind = nodeKindLiteralList
    typeInfo = {TypeInfo.createList( "pri", self:getCurrentClass(  ), {itemTypeInfo} )}
  else 
    typeInfo = {TypeInfo.createArray( "pri", self:getCurrentClass(  ), {itemTypeInfo} )}
  end
  return self:createNode( kind, token.pos, typeInfo, expList )
end

function TransUnit:analyzeMapConst( token )
  local nextToken = nil
  local map = {}
  local pairList = {}
  local keyTypeInfo = typeInfoNone
  local valTypeInfo = typeInfoNone
  repeat 
    nextToken = self:getToken(  )
    if nextToken.txt == "}" then
      break
    end
    self:pushback(  )
    local key = self:analyzeExp(  )
    if key.expType ~= keyTypeInfo then
      if keyTypeInfo ~= typeInfoNone then
        keyTypeInfo = typeInfoStem
      else 
        keyTypeInfo = key.expType
      end
    end
    self:checkNextToken( ":" )
    local val = self:analyzeExp(  )
    if val.expType ~= valTypeInfo then
      if valTypeInfo ~= typeInfoNone then
        valTypeInfo = typeInfoStem
      else 
        valTypeInfo = val.expType
      end
    end
    table.insert( pairList, {["key"] = key, ["val"] = val} )
    map[key] = val
    nextToken = self:getToken(  )
  until nextToken.txt ~= ","
  local typeInfo = TypeInfo.createMap( "pri", self:getCurrentClass(  ), keyTypeInfo, valTypeInfo )
  self:checkToken( nextToken, "}" )
  return self:createNode( nodeKindLiteralMap, token.pos, {typeInfo}, {["map"] = map, ["pairList"] = pairList} )
end

function TransUnit:analyzeExpRefItem( token, exp )
  local indexExp = self:analyzeExp(  )
  self:checkNextToken( "]" )
  local info = {["val"] = exp, ["index"] = indexExp}
  local typeInfo = typeInfoStem
  if exp.expType then
    if exp.expType.kind == TypeInfoKindMap then
      typeInfo = exp.expType:get_itemTypeInfoList(  )[2]
    elseif exp.expType.kind == TypeInfoKindArray or exp.expType.kind == TypeInfoKindArray then
      typeInfo = exp.expType:get_itemTypeInfoList(  )[1]
    end
  end
  return self:createNode( nodeKindExpRefItem, token.pos, {typeInfo}, info )
end

function TransUnit:analyzeExpCont( firstToken, exp, skipFlag )
  local nextToken = self:getToken(  )
  if not skipFlag then
    repeat 
      local matchFlag = false
      if nextToken.txt == "[" then
        matchFlag = true
        exp = self:analyzeExpRefItem( nextToken, exp )
        nextToken = self:getToken(  )
      end
      if nextToken.txt == "(" then
        matchFlag = true
        local work = self:getToken(  )
        local expList = nil
        if work.txt ~= ")" then
          self:pushback(  )
          expList = self:analyzeExpList(  )
          self:checkNextToken( ")" )
        end
        local info = {["func"] = exp, ["argList"] = expList}
        exp = self:createNode( nodeKindExpCall, firstToken.pos, exp.expType:get_retTypeInfoList(  ), info )
        nextToken = self:getToken(  )
      end
    until not matchFlag
  end
  if nextToken.txt == "." then
    return self:analyzeExpSymbol( firstToken, self:getToken(  ), "field", exp, skipFlag )
  end
  self:pushback(  )
  return exp
end

function TransUnit:analyzeExpSymbol( firstToken, token, mode, prefixExp, skipFlag )
  local exp = nil
  if mode == "field" then
    local info = {["field"] = token, ["prefix"] = prefixExp}
    local typeInfo = typeInfoNone
    if not prefixExp.expType then
      self:error( "unknown prefix type: " .. getNodeKindName( prefixExp.kind ) )
    end
    if prefixExp.expType:get_kind(  ) == TypeInfoKindClass then
      local classScope = self.typeId2Scope[prefixExp.expType:get_typeId(  )]
      local className = prefixExp.expType:getTxt(  )
      if not classScope then
        self:error( string.format( "not found field: %s, %s", className, prefixExp.expType) )
      end
      typeInfo = classScope:getTypeInfo( token.txt )
      if not typeInfo then
        print( "hoge", classScope.symbol2TypeInfoMap )
        for __index, name in pairs( classScope.symbol2TypeInfoMap ) do
          print( "hoge", name )
        end
        self:error( string.format( "not found field typeInfo: %s.%s %s", className, token.txt, classScope ) )
      end
    end
    exp = self:createNode( nodeKindRefField, firstToken.pos, {typeInfo}, info )
  elseif mode == "symbol" then
    local typeInfo = self.scope:getTypeInfo( token.txt )
    if not typeInfo and token.txt == "self" then
      local namespaceInfo = self.classList[#self.classList]
      typeInfo = namespaceInfo.typeInfo
    end
    if not typeInfo then
      self:error( "not found type -- " .. token.txt )
    end
    exp = self:createNode( nodeKindExpRef, firstToken.pos, {typeInfo}, token )
  elseif mode == "fn" then
    exp = self:analyzeDeclFunc( "pri", false, nil, token, nil )
  else 
    self:error( "illegal mode", mode )
  end
  return self:analyzeExpCont( firstToken, exp, skipFlag )
end

function TransUnit:analyzeExpOp2( firstToken, exp, prevOpLevel )
  while true do
    local nextToken = self:getToken(  )
    local opLevel = prevOpLevel
    local opTxt = nextToken.txt
    if opTxt == "@" then
      local castType = self:analyzeRefType( "pri" )
      exp = self:createNode( nodeKindExpCast, firstToken.pos, castType.expTypeList, exp )
    elseif nextToken.kind == Parser.kind.Ope then
      if Parser.isOp2( opTxt ) then
        opLevel = op2levelMap[opTxt]
        if not opLevel then
          error( string.format( "unknown op -- %s %s", opTxt, prevOpLevel ) )
        end
        if prevOpLevel and opLevel <= prevOpLevel then
          self:pushback(  )
          return exp
        end
        local exp2 = self:analyzeExp( false, opLevel )
        local info = {["op"] = nextToken, ["exp1"] = exp, ["exp2"] = exp2}
        local opTxt = nextToken.txt
        local expType = typeInfoNone
        do
          local _switchExp = opTxt
          if _switchExp == "or" or _switchExp == "and" then
            if exp.expType:equals( exp2.expType ) then
              expType = exp.expType
            else 
              expType = typeInfoStem
            end
          elseif _switchExp == "<" or _switchExp == ">" or _switchExp == "<=" or _switchExp == ">=" or _switchExp == "~=" or _switchExp == "==" or _switchExp == "not" then
            expType = typeInfoBool
          elseif _switchExp == "^" or _switchExp == "|" or _switchExp == "~" or _switchExp == "&" or _switchExp == "<<" or _switchExp == ">>" or _switchExp == "#" then
            expType = typeInfoInt
          elseif _switchExp == ".." then
            expType = typeInfoString
          elseif _switchExp == "+" or _switchExp == "-" or _switchExp == "*" or _switchExp == "/" or _switchExp == "//" or _switchExp == "%" then
            if exp.expType == typeInfoReal or exp2.expType == typeInfoReal then
              expType = typeInfoReal
            else 
              expType = typeInfoInt
            end
          elseif _switchExp == "=" then
          else 
            self:error( "unknown op " .. opTxt )
          end
        end
        
        exp = self:createNode( nodeKindExpOp2, firstToken.pos, {expType}, info )
      else 
        self:error( "illegal op" )
      end
    else 
      self:pushback(  )
      return exp
    end
  end
  return self:analyzeExpOp2( firstToken, exp, prevOpLevel )
end

local LiteralStringInfo = {}
moduleObj.LiteralStringInfo = LiteralStringInfo
function LiteralStringInfo.new( token, argList )
  local obj = {}
  setmetatable( obj, { __index = LiteralStringInfo } )
  if obj.__init then
    obj:__init( token, argList )
  end
  return obj
end
function LiteralStringInfo:__init( token, argList )
            
self.token = token
  self.argList = argList
  end
function LiteralStringInfo:get_token()
   return self.token
end
function LiteralStringInfo:get_argList()
   return self.argList
end

function TransUnit:analyzeExp( skipOp2Flag, prevOpLevel )
  local firstToken = self:getToken(  )
  local token = firstToken
  local exp = nil
  if token.kind == Parser.kind.Dlmt then
    if token.txt == "..." then
      return self:createNode( nodeKindExpDDD, firstToken.pos, {typeInfoNone}, token )
    end
    if token.txt == '[' or token.txt == '[@' then
      return self:analyzeListConst( token )
    end
    if token.txt == '{' then
      return self:analyzeMapConst( token )
    end
    if token.txt == "(" then
      exp = self:analyzeExp(  )
      self:checkNextToken( ")" )
      exp = self:createNode( nodeKindExpParen, firstToken.pos, exp.expTypeList, exp )
      exp = self:analyzeExpCont( firstToken, exp, false )
    end
  end
  if token.txt == "new" then
    exp = self:analyzeRefType( "pri" )
    self:checkNextToken( "(" )
    local nextToken = self:getToken(  )
    local argList = nil
    if nextToken.txt ~= ")" then
      self:pushback(  )
      argList = self:analyzeExpList(  )
      self:checkNextToken( ")" )
    end
    exp = self:createNode( nodeKindExpNew, firstToken.pos, exp.expTypeList, {["symbol"] = exp, ["argList"] = argList} )
    exp = self:analyzeExpCont( firstToken, exp, false )
  end
  if token.kind == Parser.kind.Ope and Parser.isOp1( token.txt ) then
    exp = self:analyzeExp( true, op1levelMap[token.txt] )
    local typeInfo = typeInfoNone
    if token.txt == "-" then
      if exp.expType ~= typeInfoInt and exp.expType ~= typeInfoReal then
        self:addErrMess( token.pos, string.format( 'unmatch type for "-" -- %s', exp.expType:getTxt(  )) )
      end
      typeInfo = exp.expType
    elseif token.txt == "#" then
      typeInfo = typeInfoInt
    elseif token.txt == "not" then
      typeInfo = typeInfoBool
    else 
      self:error( "unknown op1" )
    end
    exp = self:createNode( nodeKindExpOp1, firstToken.pos, {typeInfo}, {["op"] = token, ["exp"] = exp} )
    return self:analyzeExpOp2( firstToken, exp, prevOpLevel )
  end
  if token.kind == Parser.kind.Int then
    exp = self:createNode( nodeKindLiteralInt, firstToken.pos, {typeInfoInt}, {["token"] = token, ["num"] = tonumber( token.txt )} )
  elseif token.kind == Parser.kind.Real then
    exp = self:createNode( nodeKindLiteralReal, firstToken.pos, {typeInfoReal}, {["token"] = token, ["num"] = tonumber( token.txt )} )
  elseif token.kind == Parser.kind.Char then
    local num = 0
    if #(token.txt ) == 1 then
      num = token.txt:byte( 1 )
    else 
      num = quotedChar2Code[token.txt:sub( 2, 2 )]
    end
    exp = self:createNode( nodeKindLiteralChar, firstToken.pos, {typeInfoChar}, {["token"] = token, ["num"] = num} )
  elseif token.kind == Parser.kind.Str then
    local nextToken = self:getToken(  )
    local formatArgList = {}
    if nextToken.txt == "(" then
      repeat 
        local arg = self:analyzeExp(  )
        table.insert( formatArgList, arg )
        nextToken = self:getToken(  )
      until nextToken.txt ~= ","
      self:checkToken( nextToken, ")" )
      nextToken = self:getToken(  )
    end
    exp = self:createNode( nodeKindLiteralString, firstToken.pos, {typeInfoString}, LiteralStringInfo.new(token, formatArgList) )
    token = nextToken
    if token.txt == "[" then
      exp = self:analyzeExpRefItem( token, exp )
    else 
      self:pushback(  )
    end
  elseif token.txt == "fn" then
    exp = self:analyzeExpSymbol( firstToken, token, "fn", token, false )
  elseif token.kind == Parser.kind.Symb then
    exp = self:analyzeExpSymbol( firstToken, token, "symbol", token, false )
  elseif token.kind == Parser.kind.Type then
    exp = self:createNode( nodeKindExpRef, firstToken.pos, {typeInfoNone}, token )
  elseif token.txt == "true" or token.txt == "false" then
    exp = self:createNode( nodeKindLiteralBool, firstToken.pos, {typeInfoBool}, token )
  elseif token.txt == "nil" then
    exp = self:createNode( nodeKindLiteralNil, firstToken.pos, {typeInfoNil}, token )
  end
  if not exp then
    self:error( "illegal exp" )
  end
  if skipOp2Flag then
    return exp
  end
  return self:analyzeExpOp2( firstToken, exp, prevOpLevel )
end

function TransUnit:createAST( parser )
  self:pushNamespace( "", typeInfoRoot, self.scope )
  self:registBuiltInScope(  )
  local rootInfo = {}
  rootInfo.children = {}
  local ast = self:createNode( nodeKindRoot, {["lineNo"] = 0, ["column"] = 0}, {typeInfoNone}, rootInfo )
  self.parser = parser
  self.moduleName2Info = {}
  self:analyzeStatement( rootInfo.children )
  local token = self:getTokenNoErr(  )
  if token then
    error( string.format( "unknown:%d:%d:(%s) %s", token.pos.lineNo, token.pos.column, Parser.getKindTxt( token.kind ), token.txt) )
  end
  self:popNamespace(  )
  return ast
end

function TransUnit:analyzeStatement( stmtList, termTxt )
  while true do
    local token = self:getTokenNoErr(  )
    if not token then
      break
    end
    local statement = self:analyzeDecl( "pri", false, token, token )
    if not statement then
      if token.txt == termTxt then
        self:pushback(  )
        break
      elseif token.txt == "pub" or token.txt == "pro" or token.txt == "pri" or token.txt == "global" or token.txt == "static" then
        local accessMode = (token.txt ~= "static" ) and token.txt or "pri"
        local staticFlag = (token.txt == "static" )
        local nextToken = nil
        if token.txt ~= "static" then
          nextToken = self:getToken(  )
        else 
          nextToken = token
        end
        statement = self:analyzeDecl( accessMode, staticFlag, token, nextToken )
      elseif token.txt == "{" then
        self:pushback(  )
        statement = self:analyzeBlock( "{" )
      elseif token.txt == "if" then
        statement = self:analyzeIf( token )
      elseif token.txt == "switch" then
        statement = self:analyzeSwitch( token )
      elseif token.txt == "while" then
        statement = self:analyzeWhile( token )
      elseif token.txt == "repeat" then
        statement = self:analyzeRepeat( token )
      elseif token.txt == "for" then
        statement = self:analyzeFor( token )
      elseif token.txt == "apply" then
        statement = self:analyzeApply( token )
      elseif token.txt == "foreach" then
        statement = self:analyzeForeach( token, false )
      elseif token.txt == "forsort" then
        statement = self:analyzeForeach( token, true )
      elseif token.txt == "return" then
        local nextToken = self:getToken(  )
        local expList = nil
        if nextToken.txt ~= ";" then
          self:pushback(  )
          expList = self:analyzeExpList(  )
          self:checkNextToken( ";" )
        end
        statement = self:createNode( nodeKindReturn, token.pos, {typeInfoNone}, expList )
      elseif token.txt == "break" then
        self:checkNextToken( ";" )
        statement = self:createNode( nodeKindBreak, token.pos, {typeInfoNone}, nil )
      elseif token.txt == "import" then
        statement = self:analyzeImport( token )
      else 
        self:pushback(  )
        local exp = self:analyzeExp(  )
        self:checkNextToken( ";" )
        statement = self:createNode( nodeKindStmtExp, self.currentToken.pos, {typeInfoNone}, exp )
      end
    end
    if not statement then
      break
    end
    table.insert( stmtList, statement )
  end
end

----- meta -----
local _className2InfoMap = {}
moduleObj._className2InfoMap = _className2InfoMap
local _classInfoApplyNode = {}
_className2InfoMap.ApplyNode = _classInfoApplyNode
local _classInfoBlockNode = {}
_className2InfoMap.BlockNode = _classInfoBlockNode
local _classInfoBreakNode = {}
_className2InfoMap.BreakNode = _classInfoBreakNode
local _classInfoDeclArgDDDNode = {}
_className2InfoMap.DeclArgDDDNode = _classInfoDeclArgDDDNode
local _classInfoDeclArgNode = {}
_className2InfoMap.DeclArgNode = _classInfoDeclArgNode
local _classInfoDeclClassNode = {}
_className2InfoMap.DeclClassNode = _classInfoDeclClassNode
local _classInfoDeclConstrNode = {}
_className2InfoMap.DeclConstrNode = _classInfoDeclConstrNode
local _classInfoDeclFuncInfo = {}
_className2InfoMap.DeclFuncInfo = _classInfoDeclFuncInfo
local _classInfoDeclFuncNode = {}
_className2InfoMap.DeclFuncNode = _classInfoDeclFuncNode
local _classInfoDeclMemberNode = {}
_className2InfoMap.DeclMemberNode = _classInfoDeclMemberNode
local _classInfoDeclMethodNode = {}
_className2InfoMap.DeclMethodNode = _classInfoDeclMethodNode
local _classInfoDeclVarNode = {}
_className2InfoMap.DeclVarNode = _classInfoDeclVarNode
local _classInfoExpCallNode = {}
_className2InfoMap.ExpCallNode = _classInfoExpCallNode
local _classInfoExpCastNode = {}
_className2InfoMap.ExpCastNode = _classInfoExpCastNode
local _classInfoExpDDDNode = {}
_className2InfoMap.ExpDDDNode = _classInfoExpDDDNode
local _classInfoExpListNode = {}
_className2InfoMap.ExpListNode = _classInfoExpListNode
local _classInfoExpNewNode = {}
_className2InfoMap.ExpNewNode = _classInfoExpNewNode
local _classInfoExpOp1Node = {}
_className2InfoMap.ExpOp1Node = _classInfoExpOp1Node
local _classInfoExpOp2Node = {}
_className2InfoMap.ExpOp2Node = _classInfoExpOp2Node
local _classInfoExpParenNode = {}
_className2InfoMap.ExpParenNode = _classInfoExpParenNode
local _classInfoExpRefItemNode = {}
_className2InfoMap.ExpRefItemNode = _classInfoExpRefItemNode
local _classInfoExpRefNode = {}
_className2InfoMap.ExpRefNode = _classInfoExpRefNode
local _classInfoForNode = {}
_className2InfoMap.ForNode = _classInfoForNode
local _classInfoForeachNode = {}
_className2InfoMap.ForeachNode = _classInfoForeachNode
local _classInfoForsortNode = {}
_className2InfoMap.ForsortNode = _classInfoForsortNode
local _classInfoIfNode = {}
_className2InfoMap.IfNode = _classInfoIfNode
local _classInfoImportNode = {}
_className2InfoMap.ImportNode = _classInfoImportNode
local _classInfoLiteralCharNode = {}
_className2InfoMap.LiteralCharNode = _classInfoLiteralCharNode
local _classInfoLiteralIntNode = {}
_className2InfoMap.LiteralIntNode = _classInfoLiteralIntNode
local _classInfoLiteralNilNode = {}
_className2InfoMap.LiteralNilNode = _classInfoLiteralNilNode
local _classInfoLiteralStringInfo = {}
_className2InfoMap.LiteralStringInfo = _classInfoLiteralStringInfo
local _classInfoNode = {}
_className2InfoMap.Node = _classInfoNode
_classInfoNode.filter = {
  name='filter', staticFlag = false, accessMode = 'pub', methodFlag = false, typeId = 26 }
local _classInfoNodePos = {}
_className2InfoMap.NodePos = _classInfoNodePos
local _classInfoRefFieldNode = {}
_className2InfoMap.RefFieldNode = _classInfoRefFieldNode
local _classInfoRefTypeNode = {}
_className2InfoMap.RefTypeNode = _classInfoRefTypeNode
local _classInfoRepeatNode = {}
_className2InfoMap.RepeatNode = _classInfoRepeatNode
local _classInfoReturnNode = {}
_className2InfoMap.ReturnNode = _classInfoReturnNode
local _classInfoRootNode = {}
_className2InfoMap.RootNode = _classInfoRootNode
local _classInfoScope = {}
_className2InfoMap.Scope = _classInfoScope
local _classInfoStmtExpNode = {}
_className2InfoMap.StmtExpNode = _classInfoStmtExpNode
local _classInfoSwitchNode = {}
_className2InfoMap.SwitchNode = _classInfoSwitchNode
local _classInfoTransUnit = {}
_className2InfoMap.TransUnit = _classInfoTransUnit
local _classInfoTypeInfo = {}
_className2InfoMap.TypeInfo = _classInfoTypeInfo
local _classInfoWhileNode = {}
_className2InfoMap.WhileNode = _classInfoWhileNode
local _varName2InfoMap = {}
moduleObj._varName2InfoMap = _varName2InfoMap
_varName2InfoMap.TypeInfoKindArray = {
  name='TypeInfoKindArray', accessMode = 'pub', typeId = 12 }
_varName2InfoMap.TypeInfoKindClass = {
  name='TypeInfoKindClass', accessMode = 'pub', typeId = 12 }
_varName2InfoMap.TypeInfoKindFunc = {
  name='TypeInfoKindFunc', accessMode = 'pub', typeId = 12 }
_varName2InfoMap.TypeInfoKindList = {
  name='TypeInfoKindList', accessMode = 'pub', typeId = 12 }
_varName2InfoMap.TypeInfoKindMap = {
  name='TypeInfoKindMap', accessMode = 'pub', typeId = 12 }
_varName2InfoMap.TypeInfoKindNilable = {
  name='TypeInfoKindNilable', accessMode = 'pub', typeId = 12 }
_varName2InfoMap.TypeInfoKindPrim = {
  name='TypeInfoKindPrim', accessMode = 'pub', typeId = 12 }
_varName2InfoMap.TypeInfoKindRoot = {
  name='TypeInfoKindRoot', accessMode = 'pub', typeId = 12 }
_varName2InfoMap.nodeKind = {
  name='nodeKind', accessMode = 'pub', typeId = 680 }
_varName2InfoMap.rootTypeId = {
  name='rootTypeId', accessMode = 'pub', typeId = 12 }
_varName2InfoMap.typeInfoKind = {
  name='typeInfoKind', accessMode = 'pub', typeId = 310 }
local _funcName2InfoMap = {}
moduleObj._funcName2InfoMap = _funcName2InfoMap
moduleObj._typeInfoList = {}
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 84, baseId = 1, txt = 'Parser',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 190, baseId = 1, txt = 'Position',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 192, baseId = 1, txt = 'Token',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 194, baseId = 1, txt = 'Parser',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {212, 214, 270}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 216, baseId = 1, txt = 'Stream',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 242, baseId = 1, txt = 'getKindTxt',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {12}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 244, baseId = 1, txt = 'isOp2',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 246, baseId = 1, txt = 'isOp1',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 278, baseId = 1, txt = 'getEofToken',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {6}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 280, baseId = 1, txt = 'Parser',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 282, baseId = 1, txt = 'Position',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 284, baseId = 1, txt = 'Token',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 286, baseId = 1, txt = 'Parser',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {300, 302, 304}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 288, baseId = 1, txt = 'Stream',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 292, baseId = 1, txt = 'getKindTxt',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {12}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 294, baseId = 1, txt = 'isOp2',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 296, baseId = 1, txt = 'isOp1',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 298, baseId = 1, txt = 'getEofToken',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {6}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 306, baseId = 1, txt = 'errorLog',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 308, baseId = 1, txt = 'debugLog',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 310, baseId = 1, txt = 'Map',
staticFlag = false, accessMode = 'pub', kind = 4, itemTypeId = {18, 6}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 320, baseId = 1, txt = 'isBuiltin',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 326, baseId = 1, txt = 'TypeInfo',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {346, 348, 350, 352, 358, 360, 362, 368, 370, 374, 378, 380, 384, 390, 398, 402, 404, 406, 408, 410, 412, 414, 416, 418, 420, 422, 426}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 396, baseId = 1, txt = '',
staticFlag = false, accessMode = 'pub', kind = 3, itemTypeId = {326}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 400, baseId = 1, txt = '',
staticFlag = false, accessMode = 'pub', kind = 3, itemTypeId = {326}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 424, baseId = 1, txt = '',
staticFlag = false, accessMode = 'pub', kind = 2, itemTypeId = {326}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 428, baseId = 1, txt = 'Scope',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {444, 446, 448, 450, 452, 454, 458, 462}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 456, baseId = 1, txt = 'Map',
staticFlag = false, accessMode = 'pub', kind = 4, itemTypeId = {18, 326}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 460, baseId = 1, txt = 'Map',
staticFlag = false, accessMode = 'pub', kind = 4, itemTypeId = {18, 428}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 466, baseId = 1, txt = 'NodePos',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 468, baseId = 1, txt = 'Node',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {472, 474, 478}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 480, baseId = 468, txt = 'ImportNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 482, baseId = 468, txt = 'RootNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 484, baseId = 468, txt = 'RefTypeNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 486, baseId = 468, txt = 'IfNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 488, baseId = 468, txt = 'SwitchNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 490, baseId = 468, txt = 'WhileNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 492, baseId = 468, txt = 'RepeatNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 494, baseId = 468, txt = 'ForNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 496, baseId = 468, txt = 'ApplyNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 498, baseId = 468, txt = 'ForeachNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 500, baseId = 468, txt = 'ForsortNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 502, baseId = 468, txt = 'ReturnNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 504, baseId = 468, txt = 'BreakNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 506, baseId = 468, txt = 'ExpNewNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 508, baseId = 468, txt = 'ExpListNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 510, baseId = 468, txt = 'ExpRefNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 512, baseId = 468, txt = 'ExpOp2Node',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 514, baseId = 468, txt = 'ExpCastNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 516, baseId = 468, txt = 'ExpOp1Node',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 518, baseId = 468, txt = 'ExpRefItemNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 520, baseId = 468, txt = 'ExpCallNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 522, baseId = 468, txt = 'ExpDDDNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 524, baseId = 468, txt = 'ExpParenNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 526, baseId = 468, txt = 'BlockNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 528, baseId = 468, txt = 'StmtExpNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 530, baseId = 468, txt = 'RefFieldNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 532, baseId = 468, txt = 'DeclVarNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 534, baseId = 468, txt = 'DeclFuncNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 536, baseId = 468, txt = 'DeclMethodNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 538, baseId = 468, txt = 'DeclConstrNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 540, baseId = 468, txt = 'DeclMemberNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 542, baseId = 468, txt = 'DeclArgNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 544, baseId = 468, txt = 'DeclArgDDDNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 546, baseId = 468, txt = 'DeclClassNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 548, baseId = 468, txt = 'LiteralNilNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 550, baseId = 468, txt = 'LiteralCharNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 552, baseId = 468, txt = 'LiteralIntNode',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 556, baseId = 1, txt = 'TransUnit',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {636, 1172}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 634, baseId = 1, txt = '',
staticFlag = false, accessMode = 'pub', kind = 2, itemTypeId = {18}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 680, baseId = 1, txt = 'Map',
staticFlag = false, accessMode = 'pub', kind = 4, itemTypeId = {18, 12}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 688, baseId = 1, txt = 'getNodeKindName',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 690, baseId = 1, txt = 'nodeFilter',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {6}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 1016, baseId = 1, txt = 'DeclFuncInfo',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {1024, 1026, 1030, 1032, 1034, 1036, 1040, 1044}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 1028, baseId = 1, txt = '',
staticFlag = false, accessMode = 'pub', kind = 2, itemTypeId = {468}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 1038, baseId = 1, txt = '',
staticFlag = false, accessMode = 'pub', kind = 2, itemTypeId = {326}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 1042, baseId = 1, txt = '',
staticFlag = false, accessMode = 'pub', kind = 2, itemTypeId = {326}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 1130, baseId = 1, txt = 'LiteralStringInfo',
staticFlag = false, accessMode = 'pub', kind = 5, itemTypeId = {}, retTypeId = {}, children = {1134, 1138}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1, typeId = 1136, baseId = 1, txt = '',
staticFlag = false, accessMode = 'pub', kind = 2, itemTypeId = {468}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 194, typeId = 212, baseId = 1, txt = 'getStreamName',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 194, typeId = 214, baseId = 1, txt = 'create',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {194}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 194, typeId = 270, baseId = 1, txt = 'getToken',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 286, typeId = 300, baseId = 1, txt = 'getStreamName',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 286, typeId = 302, baseId = 1, txt = 'create',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {286}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 286, typeId = 304, baseId = 1, txt = 'getToken',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 346, baseId = 1, txt = 'getParentId',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {12}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 348, baseId = 1, txt = 'get_baseId',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {12}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 350, baseId = 1, txt = 'addChild',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 352, baseId = 1, txt = 'serialize',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 358, baseId = 1, txt = 'getTxt',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 360, baseId = 1, txt = 'equals',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 362, baseId = 1, txt = 'cloneToPublic',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 368, baseId = 1, txt = 'create',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 370, baseId = 1, txt = 'createBuiltin',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 374, baseId = 1, txt = 'createList',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 378, baseId = 1, txt = 'createArray',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 380, baseId = 1, txt = 'createMap',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 384, baseId = 1, txt = 'createClass',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 390, baseId = 1, txt = 'createFunc',
staticFlag = true, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 398, baseId = 1, txt = 'get_itemTypeInfoList',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {396}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 402, baseId = 1, txt = 'get_retTypeInfoList',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {400}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 404, baseId = 1, txt = 'get_parentInfo',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 406, baseId = 1, txt = 'get_typeId',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {12}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 408, baseId = 1, txt = 'get_kind',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {12}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 410, baseId = 1, txt = 'get_staticFlag',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 412, baseId = 1, txt = 'get_accessMode',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 414, baseId = 1, txt = 'get_autoFlag',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 416, baseId = 1, txt = 'get_orgTypeInfo',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 418, baseId = 1, txt = 'get_baseTypeInfo',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 420, baseId = 1, txt = 'get_nilable',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 422, baseId = 1, txt = 'get_nilableTypeInfo',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 326, typeId = 426, baseId = 1, txt = 'get_children',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {424}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 428, typeId = 444, baseId = 1, txt = 'add',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 428, typeId = 446, baseId = 1, txt = 'addClass',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 428, typeId = 448, baseId = 1, txt = 'getClassScope',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {428}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 428, typeId = 450, baseId = 1, txt = 'getTypeInfoChild',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 428, typeId = 452, baseId = 1, txt = 'getTypeInfo',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 428, typeId = 454, baseId = 1, txt = 'get_parent',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {428}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 428, typeId = 458, baseId = 1, txt = 'get_symbol2TypeInfoMap',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {456}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 428, typeId = 462, baseId = 1, txt = 'get_className2ScopeMap',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {460}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 468, typeId = 472, baseId = 1, txt = 'get_kind',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {12}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 468, typeId = 474, baseId = 1, txt = 'get_expType',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {326}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 468, typeId = 478, baseId = 1, txt = 'get_info',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {6}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 556, typeId = 636, baseId = 1, txt = 'get_errMessList',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {634}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 556, typeId = 1172, baseId = 1, txt = 'createAST',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {20}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1016, typeId = 1024, baseId = 1, txt = 'get_className',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {284}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1016, typeId = 1026, baseId = 1, txt = 'get_name',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {284}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1016, typeId = 1030, baseId = 1, txt = 'get_argList',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {1028}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1016, typeId = 1032, baseId = 1, txt = 'get_staticFlag',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {10}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1016, typeId = 1034, baseId = 1, txt = 'get_accessMode',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {18}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1016, typeId = 1036, baseId = 1, txt = 'get_body',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {468}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1016, typeId = 1040, baseId = 1, txt = 'get_retTypeList',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {1038}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1016, typeId = 1044, baseId = 1, txt = 'get_retTypeInfoList',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {1042}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1130, typeId = 1134, baseId = 1, txt = 'get_token',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {284}, children = {}, }
)
table.insert( 
moduleObj._typeInfoList, { parentId = 1130, typeId = 1138, baseId = 1, txt = 'get_argList',
staticFlag = false, accessMode = 'pub', kind = 6, itemTypeId = {}, retTypeId = {1136}, children = {}, }
)
----- meta -----
return moduleObj
