<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:exsl="http://exslt.org/common"
    xmlns:d="http://docbook.org/ns/docbook"
    version="1.0"
    exclude-result-prefixes="exsl d"
    extension-element-prefixes="d"
>

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl"/>
<xsl:param name="generate.legalnotice.link" select="0"/>
<xsl:param name="generate.revhistory.link" select="0"/>
<xsl:param name="suppress.navigation">1</xsl:param>
<xsl:param name="manual.toc" select="' '"/>
<xsl:param name="highlight.source" select="0"/>
<xsl:param name="use.extensions" select="0"/>
<xsl:param name="callouts.extension" select="0"/>
<xsl:param name="tablecolumns.extension" select="0"/>
<xsl:param name="make.clean.html" select="1"/>
<xsl:param name="html.cleanup" select="1"/>
<xsl:param name="html.ext" select="'.html'"/>
<xsl:param name="html.stylesheet" select="''"/>
<xsl:param name="table.borders.with.css" select="0"/>
<xsl:param name="admon.graphics" select="0"/>
<xsl:param name="css.decoration" select="0"/>
<xsl:param name="docbook.css.link" select="0"/>
<xsl:param name="generate.css.header" select="0"/>
<xsl:param name="html.stylesheet"></xsl:param>
<xsl:param name="docbook.css.source"></xsl:param>
<xsl:param name="ignore.image.scaling" select="1"/>
<xsl:param name="section.autolabel" select="1"/>
<xsl:param name="section.label.includes.component.label" select="1"/>

<xsl:param name="generate.toc">
set nop
book nop
article nop
chapter nop
qandadiv nop
qandaset nop
sect1 nop
sect2 nop
sect3 nop
sect4 nop
sect5 nop
section nop
part toc
</xsl:param>

<xsl:template name="user.head.content">
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</xsl:template>

</xsl:stylesheet>
