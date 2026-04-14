%global __python /opt/rh/rh-python36/root/usr/bin/python3

Name:           cache-api
Version:        1.0.0
Release:        1%{?dist}
Summary:        Flask cache proxy API
License:        MIT
BuildArch:      noarch

Requires:       rh-python36
Requires:       bash
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

Source0:        cache-api.py
Source1:        config.yaml
Source2:        cache-api.service
Source3:        requirements.txt

%description
Flask cache proxy API service with Redis caching layer.

%prep

%build

%install
mkdir -p %{buildroot}/opt/cache-api
mkdir -p %{buildroot}/etc/cache-api
mkdir -p %{buildroot}%{_unitdir}

install -m 0755 %{SOURCE0} %{buildroot}/opt/cache-api/cache-api.py
install -m 0644 %{SOURCE1} %{buildroot}/etc/cache-api/config.yaml
install -m 0644 %{SOURCE2} %{buildroot}%{_unitdir}/cache-api.service
install -m 0644 %{SOURCE3} %{buildroot}/opt/cache-api/requirements.txt

%post
/bin/systemctl daemon-reload >/dev/null 2>&1 || :
if [ ! -d /opt/cache-api/venv ]; then
  /usr/bin/bash -lc 'source /opt/rh/rh-python36/enable && python3 -m venv /opt/cache-api/venv'
fi
/usr/bin/bash -lc 'source /opt/rh/rh-python36/enable && /opt/cache-api/venv/bin/pip install --upgrade pip'
/usr/bin/bash -lc 'source /opt/rh/rh-python36/enable && /opt/cache-api/venv/bin/pip install -r /opt/cache-api/requirements.txt'
/bin/systemctl enable cache-api.service >/dev/null 2>&1 || :

%preun
if [ $1 -eq 0 ]; then
  /bin/systemctl --no-reload disable cache-api.service >/dev/null 2>&1 || :
  /bin/systemctl stop cache-api.service >/dev/null 2>&1 || :
fi

%postun
/bin/systemctl daemon-reload >/dev/null 2>&1 || :

%files
/opt/cache-api/cache-api.py
/opt/cache-api/requirements.txt
/etc/cache-api/config.yaml
%{_unitdir}/cache-api.service
%dir /opt/cache-api/__pycache__
/opt/cache-api/__pycache__/cache-api*.pyc

%changelog
* Sun Mar 29 2026 DevOps Student <student@example.com> - 1.0.0-1
- Initial package
