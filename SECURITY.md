# Security Policy

## Supported versions

Only the latest tagged release receives security fixes. The M5Stick S3 port is
experimental until physical verification; treat pre-verification builds as
development artifacts.

## Reporting a vulnerability

Please **do not** open a public issue for security problems. Report them
privately to the maintainer via a GitHub security advisory
(Security → Report a vulnerability on the repository), or by email if one is
published. Include:

- the affected firmware version,
- a description of the vulnerability,
- steps to reproduce, and
- any suggested fix.

A maintainer will acknowledge within 5 business days and coordinate a fix and
release.

## Security model notes

The firmware inherits the Hermes Gadget SDK's security model, summarized here;
see the SDK's `docs/architecture.md` for the full detail.

- **Transport:** use `wss://` (with `tls_cert`/`tls_key` on the host) on any
  network you don't trust. Plain `ws://` on a home LAN exposes conversation
  content to anyone on the network.
- **Device identity:** each device holds a random 32-byte key; after enrollment
  it proves possession with an HMAC over a server nonce, so recorded traffic
  can't be replayed and another device can't take over an enrolled id.
- **Authorization:** every device message is authorized by the Hermes gateway
  exactly like a messaging-platform user; pairing is approved on the host.
- **Optional gate:** `GADGET_ACCESS_TOKEN` is a shared secret every device
  presents in `hello`.

The M5PM1 power driver only reads battery/power-source registers and issues a
keyed shutdown command; it does not alter charging or rail configuration.
