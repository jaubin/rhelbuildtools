Name:		gojulgatling
Version:	%{project_version}
Release:	1%{?dist}
Summary:	Gojul's gatling distrib 

Group:		org.gojul.gojulrpmbuildtools
License:	GPL
URL:		https://www.github.com/gojul/gojulrpmbuildtools
Source0:	gatling.tgz

BuildRequires:  coreutils
BuildRequires:	gojulrpmbuildtools
BuildRequires:  unzip

Requires:	bash
Requires:       filesystem
Requires:       java-1.8.0-openjdk-devel

%description
Gatling is a well known load testing tool. This unofficial package attempts
to create a handy way to install it. For more information check https://gatling.io/download

%global __jar_repack %{nil}
%global gatling_dir /usr/share/gatling
%global gatling_conf_dir /etc/gatling

%prep
%setup -q -c
unzip gatling.zip


%build
%cmake

%install
make install DESTDIR=%{buildroot}

mkdir -p %{buildroot}/%{gatling_dir}
mv gatling*/* %{buildroot}/%{gatling_dir}
chmod a+x %{buildroot}/%{gatling_dir}/bin/*.sh
# Dirty trick because of some compilation at startup.
mkdir -p %{buildroot}/%{gatling_dir}/target
chmod 777 %{buildroot}/%{gatling_dir}/target

rm -rf %{buildroot}/%{gatling_dir}/conf 
ln -s %{gatling_conf_dir} %{buildroot}/%{gatling_dir}/conf

%files
%{_bindir}/*.sh
%{gatling_dir}
%dir %{gatling_conf_dir}

%config(noreplace) %{gatling_conf_dir}/*
