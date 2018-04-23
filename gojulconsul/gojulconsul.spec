Name:	        consul	
Version:        %{project_version} 
Release:	1%{?dist}
Summary:	Consul schema registry

Group:		org.gojul.gojulrpmbuildtools
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	consul.tgz

BuildRequires:	gojulrpmbuildtools
BuildRequires:  unzip

Requires:       bash
Requires:       filesystem
Requires:       initscripts
Requires:       shadow-utils

%description
Consul is a schema registry widely used in microservices architectures. Unfortunately
HashiCorp does not feature official RPM packages. This unofficial package attempts to
work around this limitation.

Note that this package contains init scripts copied from repository 
https://github.com/hypoport/consul-rpm-rhel6/

%package ui
Summary: Consul Web UI
Requires: consul

%description ui
Consul UI enables Consul's server Web UI. It can be reached
from URL http://localhost:8500/ui unless you've changed the
HTTP port for the UI.

Note after installing this package you'll have to manually restart
Consul for the changes to take effect.


%prep
%setup -q -c
unzip consul.zip

%build
%cmake

%install
make install DESTDIR=%{buildroot}

mkdir -p %{buildroot}%{_bindir}
mv %{_builddir}/%{buildsubdir}/consul %{buildroot}%{_bindir}

mkdir -p %{buildroot}/var/{lib,log,run}/consul

%pre
getent passwd consul > /dev/null || /usr/sbin/useradd consul

if [ -f /etc/init.d/consul ]
then
   /etc/init.d/consul stop || true
fi

%post
if [ "$1" == 0 ]
then
   chkconfig --add /etc/init.d/consul || true
fi

%preun
if [ "$1" == 0 ]
then
   /etc/init.d/consul stop || true
   chkconfig --del /etc/init.d/consul || true
fi

%post ui
echo >&2 "Please restart Consul for the UI changes to take effect."

%preun ui
echo >&2 "Please restart Consul for the UI changes to take effect."

%files
%defattr(-,root,root,-)
%{_bindir}/consul
%{_docdir}/consul
%{_sysconfdir}/init.d/consul
%dir %{_sysconfdir}/consul.d
/var/run/consul

%attr(-,consul,consul) /var/lib/consul
%attr(-,consul,consul) /var/log/consul

%config(noreplace) %{_sysconfdir}/consul.json

%files ui
%defattr(-,root,root,-)
%config(noreplace) %{_sysconfdir}/consul.d/consul-ui.json
