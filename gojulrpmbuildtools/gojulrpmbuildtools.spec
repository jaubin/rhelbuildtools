Name:	        gojulrpmbuildtools	
Version:	0.0.1
Release:	1%{?dist}
Summary:	Gojul's tool used to build RPM packages

Group:		org.gojul.gojulrpmbuildtools
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	gojulrpmbuildtools.tgz

BuildRequires:	cmake

Requires:       /bin/bash
Requires:	cmake
Requires:       gcc
Requires:       /usr/bin/rpmbuild

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
make install DESTDIR=.


%files
%doc
/usr/bin/*


