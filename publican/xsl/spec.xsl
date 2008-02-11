<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
-->
<!-- Transform bookinfo.xml into a SPEC File -->
<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<!-- Note: do not indent this file!  Any whitespace here
     will be reproduced in the output -->
<xsl:template match="/"># Red Hat Documentation Specfile
Name:	<xsl:value-of select="$book-title"/>
Version:	<xsl:value-of select="/bookinfo/issuenum"/><xsl:value-of select="/setinfo/issuenum"/>
Release:	<xsl:value-of select="/bookinfo/productnumber"/><xsl:value-of select="/setinfo/productnumber"/>
Summary:	<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/>
Group:	Documentation
License:	Open Publication License
URL:	http://www.redhat.com/docs
Source0:	%{name}-%{version}-%{release}.tgz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires(post):	coreutils
Requires(postun):	coreutils
BuildRequires:	publican

%description<xsl:value-of select="/bookinfo/abstract[1]" /><xsl:value-of select="/setinfo/abstract[1]" />

%package -n %{name}-<xsl:value-of select="$book-lang"/>
Summary:	<xsl:value-of select="/bookinfo/subtitle" /><xsl:value-of select="/setinfo/subtitle" />
Group:	Documentation
Requires(post):	coreutils
Requires(postun):	coreutils

%prep
%setup -q

%build
%{__make} publish-dist

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT

cat > $RPM_BUILD_ROOT/usr/share/applications/%{name}.desktop &lt;&lt;'EOF'
[Desktop Entry]
Name=<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/>
<xsl:value-of select="$titles"/>
Comment=<xsl:value-of select="/bookinfo/title" /><xsl:value-of select="/setinfo/title" />
Exec=htmlview %{_docdir}/%{name}-<xsl:value-of select="$book-lang"/>-%{version}/index.html
Icon=%{_docdir}/%{name}-<xsl:value-of select="$book-lang"/>-%{version}/images/icon.svg
Categories=Documentation;X-Red-Hat-Base;
Type=Application
Encoding=UTF-8
Terminal=false
EOF

%clean
rm -rf $RPM_BUILD_ROOT

%description -n %{name}-<xsl:value-of select="$book-lang"/><xsl:value-of select="/bookinfo/abstract[1]" />

%files -n %{name}-<xsl:value-of select="$book-lang"/>
%defattr(-,root,root,-)
%doc publish/<xsl:value-of select="$book-lang"/>/*
/usr/share/applications/%{name}.desktop

@@@SUBPACKAGES@@@

%changelog<xsl:value-of select="$book-log"/>

</xsl:template>

</xsl:stylesheet>

