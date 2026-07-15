# Reviewed legacy dispositions

This record captures terminal decisions for legacy installer entries. It is
evidence for the corresponding rows in `docs/legacy-inventory.tsv`; it is not a
claim that every legacy capability is installable in the active project.

Review date: **2026-07-15**

## Blocked critical components

The active installer does not take ownership of kernels, system cryptography,
or remote-login policy. Those components are coupled to distribution security
updates, ABI and crypto policy, boot recovery, SELinux/PAM integration, and
remote access. The legacy scripts offered unmanaged source builds, forced RPM
replacement, direct library links, bootloader rewrites, or authentication-policy
changes. Reproducing those paths would cross the project's safety boundary.

The supported handoff is the distribution vendor's normal update, lifecycle,
and recovery process. Installing ordinary application modules may depend on
these components, but this project will not replace or reconfigure them.

| Legacy IDs | Capability | Rejected legacy behavior | Decision |
|---|---|---|---|
| `rhel-almalinux-8-027-linux-kernel`, `rhel-almalinux-9-009-linux-kernel`, `rhel-centos-7-038-linux-kernel`, `rhel-red-hat-enterprise-linux-8-016-linux-kernel`, `rhel-red-hat-enterprise-linux-9-005-linux-kernel` | Linux kernel | Installs third-party mainline/LTS kernels and, in several variants, rewrites the default GRUB entry or generated boot configuration. | `blocked-safety`; use the distribution's supported kernel update and boot-recovery workflow. |
| `rhel-almalinux-8-033-openssh`, `rhel-almalinux-9-011-openssh`, `rhel-red-hat-enterprise-linux-8-012-openssh`, `rhel-red-hat-enterprise-linux-9-008-openssh` | OpenSSH | Builds or replaces the vendor SSH stack, removes vendor packages in some branches, overwrites PAM/configuration files, and enables root/password login in newer variants. | `blocked-safety`; use vendor OpenSSH packages and an administrator-reviewed access policy. |
| `rhel-almalinux-8-025-openssl`, `rhel-almalinux-9-010-openssl`, `rhel-red-hat-enterprise-linux-8-011-openssl`, `rhel-red-hat-enterprise-linux-9-007-openssl` | OpenSSL | Builds or force-installs non-vendor OpenSSL versions, removes vendor packages in some branches, and creates system library/binary links outside the package manager. | `blocked-safety`; use vendor crypto packages and crypto-policy guidance. |
| `ubuntu-098`, `rhel-almalinux-9-002-grub-customizer`, `rhel-red-hat-enterprise-linux-8-002-grub-customizer`, `rhel-red-hat-enterprise-linux-9-004-grub-customizer` | GRUB Customizer PPA/source build | Adds an obsolete bootloader-management channel or scrapes an unpinned “latest” archive and then performs privileged bootloader changes without a recovery contract. | `blocked-safety`; use vendor-supported GRUB tooling and recovery procedures. |
| `ubuntu-156` | VNC server setup | Creates privileged VNC credentials, starts a root-owned server, opens TCP/5901 to every source, and adds boot persistence without a reviewed authentication, encryption, or firewall policy. | `blocked-safety`; use administrator-managed authenticated remote access. |
| `rhel-red-hat-enterprise-linux-8-041-google-authenticator`, `rhel-red-hat-enterprise-linux-9-024-google-authenticator` | Google Authenticator SSH/PAM setup | Appends `nullok` and `pam_permit` rules directly to SSH PAM policy, rewrites SSH configuration and restarts remote access. | `blocked-safety`; install/authenticate through administrator-reviewed PAM and SSH policy, with recovery access and per-user enrollment. |

## Retired pinned or discontinued products

These decisions retire the *exact legacy product, release, or distribution
channel*. They do not imply that the broader product category is obsolete.
Where a maintained successor exists, it is the documented handoff; the active
installer will not recreate an unsupported pin, unsigned download, or archived
third-party channel.

| Legacy ID | Exact legacy scope | Upstream evidence and handoff | Decision |
|---|---|---|---|
| `ubuntu-001` | PHP 7.3 from an Ubuntu PPA | [PHP lists 7.3 as end-of-life since 6 December 2021](https://www.php.net/eol.php). Use the active `php` module, which follows supported distribution packages instead of pinning 7.3. | `retired` |
| `ubuntu-010` | Apache NetBeans 10 | [Apache identifies older NetBeans releases as unsupported](https://netbeans.apache.org/front/main/download/index.html); 10.0 is retained only in the release archive. Use a current, upstream-supported NetBeans release through its documented channel. | `retired` |
| `ubuntu-013` | Skype desktop client | [Microsoft retired Skype on 5 May 2025](https://support.microsoft.com/en-us/skype/f596c90a-b3b0-42c2-b120-d0630642f1f9) and documents Teams Free as the migration path. | `retired` |
| `ubuntu-039` | MonoDevelop | [MonoDevelop states that it is no longer under active development](https://www.monodevelop.com/download/) and recommends the maintained C# tooling for Visual Studio Code. | `retired` |
| `ubuntu-046` | Aptana Studio 3 binary installer | [The upstream Aptana Studio 3 repository is archived and read-only](https://github.com/aptana/studio3). Use a maintained editor/IDE selected by the user. | `retired` |
| `ubuntu-069` | Adobe Brackets PPA | [Adobe's Brackets repository is archived and read-only](https://github.com/adobe/brackets). Use a maintained editor or a maintained community successor through its own supported channel. | `retired` |
| `ubuntu-075` | Ramme unofficial Instagram client | [The upstream Ramme repository is archived and read-only](https://github.com/terkelg/ramme). Use Instagram's supported web/client surfaces. | `retired` |
| `ubuntu-076` | Atom editor | [GitHub sunset Atom on 15 December 2022](https://github.blog/news-insights/product-news/sunsetting-atom/) and ended security updates and package management. Use a maintained editor. | `retired` |
| `ubuntu-077` | Google Play Music desktop player | [YouTube replaced Google Play Music with YouTube Music by December 2020](https://blog.youtube/news-and-events/youtube-music-will-replace-google-play-music-end-2020/). Use YouTube Music's supported surfaces. | `retired` |
| `ubuntu-105` | Light Table PPA | [The upstream Light Table repository is archived and read-only](https://github.com/LightTable/LightTable). Use a maintained editor/IDE. | `retired` |
| `ubuntu-125` | Pepper Flash Player | [Adobe ended Flash Player support on 31 December 2020 and recommends removal](https://www.adobe.com/products/flashplayer/end-of-life.html). Use modern web standards; no Flash package replacement is provided. | `retired` |
| `ubuntu-081` | Neofetch PPA | [The original Neofetch repository is archived and read-only](https://github.com/dylanaraps/neofetch). Select a maintained system-information tool through a supported distribution or upstream channel. | `retired` |
| `rhel-almalinux-8-018-neofetch`, `rhel-centos-7-018-neofetch` | Neofetch COPR workflow | [The original Neofetch repository is archived and read-only](https://github.com/dylanaraps/neofetch). The legacy third-party repository path is not recreated. | `retired` |
| `ubuntu-115` | Riot PPA/package | [Riot became Element in July 2020](https://element.io/blog/welcome-to-element/). Use Element through its current supported channel. | `retired` |
| `ubuntu-117` | FeedReader PPA | [FeedReader states that it is no longer actively maintained](https://github.com/jangernert/FeedReader) and identifies NewsFlash as its successor. | `retired` |
| `ubuntu-120` | Rambox Community Edition Snap | [Rambox Community Edition is end-of-life, archived, and directs users to current Rambox](https://github.com/ramboxapp/community-edition). | `retired` |
| `ubuntu-126` | ElectronPlayer Snap | [The ElectronPlayer repository is archived and read-only](https://github.com/oscartbeaumont/ElectronPlayer). Use each streaming provider's supported web or client surface. | `retired` |
| `rhel-centos-7-033-jitsi` | Scraped Jitsi Desktop RPM | [Jitsi Desktop is not actively developed and publishes no RPM packages](https://github.com/jitsi/jitsi). Jitsi Meet is a handoff, not feature parity with the old SIP/XMPP desktop client. | `retired` |
| `ubuntu-017` | Oracle VirtualBox 6 and its extension-pack workflow | [Oracle's lifecycle table ended Premier Support for VirtualBox 6.x in December 2023](https://www.oracle.com/au/a/ocom/docs/lifetime-support-policy-oracle-and-sun.pdf). Use a currently supported virtualization release through its documented channel. | `retired` |
| `ubuntu-041` | Unity 2018.3.0f2 pin | [Unity documents that 2018.3 became 2018.4 LTS and that the 2018 LTS support cycle ended in spring 2021](https://unity.com/releases/2019-lts). Use Unity Hub and a supported editor stream under the user's license. | `retired` |
| `ubuntu-063` | Peek GIF recorder PPA | [Peek declares the project deprecated and its repository is archived](https://github.com/phw/peek/blob/main/README.md). Use the active `obs-studio` or `simplescreenrecorder` module according to the recording need. | `retired` |
| `ubuntu-079` | “Pixbuf” menu choice | [`source-defect-002`](legacy-source-defects.tsv) proves that this branch is a duplicate Ubuntu Cleaner installer, not an identifiable Pixbuf product. No invented product is carried forward. | `retired` |
| `ubuntu-101` | 4K Stogram binary | [The vendor discontinued 4K Stogram because it could not ensure reliable operation or account safety and provides no further updates or fixes](https://www.4kdownload.com/buy/stogram). | `retired` |
| `rhel-red-hat-enterprise-linux-8-050-enterprise-search` | Elastic Enterprise Search server | [Elastic states that Enterprise Search is unavailable in Elastic Stack 9.0 and later](https://www.elastic.co/docs/deploy-manage/upgrade/deployment-or-cluster/enterprise-search) and directs operators to migrate to Elasticsearch. | `retired` |

## Reviewed vendor or deployment handoffs

These products remain real and potentially useful, but owning their installation
would require user-bound licensing, authenticated downloads, secret enrollment,
kernel modules, unofficial credential-handling wrappers, privileged maintenance
policy, or a stateful service design outside this package-only installer. The
decision is a documented handoff, not a claim that the product itself is
obsolete.

| Legacy IDs | Scope | Evidence and supported handoff | Decision |
|---|---|---|---|
| `ubuntu-042` | Unreal Engine 4 source build | [Epic requires an Epic account, GitHub account linkage and EULA acceptance for source access](https://dev.epicgames.com/documentation/unreal-engine/downloading-source-code-in-unreal-engine?lang=en-US). Use Epic's authenticated installed-build or source workflow. | `out-of-scope`; the installer will not automate user identity, license acceptance or a very large authenticated toolchain build. |
| `ubuntu-128` | E-tools Snap | [The Snap Store identifies a third-party publisher and a stable build last updated in April 2019](https://snapcraft.io/e-tools). Use maintained editor/developer utilities chosen by the user. | `out-of-scope`; no current upstream/provider contract is available for this project to own. |
| `ubuntu-130` | IrfanView Snap/Wine wrapper | [IrfanView states that it has no native Linux version and documents Wine or a virtual machine as the handoff](https://www.irfanview.com/faq.htm). Use native `gimp`/`xnconvert`-class tooling or the vendor's documented compatibility path. | `out-of-scope`; this installer does not package Windows applications inside community Wine wrappers. |
| `ubuntu-139` | Notepad++ community Snap | [The Snap Store labels the package “Notepad++ (WINE)” and names its community publisher](https://snapcraft.io/notepad-plus-plus). Use the active `geany`, `neovim`, `vim` or `bluefish` module for a native editor. | `out-of-scope`; no upstream-native Linux package is being represented. |
| `rhel-red-hat-enterprise-linux-8-032-opennebula` | OpenNebula cloud deployment | [OpenNebula's current installation process covers a front-end, hypervisors, database and repositories](https://docs.opennebula.io/7.0/software/installation_process/). The legacy script also disables SELinux and package signature checks. | `out-of-scope`; use OpenNebula's reviewed OneDeploy or manual infrastructure workflow. |
| `ubuntu-021`, `rhel-centos-7-027-vmware-workstation-pro` | VMware Workstation Pro bundle | [Broadcom requires a portal login/download, privileged bundle installer and EULA acceptance](https://knowledge.broadcom.com/external/article/387947/installing-vmware-workstation-pro.html). | `out-of-scope`; kernel-module, licensing and authenticated vendor-download ownership stays with VMware's supported workflow. |
| `ubuntu-050` | TeamSpeak 3 client | [TeamSpeak publishes the current Linux client and digest](https://teamspeak.com/en/downloads), while [its terms govern client download and use as a user license](https://www.teamspeak.com/en/terms-and-conditions). | `out-of-scope`; the user completes TeamSpeak's licensed download/onboarding workflow. |
| `ubuntu-123` | Hiri proprietary mail client | [Hiri's download page documents a seven-day trial followed by purchase](https://www.hiri.com/download/), and [access and use are conditional on the user's acceptance of Hiri's terms](https://www.hiri.com/terms/). | `out-of-scope`; this installer will not accept or manage a user's proprietary mail-client license. |
| `ubuntu-131` | Altus WhatsApp wrapper | [Altus identifies itself as an Electron wrapper around WhatsApp Web](https://github.com/amanharwara/altus). | `out-of-scope`; use the supported [WhatsApp Web](https://web.whatsapp.com/) surface rather than a project-installed wrapper entrusted with account access. |
| `ubuntu-158`, `rhel-centos-7-035-electronmail` | ElectronMail community Proton client | [ElectronMail identifies itself as an unofficial Proton Mail client and documents local credential, session and mail storage](https://github.com/vladimiry/ElectronMail). [Proton provides its own Linux and web clients](https://proton.me/support/set-up-proton-mail-linux). | `out-of-scope`; use Proton's supported client instead of a project-installed credential-handling wrapper. |
| `ubuntu-078` | Ubuntu Cleaner | [Ubuntu Cleaner's upstream scope includes clearing private caches and removing packages, old kernels and installers](https://github.com/gerardpuig/ubuntu-cleaner). | `out-of-scope`; destructive cleanup selection, retention and recovery policy remain administrator-owned. |
| `ubuntu-116` | Jitsi Meet self-hosting | [Jitsi's self-hosting guide requires a domain, DNS, TLS certificate, web server and firewall/NAT decisions](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart/). | `out-of-scope`; use Jitsi's operator-reviewed self-hosting workflow or hosted service. |
| `rhel-almalinux-8-040-gocd-server-agent`, `rhel-red-hat-enterprise-linux-8-013-gocd`, `rhel-red-hat-enterprise-linux-9-026-gocd` | GoCD server and agents | [GoCD requires a server plus one or more agents, network reachability and server-side agent registration](https://docs.gocd.org/current/installation/). | `out-of-scope`; CI topology, agent authorization and execution policy belong to the GoCD operator. |
| `rhel-almalinux-8-043-zabbix-server`, `rhel-centos-7-045-zabbix-server`, `rhel-red-hat-enterprise-linux-8-022-zabbix-server`, `rhel-red-hat-enterprise-linux-9-012-zabbix-server` | Zabbix server | [Zabbix's current installation requires server, agent, frontend and database setup](https://www.zabbix.com/documentation/current/en/manual/installation), including web-server, database and SELinux/network choices. | `out-of-scope`; use Zabbix's infrastructure deployment workflow. |
| `rhel-almalinux-8-044-urbackup-server`, `rhel-red-hat-enterprise-linux-8-023-urbackup-server`, `rhel-red-hat-enterprise-linux-9-013-urbackup-server` | UrBackup server | [UrBackup's administration manual requires storage policy, administrator creation, client enrollment, DNS/TLS and network exposure decisions](https://www.urbackup.org/administration_manual.html). | `out-of-scope`; backup retention, credentials, clients, network and restore policy belong to the operator. |
| `rhel-red-hat-enterprise-linux-8-037-graylog` | Graylog server | [Graylog's Red Hat guide deploys MongoDB, Data Node and Graylog with shared secrets, storage, ports and security configuration](https://go2docs.graylog.org/current/downloading_and_installing_graylog/red_hat_installation.htm). | `out-of-scope`; use Graylog's secured log-infrastructure deployment workflow. |
| `rhel-red-hat-enterprise-linux-8-045-elasticsearch`, `rhel-red-hat-enterprise-linux-9-021-elasticsearch` | Elasticsearch service | [Elastic's RPM guide covers TLS, superuser credentials, enrollment, node discovery and cluster topology](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-rpm). | `out-of-scope`; stateful search-cluster ownership remains with the Elastic operator. |
| `rhel-red-hat-enterprise-linux-8-046-kibana`, `rhel-red-hat-enterprise-linux-9-023-kibana` | Kibana service | [Elastic documents Kibana as the UI for an operator-owned Elastic deployment and requires enrollment with Elasticsearch](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-kibana). | `out-of-scope`; use the secured Elastic Stack deployment workflow. |
| `rhel-red-hat-enterprise-linux-8-051-logstash`, `rhel-red-hat-enterprise-linux-9-022-logstash` | Logstash service | [Elastic installs Logstash as a service](https://www.elastic.co/docs/reference/logstash/installing-logstash) whose input, filter and output pipelines are deployment configuration. | `out-of-scope`; pipeline sources, credentials and destinations remain operator-owned. |
| `rhel-red-hat-enterprise-linux-8-052-gitea` | Gitea service | [Gitea's server guide requires a service account, durable data/configuration, database details and secret tokens](https://docs.gitea.com/installation/install-from-binary), with SSH and public URL policy configured by the operator. | `out-of-scope`; use Gitea's reviewed service deployment and backup workflow. |
| `rhel-red-hat-enterprise-linux-8-053-phpmyadmin`, `rhel-red-hat-enterprise-linux-9-020-phpmyadmin` | phpMyAdmin web application | [phpMyAdmin's setup guide covers web-server access control, database authentication and TLS choices](https://docs.phpmyadmin.net/en/latest/setup.html). | `out-of-scope`; database-administration exposure and credentials belong to the database operator. |
| `rhel-red-hat-enterprise-linux-8-056-passbolt-ce`, `rhel-red-hat-enterprise-linux-9-028-passbolt-ce` | Passbolt CE credential service | [Passbolt's self-hosted installation requires a database, web server, TLS certificate and server GPG keys](https://www.passbolt.com/docs/hosting/install/ce/from-source/). | `out-of-scope`; credential-service domain, keys, mail, database and recovery policy stay with the Passbolt operator. |
| `rhel-red-hat-enterprise-linux-8-055-wazuh-agent`, `rhel-red-hat-enterprise-linux-8-054-wazuh-server`, `rhel-red-hat-enterprise-linux-9-019-wazuh-server` | Wazuh agent/SIEM deployment | [Wazuh's current quickstart owns server, indexer, dashboard, certificates and generated credentials](https://documentation.wazuh.com/current/quickstart.html). The old scripts instead hard-code a manager address or fixed `admin` secrets and use `curl -k`. | `out-of-scope`; use Wazuh's deployment and enrollment workflow with administrator-managed topology, certificates and secrets. |

This review closes 84 of the 355 immutable legacy rows: 20 through a permanent
safety rejection, 25 through retirement of an unsupported legacy scope and 39
through a reviewed external handoff. The remaining 271 rows stay non-terminal
as 142 active-module candidates and 129 third-party provider gaps until their
replacement or disposition has evidence that satisfies `docs/REPLACEMENT.md`.
The proposed next route for each of those 129 gaps is tracked without changing
its status in [`PROVIDER_BACKLOG.md`](PROVIDER_BACKLOG.md).
