Name:	        gojulnexus-3	
Version:        %{project_version} 
Release:	1%{?dist}
Summary:	Gojul's Nexus 3 distribution (Nexus official one packaged)

Group:		org.gojul.gojulrpmbuildtools
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	nexus.tgz

BuildRequires:	gojulrpmbuildtools

Requires:       bash
Requires:       chkconfig
Requires:       coreutils
Requires:       createrepo
Requires:       java-1.8.0-openjdk-devel
Requires:       initscripts
Requires:       shadow-utils

%global __jar_repack %{nil}
%global _gojulinstalldir /opt/gojulnexus-3
%global _nexus_user nexus

%description
Gojul's Nexus is a standard Nexus distribution packaged in order
to make it easy to install Nexus.

%prep
%setup -q -c


%install
%cmake
make install DESTDIR=%{buildroot}

mkdir -p %{buildroot}/%{_gojulinstalldir}
cd %{buildroot}/%{_gojulinstalldir}
tar zxf %{_builddir}/%{name}-%{version}/nexus-distrib.tgz --strip-components 1

rm -f %{buildroot}%{_gojulinstalldir}/bin/nexus.{rc,vmoptions}
ln -sf /etc/gojulnexus-3/nexus.rc %{buildroot}%{_gojulinstalldir}/bin
ln -sf /etc/gojulnexus-3/nexus.vmoptions %{buildroot}%{_gojulinstalldir}/bin

mkdir -p %{buildroot}/etc/init.d
ln -sf %{_gojulinstalldir}/bin/nexus %{buildroot}/etc/init.d/gojulnexus-3

for i in log lib tmp
do
   mkdir -p %{buildroot}/var/${i}/gojulnexus-3
done

%pre
if [ -f /etc/init.d/gojulnexus-3 ]
then
   /etc/init.d/gojulnexus-3 stop
fi

getent passwd nexus > /dev/null || useradd nexus

%post
if [ "$1" == 0 ]
then
   chkconfig --add /etc/init.d/gojulnexus-3 || true
fi

%preun
if [ "$1" == 0 ]
then
   /etc/init.d/gojulnexus-3 stop || true
   chkconfig --del /etc/init.d/gojulnexus-3 || true
fi



%files
%defattr(-,root,root,-)
%{_gojulinstalldir}
/etc/init.d/gojulnexus-3

%attr(-,%{_nexus_user},%{_nexus_user}) /var/lib/gojulnexus-3
%attr(-,%{_nexus_user},%{_nexus_user}) /var/log/gojulnexus-3
%attr(-,%{_nexus_user},%{_nexus_user}) /var/tmp/gojulnexus-3

%dir /etc/gojulnexus-3
%config(noreplace) /etc/gojulnexus-3/*

