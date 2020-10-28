{ name = "jsonwebtoken"
, license = "MIT"
, repository = "https://github.com/srghma/purescript-jsonwebtoken"
, dependencies =
  [ "aff"
  , "aff-promise"
  , "console"
  , "effect"
  , "foreign-generic"
  , "generics-rep"
  , "newtype"
  , "psci-support"
  , "options"
  , "js-date"
  , "argonaut"
  , "codec-argonaut"
  , "nullable"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
