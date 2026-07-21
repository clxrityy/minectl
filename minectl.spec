Name:           minectl
Version:        0.3.0
Release:        1%{?dist}
Summary:        Remote Minecraft server automation for Rocky Linux

License:        MIT
URL:            https://github.com/clxrityy/minectl
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  bash
Requires:       bash, openssh-clients, curl
BuildArch:      noarch

%description
minectl is a command-line tool for deploying and managing multiple Minecraft
servers on Rocky Linux via SSH. Features centralized configuration, systemd
integration, and multi-server support.

%prep
%setup -q

%build
# No compilation needed

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/minectl/lib
mkdir -p %{buildroot}%{_datadir}/minectl/bootstrap
mkdir -p %{buildroot}%{_datadir}/doc/minectl
mkdir -p %{buildroot}%{_sysconfdir}/skel/.minectl

install -m 755 minectl %{buildroot}%{_bindir}/minectl
install -m 755 lib/config.sh %{buildroot}%{_datadir}/minectl/lib/config.sh
install -m 755 bootstrap/bootstrap.sh %{buildroot}%{_datadir}/minectl/bootstrap/bootstrap.sh
install -m 644 config.template %{buildroot}%{_sysconfdir}/skel/.minectl/config.template
install -m 644 README.md %{buildroot}%{_datadir}/doc/minectl/README.md
install -m 644 docs/configuration.md %{buildroot}%{_datadir}/doc/minectl/configuration.md
install -m 644 docs/usage.md %{buildroot}%{_datadir}/doc/minectl/usage.md
install -m 644 docs/architecture.md %{buildroot}%{_datadir}/doc/minectl/architecture.md

%files
%{_bindir}/minectl
%{_datadir}/minectl/lib/config.sh
%{_datadir}/minectl/bootstrap/bootstrap.sh
%doc %{_datadir}/doc/minectl/README.md
%doc %{_datadir}/doc/minectl/configuration.md
%doc %{_datadir}/doc/minectl/usage.md
%doc %{_datadir}/doc/minectl/architecture.md
%config(noreplace) %{_sysconfdir}/skel/.minectl/config.template

%post
# Create user config directory if needed
if [[ ! -d ~/.minectl ]]; then
    mkdir -p ~/.minectl
fi
if [[ ! -f ~/.minectl/config ]]; then
    cp %{_sysconfdir}/skel/.minectl/config.template ~/.minectl/config
    echo "Created ~/.minectl/config - edit CONFIG_DIR before use"
fi

%changelog
* Fri Jan 17 2025 - 0.3.0-1
- Client-side CONFIG_DIR specification
- Centralized server configuration
- Multiple servers per host support
- Systemd integration
- Configuration validation

* Fri Jan 10 2025 - 0.2.0-1
- Hierarchical configuration system
- Per-server configuration files

* Fri Jan 03 2025 - 0.1.0-1
- Initial release
- Basic server deployment and management
- Remote SSH deployment
