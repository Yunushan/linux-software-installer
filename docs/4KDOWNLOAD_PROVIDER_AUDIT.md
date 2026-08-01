# 4K Download provider audit

Review date: **2026-08-01**

This planning-only review covers the four immutable Ubuntu 16.04 menu rows
whose legacy scripts downloaded a vendor-managed 4K Download artifact:

| Legacy ID | Legacy label | Proposed outcome | Current vendor fact | Admission boundary |
| --- | --- | --- | --- | --- |
| `ubuntu-099` | 4K Video Downloader (64 Bit) | `4k-video-downloader` | The vendor continues to support the original product while offering a separate Plus generation; an upgrade changes which product a license can activate. | Keep `public-artifact` / `conditional-artifact` until a maintained Linux artifact has an immutable version and a verified vendor signature or digest. Do not carry forward a user's legacy key. |
| `ubuntu-100` | 4K Youtube to MP3 (64 Bit) | `4k-youtube-to-mp3` | The vendor documents current Ubuntu 24 support and current releases. | The artifact still needs an exact signed or digest-pinned release and real clean/repeat-install evidence on a maintained target. |
| `ubuntu-102` | 4K Slideshow Maker (64 Bit) | `4k-slideshow-maker` | The product remains named in the vendor's current product catalog, but this review has not established a current supported Linux artifact with durable verification material. | No automated download or provider is admitted; record an exact current artifact and its vendor-authenticated verification material first. |
| `ubuntu-103` | 4K Video to MP3 (64 Bit) | `4k-video-to-mp3` | The vendor sells separate product-specific licenses and distributes activation keys through the purchaser's email. | Preserve user license, billing-email, activation count, service-login and content-access decisions outside the installer; an artifact route still needs exact verification before automation. |

## License and account boundary

4K Download states that each application has its own license key and that keys
are delivered to the purchaser's email. A key is associated with a limited
number of computers, while some product features require a user to authorize a
third-party service account. The installer must never collect, insert, export,
or transfer license keys, billing email addresses, payment information, service
logins, private links, or downloaded media.

The vendor's free tiers do not make its mutable download endpoints, a user-owned
license, or authenticated service access acceptable installation evidence. This
document therefore does **not** change any inventory disposition or claim that
any 4K Download product is supported by the active installer.

## Sources

- [4K Download license and activation FAQ](https://www.4kdownload.com/blog/2022/11/02/licences-and-activations/)
- [4K Video Downloader Plus licensing and account authorization](https://www.4kdownload.com/buy/videodownloader-8?source=4k-video-downloader)
- [4K YouTube to MP3 current product page](https://www.4kdownload.com/products/youtubetomp3-73)
- [4K YouTube to MP3 Ubuntu 24 release note](https://www.4kdownload.com/blog/2026/01/16/4k-youtube-to-mp3-26-0-released/)
