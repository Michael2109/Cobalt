module AST.AST where

import Data.Scientific

data Module = Module ModuleHeader [Model]
    deriving (Show)

data ModuleHeader = ModuleHeader
    { modName :: NameSpace
    , modImports :: [Import]
    }
    deriving (Show, Eq)

data Method = Method
    { methodName :: Name
    , methodAnns :: [Annotation]
    , methodParams :: [Field]
    , methodModifiers :: [Modifier]
    , methodReturnType :: Type
    , methodBody :: Stmt
    }
    deriving (Show, Eq)

data Constant = Constant
    deriving (Show, Eq)

data ModelType
    = ClassModel
    | ObjectModel
    | TraitModel
    | UnknownModel
    deriving (Eq, Show)

data Modifier
    = Public
    | Protected
    | Private
    | PackageLocal
    | Abstract
    | Final
    deriving (Eq, Show)

data Model = Model
    { modelName :: Name
    , modelModifiers :: [Modifier]
    , modelFields :: [Field]
    , modelParent :: Maybe Type
    , modelParentArguments :: [Stmt]
    , modelInterfaces :: [Type]
    , modelBody :: [Stmt]
    }
    deriving (Show, Eq)

data Field = Field
    { fieldName :: Name
    , fieldType :: Maybe Type
    , fieldInit :: Maybe Expr
    }
    deriving (Show, Eq)

data Type
    = TypeRef Ref
    | TypeApp Ref [Type] -- type application, aka Map<A,B> -> `TyApp (RefLocal "Map") [TyRef (RefLocal "A"), TyRef (RefLocal "B")]`
    | TypeRel TypeRel Type Type -- this allows things like <T extends Something> which would be `TyRel Extends (TyRef (RefLocal "T")) (TyRef (RefLocal "Something"))`
    deriving (Show, Eq)

data Ref
    = RefSpecial SpecialRef
    | RefLocal Name
    | RefQual QualName
    -- | RefOp AOperator
    deriving (Show, Eq)

data SpecialRef
    = Super
    | This
    deriving (Show, Eq)

data TypeRel
    = Inherits
    | Extends
    | Equals
    deriving (Show, Eq)

data NameSpace = NameSpace [String]
    deriving (Show, Eq)

data Name = Name String
    deriving (Show, Eq)

data Import = Import [String]
    deriving (Show, Eq)

data Annotation = Annotation Name
    deriving (Show, Eq)

data QualName = QualName NameSpace Name
    deriving (Show, Eq)

data IntConstant = IntConstant Integer

data Expr
    = Call Expr [Expr]
    | Identifier Name
    | Ternary BExpr Expr Expr
    | Tuple [Expr]
    | BlockExpr [Expr]
    deriving (Show, Eq)

data Stmt
    = For Expr AExpr AExpr Stmt
    | While BExpr [Stmt]
    | If BExpr Stmt (Maybe Stmt)
    | TryBlock ExceptionHandler (Maybe ExceptionHandler) (Maybe ExceptionHandler)
    | Assign Name (Maybe Type) Stmt
    | AssignMultiple [Name] (Maybe Type) Stmt
    | Reassign Name Expr
    | Return Stmt
    | Lambda [Field] Stmt
    | MethodCall Name [Expr]
    | NewClassInstance Type [Stmt]
    | StringLiteral String
    | ModelDef Model
    | MethodDef Method
    | ExprAsStmt Expr
    | BlockStmt [Stmt]
    deriving (Show, Eq)

-- This needs a better name
data ExceptionHandler
    = TryStatement [Stmt]
    | CatchStatement [Field] [Stmt]
    | FinallyStatement [Stmt]
    deriving (Show, Eq)

data BExpr
    = BoolConst Bool
    | Not BExpr
    | BBinary BBinOp BExpr BExpr
    | RBinary RBinOp AExpr AExpr
    deriving (Show, Eq)

data BBinOp
    = And
    | Or
    deriving (Show, Eq)

data RBinOp
    = Greater
    | Less
    deriving (Show, Eq)

data AExpr
    = Var String
    | IntConst Integer
    | DoubleConst Scientific
    | FloatConst Float
    | LongConst Integer
    | Neg AExpr
    | ABinary ABinOp AExpr AExpr
    deriving (Show, Eq)

data ABinOp
    = Add
    | Subtract
    | Multiply
    | Divide
    deriving (Show, Eq)
