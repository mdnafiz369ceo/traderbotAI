---
name: Voice state machine — do not call configureNetworking() manually
description: How @discordjs/voice 0.18 auto-reconnects and why manual configureNetworking() breaks it.
---

## The rule
Never call `connection.configureNetworking()` manually from userland code.

**Why:** When a voice WebSocket closes (while in UdpHandshaking or SelectingProtocol state), the library's `onNetworkingClose()` handler transitions VoiceConnection back to `Signalling` and sends a new `VOICE_STATE_UPDATE` to the Discord gateway. Discord responds with fresh `VOICE_STATE_UPDATE` + `VOICE_SERVER_UPDATE` packets. The library's `addServerPacket()` handler receives `VOICE_SERVER_UPDATE` and automatically calls `configureNetworking()`, which creates a new `Networking` instance. If userland code also calls `configureNetworking()` at this point (e.g. after an `entersState` timeout), it creates a SECOND Networking instance that races the first — both try to connect to the same voice server session, causing interference and continued cycling.

**The connecting→signalling cycle** means: UDP IP discovery completed (or timed out) → WebSocket closed → library auto-retries. This is normal retry behavior. The library's internal `rejoinAttempts` counter tracks these.

**How to apply:** In the `stateChange` handler, react to `Signalling` by counting cycles and giving up after too many (e.g. 10). Do NOT call `configureNetworking()` or spawn an `entersState(Ready)` promise that outlives a single state transition — the promise accumulates across cycles and creates multiple concurrent waiters.

Correct pattern:
```js
let signallingCycles = 0;
connection.on('stateChange', async (old, next) => {
  if (next.status === VoiceConnectionStatus.Signalling) {
    if (++signallingCycles > 10) connection.destroy();
  }
  if (next.status === VoiceConnectionStatus.Ready) {
    signallingCycles = 0; // reset on success
    // setup...
  }
});
```
