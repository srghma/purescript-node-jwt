module Node.Jwt.JwtErrors where

import Control.Monad.Except
import Data.Bifunctor
import Data.Either
import Data.Function.Uncurried
import Data.List.NonEmpty
import Data.Maybe
import Data.Traversable
import Effect.Aff
import Effect.Uncurried
import Foreign
import Prelude
import Data.Foldable as Foldable

import Node.Jwt.JsonWebTokenError (JsonWebTokenError)
import Node.Jwt.JsonWebTokenError as JsonWebTokenError
import Node.Jwt.NotBeforeError (NotBeforeError)
import Node.Jwt.NotBeforeError as NotBeforeError
import Node.Jwt.NumericDate (NumericDate)
import Node.Jwt.NumericDate as NumericDate
import Node.Jwt.TokenExpiredError (TokenExpiredError)
import Node.Jwt.TokenExpiredError as TokenExpiredError

data JwtErrors
  = JwtErrors__JsonWebTokenError JsonWebTokenError
  | JwtErrors__NotBeforeError NotBeforeError
  | JwtErrors__TokenExpiredError TokenExpiredError
  | JwtErrors__Other Error

errorToJwtErrors :: Error -> JwtErrors
errorToJwtErrors error =
  fromMaybe (JwtErrors__Other error) $ Foldable.oneOf
    [ JsonWebTokenError.fromError error <#> JwtErrors__JsonWebTokenError
    , TokenExpiredError.fromError error <#> JwtErrors__TokenExpiredError
    , NotBeforeError.fromError error <#> JwtErrors__NotBeforeError
    ]

catchJwtErrors :: ∀ t20 t23. Functor t20 ⇒ MonadError Error t20 ⇒ t20 t23 → t20 (Either JwtErrors t23)
catchJwtErrors = map (lmap errorToJwtErrors) <<< try
