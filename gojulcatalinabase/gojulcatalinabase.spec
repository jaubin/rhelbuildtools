Name:	        gojul-catalina-base	
Version:        %{project_version} 
Release:	1%{?dist}
Summary:	Gojul's catalina base with default configuration to put your webapps

Group:		org.gojul.gojulrpmbuildtools
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	gojulcatalinabase.tgz

BuildRequires:  gojulrpmbuildtools	

Requires:       bash
Requires:       chkconfig
Requires:       coreutils
Requires:       gojultomcat
Requires:       initscripts
Requires:       shadow-utils

%global _catalinahomeinstalldir /home/gojultomcat

%description
Gojul's catalina base. This layout ensures proper separation between Tomcat's 
CATALINA_HOME and CATALINA_BASE. This package features a daemon launcher so that
it can start out of the box. Note that this package has not been tested with SELinux stuff. 

%prep
%setup -q -c


%build
%cmake
make

%install
make install DESTDIR=%{buildroot}

mkdir -p %{buildroot}%{_catalinahomeinstalldir}/temp
mkdir -p %{buildroot}%{_catalinahomeinstalldir}/webapps
mkdir -p %{buildroot}%{_catalinahomeinstalldir}/work

mkdir -p %{buildroot}/var/log/gojultomcat
mkdir -p %{buildroot}/var/run/gojultomcat

ln -sf /var/log/gojultomcat %{buildroot}%{_catalinahomeinstalldir}/logs

%pre
getent passwd gojultomcat > /dev/null || /usr/sbin/useradd gojultomcat

if [ -f /etc/init.d/gojultomcat ]
then
   /etc/init.d/gojultomcat stop || true
fi

%post
if [ "$1" == 0 ]
then
   chkconfig --add /etc/init.d/gojultomcat || true
fi

%preun
if [ "$1" == 0 ]
then
   /etc/init.d/gojultomcat stop || true
   chkconfig --del /etc/init.d/gojultomcat || true
fi

%files
%defattr(-,root,root,-)
%doc
%dir %{_catalinahomeinstalldir}
%dir %{_catalinahomeinstalldir}/bin
%dir %{_catalinahomeinstalldir}/conf
%{_catalinahomeinstalldir}/configApps
%{_catalinahomeinstalldir}/lib

%attr(755,gojultomcat,gojultomcat) %{_catalinahomeinstalldir}/temp
%attr(755,gojultomcat,gojultomcat) %{_catalinahomeinstalldir}/webapps
%attr(755,gojultomcat,gojultomcat) %{_catalinahomeinstalldir}/work
%attr(755,gojultomcat,gojultomcat) /var/log/gojultomcat
%attr(755,gojultomcat,gojultomcat) /var/run/gojultomcat

%config(noreplace) %{_catalinahomeinstalldir}/bin/*
%config(noreplace) %{_catalinahomeinstalldir}/conf/*

%{_catalinahomeinstalldir}/logs
/etc/init.d/gojultomcat

