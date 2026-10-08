# OpenSSL runtime

The separate, unmodified `libcrypto-3-x64.dll` and `libssl-3-x64.dll` report
`OpenSSL 3.5.8 25 Aug 2026`. They were built through the application's pinned
vcpkg dependencies. Per-file hashes and app/library commits are in the installed
`SHA256SUMS.txt` and `NATIVE-BUILD.json`. The builder preserves vcpkg's full
Apache 2.0 text as `openssl-copyright.txt`.

Copyright notices from the [exact upstream release README](https://github.com/openssl/openssl/blob/openssl-3.5.8/README.md):

Copyright (c) 1998-2026 The OpenSSL Project Authors

Copyright (c) 1995-1998 Eric A. Young, Tim J. Hudson

All rights reserved.

Source: <https://github.com/openssl/openssl/tree/openssl-3.5.8>.
Build instructions: `INSTALL.md` and `NOTES-WINDOWS.md` in that release;
the bridge's native CI workflow records the vcpkg build and deployment steps.
The OpenSSL Apache 2.0 licence governs these libraries separately from MIT and LGPL.
