module System.Socket.Internal.Platform where

import Control.Exception
import Control.Monad ( join, void, unless )
import Control.Concurrent.MVar
import Control.Concurrent ( threadWaitWrite )
import Foreign.Ptr
import Foreign.C.Types
import Foreign.C.String
import System.Posix.Types ( Fd(..) )
import System.Socket.Internal.Message
import System.Socket.Internal.Exception
import Control.Exception ( throwIO )
import GHC.Event

#include "hs_socket.h"

threadWait' :: Exception e => Event -> ((Fd -> IO FdKey) -> IO FdKey) -> e -> IO ()
threadWait' evt withFd e = do
  mmgr  <- getSystemEventManager
  case mmgr of
    Nothing -> error "threadWait': requires threaded RTS."
    Just mgr -> do
      mevt <- newEmptyMVar
      bracketOnError
        ( withFd $ \fd->
            registerFd mgr (\_ -> putMVar mevt) fd evt OneShot
        )
        ( void . unregisterFd_ mgr )
        ( const $ do
            evt' <- takeMVar mevt
            unless (evt' == evt) (throwIO e)
        )

unsafeSocketWaitRead :: MVar Fd -> Int -> IO ()
unsafeSocketWaitRead mfd _ = do
  threadWait' evtRead (withMVar mfd) eBadFileDescriptor

unsafeSocketWaitWrite :: MVar Fd -> Int -> IO ()
unsafeSocketWaitWrite mfd _ = do
  threadWait' evtWrite (withMVar mfd) eBadFileDescriptor

unsafeSocketWaitConnected :: Fd -> IO ()
unsafeSocketWaitConnected = do
  threadWaitWrite

type CSSize
   = CInt

foreign import ccall unsafe "hs_socket"
  c_socket  :: CInt -> CInt -> CInt -> Ptr CInt -> IO Fd

foreign import ccall unsafe "hs_close"
  c_close   :: Fd -> Ptr CInt -> IO CInt

foreign import ccall unsafe "hs_bind"
  c_bind    :: Fd -> Ptr a -> CInt -> Ptr CInt -> IO CInt

foreign import ccall unsafe "hs_connect"
  c_connect :: Fd -> Ptr a -> CInt -> Ptr CInt -> IO CInt

foreign import ccall unsafe "hs_accept"
  c_accept  :: Fd -> Ptr a -> Ptr CInt -> Ptr CInt -> IO Fd

foreign import ccall unsafe "hs_listen"
  c_listen  :: Fd -> CInt -> Ptr CInt -> IO CInt

foreign import ccall unsafe "hs_send"
  c_send    :: Fd -> Ptr a -> CSize -> MessageFlags -> Ptr CInt -> IO CSSize

foreign import ccall unsafe "hs_sendto"
  c_sendto  :: Fd -> Ptr a -> CSize -> MessageFlags -> Ptr b -> CInt -> Ptr CInt -> IO CSSize

foreign import ccall unsafe "hs_recv"
  c_recv    :: Fd -> Ptr a -> CSize -> MessageFlags -> Ptr CInt -> IO CSSize

foreign import ccall unsafe "hs_recvfrom"
  c_recvfrom :: Fd -> Ptr a -> CSize -> MessageFlags -> Ptr b -> Ptr CInt -> Ptr CInt -> IO CSSize

foreign import ccall unsafe "hs_getsockopt"
  c_getsockopt  :: Fd -> CInt -> CInt -> Ptr a -> Ptr CInt -> Ptr CInt -> IO CInt

foreign import ccall unsafe "hs_setsockopt"
  c_setsockopt  :: Fd -> CInt -> CInt -> Ptr a -> CInt -> Ptr CInt -> IO CInt

foreign import ccall unsafe "memset"
  c_memset       :: Ptr a -> CInt -> CSize -> IO ()

foreign import ccall safe "getaddrinfo"
  c_getaddrinfo  :: CString -> CString -> Ptr a -> Ptr (Ptr a) -> IO CInt

foreign import ccall unsafe "freeaddrinfo"
  c_freeaddrinfo :: Ptr a -> IO ()

foreign import ccall safe "getnameinfo"
  c_getnameinfo  :: Ptr a -> CInt -> CString -> CInt -> CString -> CInt -> CInt -> IO CInt

foreign import ccall unsafe "gai_strerror"
  c_gai_strerror  :: CInt -> IO CString
