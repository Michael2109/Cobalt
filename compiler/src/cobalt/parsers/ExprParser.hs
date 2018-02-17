{-|
Module      : ExprParser
Description : Parses all expressions.
The highest level parser that uses functions in the BaseParser and ABExprParser to generate the AST.
-}
module ExprParser (Parser,
  expr, moduleParser, classParser, parser) where

import Control.Applicative (empty)
import Control.Monad (void)
import Data.Void
import Data.Char (isAlphaNum)
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Text.Megaparsec.Expr
import Text.Pretty.Simple (pShow)

import ABExprParser
import Block



arithmeticParser :: String -> Parser Expr
arithmeticParser moduleName = do
  aE <- aExpr
  return $ ArithExpr aE

booleanParser :: String -> Parser Expr
booleanParser moduleName = do
  bE <- bExpr
  return $ BooleanExpr bE

stringLiteral :: Parser Expr
stringLiteral = do
  value <- char '"' >> manyTill L.charLiteral (char '"')
  return $ StringLiteral value


assignParser :: String -> Parser Expr
assignParser moduleName = do
  var  <- identifier
  symbol ":"
  vType <- valType
  symbol "="
  e <- expr' moduleName
  return (Assign vType var e)


reassignParser :: String -> Parser Expr
reassignParser moduleName = do
  name  <- identifier
  symbol "="
  value <- expr' moduleName
  return (Reassign name value)


arrayDef :: Parser Expr
arrayDef = do
  name <- identifier
  symbol ":"
  symbol "["
  arrType <- word
  symbol "]"
  symbol "="
  return $ ArrayDef arrType name


arrayValues :: Parser Expr
arrayValues = do
  symbol "["
  values <- many identifier
  symbol "]"
  return $ ArrayValues values

arrayAssign :: Parser Expr
arrayAssign = do
  def <- arrayDef
  values <- arrayValues
  return $ ArrayAssignment def values

arrayElementSelect :: Parser Expr
arrayElementSelect = do
  symbol "!!"
  elementNum <- word
  return $ ArrayElementSelect elementNum

arrayAppend :: String -> Parser Expr
arrayAppend moduleName = do
  arrays <- sepBy1 (expr' "") (symbol "++")
  return $ ArrayAppend arrays

-- Parses "True" or "False"
booleanValueParser :: String -> Parser Expr
booleanValueParser moduleName = do
  rword "True"
  return $ BooleanValueExpr True




moduleParser :: [String] -> Parser Expr
moduleParser relativeDir = do
    moduleKeyword <- rword "module"
    name <- identifier
    imports <- many (try importParser)
    exprs <- many (try (functionParser name True) <|> expr' name)
    let packageDir = if (length relativeDir <= 1) then [] else (tail relativeDir)
    return (Module (packageDir) name imports exprs)

classParser :: [String] -> Parser Expr
classParser relativeDir = do
    rword "class"
    name <- identifier
    extendsKeyword <- optional (rword "extends")
    parent <- optional (identifier)
    implementsKeyword <- optional (rword "implements")
    interfaces <- optional (identifier)
    imports <- many (try importParser)
    exprs <- many (try (functionParser name False) <|> expr' name )
    let packageDir = if (length relativeDir <= 1) then [] else (tail relativeDir)
    return (Class (packageDir) name parent interfaces imports exprs)

thisMethodCall :: String -> Parser Expr
thisMethodCall moduleName = do
  methodName <- identifier
  args <- parens (sepBy (expr' moduleName <|> argument) (symbol ","))
  return $ ThisMethodCall methodName args


objectMethodCall :: String -> Parser Expr
objectMethodCall moduleName = do
  objectName <- identifier
  symbol "."
  methodName <- identifier
  args <- parens (sepBy (expr' moduleName <|> argument) (symbol ","))
  return $ ObjectMethodCall objectName methodName args


newClassInstance :: String -> Parser Expr
newClassInstance moduleName = do
  rword "new"
  className <- identifier
  arguments <- parens (sepBy (expr' moduleName <|> argument) (symbol ","))
  return $ (NewClassInstance className arguments)

importParser :: Parser Expr
importParser = L.nonIndented scn p
  where
    p = do
      rword "import"
      locations <- sepBy1 identifier (symbol ".")
      return $ (Import locations)

globalVarParser :: String -> Parser Expr
globalVarParser moduleName = L.nonIndented scn p
  where
    p = do
      e <- assignParser moduleName
      return $ GlobalVar e

-- Function parser
functionParser :: String -> Bool -> Parser Expr
functionParser moduleName static = L.nonIndented scn (L.indentBlock scn p)
  where
    p = do
      name <- identifier
      symbol ":"
      aList <- sepBy (identifier) (symbol "->")
      let argTypes = map (\x -> ArgumentType x) (take (length aList - 1) aList)
      let rType = ReturnType $ last aList
      nameDup <- L.lineFold scn $ \sp' -> identifier
      args <- many argument
      symbol "="
      if(name == "main")
        then return (L.IndentMany Nothing (return . (MainFunction moduleName name argTypes args rType)) (expr' moduleName))
        else if name == moduleName
          then return (L.IndentMany Nothing (return . (Constructor moduleName name argTypes args)) (expr' ""))
          else return (L.IndentMany Nothing (return . (Function moduleName name argTypes args rType static)) (expr' ""))

valType :: Parser Expr
valType = do
    value <- identifier
    return $ Type value

argumentType :: Parser Expr
argumentType = do
    value <- identifier
    return $ ArgumentType value

returnType :: Parser Expr
returnType = do
    value <- identifier
    return $ ReturnType value

argument :: Parser Expr
argument = do
  value <- identifier
  return $ Argument value


functionCallParser :: String -> Parser Expr
functionCallParser moduleName = do
  name <- identifier
  args <- parens $ many argument
  return $ FunctionCall moduleName name args


-- data A = B String | C Integer
dataElementParser :: String -> Parser Expr
dataElementParser superName = do
  name <- identifier
  argTypes <- many identifier
  let args = map (\x -> "var" ++ show x) [0..((length argTypes)-1)]
  return $ DataElement superName name argTypes args


dataParser :: Parser Expr
dataParser = L.nonIndented scn p
  where
    p = do
      rword "data"
      name <- identifier
      symbol "="
      dataElements <- sepBy (dataElementParser name) (symbol "|")
      return $ Data name dataElements


dataInstanceParser :: String -> Parser Expr
dataInstanceParser moduleName = do
  typeName <- valType
  es <- parens (sepBy (expr' moduleName <|> argument) (symbol ","))
  return $ DataInstance moduleName typeName es



printParser :: String -> Parser Expr
printParser moduleName = do
  rword "println"
  e <- expr' moduleName
  return $ Print e


ifStmt :: String -> Parser Expr
ifStmt moduleName = L.indentBlock scn p
   where
     p = do
       rword "if"
       cond  <- bExpr
       return (L.IndentMany Nothing (return . (If cond)) (expr' moduleName))

elseIfStmt :: String -> Parser Expr
elseIfStmt moduleName = L.indentBlock scn p
   where
     p = do
       rword "else"
       rword "if"
       cond  <- bExpr
       return (L.IndentMany Nothing (return . (ElseIf cond)) (expr' moduleName))

elseStmt :: String -> Parser Expr
elseStmt moduleName = L.indentBlock scn p
   where
     p = do
       rword "else"
       return (L.IndentMany Nothing (return . (Else)) (expr' moduleName))

whileParser :: String -> Parser Expr
whileParser moduleName = L.indentBlock scn p
   where
     p = do
       rword "while"
       e <- parens (booleanParser moduleName)
       return (L.IndentMany Nothing (return . (While e)) (expr' moduleName))

tryParser :: String -> Parser Expr
tryParser moduleName = L.indentBlock scn p
   where
     p = do
       rword "try"
       return (L.IndentMany Nothing (return . (Try)) (expr' moduleName))


catchParser :: String -> Parser Expr
catchParser moduleName = L.indentBlock scn p
   where
     p = do
       rword "catch"
       let argType = "Exception"
       let argName = "e"
       return (L.IndentMany Nothing (return . (Catch argType argName)) (expr' moduleName))

whereStmt :: Parser Expr
whereStmt = do
  rword "where"
  symbol "{"
  exprs <- many expr
  symbol "}"
  return $ (Where exprs)


expr :: Parser Expr
expr = f <$> sepBy1 (expr' "") (symbol ";")
  where
    -- if there's only one expr return it without using ‘Seq’
    f l = if length l == 1 then head l else Seq l


expr' :: String -> Parser Expr
expr' moduleName = try dataParser
  <|> try (functionCallParser moduleName)
  <|> try (booleanParser moduleName)
  <|> try (booleanValueParser moduleName)

  -- If else
  <|> try (ifStmt moduleName)
  <|> try (elseIfStmt moduleName)
  <|> try (elseStmt moduleName)

  <|> try (whileParser moduleName)

  -- try/catch
  <|> try (tryParser moduleName)
  <|> try (catchParser moduleName)
  <|> try (printParser moduleName)
  <|> try (objectMethodCall moduleName)
  <|> try (thisMethodCall moduleName)
  <|> try (newClassInstance moduleName)
  <|> try (dataInstanceParser moduleName)
  <|> try arrayAssign
  <|> try arrayElementSelect
  <|> try (assignParser moduleName)
  <|> try (reassignParser moduleName)
  <|> try (arithmeticParser moduleName)
  <|> try whereStmt
  <|> try (globalVarParser moduleName)
  <|> try stringLiteral


parser :: Parser Expr
parser = expr' ""