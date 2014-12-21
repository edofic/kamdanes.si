{-# LANGUAGE OverloadedStrings #-}

import Control.Monad.IO.Class  (liftIO)
import Data.Aeson (object, (.=))
import qualified Database.Persist as P
import qualified Database.Persist.Postgresql as Postgresql
import qualified Database.Persist.Sql as Sql

import Network.Wai.Middleware.RequestLogger
import Network.Wai.Middleware.Static
import Web.Scotty

import Models
import Util


app :: ScottyM ()
app = do
  get "/events"
    events
  get "/"
    root
  notFound $ do
    json ("404 Not Found" :: String)

root :: ActionM ()
root = do
  file "./static/index.html"

-- TODO: get events in corrent time span
events :: ActionM ()
events = do
  connStr <- liftIO $ getOption "kamdanes.connstr"
  events <- liftIO $ runDB connStr $ P.selectList [] [ P.Asc EventTime ]
  json $ object [ "events" .= events ] 

main = scotty 3000 $ do
  connStr <- liftIO $ getOption "kamdanes.connstr"
  liftIO $ runDB connStr $ Postgresql.runMigration migrateAll
  middleware logStdoutDev
  middleware $ staticPolicy (noDots >-> hasPrefix "static/")
  app