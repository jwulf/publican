<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:d="http://docbook.org/ns/docbook"
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
        <xsl:value-of select="concat($tocpath, '/../', $brand, '/', $langpath, '/images/')"/>
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
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <xsl:if test="$embedtoc = 1">
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../chrome.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../db5.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../<xsl:value-of select="$brand"/>/<xsl:value-of select="$langpath"/>/css/brand.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../print.css</xsl:attribute><xsl:attribute name="media">print</xsl:attribute></link>
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

<!-- HTML5: replace border="0" with border="" -->
<!-- HTML5: No @summary allowed -->
<!-- HTML5: replace many table atts with CSS styles -->
<xsl:template match="d:tgroup" name="tgroup">
  <xsl:if test="not(@cols) or @cols = '' or string(number(@cols)) = 'NaN'">
    <xsl:message terminate="yes">
      <xsl:text>Error: CALS tables must specify the number of columns.</xsl:text>
    </xsl:message>
  </xsl:if>

  <xsl:variable name="summary">
    <xsl:call-template name="pi.dbhtml_table-summary"/>
  </xsl:variable>

  <xsl:variable name="cellspacing">
    <xsl:call-template name="pi.dbhtml_cellspacing"/>
  </xsl:variable>

  <xsl:variable name="cellpadding">
    <xsl:call-template name="pi.dbhtml_cellpadding"/>
  </xsl:variable>

  <!-- First generate colgroup with attributes -->
  <xsl:variable name="colgroup.with.attributes">
    <colgroup>
      <xsl:call-template name="generate.colgroup">
        <xsl:with-param name="cols" select="@cols"/>
      </xsl:call-template>
    </colgroup>
  </xsl:variable>

  <!-- then modify colgroup attributes with extension -->
  <xsl:variable name="colgroup.with.extension">
    <xsl:choose>
      <xsl:when test="$use.extensions != 0
                      and $tablecolumns.extension != 0">
        <xsl:choose>
          <xsl:when test="function-available('stbl:adjustColumnWidths')">
            <xsl:copy-of select="stbl:adjustColumnWidths($colgroup.with.attributes)"/>
          </xsl:when>
          <xsl:when test="function-available('xtbl:adjustColumnWidths')">
            <xsl:copy-of select="xtbl:adjustColumnWidths($colgroup.with.attributes)"/>
          </xsl:when>
          <xsl:when test="function-available('ptbl:adjustColumnWidths')">
            <xsl:copy-of select="ptbl:adjustColumnWidths($colgroup.with.attributes)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="yes">
              <xsl:text>No adjustColumnWidths function available.</xsl:text>
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$colgroup.with.attributes"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Now convert to @style -->
  <xsl:variable name="colgroup">
    <xsl:call-template name="colgroup.with.style">
      <xsl:with-param name="colgroup" select="$colgroup.with.extension"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="explicit.table.width">
    <xsl:call-template name="pi.dbhtml_table-width">
      <xsl:with-param name="node" select=".."/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="table.width.candidate">
    <xsl:choose>
      <xsl:when test="$explicit.table.width != ''">
        <xsl:value-of select="$explicit.table.width"/>
      </xsl:when>
      <xsl:when test="$default.table.width = ''">
        <xsl:text>100%</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$default.table.width"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>


  <xsl:variable name="table.width">
    <xsl:if test="$default.table.width != ''
                  or $explicit.table.width != ''">
      <xsl:choose>
        <xsl:when test="contains($table.width.candidate, '%')">
          <xsl:value-of select="$table.width.candidate"/>
        </xsl:when>
        <xsl:when test="$use.extensions != 0
                        and $tablecolumns.extension != 0">
          <xsl:choose>
            <xsl:when test="function-available('stbl:convertLength')">
              <xsl:value-of select="stbl:convertLength($table.width.candidate)"/>
            </xsl:when>
            <xsl:when test="function-available('xtbl:convertLength')">
              <xsl:value-of select="xtbl:convertLength($table.width.candidate)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:message terminate="yes">
                <xsl:text>No convertLength function available.</xsl:text>
              </xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$table.width.candidate"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:variable>

  <!-- assemble a table @style -->
  <xsl:variable name="table.style">

    <xsl:if test="$cellspacing != '' or $html.cellspacing != ''">
      <xsl:text>cellspacing: </xsl:text>
      <xsl:choose>
        <xsl:when test="$cellspacing != ''">
          <xsl:value-of select="$cellspacing"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$html.cellspacing"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>; </xsl:text>
    </xsl:if>

    <xsl:if test="$cellpadding != '' or $html.cellpadding != ''">
      <xsl:text>cellpadding: </xsl:text>
      <xsl:choose>
        <xsl:when test="$cellpadding != ''">
          <xsl:value-of select="$cellpadding"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$html.cellpadding"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>; </xsl:text>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="string-length($table.width) != 0">
        <xsl:text>width: </xsl:text>
        <xsl:value-of select="$table.width"/>
        <xsl:text>; </xsl:text>
      </xsl:when>
      <xsl:when test="../@pgwide=1 or local-name(.) = 'entrytbl'">
        <xsl:text>width: 100%; </xsl:text>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:choose>
      <xsl:when test="../@frame='all' or (not(../@frame) and $default.table.frame='all')">
        <xsl:text>border-collapse: collapse; </xsl:text>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'top'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'bottom'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'left'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'right'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="../@frame='topbot' or (not(../@frame) and $default.table.frame='topbot')">
        <xsl:text>border-collapse: collapse;</xsl:text>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'top'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'bottom'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="../@frame='top' or (not(../@frame) and $default.table.frame='top')">
        <xsl:text>border-collapse: collapse;</xsl:text>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'top'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="../@frame='bottom' or (not(../@frame) and $default.table.frame='bottom')">
        <xsl:text>border-collapse: collapse;</xsl:text>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'bottom'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="../@frame='sides' or (not(../@frame) and $default.table.frame='sides')">
        <xsl:text>border-collapse: collapse;</xsl:text>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'left'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'right'"/>
          <xsl:with-param name="style" select="$table.frame.border.style"/>
          <xsl:with-param name="color" select="$table.frame.border.color"/>
          <xsl:with-param name="thickness" select="$table.frame.border.thickness"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="../@frame='none'">
        <xsl:text>border: none;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>border-collapse: collapse;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="colclass">
    <xsl:choose>
      <xsl:when test="@cols &lt; 4"><xsl:text>lt-4-cols</xsl:text></xsl:when>
      <xsl:when test="@cols &lt; 9"><xsl:text>gt-4-cols</xsl:text></xsl:when>
      <xsl:otherwise><xsl:text>gt-8-cols</xsl:text></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="rowclass">
    <xsl:choose>
      <xsl:when test="count(row) &lt; 7"><xsl:text>lt-7-rows</xsl:text></xsl:when>
      <xsl:when test="count(row) &lt; 15"><xsl:text>gt-7-rows</xsl:text></xsl:when>
      <xsl:otherwise><xsl:text>gt-14-rows</xsl:text></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <table>
    <xsl:attribute name="class">
      <xsl:value-of select="$colclass"/><xsl:text> </xsl:text><xsl:value-of select="$rowclass"/>
    </xsl:attribute>
    <xsl:copy-of select="$colgroup"/>

    <xsl:apply-templates select="d:thead"/>
    <xsl:apply-templates select="d:tfoot"/>
    <xsl:apply-templates select="d:tbody"/>

    <xsl:if test=".//d:footnote|../d:title//d:footnote">
      <tbody class="footnotes">
        <tr>
          <td colspan="{@cols}">
            <xsl:apply-templates select=".//d:footnote|../d:title//d:footnote" mode="table.footnote.mode"/>
          </td>
        </tr>
      </tbody>
    </xsl:if>
  </table>
</xsl:template>

<xsl:template match="d:replaceable" priority="1">
  <xsl:call-template name="inline.italicseq"/>
</xsl:template>

</xsl:stylesheet>

