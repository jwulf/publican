<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:exsl="http://exslt.org/common"
    xmlns:d="http://docbook.org/ns/docbook"
    version="1.0"
    exclude-result-prefixes="exsl d"
    extension-element-prefixes="d"
>

<xsl:import href="http://docbook.sourceforge.net/release/xsl-ns/current/xhtml5/docbook.xsl"/>
<xsl:import href="http://docbook.sourceforge.net/release/xsl-ns/current/xhtml5/chunk.xsl"/>
<xsl:import href="html-common.xsl"/>
<xsl:param name="onechunk" select="1"/>

<xsl:template name="header.navigation">
	<ul class="docnav top" xmlns="http://www.w3.org/1999/xhtml">
		<li class="previous"></li>
		<li class="home">
			<xsl:attribute name="onClick">work=1;showhide('poptoc');</xsl:attribute>
			<xsl:value-of select="$clean_title"/>
		</li>
		<li class="next"></li>
	</ul>
</xsl:template>

<xsl:template name="href.target.uri">
  <xsl:param name="object" select="."/>
  <xsl:text>#</xsl:text>
  <xsl:call-template name="object.id">
    <xsl:with-param name="object" select="$object"/>
  </xsl:call-template>
</xsl:template>

</xsl:stylesheet>
