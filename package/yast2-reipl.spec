#
# spec file for package yast2-reipl
#
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-reipl
Version:        4.1.0
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

BuildRequires:  yast2
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  update-desktop-files
BuildRequires:  rubygem(rspec)
BuildRequires:  rubygem(yast-rake)

ExclusiveArch:  s390 s390x

# Wizard::SetDesktopTitleAndIcon
Requires:       yast2 >= 2.21.22
# needed for chreipl and lsreipl commands
Requires:       s390-tools

PreReq:         %fillup_prereq

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:        YaST2 - IPL loader
License:        GPL-2.0-only
Group:          System/YaST
Url:            http://github.com/yast/yast-reipl

%description
Module for loading IPL from running system on S/390

%prep
%setup -n %{name}-%{version}

%check
rake test:unit

%build

%install
rake install DESTDIR="%{buildroot}"

%post
%{fillup_only -ns security checksig}

%files
%defattr(-,root,root)
%{yast_clientdir}/*.rb
%{yast_moduledir}/*.rb
%{yast_desktopdir}/*.desktop
%dir %{yast_yncludedir}/reipl
%{yast_yncludedir}/reipl/*
%dir %{yast_docdir}
%doc %{yast_docdir}/*
%license COPYING

%changelog
