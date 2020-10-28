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
import Node.Jwt.JwtErrors
import Node.Jwt.Types
import Prelude

import Data.Argonaut (Json)
import Data.Array.NonEmpty (NonEmptyArray)
import Data.Array.NonEmpty as NonEmptyArray
import Data.Foldable as Foldable
import Data.JSDate (JSDate)
import Data.JSDate as JSDate
import Data.NonEmpty (NonEmpty(..), (:|))
import Data.NonEmpty as NonEmpty
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Data.String.Regex (Regex)
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

type VerifyOptionsInternal =
  { algorithms     :: NonEmptyArray String
  , audience       :: Nullable (NonEmptyArray String)
  , issuer         :: Nullable (NonEmptyArray Foreign)
  , subject        :: Nullable String
  , clockTolerance :: Int
  , maxAge         :: Nullable NumericDate
  , clockTimestamp :: Nullable JSDate
  , nonce          :: Nullable String
  }

type VerifyOptions =
  { algorithms     :: NonEmptyArray Algorithm -- non empty for better security
  , audience       :: Array String -- checks against aud
  , issuer         :: Array (Either Regex String) -- checks against iss
  , subject        :: Maybe String
  , clockTolerance :: Int -- default 0
  , maxAge         :: Maybe NumericDate
  , clockTimestamp :: Maybe JSDate -- if null - use current date
  , nonce          :: Maybe String
  }

defaultVerifyOptions :: NonEmptyArray Algorithm -> VerifyOptions
defaultVerifyOptions algorithms =
  { algorithms
  , audience:       []
  , issuer:         []
  , subject:        Nothing
  , clockTolerance: 0
  , maxAge:         Nothing
  , clockTimestamp: Nothing
  , nonce:          Nothing
  }

foreign import _verify ::
  Fn4
  Boolean
  String
  SecretOrPublicKey
  VerifyOptionsInternal
  (EffectFnAff Json)

-- returns { header, payload, signature }
-- can use catchJwtErrors
verifyComplete
  :: String
  -> SecretOrPublicKey
  -> VerifyOptions
  -> Aff Json
verifyComplete = \token secretOrPublicKey verifyOptions -> fromEffectFnAff $ runFn4 _verify true token secretOrPublicKey (verifyOptionsToVerifyOptionsInternal verifyOptions)

-- returns payload
-- can use catchJwtErrors
verify
  :: String
  -> SecretOrPublicKey
  -> VerifyOptions
  -> Aff Json
verify = \token secretOrPublicKey verifyOptions -> fromEffectFnAff $ runFn4 _verify false token secretOrPublicKey (verifyOptionsToVerifyOptionsInternal verifyOptions)

verifyOptionsToVerifyOptionsInternal :: VerifyOptions -> VerifyOptionsInternal
verifyOptionsToVerifyOptionsInternal verifyOptions =
  { algorithms:     map algorithmToInternal verifyOptions.algorithms
  , audience:       Nullable.toNullable $ NonEmptyArray.fromArray verifyOptions.audience
  , issuer:         Nullable.toNullable $ NonEmptyArray.fromArray $ map (either unsafeToForeign unsafeToForeign) $ verifyOptions.issuer
  , subject:        Nullable.toNullable verifyOptions.subject
  , clockTolerance: verifyOptions.clockTolerance
  , maxAge:         Nullable.toNullable verifyOptions.maxAge
  , clockTimestamp: Nullable.toNullable verifyOptions.clockTimestamp
  , nonce:          Nullable.toNullable verifyOptions.nonce
  }
