module System.Socket.Internal
  ( Socket (..)
  -- * FFI
  , c_socket
  , c_bind
  , c_listen
  , c_accept
  , c_connect
  , c_send
  , c_sendto
  , c_recv
  , c_recvfrom
  , c_close
  , c_getsockopt
  -- * SocketException
  , SocketException (..)
  ) where

import Control.Concurrent.MVar

import Foreign.Ptr
import Foreign.C.Types

import System.Posix.Types ( Fd(..) )

import System.Socket.Internal.Exception

-- | A generic socket type. Also see `socket` for details.
--
--   The socket is just an `Control.Concurrent.MVar.MVar`-wrapped file descriptor.
--   It is exposed in order to make this library easily extensible, but it is
--   usually not necessary nor advised to work directly on the file descriptor.
--   If you do, the following rules must be obeyed:
--
--   - Make sure not to deadlock. Use `Control.Concurrent.MVar.withMVar` or similar.
--   - The lock __must not__ be held during a blocking call. This would make it impossible
--     to send and receive simultaneously or to close the socket.
--   - The lock __must__ be held when calling operations that use the file descriptor.
--     Otherwise the socket might get closed or even reused by another
--     thread/capability which might result in reading from or writing
--     totally different connection. This is a security nightmare!
--   - The socket is non-blocking and all the code relies on that assumption.
--     You need to use GHC's eventing mechanism primitives to block until
--     something happens. The former rules forbid to use `GHC.Conc.threadWaitRead` as it
--     does not seperate between registering the file descriptor (for which
--     the lock __must__ be held) and the actual waiting (for which you must
--     __not__ hold the lock).
--     Also see [this](https://mail.haskell.org/pipermail/haskell-cafe/2014-September/115823.html)
--     thread and read the library code to see how the problem is currently circumvented.
newtype Socket d t p
      = Socket (MVar Fd)

-------------------------------------------------------------------------------
-- FFI
-------------------------------------------------------------------------------

foreign import ccall unsafe "sys/socket.h socket"
  c_socket  :: CInt -> CInt -> CInt -> IO Fd

foreign import ccall unsafe "unistd.h close"
  c_close   :: Fd -> IO CInt

foreign import ccall unsafe "sys/socket.h bind"
  c_bind    :: Fd -> Ptr a -> Int -> IO CInt

foreign import ccall unsafe "sys/socket.h connect"
  c_connect :: Fd -> Ptr a -> Int -> IO CInt

foreign import ccall unsafe "sys/socket.h accept"
  c_accept  :: Fd -> Ptr a -> Ptr Int -> IO Fd

foreign import ccall unsafe "sys/socket.h listen"
  c_listen  :: Fd -> Int -> IO CInt

foreign import ccall unsafe "sys/socket.h send"
  c_send    :: Fd -> Ptr CChar -> Int -> Int -> IO Int

foreign import ccall unsafe "sys/socket.h sendto"
  c_sendto  :: Fd -> Ptr CChar -> Int -> Int -> Ptr CChar -> Int -> IO Int

foreign import ccall unsafe "sys/socket.h recv"
  c_recv    :: Fd -> Ptr CChar -> Int -> Int -> IO Int

foreign import ccall unsafe "sys/socket.h recvfrom"
  c_recvfrom :: Fd -> Ptr CChar -> Int -> Int -> Ptr CChar -> Ptr Int -> IO Int

foreign import ccall unsafe "sys/socket.h getsockopt"
  c_getsockopt  :: Fd -> CInt -> CInt -> Ptr a -> Ptr Int -> IO CInt