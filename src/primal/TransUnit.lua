local Parser = require( 'primal.Parser' )

local TransUnit = {}


local nodeKind2NameMap = {}
local nodeKindSeed = 0
local nodeKind = {}

TransUnit.nodeKind = nodeKind

TransUnit.className2NodeMap = {}

local function regKind( name )
   local kind = nodeKindSeed
   nodeKindSeed = nodeKindSeed + 1
   nodeKind2NameMap[ kind ] = name
   nodeKind[ name ] = kind
   return kind
end

local nodeKindNone = regKind( 'None' )
local nodeKindRoot = regKind( 'Root' )
local nodeKindRefType = regKind( 'RefType' )
local nodeKindIf = regKind( 'If' )
local nodeKindWhile = regKind( 'While' )
local nodeKindRepeat = regKind( 'Repeat' )
local nodeKindFor = regKind( 'For' )
local nodeKindApply = regKind( 'Apply' )
local nodeKindForeach = regKind( 'Foreach' )
local nodeKindReturn = regKind( 'Return' )
local nodeKindBreak = regKind( 'Break' )
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

local function nodeFilter( node, filter, ... )
   if not filter[ node.kind ] then
      error( string.format( "none filter -- %s",
			    TransUnit:getNodeKindName( node.kind ) ))
   end
   filter[ node.kind ]( filter, node, ... )
end

function TransUnit:getNodeKindName( kind )
   return nodeKind2NameMap[ kind ]
end


function TransUnit:createAST( parser )

   local rootInfo = {}
   rootInfo.childlen = {}
   self.ast = self:createNode(
      nodeKindRoot, { lineNo = 0, column = 0 }, rootInfo )
   self.parser = parser
   
   TransUnit:analyzeStatement( rootInfo.childlen )

   local token = self:getTokenNoErr()
   if token then
      error( string.format( "unknown:%d:%d:(%s) %s",
			    token.pos.lineNo, token.pos.column,
			    Parser.getKindTxt( token.kind ), token.txt ) )
   end

   return self.ast
end

function TransUnit:createNoneNode()
   return self:createNode( nodeKindNone, { lineNo = 0, column = 0 }, {} )
end

function TransUnit:createNode( kind, pos, info )
   if not self:getNodeKindName( kind ) then
      error( string.format( "%d:%d: not found nodeKind", pos.lineNo, pos.column ) )
   end
   return { kind = kind, pos = pos, info = info, filter = nodeFilter }
end

function TransUnit:analyzeDecl( firstToken, token )
   if token.txt == "let" then
      return self:analyzeDeclVar( token )
   elseif token.txt == "fn" then
      return self:analyzeDeclFunc( false, token, nil )
   elseif token.txt == "class" then
      return self:analyzeDeclClass( token )
   end

   return nil
end

function TransUnit:analyzeStatement( stmtList, termTxt )
   while true do
      local token = self:getTokenNoErr()
      if not token then
	 break
      end

      local statement = self:analyzeDecl( token, token )

      if not statement then
	 if token.txt == termTxt then
	    self:pushback()
	    break
	 elseif token.txt == "pub" or token.txt == "pro" or
	    token.txt == "pri" or token.txt == "global"
	 then
	    statement = self:analyzeDecl( token, self:getToken() )
	 elseif token.txt == "{" then
	    self:pushback()
	    statement = self:analyzeBlock( "{" )
	 elseif token.txt == "if" then
	    statement = self:analyzeIf( token )
	 elseif token.txt == "while" then
	    statement = self:analyzeWhile( token )
	 elseif token.txt == "repeat" then
	    statement = self:analyzeRepeat( token )
	 elseif token.txt == "for" then
	    statement = self:analyzeFor( token )
	 elseif token.txt == "apply" then
	    statement = self:analyzeApply( token )
	 elseif token.txt == "foreach" then
	    statement = self:analyzeForeach( token )
	 elseif token.txt == "return" then
	    local expList = self:analyzeExpList()
	    self:checkNextToken( ";" )
	    statement = self:createNode( nodeKindReturn, token.pos, expList )
	 elseif token.txt == "break" then
	    self:checkNextToken( ";" )
	    statement = self:createNode( nodeKindBreak, token.pos, nil )
	 else
	    self:pushback()
	    local exp = self:analyzeExp()
	    self:checkNextToken( ";" )
	    statement = self:createNode( nodeKindStmtExp, token.pos, exp )
	 end
      end

      if not statement then
	 break
      end
      table.insert( stmtList, statement )
   end
end

function TransUnit:pushback()
   if self.pushbackToken then
      error( string.format( "multiple pushback:%d:%d: %s, %s",
			    self.currentToken.pos.lineNo,
			    self.currentToken.pos.column,
			    self.pushbackToken.txt, self.currentToken.txt ) )
   end
   self.pushbackToken = self.currentToken
   self.currentToken = nil
end

function TransUnit:getToken( mess )
   local token = self:getTokenNoErr()
   if not token then
      return Parser:getEofToken()
   end
   self.currentToken = token
   return self.currentToken
end

function TransUnit:getTokenNoErr()
   if self.pushbackToken then
      self.currentToken = self.pushbackToken
      self.pushbackToken = nil
      return self.currentToken
   end

   local commentList = {}
   local token
   while true do
      token = self.parser:getToken()
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

function TransUnit:getSymbolToken()
   return self:checkSymbol( self:getToken() )
end

function TransUnit:checkSymbol( token )
   if token.kind ~= Parser.kind.Symb and
      token.kind ~= Parser.kind.Kywd and
      token.kind ~= Parser.kind.Type
   then
      self:error( "illegal symbol" )
   end
   return token
end


function TransUnit:error( mess )
   local pos = { lineNo = 0, column = 0 }
   local txt = ""
   if self.currentToken then
      pos = self.currentToken.pos
      txt = self.currentToken.txt
   end
   error( string.format( "%d:%d:(%s) %s", pos.lineNo, pos.column, txt, mess ) )
end

function TransUnit:checkNextToken( txt )
   return self:checkToken( self:getToken(), txt )
end

function TransUnit:checkToken( token, txt )
   if not token or token.txt ~= txt then
      self:error( string.format( "not found -- %s", txt ) )
   end
   return token
end

function TransUnit:analyzeIf( token )
   local list = {}
   table.insert(
      list, { kind = "if", exp = self:analyzeExp(), block = self:analyzeBlock( "if" ) } )

   local nextToken = self:getToken()
   if nextToken.txt == "elseif" then
      while nextToken.txt == "elseif" do
	 table.insert(
	    list, { kind = "elseif", exp = self:analyzeExp(),
		    block = self:analyzeBlock( "elseif" ) } )
	 nextToken = self:getToken()
      end
   end

   if nextToken.txt == "else" then
      table.insert(
	 list, { kind = "else", block = self:analyzeBlock( "else" ) } )
   else
      self:pushback()
   end

   return self:createNode( nodeKindIf, token.pos, list )
end

function TransUnit:analyzeWhile( token )
   local info = { exp = self:analyzeExp(), block = self:analyzeBlock( "while" ) }
   return self:createNode( nodeKindWhile, token.pos, info )
end

function TransUnit:analyzeRepeat( token )
   local info = { block = self:analyzeBlock(), exp = self:analyzeExp( "repeat" ) }
   local node = self:createNode( nodeKindRepeat, token.pos, info )
   self:checkNextToken( ";" )
   return node
end

function TransUnit:analyzeFor( token )
   local val = self:getToken()
   if val.kind ~= Parser.kind.Symb then
      self:error( "not symbol" )
   end
   self:checkNextToken( "=" )
   local exp1 = self:analyzeExp()
   self:checkNextToken( "," )
   local exp2 = self:analyzeExp()
   local token = self:getToken()
   local exp3
   if token.txt == "," then
      exp3 = self:analyzeExp()
   else
      self:pushback()
   end
   
   local info = { block = self:analyzeBlock( "for" ), val = val,
		  init = exp1, to = exp2, delta = exp3 }
   local node = self:createNode( nodeKindFor, token.pos, info )
   return node
end

function TransUnit:analyzeApply( token )
   local varList = {}
   local nextToken
   repeat
      local var = self:getToken()
      if var.kind ~= Parser.kind.Symb then
	 self:error( "illegal symbol" )
      end
      table.insert( varList, var )
      nextToken = self:getToken()
   until nextToken.txt ~= ","
   self:checkToken( nextToken, "of" )

   local exp = self:analyzeExp()
   if exp.kind ~= nodeKindExpCall then
      self:error( "not call" )
   end

   local block = self:analyzeBlock( "apply" )

   local info = { varList = varList, exp = exp, block = block }
   return self:createNode( nodeKindApply, token.pos, info )
end

function TransUnit:analyzeForeach( token )
   local valSymbol
   local keySymbol
   local nextToken
   for index = 1, 2 do
      local sym = self:getToken()
      if sym.kind ~= Parser.kind.Symb then
	 self:error( "illegal symbol" )
      end
      if index == 1 then
	 valSymbol = sym
      else
	 keySymbol = sym
      end
      nextToken = self:getToken()
      if nextToken.txt ~= "," then
	 break
      end
   end
   self:checkToken( nextToken, "in" )

   local exp = self:analyzeExp()

   local block = self:analyzeBlock( "foreach" )

   local info = { val = valSymbol, key = keySymbol, exp = exp, block = block }
   return self:createNode( nodeKindForeach, token.pos, info )
end


function TransUnit:analyzeRefType()
   local firstToken = self:getToken()
   local token = firstToken
   local refFlag = false
   if token.txt == "&" then
      refFlag = true
      token = self:getToken()
   end
   local mutFlag = false
   if token.txt == "mut" then
      mutFlag = true
      token = self:getToken()
   end
   local name = self:checkSymbol( token )
   local arrayMode = "no"
   token = self:getToken()
   if token.txt == '[' or token.txt == '[@' then
      if token.txt == '[' then
	 arrayMode = "list"
      else
	 arrayMode = "array"
      end
      token = self:getToken()
      if token.txt ~= ']' then
	 self:pushback()
	 self:checkNextToken( ']' )
      end
   else
      self:pushback()
   end

   return self:createNode(
      nodeKindRefType, firstToken.pos,
      { name = name, refFlag = refFlag, mutFlag = mutFlag, array = arrayMode } )
end


function TransUnit:analyzeDeclMember( firstToken )
   local varName = self:getSymbolToken()
   token = self:getToken()
   local refType = self:analyzeRefType()
   token = self:getToken()
   -- accessor
   self:checkToken( token, ";" );

   return self:createNode(
      nodeKindDeclMember, firstToken.pos, { name = varName, refType = refType } )
end

function TransUnit:analyzeDeclMethod( className, firstToken, name )
   local node = self:analyzeDeclFunc( true, name, name )
   node.info.className = className
   return node
end

function TransUnit:analyzeDeclClass( classToken )
   local name = self:getToken()
   self:checkNextToken( "{" )

   local fieldList = {}
   while true do
      local token = self:getToken()
      if token.txt == "}" then
	 break;
      end
      if token.txt == "let" then
	 table.insert( fieldList, self:analyzeDeclMember( token ) )
      else 
	 table.insert( fieldList, self:analyzeDeclMethod( name, token, token ) )
      end
   end

   local node = self:createNode(
      nodeKindDeclClass, classToken.pos, { name = name, fieldList = fieldList } )
   self.className2NodeMap[ name.txt ] = node
   return node
end

function TransUnit:analyzeDeclFunc( methodFlag, firstToken, name )
   local argList = {}
   local token = self:getToken()
   if not name then
      if token.txt ~= "(" then
	 name = self:checkSymbol( token )
	 token = self:getToken()
      end
   else
      self:checkSymbol( name )
   end
   local className
   if token.txt == "." then
      methodFlag = true
      className = name
      name = self:getSymbolToken()
      token = self:getToken()
   end

   self:checkToken( "(" )

   local kind
   if methodFlag then
      if name.txt == "__init" then
	 kind = nodeKindDeclConstr
      else
	 kind = nodeKindDeclMethod
      end
   else
      kind = nodeKindDeclFunc
   end
   
   
   repeat
      local argName = self:getToken()
      if argName.txt == ")" then
	 token = argName
	 break
      elseif argName.txt == "..." then
	 table.insert( argList, self:createNode( nodeKindDeclArgDDD,
						 argName.pos, argName ) )
      else
	 self:checkSymbol( argName )
	 
	 self:checkNextToken( ":" )
	 local refType = self:analyzeRefType()
	 local arg = self:createNode( nodeKindDeclArg, argName.pos,
				      { name = argName, argType = refType } )
	 table.insert( argList, arg )
      end
      token = self:getToken()
   until token.txt ~= ","

   self:checkToken( token, ")" )

   token = self:getToken()
   local typeList = {}
   if token.txt == ":" then
      repeat
	 table.insert( typeList, self:analyzeRefType() )
	 token = self:getToken()
      until token.txt ~= ","
   end

   self:pushback()
   local body = self:analyzeBlock( "func" )
   local info = { name = name, argList = argList,
		  retTypeList = typeList, body = body }

   local node = self:createNode( kind, firstToken.pos, info )

   if className then
      local classNode = self.className2NodeMap[ className.txt ]
      info.className = className
   end

   return node
end

function TransUnit:analyzeBlock( blockKind )
   local token = self:checkNextToken( "{" )

   local stmtList = {}
   self:analyzeStatement( stmtList, "}" )

   self:checkNextToken( "}" )

   return self:createNode( nodeKindBlock, token.pos,
			   { kind = blockKind, stmtList = stmtList } )
end

function TransUnit:analyzeDeclVar( letToken )
   local varList = {}
   local token
   repeat
      local varName = self:getSymbolToken()
      token = self:getToken()
      if token.txt == ":" then
	 local refType = self:analyzeRefType()
	 token = self:getToken()
      end
      table.insert( varList, { name = varName, refType = refType } )
   until token.txt ~= ","
   
   local expList
   if token.txt == "=" then
      expList = self:analyzeExpList()
   end

   self:checkNextToken( ";" )

   local declVarInfo = { varList = varList, expList = expList }
   return self:createNode( nodeKindDeclVar, letToken.pos, declVarInfo )
end

function TransUnit:analyzeExpList()
   local expList = {}
   local firstExp = nil
   repeat
      local exp = self:analyzeExp()
      if not firstExp then
	 firstExp = exp
      end
      table.insert( expList, exp )
      local token = self:getToken()
   until token.txt ~= ","

   self:pushback()

   return self:createNode( nodeKindExpList, firstExp.pos, expList )
end

function TransUnit:analyzeListConst( token )
   local nextToken = self:getToken()
   local expList
   if nextToken.txt ~= "]" then
      self:pushback()
      expList = self:analyzeExpList()
      self:checkNextToken( "]" )
   end
   local kind = nodeKindLiteralArray
   if token.txt == '[' then
      kind = nodeKindLiteralList
   end
   return self:createNode( kind, token.pos, expList )
end

function TransUnit:analyzeMapConst( token )
   local nextToken
   local map = {}
   repeat
      nextToken = self:getToken()
      if nextToken.txt == "}" then
	 break
      end
      self:pushback()
      
      local key = self:analyzeExp()
      self:checkNextToken( ":" )
      local val = self:analyzeExp()
      map[ key ] = val
      nextToken = self:getToken()
   until nextToken.txt ~= ","

   self:checkToken( nextToken, "}" )
   return self:createNode( nodeKindLiteralMap, token.pos, map )
end

function TransUnit:analyzeExpRefItem( token, exp )
   local indexExp = self:analyzeExp()
   self:checkNextToken( "]" )

   local info = { val = exp, index = indexExp }
   return self:createNode( nodeKindExpRefItem, token.pos, info )
end   

function TransUnit:analyzeExpSymbol( firstToken, token, mode, prefixExp )
   local exp

   if mode == "field" then
      local info = { field = token, prefix = prefixExp }
      exp = self:createNode( nodeKindRefField, firstToken.pos, info )
   elseif mode == "symbol" then
      exp = self:createNode( nodeKindExpRef, firstToken.pos, token )
   elseif mode == "fn" then
      exp = self:analyzeDeclFunc( false, token, nil )   
   else
      self:error( "illegal mode", mode )
   end

   local nextToken = self:getToken()
   repeat
      local matchFlag = false
      if nextToken.txt == "[" then
	 matchFlag = true
	 exp = self:analyzeExpRefItem( nextToken, exp )
	 nextToken = self:getToken()
      end
      if nextToken.txt == "(" then
	 matchFlag = true
	 local work = self:getToken()
	 local expList
	 if work.txt ~= ")" then
	    self:pushback()	    
	    expList = self:analyzeExpList()
	    self:checkNextToken( ")" )
	 end
	 local info = { func = exp, argList = expList }

	 exp = self:createNode( nodeKindExpCall, token.pos, info )
	 nextToken = self:getToken()
      end
   until not matchFlag

   if nextToken.txt == "." then
      return self:analyzeExpSymbol(
	 firstToken, self:getToken(), "field", exp )
   end
   
   self:pushback()
   return exp
end


function TransUnit:analyzeExp( skipOp2Flag )
   local token = self:getToken()

   if token.txt == "..." then
      return self:createNode( nodeKindExpDDD, token.pos, token )
   end
   
   if token.txt == '[' or token.txt == '[@' then
      return self:analyzeListConst( token )
   end
   if token.txt == '{' then
      return self:analyzeMapConst( token )
   end
   
   local exp
   if token.kind == Parser.kind.Ope and Parser.isOp1( token.txt ) then
      -- 単項演算
      exp = self:analyzeExp( true )
      exp = self:createNode( nodeKindExpOp1, token.pos, { op = token, exp = exp } )
      return self:analyzeExpOp2( token, exp )
   end

   if token.txt == "(" then
      exp = self:analyzeExp( false )
      self:checkNextToken( ")" )
      return self:createNode( nodeKindExpParen, token.pos, exp )
   end

   if token.kind == Parser.kind.Int then
      exp = self:createNode( nodeKindLiteralInt, token.pos,
			     { token = token, num = tonumber( token.txt ) } )
   elseif token.kind == Parser.kind.Real then
      exp = self:createNode( nodeKindLiteralReal, token.pos,
			     { token = token, num = tonumber( token.txt ) } )
   elseif token.kind == Parser.kind.Char then
      exp = self:createNode( nodeKindLiteralChar, token.pos,
			     { token = token, num = token.txt:byte( 2 ) } )
   elseif token.kind == Parser.kind.Str then
      local nextToken = self:getToken()
      local formatArgList = {}
      if nextToken.txt == "(" then
	 repeat
	    local arg = self:analyzeExp()
	    table.insert( formatArgList, arg )
	    nextToken = self:getToken()
	 until nextToken.txt ~= ","
	 self:checkToken( nextToken, ")" )
	 nextToken = self:getToken()
      end
      exp = self:createNode( nodeKindLiteralString, token.pos,
			     { token = token, argList = formatArgList } )
      if nextToken.txt == "[" then
	 exp = self:analyzeExpRefItem( nextToken, exp )
      else
	 self:pushback()
      end
   elseif token.txt == "fn" then
      exp = self:analyzeExpSymbol( token, token, "fn", token )
   elseif token.kind == Parser.kind.Symb then
      exp = self:analyzeExpSymbol( token, token, "symbol", token )
   elseif token.kind == Parser.kind.Type then
      exp = self:createNode( nodeKindExpRef, token.pos, token )
   elseif token.txt == "true" or token.txt == "false" then
      exp = self:createNode( nodeKindLiteralBool, token.pos, token )
   elseif token.txt == "nil" then
      exp = self:createNode( nodeKindLiteralNil, token.pos, token )
   end

   if not exp then
      self:error( "illegal exp" )
   end

   if skipOp2Flag then
      return exp
   end
   
   return self:analyzeExpOp2( token, exp )
end

function TransUnit:analyzeExpOp2( token, exp )
   local nextToken = self:getToken()
   while true do
      if nextToken.txt == "@" then
	 local castType = self:analyzeRefType()
	 local info = { exp = exp, castType = castType }
	 exp = self:createNode( nodeKindExpCast, token.pos, info )
      elseif nextToken.kind == Parser.kind.Ope then
	 if Parser.isOp2( nextToken.txt ) then
	    local exp2 = self:analyzeExp()
	    local info = { op = nextToken, exp1 = exp, exp2 = exp2 }
	    exp = self:createNode( nodeKindExpOp2, token.pos, info )
	 else
	    self:error( "illegal op" )
	 end
      else
	 self:pushback()
	 return exp
      end
      nextToken = self:getToken()
   end
end

return TransUnit
