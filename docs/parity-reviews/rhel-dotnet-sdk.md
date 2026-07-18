# Parity review: `rhel/dotnet-sdk`

## Scope and decision

- Evidence key: `rhel/dotnet-sdk`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/rhel-dotnet-sdk.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-032-net-sdk` | `legacy/rhel-family/AlmaLinux-8/scripts/32-.Net-Sdk.sh` | Selected .NET SDK 2.1–6.0 after removing installed SDKs. | `implemented` |
| `rhel-centos-7-043-net-sdk` | `legacy/rhel-family/Centos-7/scripts/43-.Net-Sdk.sh` | Added the Microsoft repository RPM, selected .NET SDK 2.1–6.0, and removed installed SDKs. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and package: `dotnet-sdk`; `dotnet-sdk-10.0`
- Package source and release channel: configured signed RHEL-family AppStream repositories; no external Microsoft repository RPM is added
- Verification binary: `dotnet`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Selected obsolete SDK packages; CentOS 7 installed a Microsoft repository RPM. | Installs the maintained .NET 10 AppStream SDK. | Preserves the development-kit outcome without changing repository trust. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | The CentOS 7 route installed a persistent repository definition. | No repository configuration is written. | Keeps distribution repository policy under operator control. |
| Firewall/network exposure | No firewall or listener action; CentOS 7 fetched an external repository RPM. | Package-manager network access only during installation. | No added listener or external setup RPM. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | Each route broadly removed `dotnet*` packages before installation. | Does not remove existing SDKs. | Avoids destructive SDK switching. |
| Unsupported or unsafe legacy side effects | EOL SDK selection, external repository mutation, and broad package removal. | None of those are retained. | The active contract is deterministic and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies the supported .NET 10
SDK on both RHEL-family targets. It safely replaces the useful SDK-installation intent
of both legacy scripts; `intent` parity is accurate.
