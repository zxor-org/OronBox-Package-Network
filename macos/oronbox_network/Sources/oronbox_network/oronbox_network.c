#include "oronbox_network.h"

typedef uint32_t (*OronBoxNetworkAbiVersion)(void);

extern uint32_t ob_network_abi_version(void);

__attribute__((used))
static OronBoxNetworkAbiVersion const oronbox_network_link_anchor =
    ob_network_abi_version;

void oronbox_network_flutter_plugin_anchor(void) {
  (void)oronbox_network_link_anchor;
}
