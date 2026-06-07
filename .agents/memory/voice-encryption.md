---
name: Voice encryption — CJS/ESM interop bug
description: Why libsodium-wrappers silently fails in @discordjs/voice 0.18 and which package to use instead.
---

## The rule
Use `@stablelib/xchacha20poly1305` (not `libsodium-wrappers`) for Discord voice encryption.

**Why:** `@discordjs/voice` 0.18 loads encryption libraries via `await import(libName)` (ESM dynamic import). When importing a CommonJS module like `libsodium-wrappers`, Node.js returns `{ default: module }` — the actual sodium functions are on `lib.default`, not on `lib` directly. The library's loader calls `libs["libsodium-wrappers"](lib)` which does `sodium.crypto_aead_xchacha20poly1305_ietf_encrypt(...)` — that function is `undefined` on the namespace object. The error is swallowed silently in a try/catch, so `methods` stays as `fallbackError`. The dependency report still shows `libsodium-wrappers: 0.8.4` (found) even though encryption doesn't work.

`@stablelib/xchacha20poly1305` is a true ESM module — `await import('@stablelib/xchacha20poly1305')` returns named exports directly on `lib` (including `XChaCha20Poly1305`), so the loader succeeds.

`@noble/ciphers` v2.x does NOT work either — it exports `./chacha.js` in its exports map but `@discordjs/voice` imports `@noble/ciphers/chacha` (no `.js`), causing a "Package subpath not defined" error.

**How to apply:** When the dependency report shows `libsodium-wrappers: X.Y.Z` but voice still fails with "Cannot play audio as no valid encryption package is installed", install `@stablelib/xchacha20poly1305`. Verify with: `node -e "(async()=>{const l=await import('@stablelib/xchacha20poly1305');console.log(typeof l.XChaCha20Poly1305)})()"` — should print `function`.
