#ifndef ORONBOX_NETWORK_H
#define ORONBOX_NETWORK_H

#include <stddef.h>
#include <stdint.h>

#ifdef _WIN32
#define OB_NETWORK_API __declspec(dllimport)
#else
#define OB_NETWORK_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define OB_NETWORK_ABI_VERSION 1u

enum ob_network_status {
  OB_NETWORK_OK = 0,
  OB_NETWORK_NO_EVENT = 1,
  OB_NETWORK_INVALID_ARGUMENT = -1,
  OB_NETWORK_NOT_FOUND = -2,
  OB_NETWORK_BUFFER_TOO_SMALL = -3,
  OB_NETWORK_INTERNAL = -4,
};

enum ob_network_event_kind {
  OB_NETWORK_EVENT_PACKET = 1,
  OB_NETWORK_EVENT_STATE = 2,
  OB_NETWORK_EVENT_STATISTICS = 3,
  OB_NETWORK_EVENT_WARNING = 4,
};

typedef void (*ob_network_wake_callback)(uint64_t handle);

/* Pass NULL only for hosts that provide their own event delivery mechanism. */

typedef struct ob_network_config {
  uint32_t abi_version;
  uint16_t mtu;
  uint16_t reserved;
  uint32_t ingress_capacity;
  uint32_t stack_capacity;
  uint32_t outbound_capacity;
  uint32_t meter_window_ms;
  uint32_t statistics_interval_ms;
  const char *capture_path;
} ob_network_config;

typedef struct ob_network_snapshot {
  uint32_t abi_version;
  uint8_t active;
  uint8_t reserved[3];
  uint32_t active_sessions;
  uint64_t bytes_from_device;
  uint64_t bytes_to_device;
  uint64_t dropped_packets;
} ob_network_snapshot;

OB_NETWORK_API uint32_t ob_network_abi_version(void);
OB_NETWORK_API int32_t ob_network_open(const ob_network_config *config,
                                       ob_network_wake_callback callback,
                                       uint64_t *out_handle);
OB_NETWORK_API int32_t ob_network_push(uint64_t handle, const uint8_t *data,
                                       size_t length);
OB_NETWORK_API int32_t ob_network_event_peek(uint64_t handle,
                                             uint32_t *out_kind,
                                             size_t *out_length);
OB_NETWORK_API int32_t ob_network_event_read(uint64_t handle, uint8_t *buffer,
                                             size_t capacity,
                                             uint32_t *out_kind,
                                             size_t *out_length);
OB_NETWORK_API int32_t
ob_network_get_snapshot(uint64_t handle, ob_network_snapshot *out_snapshot);
OB_NETWORK_API int32_t ob_network_close(uint64_t handle);
OB_NETWORK_API const char *ob_network_last_error(void);

#ifdef __cplusplus
}
#endif

#endif
