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

%global __versrel %{version}-%{release}

%description
Consul is a schema registry widely used in microservices architectures. Unfortunately
HashiCorp does not feature official RPM packages. This unofficial package attempts to
work around this limitation.

Note that this package contains init scripts copied from repository 
https://github.com/hypoport/consul-rpm-rhel6/

%package ui
Summary: Consul Web UI
Requires: consul = %{__versrel}
Requires: consul-server = %{__versrel}

%description ui
Consul UI enables Consul's server Web UI. It can be reached
from URL http://localhost:8500/ui unless you've changed the
HTTP port for the UI.

Note after installing this package you'll have to manually restart
Consul for the changes to take effect.

%package client 
Summary: Consul Client mode
Requires: consul = %{__versrel}
Conflicts: consul-ui

%description client
Consul client enables Consul's client mode. This mode
is very useful for example when used with consul-template. 

%package server 
Summary: Consul Server mode
Requires: consul = %{__versrel}
Conflicts: consul-client

%description server 
Consul server enables Consul's server mode. This 
package is is to be used for cluster Consul instances,
i.e. not clients.

%package standalone
Summary: Consul Standalone mode
Requires: consul = %{__versrel}
Conflicts: consul-client
Conflicts: consul-server

%description standalone
Consul standalone enables to work in standalone mode,
i.e. with a single server instance running.

%package template
Summary: Consul template daemon
Requires: consul = %{__versrel}

%description template
Consul template is a useful tool for generating
proxy configuration files from templates. The
goal is to enable the use of a traditional reverse-proxy
server like Apache or NGINX as an API gateway.

Note that this service needs to be run as root
because it has to run command with other services
depending on your needs.

%prep
%setup -q -c
unzip consul.zip
unzip consul-template.zip

%build
%cmake

%install
make install DESTDIR=%{buildroot}

mkdir -p %{buildroot}%{_bindir}
mv %{_builddir}/%{buildsubdir}/consul{,-template} %{buildroot}%{_bindir}

mkdir -p %{buildroot}/var/{lib,log,run}/consul
mkdir -p %{buildroot}/var/{log,run}/consul-template

mkdir -p %{buildroot}%{_sysconfdir}/consul-template.d

%pre
getent passwd consul > /dev/null || /usr/sbin/useradd consul

if [ -f /etc/init.d/consul ]
then
   /etc/init.d/consul stop || true
fi

%post
if [ "$1" == 0 ]
then
   chkconfig --add /etc/init.d/consul || true
fi

%preun
if [ "$1" == 0 ]
then
   /etc/init.d/consul stop || true
   chkconfig --del /etc/init.d/consul || true
fi

%post ui
echo >&2 "Please restart Consul for the UI changes to take effect."

%preun ui
echo >&2 "Please restart Consul for the UI changes to take effect."

%pre template
if [ -f /etc/init.d/consul-template ]
then
   /etc/init.d/consul-template stop || true
fi

%post template
if [ "$1" == 0 ]
then
   chkconfig --add /etc/init.d/consul-template || true
fi

%preun template
if [ "$1" == 0 ]
then
   /etc/init.d/consul-template stop || true
   chkconfig --del /etc/init.d/consul-template || true
fi



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
%config(noreplace) %{_sysconfdir}/sysconfig/consul
%config(noreplace) %{_sysconfdir}/logrotate.d/consul

%files ui
%defattr(-,root,root,-)
%{_sysconfdir}/consul.d/consul-ui.json

%files client
%defattr(-,root,root,-)
%{_sysconfdir}/consul.d/consul-client.json

%files server 
%defattr(-,root,root,-)
%{_sysconfdir}/consul.d/consul-server.json

%files standalone
%defattr(-,root,root,-)
%{_sysconfdir}/consul.d/consul-standalone.json

%files template
%defattr(-,root,root,-)
%{_sysconfdir}/init.d/consul-template
%{_bindir}/consul-template
%dir %{_sysconfdir}/consul-template.d
/var/run/consul-template

/var/log/consul-template

%config(noreplace) %{_sysconfdir}/consul-template.hcl
%config(noreplace) %{_sysconfdir}/sysconfig/consul-template
%config(noreplace) %{_sysconfdir}/logrotate.d/consul-template



