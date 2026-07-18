# Parity review: `debian/wine`

## Scope and decision

- Evidence key: `debian/wine`
- Tested commit: `f7b772a72fa8c543cb84f79db0473cf5ad05daf5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29640717432](https://github.com/Yunushan/linux-software-installer/actions/runs/29640717432), artifact digest `sha256:e744fab69651ad0d2adce755e7a65da1191822af6524d44b8b1d1d259140d477`
- Verification report: `docs/evidence-verification/debian-wine.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-008` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:008` | Added WineHQ's Xenial repository and key, enabled i386 on x86_64, and installed `winehq-staging` with recommends. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `wine`; distribution package `wine`
- Package source and release channel: each target's configured signed distribution APT repositories; no WineHQ repository is added
- Verification binaries: `wine`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Imported a key using deprecated `apt-key` and added WineHQ's Xenial staging repository. | Installs the supported distribution `wine` package. | Intent parity: supplies the Wine compatibility layer without reusing an obsolete external channel. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Added i386 on x86_64 and moved the downloaded key into a user-dependent location. | Does not change foreign architectures or write a repository key. | The former architecture and key mutations were implementation details of the obsolete WineHQ route, not the requested compatibility capability. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Relied on an obsolete Xenial staging repository and deprecated global key trust. | Does not add a third-party repository or global key. | The active contract intentionally removes unsupported trust and release-channel side effects. |

## Reviewer conclusion

The source requested a Windows-application compatibility layer, but bound that
request to an obsolete WineHQ staging channel. The active `wine` module is
cleanly and repeatably installed on all declared current targets and verifies
the `wine` binary. It intentionally does not promise the legacy staging build,
foreign-architecture mutation, or repository-key behavior. With no service,
configuration, firewall, credential, or data contract to preserve, `intent`
parity is accurate.
