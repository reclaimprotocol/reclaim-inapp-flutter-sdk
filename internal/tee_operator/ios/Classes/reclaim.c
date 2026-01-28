// Relative import to be able to reuse the C sources.
// See the comment in ../{projectName}}.podspec for more information.
// #include "../../src/reclaim.c"

#include "binding.h"

// We only need to reference at least one symbol from the static library
// so the linker keeps the object code. Avoid including vendor headers
// by declaring the symbol signature we need.
extern char* reclaim_get_version(void);
extern int set_log_callback(void* callback);
extern void clear_log_callback(void);

void reclaim_enforce_binding(void) {
  // Call into the library (result ignored) to force-link the archive.
  (void)reclaim_get_version();
  (void)set_log_callback(0);
  (void)clear_log_callback();
}
