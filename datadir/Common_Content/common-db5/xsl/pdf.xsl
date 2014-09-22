<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version='1.0'
    xmlns="http://www.w3.org/TR/xhtml1/transitional"
    xmlns:d="http://docbook.org/ns/docbook"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:rx="http://www.renderx.com/XSL/Extensions"
    xmlns:stbl="http://nwalsh.com/xslt/ext/com.nwalsh.saxon.Table"
    xmlns:xtbl="com.nwalsh.xalan.Table"
    xmlns:ptbl="http://nwalsh.com/xslt/ext/xsltproc/python/Table"
    xmlns:perl="urn:perl"
    xmlns:exsl="http://exslt.org/common"
    exclude-result-prefixes="exsl perl ptbl xtbl stbl d"
    extension-element-prefixes="d"
>

<xsl:import href="http://docbook.sourceforge.net/release/xsl-ns/current/fo/docbook.xsl"/>
<xsl:param name="use.extensions" select="1"/>
<xsl:param name="tablecolumns.extension" select="0"/>
<xsl:param name="fop.extensions" select="0"/>
<xsl:param name="fop1.extensions" select="1"/>
<xsl:param name="linenumbering.extension" select="0"/>
<xsl:param name="callouts.extension" select="0"/>

</xsl:stylesheet>

