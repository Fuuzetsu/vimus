{-# OPTIONS_GHC -fno-warn-unused-do-bind #-}
module WindowLayout (
  WindowColor (MainColor, RulerColor, TabColor, InputColor, StatusColor, PlayStatusColor, SongStatusColor)
, defaultColor
, create
, wchgat
, mvwchgat
, defineColor
) where

import           Control.Monad
import           UI.Curses hiding (wchgat, mvwchgat)
import qualified UI.Curses as Curses

-- ReservedColor (color pair 0) cannot be modified, so we do not use it.
{-# WARNING ReservedColor "Do not use this!" #-}
data WindowColor =
    ReservedColor
  | MainColor
  | RulerColor
  | TabColor
  | InputColor
  | StatusColor
  | PlayStatusColor
  | SongStatusColor
  deriving (Show, Enum, Bounded)

defaultColor :: Color
defaultColor = Color (-1)

defineColor :: WindowColor -> Color -> Color -> IO Status
defineColor color fg bg = init_pair (fromEnum color) fg bg

setWindowColor :: WindowColor -> Window -> IO Status
setWindowColor color window = wbkgd window (color_pair . fromEnum $ color)

wchgat :: Window -> Int -> [Attribute] -> WindowColor -> IO ()
wchgat window n attr color = void $ Curses.wchgat window n attr (fromEnum color)

mvwchgat :: Window -> Int -> Int -> Int -> [Attribute] -> WindowColor -> IO ()
mvwchgat y x window n attr color = void $ Curses.mvwchgat y x window n attr (fromEnum color)

-- | Set given color pair to default/default
resetColor :: WindowColor -> IO ()
resetColor c = defineColor c defaultColor defaultColor >> return ()

-- | Set all color pairs to default/default
resetColors :: IO ()
resetColors = mapM_ resetColor [toEnum 1 .. maxBound]

create :: IO (IO Window, Window, Window, Window, Window, Window, Window)
create = do

  resetColors

  let createMainWindow = do
      (sizeY, _)    <- getmaxyx stdscr
      let mainWinSize = sizeY - 5
      window <- newwin mainWinSize 0 1 0
      setWindowColor MainColor window
      return (window, 0, mainWinSize + 1, mainWinSize + 2, mainWinSize + 3, mainWinSize + 4)

  (mainWindow, pos0, pos1, pos2, pos3, pos4) <- createMainWindow
  tabWindow        <- newwin 1 0 pos0 0
  statusWindow     <- newwin 1 0 pos1 0
  songStatusWindow <- newwin 1 0 pos2 0
  playStatusWindow <- newwin 1 0 pos3 0
  inputWindow      <- newwin 1 0 pos4 0

  setWindowColor TabColor        tabWindow
  setWindowColor InputColor      inputWindow
  setWindowColor StatusColor     statusWindow
  setWindowColor PlayStatusColor playStatusWindow
  setWindowColor SongStatusColor songStatusWindow

  let onResize = do
      (newMainWindow, newPos0, newPos1, newPos2, newPos3, newPos4) <- createMainWindow
      mvwin tabWindow        newPos0 0
      mvwin statusWindow     newPos1 0
      mvwin songStatusWindow newPos2 0
      mvwin playStatusWindow newPos3 0
      mvwin inputWindow      newPos4 0
      wrefresh statusWindow
      wrefresh songStatusWindow
      wrefresh playStatusWindow
      wrefresh inputWindow
      return newMainWindow

  return (onResize, tabWindow, mainWindow, statusWindow, songStatusWindow, playStatusWindow, inputWindow)
