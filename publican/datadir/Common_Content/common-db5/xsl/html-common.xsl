<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0"
  exclude-result-prefixes=""
  extension-element-prefixes=""
>
<xsl:param name="embedtoc"  select="'0'"/>
<xsl:param name="tocpath"   select="''"/>
<xsl:param name="pop_prod"  select="''"/>
<xsl:param name="pop_ver"   select="''"/>
<xsl:param name="pop_name"  select="''"/>
<xsl:param name="brand"     select="''"/>
<xsl:param name="langpath"  select="''"/>

<!-- Admonition Graphics -->
<xsl:param name="admon.graphics" select="1"/>
<xsl:param name="admon.style" select="''"/>
<xsl:param name="admon.graphics.path">
    <xsl:choose>
      <xsl:when test="$embedtoc != 0">
        <xsl:value-of select="concat($tocpath, '/../', $brand, '/', $langpath, '/images')"/>
      </xsl:when>
      <xsl:otherwise>
		<xsl:text>Common_Content/images/</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
</xsl:param>
<xsl:param name="callout.graphics.path"><xsl:value-of select="$admon.graphics.path"/><xsl:text>/</xsl:text></xsl:param>
<xsl:param name="html.stylesheet"><xsl:if test="$embedtoc = 0 ">Common_Content/css/default.css</xsl:if></xsl:param>
<xsl:param name="html.stylesheet.type" select="'text/css'"/>
<xsl:param name="html.stylesheet.print"><xsl:if test="$embedtoc = 0 ">Common_Content/css/print.css</xsl:if></xsl:param>
<xsl:param name="html.ext" select="'.html'"/>
<xsl:param name="suppress.header.navigation" select="1"/>
<xsl:param name="css.decoration" select="0"/>
<xsl:param name="use.id.as.filename" select="'1'"/>
<xsl:param name="docbook.css.link" select="0"/>
<xsl:param name="generate.css.header" select="0"/>
<xsl:param name="make.clean.html" select="0"/>
<xsl:param name="html.cleanup" select="0"/>

<xsl:param name="section.autolabel" select="1"/>
<xsl:param name="section.label.includes.component.label" select="1"/>

<xsl:param name="generate.toc">
set toc
book toc
article nop
chapter nop
qandadiv toc
qandaset toc
sect1 nop
sect2 nop
sect3 nop
sect4 nop
sect5 nop
section nop
part toc
</xsl:param>

<xsl:param name="header.rule" select="0"/>
<xsl:param name="footer.rule" select="0"/>

<!-- duplicated from xhtml-docbook.xsl -->
<xsl:template name="user.head.content">
  <xsl:param name="node" select="."/>
  <xsl:if test="$embedtoc = 1">
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../common-db5/<xsl:value-of select="$langpath"/>/css/menu.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../menu.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../print.css</xsl:attribute><xsl:attribute name="media">print</xsl:attribute></link>
    <xsl:if test="$brand != 'common-db5'">
      <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../<xsl:value-of select="$brand"/>/<xsl:value-of select="$langpath"/>/css/menu.css</xsl:attribute></link>
    </xsl:if>
    <script type="text/javascript">
    	<xsl:attribute name="src"><xsl:value-of select="$tocpath"/>/labels.js</xsl:attribute>
    	<xsl:text> </xsl:text>
    </script>
    <script type="text/javascript">
    	<xsl:attribute name="src"><xsl:value-of select="$tocpath"/>/../toc.js</xsl:attribute>
    	<xsl:text> </xsl:text>
    </script>
    <script type="text/javascript">
    	<xsl:attribute name="src"><xsl:value-of select="$tocpath"/>/../jquery-1.7.1.min.js</xsl:attribute>
    	<xsl:text> </xsl:text>
    </script>
    <script type="text/javascript">
      <xsl:if test="$web.type = ''">
	current_book = '<xsl:copy-of select="$pop_name"/>';
	current_version = '<xsl:copy-of select="$pop_ver"/>';
	current_product = '<xsl:copy-of select="$pop_prod"/>';
      </xsl:if>
      <xsl:if test="$web.type != ''">
	current_book = '';
	current_version = '';
      </xsl:if>
      toc_path = '<xsl:value-of select="$tocpath"/>';
      loadMenu();
    </script>
  </xsl:if>
</xsl:template>
<xsl:template name="user.header.content">
  <xsl:param name="node" select="."/>
  <xsl:if test="$embedtoc = 1">
        <div id="navigation"><xsl:text> </xsl:text></div>
        <div id="floatingtoc" class="hidden"><xsl:text> </xsl:text></div>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>

