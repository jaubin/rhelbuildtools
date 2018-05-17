Name:	        @@WARNAME@@	
Version:        @@WARVERSION@@
Release:	1%{?dist}
Summary:	Webapp @@WARNAME@@

Group:		org.gojul.gojulwebapps
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	@@WARNAME@@.tgz

BuildRequires:	gojulrpmbuildtools

Requires:       gojul-catalina-base

%description
Webapp @@WARNAME@@

%global _gojulcatalinabase /home/gojultomcat

%prep
%setup -q -c


%install
mkdir -p %{buildroot}/%{_gojulcatalinabase}/webapps
cp @@WARNAME@@.war %{buildroot}/%{_gojulcatalinabase}/webapps

cp -r configApps %{buildroot}/%{_gojulcatalinabase} 

mkdir -p %{buildroot}/%{_gojulcatalinabase}/conf/Catalina/localhost
cp @@WARNAME@@.xml %{buildroot}/%{_gojulcatalinabase}/conf/Catalina/localhost

%pre
if [ -f /etc/init.d/gojultomcat ]
then
   /etc/init.d/gojultomcat stop || true
fi
if [ -d %{_gojulcatalinabase}/webapps/@@WARNAME@@ ]
then
   rm -rf %{_gojulcatalinabase}/webapps/@@WARNAME@@
fi


%preun
if [ -f /etc/init.d/gojultomcat ]
then
   /etc/init.d/gojultomcat stop || true
fi
if [ -d %{_gojulcatalinabase}/webapps/@@WARNAME@@ ]
then
   rm -rf %{_gojulcatalinabase}/webapps/@@WARNAME@@
fi



%files
%defattr(-,root,root,-)


%dir %{_gojulcatalinabase}/configApps/@@WARNAME@@
%config(noreplace)  %{_gojulcatalinabase}/configApps/@@WARNAME@@/*

%{_gojulcatalinabase}/conf/Catalina/localhost/@@WARNAME@@.xml
%attr(644,gojultomcat,gojultomcat) %{_gojulcatalinabase}/webapps/@@WARNAME@@.war

