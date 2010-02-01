%define brand jboss-community

Name:		publican-jboss-community
Summary:	Common documentation files for JBoss community documents
Version:	0.9
Release:	0%{?dist}
License:	CC-BY-SA
Group:		Applications/Text
Buildroot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Buildarch:	noarch
Source:		https://fedorahosted.org/releases/publican/%{name}-%{version}.tgz
Requires:	publican >= 1.0
BuildRequires:	publican >= 1.0
URL:		https://publican.fedorahosted.org/

%description
This package provides common files and templates needed to build documentation
for JBoss community documents with Publican.

%prep
%setup -q 

%build
publican build --formats=xml --langs=all --publish

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_datadir}/publican/Common_Content
publican installbrand --path=$RPM_BUILD_ROOT%{_datadir}/publican/Common_Content

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README
%doc COPYING
%{_datadir}/publican/Common_Content/%{brand}

%changelog
* Mon Feb 1 2010  James Cobb <jcobb@redhat.com> 0.9
- CSS fix for gradient in draft docs
* Tue Jan 12 2010  Rüdiger Landmann <r.landmann@redhat.com> 0.8
- Revert to original draft background, fine tune title logo
* Mon Jan 11 2010  James Cobb <jcobb@redhat.com> 0.7
- fine-tune CSS, change title logo, add more images
* Tue Dec 8 2009  Jeff Fearn <jfearn@redhat.com> 0.6
- fine-tune CSS and title SVG
* Fri Nov 27 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.5
- Import more CSS from documentation.css -- not tested
* Fri Nov 27 2009  Ryan Lerch <rlerch@redhat.com> 0.4
- Tweak CSS
* Thu Nov 26 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.3
- More CSS
* Thu Nov 26 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.2
- Add title logo in SVG format
- Initial tweak of CSS
* Wed Nov 25 2009  Rüdiger Landmann <r.landmann@redhat.com> 0.1
- Created brand

