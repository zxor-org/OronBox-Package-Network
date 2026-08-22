# OronBox Network ABI

The public native boundary is the versioned C ABI declared in [`include/oronbox_network.h`](../include/oronbox_network.h)

## Ownership

- `ob_network_open` creates a session and returns an opaque non-zero handle
- The caller owns the handle and must call `ob_network_close` exactly once
- Buffers passed to `ob_network_push` are copied before the function returns
- Event payloads remain owned by the native session until `ob_network_event_read` copies and removes them
- The pointer returned by `ob_network_last_error` is thread-local and remains valid until the next ABI call on that thread

## Event delivery

The wake callback is a notification only. It may run on a native runtime thread and must not perform blocking work or call back into the session directly

After a wake, the host drains the queue with `ob_network_event_peek` and `ob_network_event_read` until `OB_NETWORK_NO_EVENT` is returned. Dart uses `NativeCallable.listener`, so native runtime threads only enqueue isolate messages while all FFI reads stay on the Dart isolate

The Dart host owns one wake callback for the lifetime of its isolate and routes
wakes by session handle. Closing an individual session unregisters its handle but
does not close the `NativeCallable`. This makes a wake already queued on the Dart
isolate harmless after the native session has stopped.

Native integration tests may set `ORONBOX_NETWORK_LIBRARY` to an absolute
dynamic-library path. Packaged applications leave it unset and use the normal
platform library name.

Packet events contain raw IPv4 packets that the host sends back to the Xiaomi protocol network channel. Statistics events contain UTF-8 JSON. State and warning events contain UTF-8 text

## Compatibility

Both `ob_network_abi_version()` and the `abi_version` fields currently return `1`. A caller must reject a library with a different major ABI version

Struct fields may only be appended in a future compatible ABI. Existing field order, width, signedness, and function signatures are stable for ABI version 1
