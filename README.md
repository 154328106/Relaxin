# Relaxin

Relaxin is a jailbreak for iOS and iPadOS 16.5.1–17.3.1 on devices with RootHide architecture.

This repository is an open-source snapshot for public audit. It does not accept issues, pull requests, or other external contributions, and it will not receive further open-source updates.

Build and package locally with the Makefile.

## Development

The repository uses the top-level `Makefile` for all build and packaging workflows.

```bash
make build               # Build the iOS app (unsigned)
make ipa                 # Build and package an unsigned IPA
make tipa                # Build and package a no-sandbox TIPA
make hybrid-048-tipa     # Use this UI with an audited upstream 0.4.8 app
make hybrid-049-tipa     # Put FlatGlass over the audited upstream 0.4.9 core
make bootstrap-resources # Download, ad-hoc sign, and stage the RootHide bootstrap
make check               # Validate the zstd integration contract
make test-host           # Run the host-side trust-cache model and fault-injection tests
make format              # Run Swift and C-family formatters (write)
make format-lint         # Run Swift and C-family formatters in check mode
make scan-license        # Refresh Relaxin/Resources/Licenses.txt from Vendor
make clean               # Remove derived data and generated BaseBin resources
```

### Relaxin 0.4.8 or 0.4.9 core with this UI

The repository does not redistribute the closed-source 0.4.8 or 0.4.9 binaries. If you
have the upstream app bundle, the hybrid packager starts from that bundle and
replaces only the main executable, optional Xcode Debug support dylibs,
compiled asset catalog, Metal library, and icons. The upstream localizations
and every core file remain intact:

```bash
make hybrid-048-tipa \
    UPSTREAM_048_APP=/path/to/Relaxin-v0.4.8/Payload/Relaxin.app

make hybrid-049-tipa \
    UPSTREAM_049_APP=/path/to/Relaxin-v0.4.9/Payload/Relaxin.app
```

Each version-specific packager pins the audited `RelaxinEngine`, `basebin.tar`, and `basebin.tc`
hashes and verifies that all non-UI files remain unchanged. The resulting file
is written to `build/Artifacts/Relaxin-0.4.8-ui.tipa`.

## License

Relaxin is licensed under the MIT License. See `LICENSE` for details.

## Credits

Relaxin is an OwnGoal Studio project built by the following members. Relaxin could not have been made alive without any of them.

- [@Lakr233](https://x.com/Lakr233)
- [@0x88FFA357](https://x.com/0x88FFA357)
- [@82Flex](https://x.com/82Flex)
- [@roothideDev](https://x.com/roothideDev)
- [@pattern_F_](https://x.com/pattern_F_)

Relaxin also uses external software and binaries during the jailbreak; refer to the Software License section inside the app.
