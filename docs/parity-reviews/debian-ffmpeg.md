# Parity review: `debian/ffmpeg`

## Scope and decision

- Evidence key: `debian/ffmpeg`
- Tested commit: `f7b772a72fa8c543cb84f79db0473cf5ad05daf5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29640717432](https://github.com/Yunushan/linux-software-installer/actions/runs/29640717432), artifact digest `sha256:e744fab69651ad0d2adce755e7a65da1191822af6524d44b8b1d1d259140d477`
- Verification report: `docs/evidence-verification/debian-ffmpeg.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-006` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:006` | Added `ppa:jonathonf/ffmpeg-4`, refreshed APT, then installed `ffmpeg`. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `ffmpeg`; distribution package `ffmpeg`
- Package source and release channel: each target's configured signed distribution APT repositories; no PPA is added
- Verification binaries: `ffmpeg`, `ffprobe`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added the unpinned `jonathonf/ffmpeg-4` PPA and refreshed its metadata. | Installs the maintained distribution `ffmpeg` package from the target image's configured APT sources. | Intent parity: provides FFmpeg without adding an unsupported third-party repository. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration files were written. | No configuration files are written. | None. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added an external PPA whose support and package provenance are no longer part of the active contract. | Does not add a PPA. | The active installer preserves the requested capability while removing the unreviewed repository side effect. |

## Reviewer conclusion

The preserved source is an FFmpeg installation request, not a requirement to
retain a specific obsolete PPA. The accepted artifact proves clean installation
and repeat installation of the active `ffmpeg` package on every declared
Debian-family target cell, including the `ffmpeg` and `ffprobe` verification
binaries. No service, configuration, firewall, credential, or data behavior is
lost. The different package channel is an intentional safety improvement, so
`intent` parity is the accurate decision.
