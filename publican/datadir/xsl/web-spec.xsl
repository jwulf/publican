<?xml version='1.0'?>

<!--
	Copyright (c) 2007-2009 Red Hat, Inc.
	License: GPLv2+ or Artistic
	Author: Jeff Fearn <jfearn@redhat.com>
-->
<!-- Transform bookinfo.xml into a SPEC File -->
<xsl:stylesheet version="1.0" xml:space="preserve" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="no" standalone="no" version="1.0"/>
<!-- Note: do not indent this file!  Any whitespace here
     will be reproduced in the output -->
<xsl:template match="/">#Documentation Specfile
%define HTMLVIEW %(eval 'if [ "%{?dist}" = ".el5" ]; then echo "1"; else echo "0"; fi')

%define viewer xdg-open

%if %{HTMLVIEW}
%define viewer htmlview
%define vendor redhat-
%define vendoropt --vendor="redhat"
%endif

Name:          <xsl:value-of select="$book-title"/>-web-<xsl:value-of select="$lang"/>
Version:       <xsl:value-of select="$rpmver"/>
Release:       <xsl:value-of select="$rpmrel"/>%{?dist}
<xsl:if test="$translation = '1'">
Summary:      <xsl:value-of select="$language"/> translation of <xsl:value-of select="$book-title"/>
Summary(<xsl:value-of select="$lang"/>):       <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
</xsl:if>
<xsl:if test="$translation != '1'">
Summary:       <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
</xsl:if>
Group:         Documentation
License:       <xsl:value-of select="$license"/>
URL:           <xsl:value-of select="$url"/>
Source:        <xsl:value-of select="$src_url"/>%{name}-%{version}-<xsl:value-of select="$rpmrel"/>.tgz
BuildArch:     noarch
BuildRoot:     %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: publican
BuildRequires: desktop-file-utils
Requires:      perl-Publican-WebSite
<xsl:if test="$brand != 'publican-common'">BuildRequires: <xsl:value-of select="$brand"/></xsl:if>
<xsl:if test="$web_obsoletes != ''">Obsoletes:    <xsl:value-of select="$web_obsoletes"/></xsl:if>
Prefix:        /var/www/html/docs

%description
<xsl:if test="$translation = '1'"><xsl:value-of select="$language"/> translation of <xsl:value-of select="$book-title"/>

%description -l <xsl:value-of select="$lang"/></xsl:if>
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" /><xsl:value-of select="/articleinfo/abstract/para" />

%package -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>
<xsl:if test="$translation = '1'">
Summary:      <xsl:value-of select="$language"/> translation of <xsl:value-of select="$docname"/>
Summary(<xsl:value-of select="$lang"/>):    <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
</xsl:if>
<xsl:if test="$translation != '1'">
Summary:    <xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
</xsl:if>
Group:        Documentation
%if %{HTMLVIEW}
Requires:    htmlview
%else
Requires:    xdg-utils
%endif
<xsl:if test="$dt_obsoletes != ''">Obsoletes:    <xsl:value-of select="$dt_obsoletes"/></xsl:if>

%description  -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>
<xsl:if test="$translation = '1'"><xsl:value-of select="$language"/> translation of <xsl:value-of select="$docname"/>

%description -l <xsl:value-of select="$lang"/></xsl:if>  -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>
<xsl:value-of select="/bookinfo/abstract/para" /><xsl:value-of select="/setinfo/abstract/para" /><xsl:value-of select="/articleinfo/abstract/para" />

%prep
%setup -q

%build
export CLASSPATH=$CLASSPATH:%{_javadir}/ant/ant-trax-1.7.0.jar:%{_javadir}/xmlgraphics-commons.jar:%{_javadir}/batik-all.jar:%{_javadir}/xml-commons-apis.jar:%{_javadir}/xml-commons-apis-ext.jar
publican build --embedtoc --formats="html,html-single,html-desktop,pdf" --langs=<xsl:value-of select="$lang"/> --publish

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{prefix}
mkdir -p $RPM_BUILD_ROOT%{_datadir}/applications
cp -rf publish/<xsl:value-of select="$lang"/> $RPM_BUILD_ROOT/%{prefix}/.

cat > <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-<xsl:value-of select="$rpmver"/>.desktop &lt;&lt;'EOF'
[Desktop Entry]
Name=<xsl:value-of select="/bookinfo/productname" /><xsl:value-of select="/setinfo/productname" /><xsl:value-of select="/articleinfo/productname"/> <xsl:value-of select="/bookinfo/productnumber" /><xsl:value-of select="/setinfo/productnumber" /><xsl:value-of select="/articleinfo/productnumber"/>: <xsl:value-of select="/bookinfo/title" /><xsl:value-of select="/setinfo/title" /><xsl:value-of select="/articleinfo/title"/>
Comment=<xsl:value-of select="/bookinfo/subtitle"/><xsl:value-of select="/setinfo/subtitle"/><xsl:value-of select="/articleinfo/subtitle"/>
Exec=%{viewer} %{_docdir}/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-%{version}/index.html
Icon=%{_docdir}/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-%{version}/images/icon.svg
Categories=Documentation;X-Red-Hat-Base;
Type=Application
Encoding=UTF-8
Terminal=false
EOF

%if %{HTMLVIEW}
desktop-file-install  %{?vendoropt} --dir=${RPM_BUILD_ROOT}%{_datadir}/applications <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-<xsl:value-of select="$rpmver"/>.desktop
%else
desktop-file-install --dir=${RPM_BUILD_ROOT}%{_datadir}/applications <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-<xsl:value-of select="$rpmver"/>.desktop
%endif


%preun -n <xsl:value-of select="$book-title"/>-web-<xsl:value-of select="$lang"/>
if [ "$1" = "0" ] ; then # last uninstall
%{__perl} -e 'if (eval {require Publican::WebSite}) { my @formats = ("html", "pdf", "html-single"); my $ws = Publican::WebSite->new(); foreach my $format (@formats) { $ws->del_entry({ language => "<xsl:value-of select="$lang"/>", product => "<xsl:value-of select="$prod" />", version => "<xsl:value-of select="$prodver" />", name => "<xsl:value-of select="$docname" />", format => "$format"} ); } $ws->regen_all_toc();}';
fi

%post -n <xsl:value-of select="$book-title"/>-web-<xsl:value-of select="$lang"/>
%{__perl} -e 'use Publican::WebSite; my @formats = ("html", "pdf", "html-single"); my $ws = Publican::WebSite->new(); foreach my $format (@formats) { $ws->add_entry( { language => "<xsl:value-of select="$lang"/>", product => "<xsl:value-of select="$prod" />", version => "<xsl:value-of select="$prodver" />", name => "<xsl:value-of select="$docname" />", format => "$format" }); } $ws->regen_all_toc();'

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{prefix}/<xsl:value-of select="$lang"/>

%files -n <xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>
%defattr(-,root,root,-)
%doc tmp/<xsl:value-of select="$lang"/>/html-desktop/*
%if %{HTMLVIEW}
%{_datadir}/applications/%{?vendor}<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-<xsl:value-of select="$rpmver"/>.desktop
%else
%{_datadir}/applications/<xsl:value-of select="$book-title"/>-<xsl:value-of select="$lang"/>-<xsl:value-of select="$rpmver"/>.desktop
%endif

%changelog
<xsl:value-of select="$log"/>

</xsl:template>

</xsl:stylesheet>
