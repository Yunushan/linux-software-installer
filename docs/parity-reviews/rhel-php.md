# Pre-admission parity review: `rhel/php`

## Scope and status

- Evidence key: `rhel/php`
- Container evidence: `docs/evidence-verification/rhel-php.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**.

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-almalinux-8-001-php` | `legacy/rhel-family/AlmaLinux-8/scripts/1-Php.sh#script` | Added EPEL and Remi, then selected PHP 5.6–8.1 streams. |
| `rhel-almalinux-9-001-php` | `legacy/rhel-family/AlmaLinux-9/scripts/1-Php.sh#script` | Added Remi, then selected PHP 7.4–8.2 packages. |
| `rhel-centos-6-001-php` | `legacy/rhel-family/Centos-6/scripts/1-Php.sh#script` | Replaced Webtatic with IUS PHP 7.1 packages. |
| `rhel-centos-7-001-php` | `legacy/rhel-family/Centos-7/scripts/1-Php.sh#script` | Added EPEL and Remi, then selected PHP 5.4–8.1 streams. |
| `rhel-red-hat-enterprise-linux-8-001-php` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/1-Php.sh#script` | Added Remi and selected PHP 7.2–8.1 module streams. |
| `rhel-red-hat-enterprise-linux-9-001-php` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-9/scripts/1-Php.sh#script` | Offered distribution PHP or Remi PHP 7.4–8.2 packages. |

## Active replacement contract and boundary

- Target cells: `alma-9-8`, `rocky-9-8`; packages `php-cli`, `php-fpm`, `php-mysqlnd`, `php-pgsql`; verified binary `php`; service `php-fpm`.
- The active module uses configured signed DNF repositories, does not add external repositories or select obsolete streams, and does not explicitly activate PHP-FPM by default.
- Runtime version, FPM pools, socket/listener configuration, credentials, and web-server coupling remain administrator decisions. Promotion needs accepted VM evidence for `php-fpm` lifecycle.
