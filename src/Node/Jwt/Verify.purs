module Node.Jwt.Verify where

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
import Node.Jwt.Types
import Prelude

import Data.Argonaut (Json)
import Data.Array.NonEmpty (NonEmptyArray)
import Data.Foldable as Foldable
import Data.JSDate (JSDate)
import Data.JSDate as JSDate
import Data.NonEmpty (NonEmpty(..), (:|))
import Data.NonEmpty as NonEmpty
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect.Aff.Compat (EffectFnAff(..), fromEffectFnAff)
import Node.Jwt.JsonWebTokenError (JsonWebTokenError)
import Node.Jwt.JsonWebTokenError as JsonWebTokenError
import Node.Jwt.NotBeforeError (NotBeforeError)
import Node.Jwt.NotBeforeError as NotBeforeError
import Node.Jwt.NumericDate (NumericDate)
import Node.Jwt.NumericDate as Exports
import Node.Jwt.NumericDate as NumericDate
import Node.Jwt.TokenExpiredError (TokenExpiredError)
import Node.Jwt.TokenExpiredError as TokenExpiredError
import Node.Jwt.Types as Exports
import Unsafe.Coerce (unsafeCoerce)
import Node.Jwt.JwtErrors

type VerifyOptionsGeneric n =
  { algorithms     :: NonEmptyArray String
  , audience       :: n (NonEmptyArray String)
  , issuer         :: NonEmptyArray String
  , subject        :: String
  , clockTolerance :: Int
  , maxAge         :: n NumericDate
  , clockTimestamp :: n JSDate -- if null - use current date
  , nonce          :: n String
  }

type VerifyOptionsInternal = VerifyOptionsGeneric Nullable

type VerifyOptions = VerifyOptionsGeneric Maybe

foreign import _verify ::
  Fn4
  Boolean
  String
  SecretOrPublicKey
  VerifyOptionsInternal
  (EffectFnAff Json)

-- returns { header, payload, signature }
verifyComplete
  :: String
  -> SecretOrPublicKey
  -> VerifyOptions
  -> Aff (Either JwtErrors Json)
verifyComplete = \token secretOrPublicKey verifyOptions -> map (lmap errorToJwtErrors) $ try $ fromEffectFnAff $ runFn4 _verify true token secretOrPublicKey (verifyOptionsToVerifyOptionsInternal verifyOptions)

-- returns payload
verify
  :: String
  -> SecretOrPublicKey
  -> VerifyOptions
  -> Aff (Either JwtErrors Json)
verify = \token secretOrPublicKey verifyOptions -> map (lmap errorToJwtErrors) $ try $ fromEffectFnAff $ runFn4 _verify false token secretOrPublicKey (verifyOptionsToVerifyOptionsInternal verifyOptions)

verifyOptionsToVerifyOptionsInternal :: VerifyOptions -> VerifyOptionsInternal
verifyOptionsToVerifyOptionsInternal verifyOptions =
  { algorithms:     verifyOptions.algorithms
  , audience:       Nullable.toNullable verifyOptions.audience
  , issuer:         verifyOptions.issuer
  , subject:        verifyOptions.subject
  , clockTolerance: verifyOptions.clockTolerance
  , maxAge:         Nullable.toNullable verifyOptions.maxAge
  , clockTimestamp: Nullable.toNullable verifyOptions.clockTimestamp
  , nonce:          Nullable.toNullable verifyOptions.nonce
  }
