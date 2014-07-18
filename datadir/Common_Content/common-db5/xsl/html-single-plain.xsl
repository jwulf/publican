<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:exsl="http://exslt.org/common"
    xmlns:d="http://docbook.org/ns/docbook"
    version="1.0"
    exclude-result-prefixes="exsl d"
    extension-element-prefixes="d"
>

<xsl:import href="http://docbook.sourceforge.net/release/xsl-ns/current/xhtml5/docbook.xsl"/>
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

<!-- HTML5: converts obsolete HTML attributes to CSS styles -->
<xsl:template match="*" mode="convert.to.style">

  <xsl:variable name="element" select="local-name(.)"/>

  <xsl:variable name="style.from.atts">
    <xsl:for-each select="@*">

      <xsl:choose>
        <!-- width and height attributes are ok for img element -->
        <xsl:when test="local-name() = 'width' and $element != 'img'">
          <xsl:text>width: </xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>; </xsl:text>
        </xsl:when>

        <xsl:when test="local-name() = 'height' and $element != 'img'">
          <xsl:text>height: </xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>; </xsl:text>
        </xsl:when>

        <xsl:when test="local-name() = 'align'">
          <xsl:text>text-align: </xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>; </xsl:text>
        </xsl:when>

        <xsl:when test="local-name() = 'valign'">
          <xsl:text>vertical-align: </xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>; </xsl:text>
        </xsl:when>

        <xsl:when test="local-name() = 'border'">
          <xsl:text>border: </xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>; </xsl:text>
        </xsl:when>

        <xsl:when test="local-name() = 'cellspacing'">
          <xsl:text>border-spacing: </xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>; </xsl:text>
        </xsl:when>

        <xsl:when test="local-name() = 'cellpadding'">
          <xsl:text>padding: </xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>; </xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:variable>

  <!-- merge existing styles with these new styles -->
  <xsl:variable name="style">
    <xsl:value-of select="concat($style.from.atts, @style)"/>
  </xsl:variable>

  <!-- HTML5: reserved for element name conversion if needed -->
  <xsl:variable name="element.name">
    <xsl:value-of select="local-name(.)"/>
  </xsl:variable>

  <xsl:element name="{$element.name}">
    <xsl:if test="string-length($style) != 0">
      <xsl:attribute name="style">
        <xsl:value-of select="$style"/>
      </xsl:attribute>
    </xsl:if>
    <!-- skip converted atts, and also skip disallowed summary attribute -->
    <xsl:for-each select="@*">
      <xsl:choose>
        <xsl:when test="local-name(.) = 'width' and $element != 'img'"/>
        <xsl:when test="local-name(.) = 'height' and $element != 'img'"/>
        <xsl:when test="local-name(.) = 'summary'"/>
        <xsl:when test="local-name(.) = 'border'"/>
        <xsl:when test="local-name(.) = 'cellspacing'"/>
        <xsl:when test="local-name(.) = 'cellpadding'"/>
        <xsl:when test="local-name(.) = 'style'"/>
        <xsl:when test="local-name(.) = 'align'"/>
        <xsl:when test="local-name(.) = 'valign'"/>
        <xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:apply-templates mode="convert.to.style"/>
  </xsl:element>
</xsl:template>

</xsl:stylesheet>
