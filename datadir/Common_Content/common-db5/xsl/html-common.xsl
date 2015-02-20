<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:d="http://docbook.org/ns/docbook"
  version="1.0"
  xmlns:stbl="http://nwalsh.com/xslt/ext/com.nwalsh.saxon.Table"
  xmlns:xtbl="xalan://com.nwalsh.xalan.Table"
  xmlns:ptbl="http://nwalsh.com/xslt/ext/xsltproc/python/Table"
  xmlns:sverb="http://nwalsh.com/xslt/ext/com.nwalsh.saxon.Verbatim"
  xmlns:xverb="xalan://com.nwalsh.xalan.Verbatim"
  xmlns:exsl="http://exslt.org/common"
  xmlns:simg="http://nwalsh.com/xslt/ext/com.nwalsh.saxon.ImageIntrinsics" 
  xmlns:ximg="xalan://com.nwalsh.xalan.ImageIntrinsics" 
  xmlns:perl="urn:perl"
  exclude-result-prefixes="stbl xtbl ptbl exsl d sverb xverb simg ximg"
  extension-element-prefixes="perl d"
>
<xsl:param name="embedtoc"  select="'0'"/>
<xsl:param name="tocpath"   select="''"/>
<xsl:param name="pop_prod"  select="''"/>
<xsl:param name="pop_ver"   select="''"/>
<xsl:param name="pop_name"  select="''"/>
<xsl:param name="brand"     select="''"/>
<xsl:param name="langpath"  select="''"/>
<xsl:param name="desktop"   select="0"/>

<xsl:param name="tablecolumns.extension" select="1"/>
<xsl:param name="use.embed.for.svg" select="1"/>
<xsl:param name="table.borders.with.css" select="0"/>
<xsl:param name="ulink.target" select="''"/>
<xsl:param name="qandadiv.autolabel" select="1"/>
<xsl:param name="generate.section.toc.level" select="0"/>
<xsl:param name="qanda.defaultlabel">qanda</xsl:param>
<xsl:param name="glossary.sort" select="1"/>
<xsl:param name="formal.object.break.after">0</xsl:param>
<xsl:param name="highlight.source" select="0"/>
<xsl:param name="draft.mode">maybe</xsl:param>
<xsl:param name="poper.as.dl"  select="0"/>
<xsl:param name="callout.list.table" select="0"/>
<xsl:param name="callout.graphics" select="0"/>
<xsl:param name="callouts.extension" select="1"/>
<xsl:param name="chunk.first.sections" select="0"/>
<xsl:param name="chunk.toc" select="''"/>
<xsl:param name="chunk.section.depth" select="1"/>
<xsl:param name="chunk.tocs.and.lots" select="0"/>
<xsl:param name="linenumbering.extension" select="0"/>
<xsl:param name="chunk.quietly" select="1"/>

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
<xsl:param name="html.stylesheet"></xsl:param>
<xsl:param name="html.stylesheet.type" select="'text/css'"/>
<xsl:param name="html.stylesheet.print"><xsl:if test="$embedtoc = 0 ">Common_Content/css/print.css</xsl:if></xsl:param>
<xsl:param name="html.ext" select="'.html'"/>
<xsl:param name="suppress.header.navigation" select="0"/>
<xsl:param name="suppress.footer.navigation" select="'1'"/>
<xsl:param name="css.decoration" select="0"/>
<xsl:param name="use.id.as.filename" select="'1'"/>
<xsl:param name="docbook.css.link" select="0"/>
<xsl:param name="generate.css.header" select="0"/>
<xsl:param name="make.clean.html" select="0"/>
<xsl:param name="html.cleanup" select="0"/>
<xsl:param name="email.delimiters.enabled">0</xsl:param>

<xsl:param name="section.autolabel" select="1"/>
<xsl:param name="section.label.includes.component.label" select="0"/>

<xsl:param name="local.l10n.xml" select="document('')"/>

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

<!-- Change Japanese name order to first-last BZ#1150866 -->
<xsl:param name="local.l10n.xml" select="document('')"/>
<l:i18n xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0">
    <l:l10n language="ja">
      <l:context name="styles">
        <l:template name="person-name" text="first-last"/>
      </l:context>
    </l:l10n>
</l:i18n>

<xsl:template name="head.content.generator">
  <xsl:param name="node" select="."/>
  <meta name="generator" content="publican {$publican.version}"/>
</xsl:template>

<xsl:template name="user.head.content">
  <xsl:param name="node" select="."/>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <xsl:if test="$embedtoc = 1">
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../common-db5/en-US/scripts/highlight.js/styles/docco.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../chrome.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../db5.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../<xsl:value-of select="$brand"/>/<xsl:value-of select="$langpath"/>/css/brand.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href"><xsl:value-of select="$tocpath"/>/../print.css</xsl:attribute><xsl:attribute name="media">print</xsl:attribute></link>
    <script type="text/javascript">
        <xsl:attribute name="src"><xsl:value-of select="$tocpath"/>/../jquery-1.7.1.min.js</xsl:attribute>
        <xsl:text> </xsl:text>
    </script>
    <script type="text/javascript">
        <xsl:attribute name="src"><xsl:value-of select="$tocpath"/>/labels.js</xsl:attribute>
        <xsl:text> </xsl:text>
    </script>
    <script type="text/javascript">
        <xsl:attribute name="src"><xsl:value-of select="$tocpath"/>/../toc.js</xsl:attribute>
        <xsl:text> </xsl:text>
    </script>
    <script type="text/javascript">
        <xsl:attribute name="src"><xsl:value-of select="$tocpath"/>/../common-db5/en-US/scripts/utils.js</xsl:attribute>
        <xsl:text> </xsl:text>
    </script>
    <script type="text/javascript">
        <xsl:attribute name="src"><xsl:value-of select="$tocpath"/>/../common-db5/en-US/scripts/highlight.js/highlight.pack.js</xsl:attribute>
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
  <xsl:if test="$embedtoc != 1">
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href">Common_Content/scripts/highlight.js/styles/docco.css</xsl:attribute></link>
    <link rel="stylesheet" type="text/css"><xsl:attribute name="href">Common_Content/css/default.css</xsl:attribute></link>
    <script type="text/javascript">
        <xsl:attribute name="src">Common_Content/scripts/jquery-1.7.1.min.js</xsl:attribute>
        <xsl:text> </xsl:text>
    </script>
    <script type="text/javascript">
        <xsl:attribute name="src">Common_Content/scripts/highlight.js/highlight.pack.js</xsl:attribute>
        <xsl:text> </xsl:text>
    </script>
    <script type="text/javascript">
        <xsl:attribute name="src">Common_Content/scripts/utils.js</xsl:attribute>
        <xsl:text> </xsl:text>
    </script>
  </xsl:if>
</xsl:template>

<xsl:template name="user.header.content">
  <xsl:param name="node" select="."/>
  <xsl:if test="$embedtoc = 1">
        <div id="navigation"><xsl:text> </xsl:text></div>
  </xsl:if>
  <div id="poptoc" class="hidden"><xsl:text> </xsl:text></div>
</xsl:template>

<xsl:template name="head.content.style"/>

<xsl:template name="body.attributes">
    <xsl:if test="starts-with($writing.mode, 'rl')">
        <xsl:attribute name="dir">rtl</xsl:attribute>
    </xsl:if>
    <xsl:variable name="class">
        <xsl:if test="ancestor-or-self::*[@status][1]/@status = 'draft'">
            <xsl:text>draft </xsl:text>
        </xsl:if>
        <xsl:if test="$embedtoc != 0">
            <xsl:text>menu_embeded </xsl:text>
        </xsl:if>
               <xsl:if test="$desktop != 0">
          <xsl:text>desktop </xsl:text>
        </xsl:if>
    </xsl:variable>
        <xsl:if test="$class != ''">
      <xsl:attribute name="class">
        <xsl:value-of select="$class"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:attribute name="onLoad">initSwitchery(); jQuery("#poptoc").load('index.html .toc:eq(0)'); jQuery('.programlisting').each(function(i, block){hljs.highlightBlock(block);});</xsl:attribute>
    <xsl:attribute name="onClick">hide('poptoc');</xsl:attribute>
</xsl:template>

<xsl:template match="*" mode="class.attribute">
  <xsl:param name="class" select="local-name(.)"/>
  <!-- permit customization of class attributes -->
  <!-- Use element name by default -->
  <xsl:variable name="class.value">
    <xsl:apply-templates select="." mode="class.value">
      <xsl:with-param name="class" select="$class"/>
    </xsl:apply-templates>
    <xsl:if test="@role">
        <xsl:text> </xsl:text>
        <xsl:value-of select="@role"/>
    </xsl:if>
    <xsl:if test="@revisionflag and (ancestor-or-self::*[@status][1]/@status = 'draft')">
        <xsl:text> </xsl:text>
        <xsl:value-of select="@revisionflag"/>
    </xsl:if>
  </xsl:variable>

  <xsl:if test="string-length(normalize-space($class.value)) != 0">
    <xsl:attribute name="class">
      <xsl:value-of select="$class.value"/>
    </xsl:attribute>
  </xsl:if>
</xsl:template>

<xsl:template name="inline.charseq">
  <xsl:param name="content">
    <xsl:call-template name="anchor"/>
    <xsl:call-template name="simple.xlink">
      <xsl:with-param name="content">
        <xsl:apply-templates/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:param>
  <!-- * if you want output from the inline.charseq template wrapped in -->
  <!-- * something other than a Span, call the template with some value -->
  <!-- * for the 'wrapper-name' param -->
  <xsl:param name="wrapper-name">span</xsl:param>
  <xsl:element name="{$wrapper-name}" namespace="http://www.w3.org/1999/xhtml">
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:call-template name="id.attribute"/>
    <xsl:call-template name="dir"/>
    <xsl:call-template name="generate.html.title"/>
    <xsl:copy-of select="$content"/>
    <xsl:call-template name="apply-annotations"/>
  </xsl:element>
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
          <xsl:when test="function-available('perl:adjustColumnWidths')">
            <xsl:copy-of select="perl:adjustColumnWidths($table.width, $colgroup.with.attributes)"/>
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
      <xsl:when test="count(tbody/row) &lt; 7"><xsl:text>lt-7-rows</xsl:text></xsl:when>
      <xsl:when test="count(tbody/row) &lt; 15"><xsl:text>gt-7-rows</xsl:text></xsl:when>
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

<xsl:template match="d:uri">
  <!--xsl:call-template name="inline.charseq"/-->
    <xsl:call-template name="anchor"/>
    <xsl:call-template name="simple.xlink">
      <xsl:with-param name="content">
        <xsl:apply-templates/>
      </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="number.rtf.lines">
  <xsl:param name="rtf" select="''"/>
  <xsl:param name="pi.context" select="."/>

  <!-- Save the global values -->
  <xsl:variable name="global.linenumbering.everyNth" select="$linenumbering.everyNth"/>

  <xsl:variable name="global.linenumbering.separator" select="$linenumbering.separator"/>

  <xsl:variable name="global.linenumbering.width" select="$linenumbering.width"/>

  <!-- Extract the <?dbhtml linenumbering.*?> PI values -->
  <xsl:variable name="pi.linenumbering.everyNth">
    <xsl:call-template name="pi.dbhtml_linenumbering.everyNth">
      <xsl:with-param name="node" select="$pi.context"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="pi.linenumbering.separator">
    <xsl:call-template name="pi.dbhtml_linenumbering.separator">
      <xsl:with-param name="node" select="$pi.context"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="pi.linenumbering.width">
    <xsl:call-template name="pi.dbhtml_linenumbering.width">
      <xsl:with-param name="node" select="$pi.context"/>
    </xsl:call-template>
  </xsl:variable>

  <!-- Construct the 'in-context' values -->
  <xsl:variable name="linenumbering.everyNth">
    <xsl:choose>
      <xsl:when test="$pi.linenumbering.everyNth != ''">
        <xsl:value-of select="$pi.linenumbering.everyNth"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$global.linenumbering.everyNth"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="linenumbering.separator">
    <xsl:choose>
      <xsl:when test="$pi.linenumbering.separator != ''">
        <xsl:value-of select="$pi.linenumbering.separator"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$global.linenumbering.separator"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="linenumbering.width">
    <xsl:choose>
      <xsl:when test="$pi.linenumbering.width != ''">
        <xsl:value-of select="$pi.linenumbering.width"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$global.linenumbering.width"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="linenumbering.startinglinenumber">
    <xsl:choose>
      <xsl:when test="$pi.context/@startinglinenumber">
        <xsl:value-of select="$pi.context/@startinglinenumber"/>
      </xsl:when>
      <xsl:when test="$pi.context/@continuation='continues'">
        <xsl:variable name="lastLine">
          <xsl:choose>
            <xsl:when test="$pi.context/self::d:programlisting">
              <xsl:call-template name="lastLineNumber">
                <xsl:with-param name="listings" select="preceding::d:programlisting[@linenumbering='numbered']"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$pi.context/self::d:screen">
              <xsl:call-template name="lastLineNumber">
                <xsl:with-param name="listings" select="preceding::d:screen[@linenumbering='numbered']"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$pi.context/self::d:literallayout">
              <xsl:call-template name="lastLineNumber">
                <xsl:with-param name="listings" select="preceding::d:literallayout[@linenumbering='numbered']"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$pi.context/self::d:address">
              <xsl:call-template name="lastLineNumber">
                <xsl:with-param name="listings" select="preceding::d:address[@linenumbering='numbered']"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$pi.context/self::d:synopsis">
              <xsl:call-template name="lastLineNumber">
                <xsl:with-param name="listings" select="preceding::d:synopsis[@linenumbering='numbered']"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:message>
                <xsl:text>Unexpected verbatim environment: </xsl:text>
                <xsl:value-of select="local-name($pi.context)"/>
              </xsl:message>
              <xsl:value-of select="0"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:value-of select="$lastLine + 1"/>
      </xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="function-available('sverb:numberLines')">
      <xsl:copy-of select="sverb:numberLines($rtf)"/>
    </xsl:when>
    <xsl:when test="function-available('xverb:numberLines')">
      <xsl:copy-of select="xverb:numberLines($rtf)"/>
    </xsl:when>
    <xsl:when test="function-available('perl:numberLines')">
      <xsl:copy-of select="perl:numberLines($linenumbering.startinglinenumber, $rtf)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message terminate="yes">
        <xsl:text>No numberLines function available.</xsl:text>
      </xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="graphical.admonition">
    <xsl:variable name="admon.type">
        <xsl:choose>
            <xsl:when test="local-name(.)='note'">Note</xsl:when>
            <xsl:when test="local-name(.)='warning'">Warning</xsl:when>
            <xsl:when test="local-name(.)='important'">Important</xsl:when>
            <xsl:when test="local-name(.)='tip'">Tip</xsl:when>
            <xsl:when test="local-name(.)='caution'">Caution</xsl:when>
            <xsl:otherwise>Note</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="alt">
        <xsl:call-template name="gentext">
            <xsl:with-param name="key" select="$admon.type"/>
        </xsl:call-template>
    </xsl:variable>

    <div xmlns="http://www.w3.org/1999/xhtml">
                <xsl:call-template name="common.html.attributes"/>
        <xsl:apply-templates select="." mode="class.attribute">
            <xsl:with-param name="class" select="concat('admonition ', local-name(.))"/>
        </xsl:apply-templates>
            
        <xsl:if test="$admon.style != ''">
            <xsl:attribute name="style">
                <xsl:value-of select="$admon.style"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="@id or @xml:id">
            <xsl:attribute name="id">
                <xsl:value-of select="(@id|@xml:id)[1]"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="$admon.textlabel != 0 or title">
            <div class="admonition_header">
                <xsl:apply-templates select="." mode="object.title.markup"/>
            </div>
        </xsl:if>
        <div>
            <xsl:apply-templates/>
        </div>
    </div>
</xsl:template>

<xsl:template name="header.navigation">
    <xsl:param name="prev" select="/foo"/>
    <xsl:param name="next" select="/foo"/>
    <xsl:param name="nav.context"/>
    <xsl:variable name="home" select="/*[1]"/>
    <xsl:variable name="up" select="parent::*"/>
    <xsl:variable name="row1" select="$navig.showtitles != 0"/>
    <xsl:variable name="row2" select="count($prev) &gt; 0 or (count($up) &gt; 0 and generate-id($up) != generate-id($home) and $navig.showtitles != 0) or count($next) &gt; 0"/>
    <xsl:if test="$suppress.navigation = '0' and $suppress.header.navigation = '0'">
        <xsl:if test="$row1 or $row2">
            <xsl:if test="$row1">
            </xsl:if>
            <xsl:if test="$row2">
                <ul class="docnav top" xmlns="http://www.w3.org/1999/xhtml">
                    <li class="previous">
                        <xsl:if test="count($prev)&gt;0">
                            <a accesskey="p">
                                <xsl:attribute name="href">
                                    <xsl:call-template name="href.target">
                                        <xsl:with-param name="object" select="$prev"/>
                                    </xsl:call-template>
                                </xsl:attribute>
                                <strong>
                                    <xsl:call-template name="navig.content">
                                        <xsl:with-param name="direction" select="'prev'"/>
                                    </xsl:call-template>
                                </strong>
                            </a>
                        </xsl:if>
                    </li>
                        <li class="home">
                         <xsl:attribute name="onClick">work=1;showhide('poptoc');</xsl:attribute>
                        <xsl:value-of select="$clean_title"/>
                        </li>
                        <li class="next">
                        <xsl:if test="count($next)&gt;0">
                            <a accesskey="n">
                                <xsl:attribute name="href">
                                    <xsl:call-template name="href.target">
                                        <xsl:with-param name="object" select="$next"/>
                                    </xsl:call-template>
                                </xsl:attribute>
                                <strong>
                                    <xsl:call-template name="navig.content">
                                        <xsl:with-param name="direction" select="'next'"/>
                                    </xsl:call-template>
                                </strong>
                            </a>
                        </xsl:if>
                    </li>
                </ul>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$header.rule != 0">
            <hr/>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!--
From: xhtml/chunk-common.xsl
Reason: remove tables, truncate link text
Version:
-->
<xsl:template name="footer.navigation">
    <xsl:param name="prev" select="/foo"/>
    <xsl:param name="next" select="/foo"/>
    <xsl:param name="nav.context"/>
    <xsl:param name="title-limit" select="'50'"/>
    <xsl:variable name="home" select="/*[1]"/>
    <xsl:variable name="up" select="parent::*"/>
    <xsl:variable name="row1" select="count($prev) &gt; 0 or count($up) &gt; 0 or count($next) &gt; 0"/>
    <xsl:variable name="row2" select="($prev and $navig.showtitles != 0) or (generate-id($home) != generate-id(.) or $nav.context = 'toc') or ($chunk.tocs.and.lots != 0 and $nav.context != 'toc') or ($next and $navig.showtitles != 0)"/>

    <xsl:if test="$suppress.navigation = '0' and $suppress.footer.navigation = '0'">
        <xsl:if test="$footer.rule != 0">
            <hr/>
        </xsl:if>
        <xsl:if test="$row1 or $row2">
            <ul class="docnav bottom" xmlns="http://www.w3.org/1999/xhtml">
                <xsl:if test="$row1">
                    <li class="previous">
                        <xsl:if test="count($prev) &gt; 0">
                            <a accesskey="p">
                                <xsl:attribute name="href">
                                    <xsl:call-template name="href.target">
                                        <xsl:with-param name="object" select="$prev"/>
                                    </xsl:call-template>
                                </xsl:attribute>
                                <strong>
                                    <xsl:call-template name="navig.content">
                                        <xsl:with-param name="direction" select="'prev'"/>
                                    </xsl:call-template>
                                </strong>
                                <xsl:variable name="text">
                                    <xsl:apply-templates select="$prev" mode="object.title.markup"/>
                                </xsl:variable>
                                <xsl:choose>
                                    <xsl:when test="string-length($text) &gt; $title-limit">
                                        <xsl:value-of select="concat(substring($text, 0, $title-limit), '...')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$text"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </a>
                        </xsl:if>
                    </li>
                    <xsl:if test="count($up) &gt; 0">
                        <li class="up">
                            <a accesskey="u">
                                <xsl:attribute name="href">
                                    <xsl:text>#</xsl:text>
                                </xsl:attribute>
                                <strong>
                                    <xsl:call-template name="navig.content">
                                        <xsl:with-param name="direction" select="'up'"/>
                                    </xsl:call-template>
                                </strong>
                            </a>
                        </li>
                    </xsl:if>
                    <xsl:if test="$home != . or $nav.context = 'toc'">
                        <li class="home">
                            <a accesskey="h">
                                <xsl:attribute name="href">
                                    <xsl:call-template name="href.target">
                                        <xsl:with-param name="object" select="$home"/>
                                    </xsl:call-template>
                                </xsl:attribute>
                                <strong>
                                    <xsl:call-template name="navig.content">
                                        <xsl:with-param name="direction" select="'home'"/>
                                    </xsl:call-template>
                                </strong>
                            </a>
                        </li>
                    </xsl:if>
                    <xsl:if test="count($next)&gt;0">
                        <li class="next">
                            <a accesskey="n">
                                <xsl:attribute name="href">
                                    <xsl:call-template name="href.target">
                                        <xsl:with-param name="object" select="$next"/>
                                    </xsl:call-template>
                                </xsl:attribute>
                                <strong>
                                    <xsl:call-template name="navig.content">
                                        <xsl:with-param name="direction" select="'next'"/>
                                    </xsl:call-template>
                                </strong>
                                <xsl:variable name="text">
                                    <xsl:apply-templates select="$next" mode="object.title.markup"/>
                                </xsl:variable>
                                <xsl:choose>
                                    <xsl:when test="string-length($text) &gt; $title-limit">
                                        <xsl:value-of select="concat(substring($text, 0, $title-limit),'...')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$text"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </a>
                        </li>
                    </xsl:if>
                </xsl:if>
            </ul>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!--
From: xhtml/qandaset.xsl
Reason: No stinking tables
Version: 1.72.0
-->
<xsl:template name="d:qandaset">
  <div class="qandaset">
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates />
  </div>
</xsl:template>

<xsl:template name="process.qandaset">
  <div class="qandaset">
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates />
  </div>
</xsl:template>

<xsl:template match="qandadiv">
  <xsl:variable name="preamble" select="*[local-name(.) != 'title'                                           and local-name(.) != 'titleabbrev'                                           and local-name(.) != 'qandadiv'                                           and local-name(.) != 'qandaentry']"/>

  <xsl:if test="blockinfo/title|info/title|title">
    <div class="qandadiv">
        <xsl:apply-templates select="(blockinfo/title|info/title|title)[1]"/>
    </div>
  </xsl:if>

  <xsl:variable name="toc">
    <xsl:call-template name="dbhtml-attribute">
      <xsl:with-param name="pis" select="processing-instruction('dbhtml')"/>
      <xsl:with-param name="attribute" select="'toc'"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="toc.params">
    <xsl:call-template name="find.path.params">
      <xsl:with-param name="table" select="normalize-space($generate.toc)"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:if test="(contains($toc.params, 'toc') and $toc != '0') or $toc = '1'">
    <div class="toc">
        <xsl:call-template name="process.qanda.toc"/>
    </div>
  </xsl:if>
  <xsl:if test="$preamble">
    <div class="preamble">
        <xsl:apply-templates select="$preamble"/>
    </div>
  </xsl:if>
  <div>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates select="qandadiv|qandaentry"/>
  </div>
</xsl:template>

<xsl:template match="d:qandaentry">
  <div>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="d:question">
  <xsl:variable name="deflabel">
    <xsl:choose>
      <xsl:when test="ancestor-or-self::*[@defaultlabel]">
        <xsl:value-of select="(ancestor-or-self::*[@defaultlabel])[last()] /@defaultlabel"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$qanda.defaultlabel"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="label.content">
    <xsl:apply-templates select="." mode="label.markup"/>
    <xsl:if test="$deflabel = 'number' and not(label)">
      <xsl:apply-templates select="." mode="intralabel.punctuation"/>
    </xsl:if>
  </xsl:variable>
  <div>
    <xsl:apply-templates select="." mode="class.attribute"/>
      <xsl:call-template name="anchor">
        <xsl:with-param name="node" select=".."/>
        <xsl:with-param name="conditional" select="0"/>
      </xsl:call-template>
      <!--xsl:call-template name="anchor">
        <xsl:with-param name="conditional" select="0"/>
      </xsl:call-template-->
      <xsl:if test="string-length($label.content) &gt; 0">
        <div class="label">
          <xsl:copy-of select="$label.content"/>
        </div>
      </xsl:if>
    <div class="data">
      <xsl:apply-templates/>
    </div>
  </div>
</xsl:template>

<xsl:template match="d:answer">
  <xsl:variable name="deflabel">
    <xsl:choose>
      <xsl:when test="ancestor-or-self::*[@defaultlabel]">
        <xsl:value-of select="(ancestor-or-self::*[@defaultlabel])[last()] /@defaultlabel"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$qanda.defaultlabel"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div>
    <xsl:apply-templates select="." mode="class.attribute"/>
    <xsl:variable name="answer.label">
      <xsl:apply-templates select="." mode="label.markup"/>
    </xsl:variable>
    <xsl:if test="string-length($answer.label) &gt; 0">
      <div class="label">
        <xsl:copy-of select="$answer.label"/>
      </div>
    </xsl:if>
     <div class="data">
       <xsl:apply-templates />
     </div>
   </div>
</xsl:template>

<!-- change <video> to iframe -->
<xsl:template match="d:videodata">
  <xsl:variable name="filename">
    <xsl:call-template name="mediaobject.filename">
      <xsl:with-param name="object" select=".."/>
    </xsl:call-template>
  </xsl:variable>

  <iframe>
    <xsl:call-template name="common.html.attributes"/>

    <xsl:attribute name="src">
      <xsl:value-of select="$filename"/>
    </xsl:attribute>

    <xsl:call-template name="video.poster"/>

    <xsl:apply-templates select="@*[local-name() != 'fileref']"/>
    <xsl:apply-templates select="../d:multimediaparam"/>
    
    <!-- add any fallback content -->
    <xsl:call-template name="video.fallback"/>
    <xsl:text> </xsl:text>
  </iframe>
</xsl:template>

<!-- add iframe to img rules -->
<xsl:template match="*" mode="convert.to.style">

  <xsl:variable name="element" select="local-name(.)"/>

  <xsl:variable name="style.from.atts">
    <xsl:for-each select="@*">

      <xsl:choose>
        <!-- width and height attributes are ok for img element -->
        <xsl:when test="local-name() = 'width' and ($element != 'img' and  $element != 'iframe')">
          <xsl:text>width: </xsl:text>
          <xsl:value-of select="."/>
          <xsl:text>; </xsl:text>
        </xsl:when>

        <xsl:when test="local-name() = 'height' and ($element != 'img' and  $element != 'iframe')">
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
        <xsl:when test="local-name(.) = 'width' and ( $element != 'img' and  $element != 'iframe')"/>
        <xsl:when test="local-name(.) = 'height' and ( $element != 'img' and  $element != 'iframe')"/>
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

<xsl:template match="d:programlisting|d:screen|d:synopsis">
  <xsl:param name="suppress-numbers" select="'0'"/>
  <xsl:param name="set-id" select="'0'"/>

  <xsl:call-template name="anchor"/>
  
  <xsl:variable name="div.element">pre</xsl:variable>
  <xsl:variable name="myclass">
    <xsl:value-of  select="local-name(.)"/>
    <xsl:if test="@language != ''">
      <xsl:value-of select="concat(' ', translate(@language, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'))"/>
    </xsl:if>
    <xsl:if test="@role != ''">
      <xsl:text> </xsl:text><xsl:value-of select="@role"/>
    </xsl:if>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$suppress-numbers = '0'
                and @linenumbering = 'numbered'
                and $use.extensions != '0'
                and $linenumbering.extension != '0'">
      <xsl:variable name="rtf">
        <xsl:choose>
          <xsl:when test="$highlight.source != 0">
            <xsl:call-template name="apply-highlighting"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:element name="{$div.element}" namespace="http://www.w3.org/1999/xhtml">
        <!--xsl:apply-templates select="." mode="common.html.attributes"/-->
        <xsl:call-template name="common.html.attributes"/>
        <xsl:apply-templates select="." mode="class.attribute">
            <xsl:with-param name="class" select="$myclass"/>
        </xsl:apply-templates>
        <xsl:call-template name="id.attribute"/>
        <xsl:if test="$set-id != 0">
          <xsl:attribute name="id">
            <xsl:value-of select="$set-id"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="@width != ''">
          <xsl:attribute name="width">
            <xsl:value-of select="@width"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="@role = 'popper' and $poper.as.dl = '0'">
        <a href="#" onclick="pop(this);return false;" class="show">[Show All]</a><a href="#" onclick="unpop(this);return false;" class="hide">[Hide]</a>
        </xsl:if>
        <xsl:call-template name="number.rtf.lines">
          <xsl:with-param name="rtf" select="$rtf"/>
        </xsl:call-template>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="{$div.element}" namespace="http://www.w3.org/1999/xhtml">
        <xsl:apply-templates select="." mode="common.html.attributes"/>
        <xsl:call-template name="common.html.attributes"/>
        <xsl:apply-templates select="." mode="class.attribute">
            <xsl:with-param name="class" select="$myclass"/>
        </xsl:apply-templates>
        <xsl:call-template name="id.attribute"/>
        <xsl:if test="$set-id != 0">
          <xsl:attribute name="id">
            <xsl:value-of select="$set-id"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="@width != ''">
          <xsl:attribute name="width">
            <xsl:value-of select="@width"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="@linenumbering = 'numbered'">
          <xsl:attribute name="class">
            <xsl:value-of select="$myclass"/><xsl:text> numbered</xsl:text>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="@role = 'popper' and $poper.as.dl = '0'">
        <a href="#" onclick="pop(this);return false;" class="show">[Show All]</a><a href="#" onclick="unpop(this);return false;" class="hide">[Hide]</a>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$highlight.source != 0">
            <xsl:call-template name="apply-highlighting"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="d:informalexample">
  <xsl:param name="class">
    <xsl:apply-templates select="." mode="class.value"/>
  </xsl:param>
  <xsl:param name="id">
        <xsl:call-template name="object.id"/>
  </xsl:param>

  <xsl:choose>
    <xsl:when test="@role = 'switchery' and $poper.as.dl = '1'">
      <div class="{$class} {@role}">
        <xsl:call-template name="id.attribute"/>
      <dl>
        <xsl:call-template name="anchor"/>
        <xsl:for-each select="d:programlisting">
          <dt><xsl:value-of select="@language" /></dt>
      <dd>
            <xsl:apply-templates select=".">
              <xsl:with-param name="set-id" select="concat($id, '-code')"/>
            </xsl:apply-templates>
          </dd>
        </xsl:for-each>
      </dl>
      </div>
    </xsl:when>
    <xsl:when test="@role = 'switchery' and $poper.as.dl = '0'">
      <div class="{$class} {@role}">
        <xsl:call-template name="id.attribute"/>
        <xsl:call-template name="anchor"/>
        <div class="labels">
          <xsl:for-each select="d:programlisting">
        <span id="{$id}-{@language}" onclick="activateElement('{$id}-{@language}'); activateElement('{$id}-{@language}-code'); return false;" >
          <xsl:value-of select="@language" />
        </span>
      </xsl:for-each>
                <select class="deflang" onchange="setDefLangCookie(this)">
                    <option value="">Default Language</option>
                  <xsl:for-each select="d:programlisting">
                    <option value="{@language}"><xsl:value-of select="@language"/></option>
              </xsl:for-each>
                </select>
        </div>
        <div class="code">
        <xsl:for-each select="d:programlisting">
            <xsl:apply-templates select=".">
              <xsl:with-param name="set-id" select="concat($id, '-', @language, '-code')"/>
            </xsl:apply-templates>
        </xsl:for-each>
        </div>
      </div>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="informal.object"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="d:formalpara/d:title|d:formalpara/d:info/d:title">
  <xsl:variable name="titleStr">
      <xsl:apply-templates/>
  </xsl:variable>
  <xsl:variable name="lastChar">
    <xsl:if test="$titleStr != ''">
      <xsl:value-of select="substring($titleStr,string-length($titleStr),1)"/>
    </xsl:if>
  </xsl:variable>

  <span class="formalpara-title">
    <xsl:copy-of select="$titleStr"/>
    <xsl:if test="$lastChar != '' and not(contains($runinhead.title.end.punct, $lastChar))">
      <xsl:value-of select="$runinhead.default.title.end.punct"/>
    </xsl:if>
  </span>
</xsl:template>

<xsl:template name="book.titlepage.recto">
  <xsl:choose>
    <xsl:when test="d:bookinfo/d:title">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:bookinfo/d:title"/>
    </xsl:when>
    <xsl:when test="d:info/d:title">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:title"/>
    </xsl:when>
    <xsl:when test="d:title">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:title"/>
    </xsl:when>
  </xsl:choose>

  <xsl:choose>
    <xsl:when test="d:bookinfo/d:subtitle">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:bookinfo/d:subtitle"/>
    </xsl:when>
    <xsl:when test="d:info/d:subtitle">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:subtitle"/>
    </xsl:when>
    <xsl:when test="d:subtitle">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:subtitle"/>
    </xsl:when>
  </xsl:choose>

  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:mediaobject[@role='logo']"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:authorgroup"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:author"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:othercredit"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:releaseinfo"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:copyright"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:legalnotice"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:pubdate"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:revision"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:revhistory"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:abstract"/>
</xsl:template>


<xsl:template match="d:mediaobject" mode="book.titlepage.recto.auto.mode">
<div>
<xsl:apply-templates select="."/>
</div>
</xsl:template>

<xsl:template match="d:mediaobject" mode="article.titlepage.recto.auto.mode">
<div>
<xsl:apply-templates select="."/>
</div>
</xsl:template>
<xsl:template name="process.image">
  <!-- When this template is called, the current node should be  -->
  <!-- a graphic, inlinegraphic, imagedata, or videodata. All    -->
  <!-- those elements have the same set of attributes, so we can -->
  <!-- handle them all in one place.                             -->
  <xsl:param name="tag" select="'img'"/>
  <xsl:param name="alt"/>
  <xsl:param name="longdesc"/>

  <!-- The HTML img element only supports the notion of content-area
       scaling; it doesn't support the distinction between a
       content-area and a viewport-area, so we have to make some
       compromises.

       1. If only the content-area is specified, everything is fine.
          (If you ask for a three inch image, that's what you'll get.)

       2. If only the viewport-area is provided:
          - If scalefit=1, treat it as both the content-area and
            the viewport-area. (If you ask for an image in a five inch
            area, we'll make the image five inches to fill that area.)
          - If scalefit=0, ignore the viewport-area specification.

          Note: this is not quite the right semantic and has the additional
          problem that it can result in anamorphic scaling, which scalefit
          should never cause.

       3. If both the content-area and the viewport-area is specified
          on a graphic element, ignore the viewport-area.
          (If you ask for a three inch image in a five inch area, we'll assume
           it's better to give you a three inch image in an unspecified area
           than a five inch image in a five inch area.

       Relative units also cause problems. As a general rule, the stylesheets
       are operating too early and too loosely coupled with the rendering engine
       to know things like the current font size or the actual dimensions of
       an image. Therefore:

       1. We use a fixed size for pixels, $pixels.per.inch

       2. We use a fixed size for "em"s, $points.per.em

       Percentages are problematic. In the following discussion, we speak
       of width and contentwidth, but the same issues apply to depth and
       contentdepth

       1. A width of 50% means "half of the available space for the image."
          That's fine. But note that in HTML, this is a dynamic property and
          the image size will vary if the browser window is resized.

       2. A contentwidth of 50% means "half of the actual image width". But
          the stylesheets have no way to assess the image's actual size. Treating
          this as a width of 50% is one possibility, but it produces behavior
          (dynamic scaling) that seems entirely out of character with the
          meaning.

          Instead, the stylesheets define a $nominal.image.width
          and convert percentages to actual values based on that nominal size.

       Scale can be problematic. Scale applies to the contentwidth, so
       a scale of 50 when a contentwidth is not specified is analagous to a
       width of 50%. (If a contentwidth is specified, the scaling factor can
       be applied to that value and no problem exists.)

       If scale is specified but contentwidth is not supplied, the
       nominal.image.width is used to calculate a base size
       for scaling.

       Warning: as a consequence of these decisions, unless the aspect ratio
       of your image happens to be exactly the same as (nominal width / nominal height),
       specifying contentwidth="50%" and contentdepth="50%" is NOT going to
       scale the way you expect (or really, the way it should).

       Don't do that. In fact, a percentage value is not recommended for content
       size at all. Use scale instead.

       Finally, align and valign are troublesome. Horizontal alignment is now
       supported by wrapping the image in a <div align="{@align}"> (in block
       contexts!). I can't think of anything (practical) to do about vertical
       alignment.
  -->

  <xsl:variable name="width-units">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0"/>
      <xsl:when test="@width">
        <xsl:call-template name="length-units">
          <xsl:with-param name="length" select="@width"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="not(@depth) and $default.image.width != ''">
        <xsl:call-template name="length-units">
          <xsl:with-param name="length" select="$default.image.width"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="width">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0"/>
      <xsl:when test="@width">
        <xsl:choose>
          <xsl:when test="$width-units = '%'">
            <xsl:value-of select="@width"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="length-spec">
              <xsl:with-param name="length" select="@width"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="not(@depth) and $default.image.width != ''">
        <xsl:value-of select="$default.image.width"/>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="scalefit">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0">0</xsl:when>
      <xsl:when test="@contentwidth or @contentdepth">0</xsl:when>
      <xsl:when test="@scale">0</xsl:when>
      <xsl:when test="@scalefit"><xsl:value-of select="@scalefit"/></xsl:when>
      <xsl:when test="$width != '' or @depth">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="scale">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0">1.0</xsl:when>
      <xsl:when test="@contentwidth or @contentdepth">1.0</xsl:when>
      <xsl:when test="@scale">
        <xsl:value-of select="@scale div 100.0"/>
      </xsl:when>
      <xsl:otherwise>1.0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="filename">
    <xsl:choose>
      <xsl:when test="local-name(.) = 'graphic'                       or local-name(.) = 'inlinegraphic'">
        <!-- handle legacy graphic and inlinegraphic by new template --> 
        <xsl:call-template name="mediaobject.filename">
          <xsl:with-param name="object" select="."/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- imagedata, videodata, audiodata -->
        <xsl:call-template name="mediaobject.filename">
          <xsl:with-param name="object" select=".."/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="output_filename">
    <xsl:choose>
      <xsl:when test="$embedtoc != 0 and contains($filename, 'Common_Content')">
        <xsl:value-of select=" concat($tocpath, '/../', $brand, '/',$langpath)"/>
        <xsl:value-of select="substring-after($filename, 'Common_Content')"/>
      </xsl:when>
      <xsl:when test="@entityref">
        <xsl:value-of select="$filename"/>
      </xsl:when>
      <!--
        Moved test for $keep.relative.image.uris to template below:
            <xsl:template match="@fileref">
      -->
      <xsl:otherwise>
        <xsl:value-of select="$filename"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="img.src.path.pi">
    <xsl:call-template name="pi.dbhtml_img.src.path">
      <xsl:with-param name="node" select=".."/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="filename.for.graphicsize">
    <xsl:choose>
      <xsl:when test="$img.src.path.pi != ''">
        <xsl:value-of select="concat($img.src.path.pi, $filename)"/>
      </xsl:when>
      <xsl:when test="$img.src.path != '' and                       $graphicsize.use.img.src.path != 0 and                       $tag = 'img' and                       not(starts-with($filename, '/')) and                       not(contains($filename, '://'))">
        <xsl:value-of select="concat($img.src.path, $filename)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$filename"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="realintrinsicwidth">
    <!-- This funny compound test works around a bug in XSLTC -->
    <xsl:choose>
      <xsl:when test="$use.extensions != 0 and $graphicsize.extension != 0                       and not(@format='SVG')">
        <xsl:choose>
          <xsl:when test="function-available('simg:getWidth')">
            <xsl:value-of select="simg:getWidth(simg:new($filename.for.graphicsize),                                                 $nominal.image.width)"/>
          </xsl:when>
          <xsl:when test="function-available('ximg:getWidth')">
            <xsl:value-of select="ximg:getWidth(ximg:new($filename.for.graphicsize),                                                 $nominal.image.width)"/>
          </xsl:when>
          <xsl:otherwise>
           <xsl:value-of select="0"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="intrinsicwidth">
    <xsl:choose>
      <xsl:when test="$realintrinsicwidth = 0">
       <xsl:value-of select="$nominal.image.width"/>
      </xsl:when>
      <xsl:otherwise>
       <xsl:value-of select="$realintrinsicwidth"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="intrinsicdepth">
    <!-- This funny compound test works around a bug in XSLTC -->
    <xsl:choose>
      <xsl:when test="$use.extensions != 0 and $graphicsize.extension != 0                       and not(@format='SVG')">
        <xsl:choose>
          <xsl:when test="function-available('simg:getDepth')">
            <xsl:value-of select="simg:getDepth(simg:new($filename.for.graphicsize),                                                 $nominal.image.depth)"/>
          </xsl:when>
          <xsl:when test="function-available('ximg:getDepth')">
            <xsl:value-of select="ximg:getDepth(ximg:new($filename.for.graphicsize),                                                 $nominal.image.depth)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$nominal.image.depth"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$nominal.image.depth"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="contentwidth">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0"/>
      <xsl:when test="@contentwidth">
        <xsl:variable name="units">
          <xsl:call-template name="length-units">
            <xsl:with-param name="length" select="@contentwidth"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="$units = '%'">
            <xsl:variable name="cmagnitude">
              <xsl:call-template name="length-magnitude">
                <xsl:with-param name="length" select="@contentwidth"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="$intrinsicwidth * $cmagnitude div 100.0"/>
            <xsl:text>px</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="length-spec">
              <xsl:with-param name="length" select="@contentwidth"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$intrinsicwidth"/>
        <xsl:text>px</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="scaled.contentwidth">
    <xsl:if test="$contentwidth != ''">
      <xsl:variable name="cwidth.in.points">
        <xsl:call-template name="length-in-points">
          <xsl:with-param name="length" select="$contentwidth"/>
          <xsl:with-param name="pixels.per.inch" select="$pixels.per.inch"/>
          <xsl:with-param name="em.size" select="$points.per.em"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:value-of select="round($cwidth.in.points div 72.0 * $pixels.per.inch * $scale)"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="html.width">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0"/>
      <xsl:when test="$width-units = '%'">
        <xsl:value-of select="$width"/>
      </xsl:when>
      <xsl:when test="$width != ''">
        <xsl:variable name="width.in.points">
          <xsl:call-template name="length-in-points">
            <xsl:with-param name="length" select="$width"/>
            <xsl:with-param name="pixels.per.inch" select="$pixels.per.inch"/>
            <xsl:with-param name="em.size" select="$points.per.em"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="round($width.in.points div 72.0 * $pixels.per.inch)"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="contentdepth">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0"/>
      <xsl:when test="@contentdepth">
        <xsl:variable name="units">
          <xsl:call-template name="length-units">
            <xsl:with-param name="length" select="@contentdepth"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="$units = '%'">
            <xsl:variable name="cmagnitude">
              <xsl:call-template name="length-magnitude">
                <xsl:with-param name="length" select="@contentdepth"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="$intrinsicdepth * $cmagnitude div 100.0"/>
            <xsl:text>px</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="length-spec">
              <xsl:with-param name="length" select="@contentdepth"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$intrinsicdepth"/>
        <xsl:text>px</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="scaled.contentdepth">
    <xsl:if test="$contentdepth != ''">
      <xsl:variable name="cdepth.in.points">
        <xsl:call-template name="length-in-points">
          <xsl:with-param name="length" select="$contentdepth"/>
          <xsl:with-param name="pixels.per.inch" select="$pixels.per.inch"/>
          <xsl:with-param name="em.size" select="$points.per.em"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:value-of select="round($cdepth.in.points div 72.0 * $pixels.per.inch * $scale)"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="depth-units">
    <xsl:if test="@depth">
      <xsl:call-template name="length-units">
        <xsl:with-param name="length" select="@depth"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="depth">
    <xsl:if test="@depth">
      <xsl:choose>
        <xsl:when test="$depth-units = '%'">
          <xsl:value-of select="@depth"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="length-spec">
            <xsl:with-param name="length" select="@depth"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="html.depth">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0"/>
      <xsl:when test="$depth-units = '%'">
        <xsl:value-of select="$depth"/>
      </xsl:when>
      <xsl:when test="@depth and @depth != ''">
        <xsl:variable name="depth.in.points">
          <xsl:call-template name="length-in-points">
            <xsl:with-param name="length" select="$depth"/>
            <xsl:with-param name="pixels.per.inch" select="$pixels.per.inch"/>
            <xsl:with-param name="em.size" select="$points.per.em"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="round($depth.in.points div 72.0 * $pixels.per.inch)"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="viewport">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0">0</xsl:when>
      <xsl:when test="local-name(.) = 'inlinegraphic'                       or ancestor::d:inlinemediaobject                       or ancestor::d:inlineequation">0</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$make.graphic.viewport"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

<!--
  <xsl:message>=====================================
scale: <xsl:value-of select="$scale"/>, <xsl:value-of select="$scalefit"/>
@contentwidth <xsl:value-of select="@contentwidth"/>
$contentwidth <xsl:value-of select="$contentwidth"/>
scaled.contentwidth: <xsl:value-of select="$scaled.contentwidth"/>
@width: <xsl:value-of select="@width"/>
width: <xsl:value-of select="$width"/>
html.width: <xsl:value-of select="$html.width"/>
@contentdepth <xsl:value-of select="@contentdepth"/>
$contentdepth <xsl:value-of select="$contentdepth"/>
scaled.contentdepth: <xsl:value-of select="$scaled.contentdepth"/>
@depth: <xsl:value-of select="@depth"/>
depth: <xsl:value-of select="$depth"/>
html.depth: <xsl:value-of select="$html.depth"/>
align: <xsl:value-of select="@align"/>
valign: <xsl:value-of select="@valign"/></xsl:message>
-->

  <xsl:variable name="scaled" select="@width|@depth|@contentwidth|@contentdepth                         |@scale|@scalefit"/>

  <xsl:variable name="img">
    <xsl:choose>
      <xsl:when test="@format = 'SVG'">
        <object type="image/svg+xml">
	  <xsl:attribute name="data">
	    <xsl:choose>
	      <xsl:when test="$img.src.path != '' and                            $tag = 'img' and       not(starts-with($output_filename, '/')) and       not(contains($output_filename, '://'))">
		<xsl:value-of select="$img.src.path"/>
	      </xsl:when>
           </xsl:choose>
	   <xsl:value-of select="$output_filename"/>
	  </xsl:attribute>
	  <xsl:call-template name="process.image.attributes">
            <!--xsl:with-param name="alt" select="$alt"/ there's no alt here-->
            <xsl:with-param name="html.depth" select="$html.depth"/>
            <xsl:with-param name="html.width" select="$html.width"/>
            <xsl:with-param name="longdesc" select="$longdesc"/>
            <xsl:with-param name="scale" select="$scale"/>
            <xsl:with-param name="scalefit" select="$scalefit"/>
            <xsl:with-param name="scaled.contentdepth" select="$scaled.contentdepth"/>
            <xsl:with-param name="scaled.contentwidth" select="$scaled.contentwidth"/>
            <xsl:with-param name="viewport" select="$viewport"/>
          </xsl:call-template>
          <xsl:if test="@align">
            <xsl:attribute name="style"><xsl:text>text-align: </xsl:text>
                <xsl:choose>
                  <xsl:when test="@align = 'center'">middle</xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="@align"/>
                  </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="$use.embed.for.svg != 0">
	    <embed type="image/svg+xml">
	      <xsl:attribute name="src">
		<xsl:choose>
                  <xsl:when test="$img.src.path != '' and       $tag = 'img' and       not(starts-with($output_filename, '/')) and       not(contains($output_filename, '://'))">
		    <xsl:value-of select="$img.src.path"/>
                  </xsl:when>
		</xsl:choose>
		<xsl:value-of select="$output_filename"/>
              </xsl:attribute>
              <xsl:call-template name="process.image.attributes">
                <!--xsl:with-param name="alt" select="$alt"/ there's no alt here -->
                <xsl:with-param name="html.depth" select="$html.depth"/>
                <xsl:with-param name="html.width" select="$html.width"/>
                <xsl:with-param name="longdesc" select="$longdesc"/>
                <xsl:with-param name="scale" select="$scale"/>
                <xsl:with-param name="scalefit" select="$scalefit"/>
                <xsl:with-param name="scaled.contentdepth" select="$scaled.contentdepth"/>
                <xsl:with-param name="scaled.contentwidth" select="$scaled.contentwidth"/>
                <xsl:with-param name="viewport" select="$viewport"/>
              </xsl:call-template>
            </embed>
          </xsl:if>
        </object>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{$tag}" namespace="http://www.w3.org/1999/xhtml">
         <xsl:if test="$tag = 'img' and ../../self::d:imageobjectco">
           <xsl:variable name="mapname">
             <xsl:call-template name="object.id">
               <xsl:with-param name="object" select="../../d:areaspec"/>
             </xsl:call-template>
           </xsl:variable>
           <xsl:choose>
             <xsl:when test="$scaled">
              <!-- It might be possible to handle some scaling; needs -->
              <!-- more investigation -->
              <xsl:message>
                <xsl:text>Warning: imagemaps not supported </xsl:text>
                <xsl:text>on scaled images</xsl:text>
              </xsl:message>
             </xsl:when>
             <xsl:otherwise>
              <xsl:attribute name="border">0</xsl:attribute>
              <xsl:attribute name="usemap">
                <xsl:value-of select="concat('#', $mapname)"/>
              </xsl:attribute>
             </xsl:otherwise>
           </xsl:choose>
         </xsl:if>

          <xsl:attribute name="src">
           <xsl:choose>
             <xsl:when test="$img.src.path != '' and                            $tag = 'img' and                              not(starts-with($output_filename, '/')) and                            not(contains($output_filename, '://'))">
               <xsl:value-of select="$img.src.path"/>
             </xsl:when>
           </xsl:choose>
            <xsl:value-of select="$output_filename"/>
          </xsl:attribute>

          <xsl:if test="@align">
            <xsl:attribute name="style"><xsl:text>text-align: </xsl:text>
              <xsl:choose>
                <xsl:when test="@align = 'center'">middle</xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@align"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
          </xsl:if>

          <xsl:call-template name="process.image.attributes">
            <xsl:with-param name="alt">
              <xsl:choose>
                <xsl:when test="$alt != ''">
                  <xsl:copy-of select="$alt"/>
                </xsl:when>
                <xsl:when test="ancestor::d:figure">
                  <xsl:variable name="fig.title">
                    <xsl:apply-templates select="ancestor::d:figure/d:title/node()"/>
                  </xsl:variable>
                  <xsl:value-of select="normalize-space($fig.title)"/>
                </xsl:when>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="html.depth" select="$html.depth"/>
            <xsl:with-param name="html.width" select="$html.width"/>
            <xsl:with-param name="longdesc" select="$longdesc"/>
            <xsl:with-param name="scale" select="$scale"/>
            <xsl:with-param name="scalefit" select="$scalefit"/>
            <xsl:with-param name="scaled.contentdepth" select="$scaled.contentdepth"/>
            <xsl:with-param name="scaled.contentwidth" select="$scaled.contentwidth"/>
            <xsl:with-param name="viewport" select="$viewport"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="bgcolor">
    <xsl:call-template name="pi.dbhtml_background-color">
      <xsl:with-param name="node" select=".."/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="use.viewport" select="0"/>

  <xsl:choose>
    <xsl:when test="$use.viewport">
      <table border="{$table.border.off}">
        <xsl:if test="$div.element != 'section'">
          <xsl:attribute name="summary">manufactured viewport for HTML img</xsl:attribute>
        </xsl:if>
        <xsl:if test="$css.decoration != ''">
          <xsl:attribute name="style">cellpadding: 0; cellspacing: 0;</xsl:attribute>
        </xsl:if>
        <xsl:if test="$html.width != ''">
          <xsl:attribute name="width">
            <xsl:value-of select="$html.width"/>
          </xsl:attribute>
        </xsl:if>
        <tr>
          <xsl:if test="$html.depth != '' and $depth-units != '%'">
            <!-- don't do this for percentages because browsers get confused -->
            <xsl:choose>
              <xsl:when test="$css.decoration != 0">
                <xsl:attribute name="style">
                  <xsl:text>height: </xsl:text>
                  <xsl:value-of select="$html.depth"/>
                  <xsl:text>px</xsl:text>
                </xsl:attribute>
              </xsl:when>
              <xsl:otherwise>
                <xsl:attribute name="height">
                  <xsl:value-of select="$html.depth"/>
                </xsl:attribute>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
          <td>
            <xsl:if test="$bgcolor != ''">
              <xsl:choose>
                <xsl:when test="$css.decoration != 0">
                  <xsl:attribute name="style">
                    <xsl:text>background-color: </xsl:text>
                    <xsl:value-of select="$bgcolor"/>
                  </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="style"><xsl:text>background-color: </xsl:text>
                    <xsl:value-of select="$bgcolor"/>
                  </xsl:attribute>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
            <xsl:if test="@align">
              <xsl:attribute name="style"><xsl:text>text-align: </xsl:text>
                <xsl:value-of select="@align"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:if test="@valign">
              <xsl:attribute name="valign">
                <xsl:value-of select="@valign"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:copy-of select="$img"/>
          </td>
        </tr>
      </table>
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="$img"/>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:if test="$tag = 'img' and ../../self::d:imageobjectco and not($scaled)">
    <xsl:variable name="mapname">
      <xsl:call-template name="object.id">
        <xsl:with-param name="object" select="../../d:areaspec"/>
      </xsl:call-template>
    </xsl:variable>

    <map name="{$mapname}">
      <xsl:for-each select="../../d:areaspec//d:area">
        <xsl:variable name="units">
          <xsl:choose>
            <xsl:when test="@units = 'other' and @otherunits">
              <xsl:value-of select="@otherunits"/>
            </xsl:when>
            <xsl:when test="@units">
              <xsl:value-of select="@units"/>
            </xsl:when>
            <!-- areaspec|areaset/area -->
            <xsl:when test="../@units = 'other' and ../@otherunits">
              <xsl:value-of select="../@otherunits"/>
            </xsl:when>
            <xsl:when test="../@units">
              <xsl:value-of select="../@units"/>
            </xsl:when>
            <!-- areaspec/areaset/area -->
            <xsl:when test="../../@units = 'other' and ../../@otherunits">
              <xsl:value-of select="../@otherunits"/>
            </xsl:when>
            <xsl:when test="../../@units">
              <xsl:value-of select="../../@units"/>
            </xsl:when>
            <xsl:otherwise>calspair</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
 
        <xsl:choose>
          <xsl:when test="$units = 'calspair' or                           $units = 'imagemap'">
            <xsl:variable name="coords" select="normalize-space(@coords)"/>

            <area shape="rect">
              <xsl:variable name="linkends">
                <xsl:choose>
                  <xsl:when test="@linkends">
                    <xsl:value-of select="normalize-space(@linkends)"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="normalize-space(../@linkends)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
 
              <xsl:variable name="href">
                <xsl:choose>
                  <xsl:when test="@xlink:href">
                    <xsl:value-of select="@xlink:href"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="../@xlink:href"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
 
              <xsl:choose>
                <xsl:when test="$linkends != ''">
                  <xsl:variable name="linkend">
                    <xsl:choose>
                      <xsl:when test="contains($linkends, ' ')">
                        <xsl:value-of select="substring-before($linkends, ' ')"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$linkends"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <xsl:variable name="target" select="key('id', $linkend)[1]"/>
                 
                  <xsl:if test="$target">
                    <xsl:attribute name="href">
                      <xsl:call-template name="href.target">
                        <xsl:with-param name="object" select="$target"/>
                      </xsl:call-template>
                    </xsl:attribute>
                  </xsl:if>
                </xsl:when>
                <xsl:when test="$href != ''">
                  <xsl:attribute name="href">
                    <xsl:value-of select="$href"/>
                  </xsl:attribute>
                </xsl:when>
              </xsl:choose>
 
              <xsl:if test="d:alt">
                <xsl:attribute name="alt">
                  <xsl:value-of select="d:alt[1]"/>
                </xsl:attribute>
              </xsl:if>
 
              <xsl:attribute name="coords">
                <xsl:choose>
                  <xsl:when test="$units = 'calspair'">

                    <xsl:variable name="p1" select="substring-before($coords, ' ')"/>
                    <xsl:variable name="p2" select="substring-after($coords, ' ')"/>
         
                    <xsl:variable name="x1" select="substring-before($p1,',')"/>
                    <xsl:variable name="y1" select="substring-after($p1,',')"/>
                    <xsl:variable name="x2" select="substring-before($p2,',')"/>
                    <xsl:variable name="y2" select="substring-after($p2,',')"/>
         
                    <xsl:variable name="x1p" select="$x1 div 100.0"/>
                    <xsl:variable name="y1p" select="$y1 div 100.0"/>
                    <xsl:variable name="x2p" select="$x2 div 100.0"/>
                    <xsl:variable name="y2p" select="$y2 div 100.0"/>
         
         <!--
                    <xsl:message>
                      <xsl:text>units: </xsl:text>
                      <xsl:value-of select="$units"/>
                      <xsl:text> </xsl:text>
                      <xsl:value-of select="$x1p"/><xsl:text>, </xsl:text>
                      <xsl:value-of select="$y1p"/><xsl:text>, </xsl:text>
                      <xsl:value-of select="$x2p"/><xsl:text>, </xsl:text>
                      <xsl:value-of select="$y2p"/><xsl:text>, </xsl:text>
                    </xsl:message>
         
                    <xsl:message>
                      <xsl:text>      </xsl:text>
                      <xsl:value-of select="$intrinsicwidth"/>
                      <xsl:text>, </xsl:text>
                      <xsl:value-of select="$intrinsicdepth"/>
                    </xsl:message>
         
                    <xsl:message>
                      <xsl:text>      </xsl:text>
                      <xsl:value-of select="$units"/>
                      <xsl:text> </xsl:text>
                      <xsl:value-of 
                            select="round($x1p * $intrinsicwidth div 100.0)"/>
                      <xsl:text>,</xsl:text>
                      <xsl:value-of select="round($intrinsicdepth
                                       - ($y2p * $intrinsicdepth div 100.0))"/>
                      <xsl:text>,</xsl:text>
                      <xsl:value-of select="round($x2p * 
                                            $intrinsicwidth div 100.0)"/>
                      <xsl:text>,</xsl:text>
                      <xsl:value-of select="round($intrinsicdepth
                                       - ($y1p * $intrinsicdepth div 100.0))"/>
                    </xsl:message>
         -->
                    <xsl:value-of select="round($x1p * $intrinsicwidth div 100.0)"/>
                    <xsl:text>,</xsl:text>
                    <xsl:value-of select="round($intrinsicdepth                                         - ($y2p * $intrinsicdepth div 100.0))"/>
                    <xsl:text>,</xsl:text>
                    <xsl:value-of select="round($x2p * $intrinsicwidth div 100.0)"/>
                    <xsl:text>,</xsl:text>
                    <xsl:value-of select="round($intrinsicdepth                                       - ($y1p * $intrinsicdepth div 100.0))"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="$coords"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
            </area>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>
              <xsl:text>Warning: only calspair or </xsl:text>
              <xsl:text>otherunits='imagemap' supported </xsl:text>
              <xsl:text>in imageobjectco</xsl:text>
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </map>
  </xsl:if>
</xsl:template>


<xsl:template name="callout-bug">
  <xsl:param name="conum" select="1"/>
    <span class="callout">
      <xsl:value-of select="$conum"/>
    </span>
</xsl:template>

<xsl:template match="d:co" name="co">
  <!-- Support a single linkend in HTML -->
  <xsl:variable name="targets" select="key('id', @linkends)"/>
  <xsl:variable name="target" select="$targets[1]"/>
  <xsl:choose>
    <xsl:when test="$target">
      <a>
        <xsl:apply-templates select="." mode="common.html.attributes"/>
        <xsl:choose>
          <xsl:when test="$generate.id.attributes = 0">
            <!-- force an id attribute here -->
            <xsl:if test="@id or @xml:id">
              <xsl:attribute name="id">
                <xsl:value-of select="(@id|@xml:id)[1]"/>
              </xsl:attribute>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="id.attribute"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:attribute name="href">
          <xsl:call-template name="href.target">
            <xsl:with-param name="object" select="$target"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="onmouseover">
 		<xsl:text>highlightTarget(this);</xsl:text> 
        </xsl:attribute>
        <xsl:attribute name="onclick">
 		<xsl:text>highlightTarget(this, 1);</xsl:text> 
        </xsl:attribute>
        <xsl:attribute name="onmouseout">
 		<xsl:text>dehighlightTarget(this);</xsl:text> 
        </xsl:attribute>
        <xsl:apply-templates select="." mode="callout-bug"/>
     </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:if test="$generate.id.attributes != 0">
        <xsl:if test="@id or @xml:id">
          <span>
             <xsl:attribute name="id">
                <xsl:value-of select="(@id|@xml:id)[1]"/>
              </xsl:attribute>
          </span>
        </xsl:if>
      </xsl:if>
      <xsl:call-template name="anchor"/>
      <xsl:apply-templates select="." mode="callout-bug"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="d:programlistingco|d:screenco">
  <xsl:variable name="verbatim" select="d:programlisting|d:screen"/>

  <xsl:choose>
    <xsl:when test="$use.extensions != '0' and $callouts.extension != '0'">
      <xsl:variable name="rtf">
        <xsl:apply-templates select="$verbatim">
          <xsl:with-param name="suppress-numbers" select="'1'"/>
        </xsl:apply-templates>
      </xsl:variable>

      <xsl:variable name="rtf-with-callouts">
        <xsl:choose>
          <xsl:when test="function-available('sverb:insertCallouts')">
            <xsl:copy-of select="sverb:insertCallouts(d:areaspec,$rtf)"/>
          </xsl:when>
          <xsl:when test="function-available('xverb:insertCallouts')">
            <xsl:copy-of select="xverb:insertCallouts(d:areaspec,$rtf)"/>
          </xsl:when>
          <xsl:when test="function-available('perl:insertCallouts')">
            <xsl:copy-of select="perl:insertCallouts(d:areaspec,$rtf, 'css')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="yes">
              <xsl:text>No insertCallouts function is available.</xsl:text>
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test="$verbatim/@linenumbering = 'numbered' and $linenumbering.extension != '0'">
          <div>
            <xsl:call-template name="common.html.attributes"/>
            <xsl:call-template name="id.attribute"/>
            <xsl:call-template name="number.rtf.lines">
              <xsl:with-param name="rtf" select="$rtf-with-callouts"/>
              <xsl:with-param name="pi.context" select="d:programlisting|d:screen"/>
            </xsl:call-template>
            <xsl:apply-templates select="d:calloutlist"/>
          </div>
        </xsl:when>
        <xsl:otherwise>
          <div>
            <xsl:call-template name="common.html.attributes"/>
            <xsl:call-template name="id.attribute"/>
            <xsl:copy-of select="$rtf-with-callouts"/>
            <xsl:apply-templates select="d:calloutlist"/>
          </div>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <div>
        <xsl:apply-templates select="." mode="common.html.attributes"/>
        <xsl:call-template name="id.attribute"/>
        <xsl:apply-templates/>
      </div>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

