module Potoki.Prelude
( 
  module Exports,
  ioChunkSize,
  textString,
)
where

-- base
-------------------------
import Data.Functor.Compose as Exports
import System.IO as Exports
import Control.Arrow as Exports (first, second)

-- base-prelude
-------------------------
import BasePrelude as Exports hiding (first, second)

-- profunctors
-------------------------
import Data.Profunctor.Unsafe as Exports
import Data.Profunctor.Choice as Exports
import Data.Profunctor.Strong as Exports

-- text
-------------------------
import Data.Text as Exports (Text)

-- bytestring
-------------------------
import Data.ByteString as Exports (ByteString)

-- unordered-containers
-------------------------
import Data.HashMap.Strict as Exports (HashMap)

-- vector
-------------------------
import Data.Vector as Exports (Vector)

-- hashable
-------------------------
import Data.Hashable as Exports (Hashable)

--------------------------------------------------------------------------------

import qualified Data.Text as A

{-# NOINLINE ioChunkSize #-}
ioChunkSize :: Int
ioChunkSize =
  shiftL 2 12

textString :: Text -> String
textString =
  A.unpack
