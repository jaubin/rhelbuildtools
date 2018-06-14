%global project_version %(echo $PROJECT_VERSION) 

Name:	        gojulrpmbuildtools	
Version:        %{project_version} 
Release:	1%{?dist}
Summary:	Gojul's tool used to build RPM packages

Group:		org.gojul.gojulrpmbuildtools
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	gojulrpmbuildtools.tgz

BuildRequires:	cmake
BuildRequires:  gcc

Requires:       /bin/bash
Requires:	cmake
Requires:       gcc
Requires:       git
# Turns out that setting up an explicit dependency over OpenJDK is mandatory
# to avoid crappy local JVM implementations that may have already been "manually"
# installed.
# A "good" JDK is mandatory for Maven.
Requires:       java-1.8.0-openjdk-devel
Requires:       /usr/bin/rpmbuild
Requires:       /usr/bin/spectool
Requires:       wget

# Maven is already provided on RHEL7+
%{?el6:Requires:       apache-maven}
%{?el7:Requires:       maven}


%description
Gojul RPM build tools are intended to make it easier to create RPM packages
from continuous integration servers like Jenkins. Most of the tools do not
use mock unlike what is suggested by Fedora guidelines because this tool is
extremely expensive to run on a continuous integration server.

%prep
%setup -q -c


%build
%cmake
make

%install
make install DESTDIR=%{buildroot}


%files
%defattr(-,root,root,-)
%doc
%dir /etc/gojulrpmbuildtools
/usr/share/gojulrpmbuildtools

/usr/bin/*
/etc/rpm/*
%config(noreplace) /etc/gojulrpmbuildtools/*
