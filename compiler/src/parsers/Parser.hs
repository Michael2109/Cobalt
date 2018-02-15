{-# LANGUAGE TupleSections #-}

module Parser where

import Control.Applicative (empty)
import Control.Monad (void)
import Data.Void
import Data.Char (isAlphaNum)
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Text.Megaparsec.Expr
import Text.Pretty.Simple (pShow)

import ExprParser


parseFromFile file = runParser expr file <$> readFile file

parseTree relativeDir input = parse (moduleParser relativeDir) "" input

parseString relativeDir input =
  case parse (moduleParser relativeDir) "" input of
    Left  e -> show e
    Right x -> show x


parsePrint :: String -> IO()
parsePrint s = parseTest' parser s