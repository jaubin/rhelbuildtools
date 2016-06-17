Name:	        gojultomcat	
Version:        %{project_version} 
Release:	1%{?dist}
Summary:	Gojul's Tomcat distribution (apache official one packaged)

Group:		org.gojul.gojulrpmbuildtools
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	gojultomcat8.tgz

BuildRequires:	gojulrpmbuildtools

Requires:       java-1.8.0-openjdk-devel

%global _gojulinstalldir /usr/share/gojultomcat

%description
Gojul's Tomcat is a Tomcat distribution to be used with other Gojul's tools.
The purpose here is to have a standard easy-to-use Tomcat, as RHEL Tomcat does
not feature the standard layout.

%prep
%setup -q -c


%install
mkdir -p %{buildroot}/%{_gojulinstalldir}
cd %{buildroot}/%{_gojulinstalldir}
tar zxf %{_builddir}/%{name}-%{version}/tomcat-distrib.tgz --strip-components 1

%files
%defattr(-,root,root,-)
%{_gojulinstalldir}

