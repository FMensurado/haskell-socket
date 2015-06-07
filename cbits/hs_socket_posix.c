#include <hs_socket.h>

int hs_setnonblocking(int fd) {
  int flags;

  if (-1 == (flags = fcntl(fd, F_GETFL, 0))) {
        flags = 0;
  }
  return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

int hs_get_last_socket_error(void) {
  return errno;
};