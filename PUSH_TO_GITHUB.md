# Push this repository to GitHub

The project is initialized on the `main` branch with an initial commit and no
remote. Create an empty public repository named `linux-software-installer`
under the `Yunushan` account. Do not add a README, license or `.gitignore` from
the GitHub form because those files already exist here.

Then run:

```bash
cd linux-software-installer
git remote add origin https://github.com/Yunushan/linux-software-installer.git
git push -u origin main
```

Optional release tag:

```bash
git tag -a v1.0.0 -m "Linux Software Installer 1.0.0"
git push origin v1.0.0
```

Recommended GitHub repository description:

> Modular, distro-aware Bash software installer for Debian/Ubuntu and RHEL-compatible Linux systems.

Recommended topics:

```text
linux bash installer automation ubuntu debian rhel rocky-linux almalinux
centos sysadmin devops apt dnf open-source
```

After the first push, enable:

- branch protection for `main`;
- required `Lint and test` and `Container smoke` checks;
- private vulnerability reporting;
- Dependabot pull requests for GitHub Actions.
