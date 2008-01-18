Summary:	Parser that builds a tree of XML::Element objects
Name:		perl-XML-TreeBuilder
Version:	3.09
Release:	8%{?dist}
License:	GPL+ or Artistic
Group:		Development/Libraries
URL:		http://search.cpan.org/dist/XML-TreeBuilder/
# have to:
#  push the patch upstream
Source:		http://www.cpan.org/modules/by-module/XML/XML-TreeBuilder-%{version}.tar.gz
Patch0:		XML-TreeBuilder-NoExpand.patch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root%(%{__id_u} -n)
BuildArch:	noarch
BuildRequires:	perl
BuildRequires:	perl(ExtUtils::MakeMaker)
BuildRequires:	perl(HTML::Element)
BuildRequires:	perl(HTML::Tagset)
BuildRequires:	perl(XML::Parser)
Requires:	perl(HTML::Element) perl(HTML::Tagset) perl(XML::Parser)

%description
perl-XML-TreeBuilder is a Perl module that implements a parser
that builds a tree of XML::Element objects.

%prep
%setup -q -n XML-TreeBuilder-%{version}
%patch0 -p1

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor"
%{__make} %{?_smp_mflags}

%check
%{__make} test

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__make} pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT create_packlist=0

### Clean up buildroot
find $RPM_BUILD_ROOT -name .packlist -exec %{__rm} {} \;

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root, -)
%doc Changes README
%{_mandir}/man3/*.3pm*
%{perl_vendorlib}/XML/

%changelog
* Fri Jan 18 2008 Jeff Fearn <jfearn@redhat.com> - 3.09-8
- Pretend 3.10 never happened

* Thu Jan 17 2008 Jeff Fearn <jfearn@redhat.com> - 3.09-7
- Trimmed Summary

* Fri Jan 11 2008 Jeff Fearn <jfearn@redhat.com> - 3.09-6
- Fixed test
- Fixed Source URL
- Added %%check

* Tue Jan 08 2008 Jeff Fearn <jfearn@redhat.com> - 3.09-5
- Changed Development/Languages to Development/Libraries

* Tue Jan 08 2008 Jeff Fearn <jfearn@redhat.com> - 3.09-4
- Remove %%doc from man files, used glob
- Simplify XML in filelist
- Remove OPTIMIZE setting from make call
- Change buildroot to fedora style
- Remove unused defines

* Mon Jan 07 2008 Jeff Fearn <jfearn@redhat.com> - 3.09-3
- Tidy spec file

* Wed Dec 12 2007 Jeff Fearn <jfearn@redhat.com> - 3.09-2
- Add dist param
- Add NoExpand to allow entities to pass thru un-expanded

* Fri May 04 2007 Dag Wieers <dag@wieers.com> - 3.09-1
- Initial package. (using DAR)
