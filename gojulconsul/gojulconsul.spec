Name:	        consul	
Version:        %{project_version} 
Release:	1%{?dist}
Summary:	Consul schema registry

Group:		org.gojul.gojulrpmbuildtools
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	consul.tgz

BuildRequires:	gojulrpmbuildtools

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
mkdir -p %{buildroot}/etc/consul.d

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

%files
%defattr(-,root,root,-)
%{_bindir}/consul
%{_docdir}/consul
%{_sysconfdir}/init.d/consul
%{_sysconfdir}/consul.d
/var/run/consul

%attr(-,consul,consul) /var/lib/consul
%attr(-,consul,consul) /var/log/consul

%config(noreplace) %{_sysconfdir}/consul.json
