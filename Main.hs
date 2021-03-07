{-# LANGUAGE DataKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import Control.Monad.Reader
import qualified Data.ByteString.Lazy as BS
import Data.List as List
import Network.HTTP.Media as Media ((//), (/:))
import qualified Network.HTTP.Req as Req
import qualified Network.Wai.Handler.Warp as Warp
import Network.Wai.Middleware.Static
import Servant
import System.IO.Unsafe (unsafePerformIO)
import qualified Text.HTML.TagSoup as TagSoup
import qualified Text.Printf as Printf

data HTML = HTML

newtype RawHTML = RawHTML {unRaw :: BS.ByteString}

instance Accept HTML where
  contentType _ = "text" // "html" /: ("charset", "utf-8")

instance MimeRender HTML RawHTML where
  mimeRender _ = unRaw

type Site = Get '[HTML] RawHTML

type WebsiteM = ReaderT [String] Handler

runWebsiteM :: [String] -> WebsiteM a -> Handler a
runWebsiteM = flip runReaderT

mkTags :: BS.ByteString -> BS.ByteString -> BS.ByteString -> [TagSoup.Tag BS.ByteString]
mkTags title image url =
  List.concatMap
    TagSoup.parseTags
    [ meta "og:title" title,
      meta "og:image" image,
      meta "og:url" url
    ]
  where
    meta property content =
      "<meta property=\"" <> property <> "\" content=\"" <> content <> "\"/>"

injectTags ::
  BS.ByteString ->
  BS.ByteString ->
  BS.ByteString ->
  BS.ByteString ->
  [TagSoup.Tag BS.ByteString]
injectTags title image url og_ =
  let og = TagSoup.parseTags og_
      st = List.takeWhile (not . TagSoup.isTagCloseName "head") og
      en = List.dropWhile (not . TagSoup.isTagCloseName "head") og
   in (st ++ mkTags title image url ++ en)

site :: ServerT Site WebsiteM
site = do
  index <- liftIO $ do
    Req.runReq Req.defaultHttpConfig $
      Req.responseBody <$> Req.req
        Req.GET
        (Req.http "site-frontend" Req./: "static" Req./: "index.html")
        Req.NoReqBody
        Req.lbsResponse
        (Req.port 4000)
  return $
    RawHTML $
      TagSoup.renderTags $
        injectTags
          "PureFunctor"
          "https://avatars.githubusercontent.com/u/66708316"
          "localhost"
          index

main :: IO ()
main = do
  let server = hoistServer (Proxy :: Proxy Site) (runWebsiteM ["Haskell", "Python"]) site
  Warp.run 3000 (static (serve (Proxy :: Proxy Site) server))
