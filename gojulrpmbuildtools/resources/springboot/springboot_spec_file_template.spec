Name:	        @@JARNAME@@	
Version:        @@JARVERSION@@
Release:	1%{?dist}
Summary:	Service @@JARNAME@@

Group:		org.gojul.gojulspringboot
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	@@JARNAME@@.tgz

BuildRequires:	gojulrpmbuildtools

Requires:       bash
Requires:       chkconfig
Requires:       coreutils
Requires:       initscripts
Requires:       java-1.8.0-openjdk-devel
Requires:       shadow-utils

%description
SpringBoot service @@JARNAME@@

%global _serviceinstalldir /usr/lib/springboot/@@JARNAME@@/
%global _serviceconfdir /etc/springboot/@@JARNAME@@/
%global __jar_repack %{nil}

%prep
%setup -q -c


%install
mkdir -p %{buildroot}/%{_serviceinstalldir}
cp @@JARNAME@@-spring-boot.jar %{buildroot}/%{_serviceinstalldir}

mkdir -p %{buildroot}/etc/init.d
cp @@JARNAME@@ %{buildroot}/etc/init.d

mkdir -p %{buildroot}/%{_serviceconfdir}
cp -r configApps/* %{buildroot}/%{_serviceconfdir} 

mkdir -p %{buildroot}/var/{log,run}/springboot/@@JARNAME@@

%pre

getent passwd gojultomcat > /dev/null || /usr/sbin/useradd gojultomcat

if [ -f /etc/init.d/@@JARNAME@@ ]
then
   /etc/init.d/@@JARNAME@@ stop || true
fi

%preun
if [ -f /etc/init.d/@@JARNAME@@ ]
then
   /etc/init.d/@@JARNAME@@ stop || true
fi


%files
%defattr(-,root,root,-)

/etc/init.d/@@JARNAME@@
%{_serviceinstalldir}

%dir %{_serviceconfdir} 
%config(noreplace)  %{_serviceconfdir}/*

%attr(755,gojultomcat,gojultomcat) /var/log/springboot/@@JARNAME@@
/var/run/springboot/@@JARNAME@@
