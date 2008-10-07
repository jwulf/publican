<?xml version='1.0'?>
 
<!--
	Copyright 2007 Red Hat, Inc.
	License: GPL
	Author: Jeff Fearn <jfearn@redhat.com>
	Author: Tammy Fox <tfox@redhat.com>
	Author: Andy Fitzsimon <afitzsim@redhat.com>
-->

<!DOCTYPE xsl:stylesheet [
<!ENTITY lowercase "'abcdefghijklmnopqrstuvwxyz'">
<!ENTITY uppercase "'ABCDEFGHIJKLMNOPQRSTUVWXYZ'">
<!ENTITY primary   'normalize-space(concat(primary/@sortas, primary[not(@sortas)]))'>
<!ENTITY secondary 'normalize-space(concat(secondary/@sortas, secondary[not(@sortas)]))'>
<!ENTITY tertiary  'normalize-space(concat(tertiary/@sortas, tertiary[not(@sortas)]))'>
<!ENTITY comment.block.parents "parent::answer|parent::appendix|parent::article|parent::bibliodiv|
                                  parent::bibliography|parent::blockquote|parent::caution|parent::chapter|
                                  parent::glossary|parent::glossdiv|parent::important|parent::index|
                                  parent::indexdiv|parent::listitem|parent::note|parent::orderedlist|
                                  parent::partintro|parent::preface|parent::procedure|parent::qandadiv|
                                  parent::qandaset|parent::question|parent::refentry|parent::refnamediv|
                                  parent::refsect1|parent::refsect2|parent::refsect3|parent::refsection|
                                  parent::refsynopsisdiv|parent::sect1|parent::sect2|parent::sect3|parent::sect4|
                                  parent::sect5|parent::section|parent::setindex|parent::sidebar|
                                  parent::simplesect|parent::taskprerequisites|parent::taskrelated|
                                  parent::tasksummary|parent::warning">
 ]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		version='1.0'
		xmlns="http://www.w3.org/TR/xhtml1/transitional"
		xmlns:fo="http://www.w3.org/1999/XSL/Format"
		xmlns:xslthl="http://xslthl.sf.net"
                exclude-result-prefixes="xslthl">
<!--		exclude-result-prefixes="#default"> -->

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl"/>
<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/graphics.xsl"/>
<xsl:import href="defaults.xsl"/>
<xsl:param name="alignment">
	<xsl:choose>
		<xsl:when test="$l10n.gentext.language = 'zh-CN' or $l10n.gentext.language = 'zh-TW' or $l10n.gentext.language = 'ja-JP' or $l10n.gentext.language = 'ko-KR'">
			<xsl:text>justify</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>left</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:param>
<xsl:param name="use.extensions" select="1"/>
<xsl:param name="tablecolumns.extensions" select="1"/>
<xsl:param name="fop.extensions" select="0"/>
<xsl:param name="fop1.extensions" select="1"/>
<xsl:param name="img.src.path"/>
<xsl:param name="qandadiv.autolabel" select="0"/>
<xsl:param name="keep.relative.image.uris" select="0"/>
<xsl:param name="email.delimiters.enabled">0</xsl:param>

<xsl:param name="hyphenation-character">
	<xsl:choose>
		<xsl:when test="$l10n.gentext.language = 'zh-CN' or $l10n.gentext.language = 'zh-TW' or $l10n.gentext.language = 'ja-JP' or $l10n.gentext.language = 'ko-KR'">
			<xsl:text></xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>-</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:param>
<xsl:param name="default.image.width" select="'440'"/>
<xsl:param name="hyphenate.verbatim" select="0"/>
<xsl:param name="hyphenate">true</xsl:param>
<xsl:param name="ulink.hyphenate" select="1"/>
<xsl:param name="ulink.footnotes" select="1"/>
<xsl:param name="ulink.show" select="1"/>
<xsl:param name="table.footnote.number.format" select="'1'"/>
<xsl:param name="table.footnote.number.symbols" select="''"/>
<xsl:param name="highlight.source" select="1"/>

<xsl:param name="line-height" select="1.3"/>
<xsl:param name="segmentedlist.as.table" select="1"/>

<xsl:param name="xslthl.keyword.color">#002F5D</xsl:param>
<xsl:param name="xslthl.string.color">#00774B</xsl:param>
<xsl:param name="xslthl.comment.color">#FFFFFF</xsl:param>
<xsl:param name="xslthl.tag.color">#002F5D</xsl:param>
<xsl:param name="xslthl.attribute.color">#a70000</xsl:param>
<xsl:param name="xslthl.value.color">#4E376B</xsl:param>
<xsl:param name="xslthl.html.color">#002F5D</xsl:param>
<xsl:param name="xslthl.xslt.color">#00774B</xsl:param>
<xsl:param name="xslthl.section.color">#00774B</xsl:param>
<xsl:param name="xslthl.directive.color">#002F5D</xsl:param>
<xsl:param name="xslthl.doctype.color">#002F5D</xsl:param>
<!--xsl:param name="xslthl..color"></xsl:param-->

<xsl:attribute-set name="xref.properties">
  <xsl:attribute name="font-style">italic</xsl:attribute>
  <xsl:attribute name="color">
	<xsl:choose>
		<xsl:when test="ancestor::note or ancestor::important or ancestor::warning">
			<xsl:text>#aee6ff</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>#0066cc</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="monospace.properties">
	<!--xsl:attribute name="font-size">9pt</xsl:attribute-->
	<xsl:attribute name="font-family">
		<xsl:value-of select="$monospace.font.family"/>
	</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="monospace.verbatim.properties" use-attribute-sets="verbatim.properties monospace.properties">
	<xsl:attribute name="text-align">start</xsl:attribute>
	<xsl:attribute name="wrap-option">wrap</xsl:attribute>
	<xsl:attribute name="hyphenation-character">\</xsl:attribute>
</xsl:attribute-set>

<xsl:param name="shade.verbatim" select="1"/>
<xsl:attribute-set name="shade.verbatim.style">
  <xsl:attribute name="wrap-option">wrap</xsl:attribute>
        <xsl:attribute name="hyphenation-character">\</xsl:attribute>
  <xsl:attribute name="background-color">
	<xsl:choose>
		<xsl:when test="ancestor::note or ancestor::caution or ancestor::important or ancestor::warning or ancestor::tip">
			<xsl:text>#333333</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>#eeeeee</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>
  <xsl:attribute name="color">
	<xsl:choose>
		<xsl:when test="ancestor::note or ancestor::caution or ancestor::important or ancestor::warning or ancestor::tip">
			<xsl:text>white</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>black</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
  </xsl:attribute>
	<xsl:attribute name="padding-left">12pt</xsl:attribute>
	<xsl:attribute name="padding-right">12pt</xsl:attribute>
	<xsl:attribute name="padding-top">6pt</xsl:attribute>
	<xsl:attribute name="padding-bottom">6pt</xsl:attribute>
	<xsl:attribute name="margin-left">
		<xsl:value-of select="$title.margin.left"/>
	</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="hidden.properties">
  <xsl:attribute name="space-before.minimum">0em</xsl:attribute>
  <xsl:attribute name="space-before.optimum">0em</xsl:attribute>
  <xsl:attribute name="space-before.maximum">0em</xsl:attribute>
  <xsl:attribute name="space-after.minimum">0em</xsl:attribute>
  <xsl:attribute name="space-after.optimum">0em</xsl:attribute>
  <xsl:attribute name="space-after.maximum">0em</xsl:attribute>
  <xsl:attribute name="font-size">0pt</xsl:attribute>
  <xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="verbatim.properties">
  <xsl:attribute name="space-before.minimum">0.8em</xsl:attribute>
  <xsl:attribute name="space-before.optimum">1em</xsl:attribute>
  <xsl:attribute name="space-before.maximum">1.2em</xsl:attribute>
  <xsl:attribute name="space-after.minimum">0.8em</xsl:attribute>
  <xsl:attribute name="space-after.optimum">1em</xsl:attribute>
  <xsl:attribute name="space-after.maximum">1.2em</xsl:attribute>
  <xsl:attribute name="hyphenate">true</xsl:attribute>
  <xsl:attribute name="wrap-option">wrap</xsl:attribute>
  <xsl:attribute name="white-space-collapse">false</xsl:attribute>
  <xsl:attribute name="white-space-treatment">preserve</xsl:attribute>
  <xsl:attribute name="linefeed-treatment">preserve</xsl:attribute>
  <xsl:attribute name="text-align">start</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="toc.line.properties">
  <xsl:attribute name="text-align-last">justify</xsl:attribute>
  <xsl:attribute name="text-align">start</xsl:attribute>
</xsl:attribute-set>

<!-- Admonitions -->
<xsl:param name="admon.graphics" select="1"/>
<xsl:param name="admon.graphics.path">
	<xsl:if test="$img.src.path != ''"><xsl:value-of select="$img.src.path"/></xsl:if><xsl:text>Common_Content/images/</xsl:text>
</xsl:param>
<xsl:param name="admon.graphics.extension" select="'.svg'"/>
<xsl:attribute-set name="admonition.title.properties">
	<xsl:attribute name="font-size">13pt</xsl:attribute>
	<xsl:attribute name="color">white</xsl:attribute>
	<xsl:attribute name="font-weight">bold</xsl:attribute>
	<xsl:attribute name="hyphenate">true</xsl:attribute>
	<xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>
</xsl:attribute-set>

<!--xsl:attribute-set name="admonition.properties"></xsl:attribute-set-->

<xsl:attribute-set name="graphical.admonition.properties">
	<xsl:attribute name="color">white</xsl:attribute>
	<xsl:attribute name="background-color">
	  <xsl:choose>
		<xsl:when test="local-name(.)='note'">
			<xsl:text>#8e9f00</xsl:text>
		</xsl:when>
		<xsl:when test="local-name(.)='important'">
			<xsl:text>#d08e13</xsl:text>
		</xsl:when>
		<xsl:when test="local-name(.)='warning'">
			<xsl:text>#9e292b</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>#dddddd</xsl:text>
		</xsl:otherwise>
	  </xsl:choose>
	</xsl:attribute>
	<xsl:attribute name="space-before.optimum">1em</xsl:attribute>
	<xsl:attribute name="space-before.minimum">0.8em</xsl:attribute>
	<xsl:attribute name="space-before.maximum">1.2em</xsl:attribute>
	<xsl:attribute name="space-after.optimum">1em</xsl:attribute>
	<xsl:attribute name="space-after.minimum">0.8em</xsl:attribute>
	<xsl:attribute name="space-after.maximum">1em</xsl:attribute>
	<xsl:attribute name="padding-bottom">12pt</xsl:attribute>
	<xsl:attribute name="padding-top">12pt</xsl:attribute>
	<xsl:attribute name="padding-right">12pt</xsl:attribute>
	<xsl:attribute name="padding-left">12pt</xsl:attribute>
	<xsl:attribute name="margin-left">
		<xsl:value-of select="$title.margin.left"/>
	</xsl:attribute>
</xsl:attribute-set>

<xsl:param name="generate.toc">
set toc
book toc
article toc
</xsl:param>

<xsl:param name="toc.section.depth">3</xsl:param>
<xsl:param name="section.autolabel" select="1"/>
<xsl:param name="section.label.includes.component.label" select="1"/>

<xsl:param name="callout.graphics.path">
    <xsl:if test="$img.src.path != ''"><xsl:value-of select="$img.src.path"/></xsl:if><xsl:text>Common_Content/images/</xsl:text>
</xsl:param>

<!-- Format Variable Lists as Blocks (prevents horizontal overflow). -->
<xsl:param name="variablelist.as.blocks">1</xsl:param>

<!-- The horrible list spacing problems, this is much better. -->
<xsl:attribute-set name="list.block.spacing">
	<xsl:attribute name="space-before.optimum">0.1pt</xsl:attribute>
	<xsl:attribute name="space-before.minimum">0.1pt</xsl:attribute>
	<xsl:attribute name="space-before.maximum">0.1pt</xsl:attribute>
	<xsl:attribute name="space-after.optimum">1em</xsl:attribute>
	<xsl:attribute name="space-after.minimum">1em</xsl:attribute>
	<xsl:attribute name="space-after.maximum">1em</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="list.item.spacing">
  <xsl:attribute name="space-before.optimum">0.1em</xsl:attribute>
  <xsl:attribute name="space-before.minimum">0.1em</xsl:attribute>
  <xsl:attribute name="space-before.maximum">0.1em</xsl:attribute>
	<xsl:attribute name="space-after.optimum">1em</xsl:attribute>
	<xsl:attribute name="space-after.minimum">1em</xsl:attribute>
	<xsl:attribute name="space-after.maximum">1em</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="fat.list.item.spacing" use-attribute-sets="list.item.spacing">
	<xsl:attribute name="space-after.optimum">1em</xsl:attribute>
	<xsl:attribute name="space-after.minimum">1em</xsl:attribute>
	<xsl:attribute name="space-after.maximum">1em</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="dash.list.item.spacing" use-attribute-sets="list.item.spacing">
 <xsl:attribute name="padding-top">5pt</xsl:attribute>
 <xsl:attribute name="space-before.optimum">0.5em</xsl:attribute>
  <xsl:attribute name="space-before.minimum">0.5em</xsl:attribute>
  <xsl:attribute name="space-before.maximum">0.5em</xsl:attribute>
	<xsl:attribute name="border-top-width">0.5pt</xsl:attribute>
	<xsl:attribute name="border-top-style">dashed</xsl:attribute>
	<xsl:attribute name="border-top-color">black</xsl:attribute>
</xsl:attribute-set>

<xsl:template match="listitem/*[1][local-name()='para' or 
                                   local-name()='simpara' or 
                                   local-name()='formalpara']
                     |glossdef/*[1][local-name()='para' or 
                                   local-name()='simpara' or 
                                   local-name()='formalpara']
                     |step/*[1][local-name()='para' or 
                                   local-name()='simpara' or 
                                   local-name()='formalpara']
                     |callout/*[1][local-name()='para' or 
                                   local-name()='simpara' or 
                                   local-name()='formalpara']"
              priority="2">
  <fo:block xsl:use-attribute-sets="list.item.spacing">
    <xsl:call-template name="anchor"/>
    <xsl:apply-templates/>
  </fo:block>
</xsl:template>

<!-- Some padding inside tables -->
<xsl:attribute-set name="table.cell.padding">
<xsl:attribute name="padding-left">4pt</xsl:attribute>
<xsl:attribute name="padding-right">4pt</xsl:attribute>
<xsl:attribute name="padding-top">2pt</xsl:attribute>
<xsl:attribute name="padding-bottom">2pt</xsl:attribute>
</xsl:attribute-set>

<!-- Only hairlines as frame and cell borders in tables -->
<xsl:param name="table.frame.border.thickness">0.3pt</xsl:param>
<xsl:param name="table.cell.border.thickness">0.15pt</xsl:param>
<xsl:param name="table.cell.border.color">#dc9f2e</xsl:param>
<xsl:param name="table.frame.border.color">#dc9f2e</xsl:param>
<xsl:param name="table.cell.border.right.color">white</xsl:param>
<xsl:param name="table.cell.border.left.color">white</xsl:param>
<xsl:param name="table.frame.border.right.color">white</xsl:param>
<xsl:param name="table.frame.border.left.color">white</xsl:param>
<!-- Paper type, no headers on blank pages, no double sided printing -->
<xsl:param name="paper.type" select="'A4'"/>
<xsl:param name="double.sided">1</xsl:param>
<xsl:param name="headers.on.blank.pages">1</xsl:param>
<xsl:param name="footers.on.blank.pages">1</xsl:param>
<!--xsl:param name="header.column.widths" select="'1 4 1'"/-->
<xsl:param name="header.column.widths" select="'1 0 1'"/>
<xsl:param name="footer.column.widths" select="'1 1 1'"/>
<xsl:param name="header.rule" select="1"/>

<!-- Space between paper border and content (chaotic stuff, don't touch) -->
<xsl:param name="page.margin.top">15mm</xsl:param>
<xsl:param name="region.before.extent">10mm</xsl:param>
<xsl:param name="body.margin.top">15mm</xsl:param>

<xsl:param name="body.margin.bottom">15mm</xsl:param>
<xsl:param name="region.after.extent">10mm</xsl:param>
<xsl:param name="page.margin.bottom">15mm</xsl:param>

<xsl:param name="page.margin.outer">19mm</xsl:param>
<xsl:param name="page.margin.inner">31mm</xsl:param>

<xsl:param name="body.start.indent">
  <xsl:choose>
    <xsl:when test="$fop.extensions != 0">0pt</xsl:when>
    <xsl:when test="$fop1.extensions != 0">0pt</xsl:when>
    <xsl:when test="$passivetex.extensions != 0">0pt</xsl:when>
    <xsl:otherwise>4pc</xsl:otherwise>
  </xsl:choose>
</xsl:param>

<!-- No intendation of Titles -->
<xsl:param name="title.margin.left">0pc</xsl:param>

<xsl:param name="title.color">#336699</xsl:param>

<xsl:attribute-set name="formal.title.properties" use-attribute-sets="normal.para.spacing">
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="background-color">white</xsl:attribute>
	<xsl:attribute name="font-weight">bold</xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master * 1.2"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
	<xsl:attribute name="hyphenate">false</xsl:attribute>
	<xsl:attribute name="space-before.optimum"><xsl:value-of select="concat($body.font.master, 'pt')"/></xsl:attribute>
	<xsl:attribute name="space-before.minimum"><xsl:value-of select="concat($body.font.master, 'pt')"/></xsl:attribute>
	<xsl:attribute name="space-before.maximum"><xsl:value-of select="concat($body.font.master, 'pt')"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="example.properties" use-attribute-sets="formal.object.properties">
	<xsl:attribute name="background-color">#eeeeee</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="table.properties">
  <xsl:attribute name="space-before.minimum">0.5em</xsl:attribute>
  <xsl:attribute name="space-before.optimum">1em</xsl:attribute>
  <xsl:attribute name="space-before.maximum">2em</xsl:attribute>
  <xsl:attribute name="space-after.minimum">0.5em</xsl:attribute>
  <xsl:attribute name="space-after.optimum">1em</xsl:attribute>
  <xsl:attribute name="space-after.maximum">2em</xsl:attribute>
  <xsl:attribute name="keep-together.within-column">auto</xsl:attribute>
</xsl:attribute-set>


<xsl:attribute-set name="below.title.properties" use-attribute-sets="formal.title.properties">
	<xsl:attribute name="font-weight">normal</xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
	<xsl:attribute name="space-before.optimum"><xsl:text>0.1pt</xsl:text></xsl:attribute>
	<xsl:attribute name="space-before.minimum"><xsl:text>0.1pt</xsl:text></xsl:attribute>
	<xsl:attribute name="space-before.maximum"><xsl:text>0.1pt</xsl:text></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="above.title.properties" use-attribute-sets="formal.title.properties">
	<xsl:attribute name="font-weight">normal</xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
	<xsl:attribute name="space-before.optimum"><xsl:text>2em</xsl:text></xsl:attribute>
	<xsl:attribute name="space-before.minimum"><xsl:text>2em</xsl:text></xsl:attribute>
	<xsl:attribute name="space-before.maximum"><xsl:text>2em</xsl:text></xsl:attribute>
	<xsl:attribute name="space-after.optimum"><xsl:text>0.1pt</xsl:text></xsl:attribute>
	<xsl:attribute name="space-after.minimum"><xsl:text>0.1pt</xsl:text></xsl:attribute>
	<xsl:attribute name="space-after.maximum"><xsl:text>0.1pt</xsl:text></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="section.title.level1.properties">
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master * 1.6"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="section.title.level2.properties">
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master * 1.4"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="section.title.level3.properties">
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master * 1.3"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="section.title.level4.properties">
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master * 1.2"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="section.title.level5.properties">
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master * 1.1"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="section.title.level6.properties">
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:value-of select="$body.font.master"/>
		<xsl:text>pt</xsl:text>
	</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="section.title.properties">
	<xsl:attribute name="font-family">
		<xsl:value-of select="$title.font.family"/>
	</xsl:attribute>
	<xsl:attribute name="font-weight">bold</xsl:attribute>
	<!-- font size is calculated dynamically by section.heading template -->
	<xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>
	<xsl:attribute name="space-before.minimum">1.8em</xsl:attribute>
	<xsl:attribute name="space-before.optimum">2.0em</xsl:attribute>
	<xsl:attribute name="space-before.maximum">2.2em</xsl:attribute>
	<xsl:attribute name="space-after.minimum">0.1em</xsl:attribute>
	<xsl:attribute name="space-after.optimum">0.1em</xsl:attribute>
	<xsl:attribute name="space-after.maximum">0.1em</xsl:attribute>
	<xsl:attribute name="text-align">left</xsl:attribute>
	<xsl:attribute name="start-indent"><xsl:value-of select="$title.margin.left"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="normal.para.spacing">
	<xsl:attribute name="space-before.minimum">0.1em</xsl:attribute>
	<xsl:attribute name="space-before.optimum">0.1em</xsl:attribute>
	<xsl:attribute name="space-before.maximum">0.1em</xsl:attribute>
	<xsl:attribute name="space-after.optimum">1em</xsl:attribute>
	<xsl:attribute name="space-after.minimum">0.8em</xsl:attribute>
	<xsl:attribute name="space-after.maximum">1.2em</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="book.titlepage.recto.style">
	<xsl:attribute name="font-family">
		<xsl:value-of select="$title.fontset"/>
	</xsl:attribute>
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="font-weight">bold</xsl:attribute>
	<xsl:attribute name="font-size">12pt</xsl:attribute>
	<xsl:attribute name="text-align">center</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="component.title.properties">
	<xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>
	<xsl:attribute name="space-before.optimum"><xsl:value-of select="concat($body.font.master, 'pt')"/></xsl:attribute>
	<xsl:attribute name="space-before.minimum"><xsl:value-of select="concat($body.font.master, 'pt')"/></xsl:attribute>
	<xsl:attribute name="space-before.maximum"><xsl:value-of select="concat($body.font.master, 'pt')"/></xsl:attribute>
	<xsl:attribute name="hyphenate">false</xsl:attribute>
	<xsl:attribute name="color">
		<xsl:choose>
			<xsl:when test="not(parent::chapter | parent::article | parent::appendix)"><xsl:value-of select="$title.color"/></xsl:when>
			<xsl:otherwise>black</xsl:otherwise>
		</xsl:choose>
	</xsl:attribute>
	<xsl:attribute name="text-align">
		<xsl:choose>
			<xsl:when test="((parent::article | parent::articleinfo) and not(ancestor::book) and not(self::bibliography))				 or (parent::slides | parent::slidesinfo)">center</xsl:when>
			<xsl:otherwise>left</xsl:otherwise>
		</xsl:choose>
	</xsl:attribute>
	<xsl:attribute name="start-indent"><xsl:value-of select="$title.margin.left"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="chapter.titlepage.recto.style">
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="background-color">white</xsl:attribute>
	<xsl:attribute name="font-size">
		<xsl:choose>
			<xsl:when test="$l10n.gentext.language = 'ja-JP'">
				<xsl:value-of select="$body.font.master * 1.7"/>
				<xsl:text>pt</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>24pt</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:attribute>
	<xsl:attribute name="font-weight">bold</xsl:attribute>
	<xsl:attribute name="text-align">left</xsl:attribute>
	<!--xsl:attribute name="wrap-option">no-wrap</xsl:attribute-->
	<xsl:attribute name="padding-left">1em</xsl:attribute>
	<xsl:attribute name="padding-right">1em</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="preface.titlepage.recto.style">
	<xsl:attribute name="font-family">
		<xsl:value-of select="$title.fontset"/>
	</xsl:attribute>
	<xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="font-size">24pt</xsl:attribute>
	<xsl:attribute name="font-weight">bold</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="part.titlepage.recto.style">
  <xsl:attribute name="color"><xsl:value-of select="$title.color"/></xsl:attribute>
  <xsl:attribute name="text-align">center</xsl:attribute>
</xsl:attribute-set>


<!--
From: fo/table.xsl
Reason: Table Header format
Version:1.72
-->
<xsl:template name="table.cell.block.properties">
  <!-- highlight this entry? -->
  <xsl:if test="ancestor::thead or ancestor::tfoot">
    <xsl:attribute name="font-weight">bold</xsl:attribute>
	<xsl:attribute name="background-color"><xsl:value-of select="$title.color"/></xsl:attribute>
	<xsl:attribute name="color">white</xsl:attribute>
  </xsl:if>
</xsl:template>

<!--
From: fo/table.xsl
Reason: Table Header format
Version:1.72
-->
<!-- customize this template to add row properties -->
<xsl:template name="table.row.properties">
  <xsl:variable name="bgcolor">
    <xsl:call-template name="dbfo-attribute">
      <xsl:with-param name="pis" select="processing-instruction('dbfo')"/>
      <xsl:with-param name="attribute" select="'bgcolor'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:if test="$bgcolor != ''">
    <xsl:attribute name="background-color">
      <xsl:value-of select="$bgcolor"/>
    </xsl:attribute>
  </xsl:if>
  <xsl:if test="ancestor::thead or ancestor::tfoot">
	<xsl:attribute name="background-color"><xsl:value-of select="$title.color"/></xsl:attribute>
  </xsl:if>
</xsl:template>

<!--
From: fo/titlepage.templates.xsl
Reason: Switch to using chapter.titlepage.recto.style
Version:1.72
-->
<xsl:template match="title" mode="appendix.titlepage.recto.auto.mode">
<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="chapter.titlepage.recto.style">
<xsl:call-template name="component.title.nomarkup">
<xsl:with-param name="node" select="ancestor-or-self::appendix[1]"/>
</xsl:call-template>
</fo:block>
</xsl:template>

<!--
From: fo/titlepage.templates.xsl
Reason: Remove font size and weight overrides
Version:1.72
-->
<xsl:template match="title" mode="chapter.titlepage.recto.auto.mode">
<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="chapter.titlepage.recto.style">
<xsl:value-of select="."/>
</fo:block>
</xsl:template>

<!--
From: fo/titlepage.templates.xsl
Reason: Remove font family, size and weight overrides
Version:1.72
-->
<xsl:template name="preface.titlepage.recto">
	<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="preface.titlepage.recto.style" margin-left="{$title.margin.left}">
<xsl:call-template name="component.title.nomarkup">
<xsl:with-param name="node" select="ancestor-or-self::preface[1]"/>
</xsl:call-template></fo:block>
	<xsl:choose>
		<xsl:when test="prefaceinfo/subtitle">
			<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/subtitle"/>
		</xsl:when>
		<xsl:when test="docinfo/subtitle">
			<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/subtitle"/>
		</xsl:when>
		<xsl:when test="info/subtitle">
			<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/subtitle"/>
		</xsl:when>
		<xsl:when test="subtitle">
			<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="subtitle"/>
		</xsl:when>
	</xsl:choose>

	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/corpauthor"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/corpauthor"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/corpauthor"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/authorgroup"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/authorgroup"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/authorgroup"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/author"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/author"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/author"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/othercredit"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/othercredit"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/othercredit"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/releaseinfo"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/releaseinfo"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/releaseinfo"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/copyright"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/copyright"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/copyright"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/legalnotice"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/legalnotice"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/legalnotice"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/pubdate"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/pubdate"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/pubdate"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/revision"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/revision"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/revision"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/revhistory"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/revhistory"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/revhistory"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="prefaceinfo/abstract"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="docinfo/abstract"/>
	<xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="info/abstract"/>
</xsl:template>


<xsl:template name="pickfont-sans">
	<xsl:variable name="font">
		<xsl:choose>
			<xsl:when test="$l10n.gentext.language = 'ja-JP'">
				<xsl:text>SazanamiGothic,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ko-KR'">
				<xsl:text>BaekmukBatang,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-CN'">
				<xsl:text>Zysong,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'as-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'bn-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ta-IN'">
				<xsl:text>LohitTamil,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'pa-IN'">
				<xsl:text>LohitPunjabi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'hi-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'mr-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'gu-IN'">
				<xsl:text>LohitGujarati,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-TW'">
				<xsl:text>Uming,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'kn-IN'">
				<xsl:text>LohitKannada,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ml-IN'">
				<xsl:text>LohitMalayalam,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'or-IN'">
				<xsl:text>LohitOriya,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'te-IN'">
				<xsl:text>LohitTelugu,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'si-LK'">
				<xsl:text>Lklug,</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$fop.extensions != 0">
		  <xsl:copy-of select="$font"/><xsl:text>LiberationSans,sans-serif</xsl:text>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:copy-of select="$font"/><xsl:text>LiberationSans,sans-serif</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="pickfont-serif">
	<xsl:variable name="font">
		<xsl:choose>
			<xsl:when test="$l10n.gentext.language = 'ja-JP'">
				<xsl:text>SazanamiGothic,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ko-KR'">
				<xsl:text>BaekmukBatang,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-CN'">
				<xsl:text>Zysong,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'as-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'bn-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ta-IN'">
				<xsl:text>LohitTamil,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'pa-IN'">
				<xsl:text>LohitPunjabi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'hi-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'mr-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'gu-IN'">
				<xsl:text>LohitGujarati,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-TW'">
				<xsl:text>Uming,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'kn-IN'">
				<xsl:text>LohitKannada,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ml-IN'">
				<xsl:text>LohitMalayalam,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'or-IN'">
				<xsl:text>LohitOriya,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'te-IN'">
				<xsl:text>LohitTelugu,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'si-LK'">
				<xsl:text>Lklug,</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$fop.extensions != 0">
		  <xsl:copy-of select="$font"/><xsl:text>LiberationSerif,serif</xsl:text>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:copy-of select="$font"/><xsl:text>LiberationSerif,serif</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="pickfont-mono">
	<xsl:variable name="font">
		<xsl:choose>
			<xsl:when test="$l10n.gentext.language = 'ja-JP'">
				<xsl:text>SazanamiGothic,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ko-KR'">
				<xsl:text>BaekmukBatang,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-CN'">
				<xsl:text>Zysong,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'as-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'bn-IN'">
				<xsl:text>LohitBengali,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ta-IN'">
				<xsl:text>LohitTamil,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'pa-IN'">
				<xsl:text>LohitPunjabi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'hi-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'mr-IN'">
				<xsl:text>Lohit-Hindi,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'gu-IN'">
				<xsl:text>LohitGujarati,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'zh-TW'">
				<xsl:text>Uming,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'kn-IN'">
				<xsl:text>LohitKannada,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'ml-IN'">
				<xsl:text>LohitMalayalam,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'or-IN'">
				<xsl:text>LohitOriya,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'te-IN'">
				<xsl:text>LohitTelugu,</xsl:text>
			</xsl:when>
			<xsl:when test="$l10n.gentext.language = 'si-LK'">
				<xsl:text>Lklug,</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$fop.extensions != 0">
		  <xsl:copy-of select="$font"/><xsl:text>LiberationMono,monospace</xsl:text>
		</xsl:when>
		<xsl:otherwise>
		  <xsl:copy-of select="$font"/><xsl:text>LiberationMono,monospace</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!--xsl:param name="symbol.font.family">
	<xsl:choose>
		<xsl:when test="$l10n.gentext.language = 'ja-JP'">
			<xsl:text>Symbol,ZapfDingbats</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>Symbol,ZapfDingbats</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:param-->

<xsl:param name="title.font.family">
	<xsl:call-template name="pickfont-sans"/>
</xsl:param>

<xsl:param name="body.font.family">
	<xsl:call-template name="pickfont-sans"/>
</xsl:param>

<xsl:param name="monospace.font.family">
	<xsl:call-template name="pickfont-mono"/>
</xsl:param>

<xsl:param name="sans.font.family">
	<xsl:call-template name="pickfont-sans"/>
</xsl:param>

<!--xsl:param name="callout.unicode.font">
	<xsl:call-template name="pickfont-sans"/>
</xsl:param-->

<!--
From: fo/verbatim.xsl
Reason: Left align address
Version: 1.72
-->

<xsl:template match="address">
	<xsl:param name="suppress-numbers" select="'0'"/>

	<xsl:variable name="content">
		<xsl:choose>
			<xsl:when test="$suppress-numbers = '0'
											and @linenumbering = 'numbered'
											and $use.extensions != '0'
											and $linenumbering.extension != '0'">
				<xsl:call-template name="number.rtf.lines">
					<xsl:with-param name="rtf">
						<xsl:apply-templates/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<fo:block wrap-option='no-wrap'
						white-space-collapse='false'
			white-space-treatment='preserve'
						linefeed-treatment="preserve"
						text-align="start"
						xsl:use-attribute-sets="verbatim.properties">
		<xsl:copy-of select="$content"/>
	</fo:block>
</xsl:template>

<xsl:template name="component.title.nomarkup">
  <xsl:param name="node" select="."/>

  <xsl:variable name="id">
    <xsl:call-template name="object.id">
      <xsl:with-param name="object" select="$node"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="title">
    <xsl:apply-templates select="$node" mode="object.title.markup">
      <xsl:with-param name="allow-anchors" select="1"/>
    </xsl:apply-templates>
  </xsl:variable>
  <xsl:copy-of select="$title"/>
</xsl:template>

<xsl:attribute-set name="header.content.properties">
  <xsl:attribute name="wrap-option">no-wrap</xsl:attribute>
  <xsl:attribute name="font-family">
    <xsl:value-of select="$body.fontset"/>
  </xsl:attribute>
  <xsl:attribute name="margin-left">
    <xsl:value-of select="$title.margin.left"/>
  </xsl:attribute>
</xsl:attribute-set>

<!--
From: fo/pagesetup.xsl
Reason: Custom Header
Version: 1.72
-->
<xsl:template name="header.content">
  <xsl:param name="pageclass" select="''"/>
  <xsl:param name="sequence" select="''"/>
  <xsl:param name="position" select="''"/>
  <xsl:param name="gentext-key" select="''"/>
	<xsl:param name="title-limit" select="'30'"/>
<!--
  <fo:block>
    <xsl:value-of select="$pageclass"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$sequence"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$position"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$gentext-key"/>
  </fo:block>
body, blank, left, chapter
-->
    <!-- sequence can be odd, even, first, blank -->
    <!-- position can be left, center, right -->
    <xsl:choose>
      <!--xsl:when test="($sequence='blank' and $position='left' and $gentext-key='chapter')">
			<xsl:variable name="text">
				<xsl:call-template name="component.title.nomarkup"/>
			</xsl:variable>
	      <fo:inline keep-together.within-line="always" font-weight="bold">
  			  <xsl:choose>
		  		<xsl:when test="string-length($text) &gt; '33'">
					<xsl:value-of select="concat(substring($text, 0, $title-limit), '...')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$text"/>
				</xsl:otherwise>
			  </xsl:choose>
		  </fo:inline>
      </xsl:when-->
	  <xsl:when test="$confidential = 1 and (($sequence='odd' and $position='left') or ($sequence='even' and $position='right'))">
	      <fo:inline keep-together.within-line="always" font-weight="bold">
			<xsl:text>RED HAT CONFIDENTIAL</xsl:text>
		  </fo:inline>
      </xsl:when>
	  <xsl:when test="$sequence = 'blank'">
        <!-- nothing -->
      </xsl:when>
 	  <!-- Extracting 'Chapter' + Chapter Number from the full Chapter title, with a dirty, dirty hack -->
  		<xsl:when test="($sequence='first' and $position='left' and $gentext-key='chapter')">
		<xsl:variable name="text">
			<xsl:call-template name="component.title.nomarkup"/>
		</xsl:variable>
		<xsl:variable name="chapt">
			<xsl:value-of select="substring-before($text, '&#xA0;')"/>
		</xsl:variable>
		<xsl:variable name="remainder">
			<xsl:value-of select="substring-after($text, '&#xA0;')"/>
		</xsl:variable>
		<xsl:variable name="chapt-num">
			<xsl:value-of select="substring-before($remainder, '&#xA0;')"/>
		</xsl:variable>
		<xsl:variable name="text1">
			<xsl:value-of select="concat($chapt, '&#xA0;', $chapt-num)"/>
		</xsl:variable>
        <fo:inline keep-together.within-line="always" font-weight="bold">
 		  <xsl:value-of select="$text1"/>
		</fo:inline>
      </xsl:when>
     <!--xsl:when test="($sequence='odd' or $sequence='even') and $position='center'"-->
      <xsl:when test="($sequence='even' and $position='left')">
        <!--xsl:if test="$pageclass != 'titlepage'"-->
	      <fo:inline keep-together.within-line="always" font-weight="bold">
				<xsl:call-template name="component.title.nomarkup"/>
		  </fo:inline>
        <!--xsl:if-->
      </xsl:when>
      <xsl:when test="($sequence='odd' and $position='right')">
        <!--xsl:if test="$pageclass != 'titlepage'"-->
	      <fo:inline keep-together.within-line="always"><fo:retrieve-marker retrieve-class-name="section.head.marker" retrieve-position="first-including-carryover" retrieve-boundary="page-sequence"/></fo:inline>
        <!--/xsl:if-->
      </xsl:when>
	  <xsl:when test="$position='left'">
        <!-- Same for odd, even, empty, and blank sequences -->
        <xsl:call-template name="draft.text"/>
      </xsl:when>
      <xsl:when test="$position='center'">
        <!-- nothing for empty and blank sequences -->
      </xsl:when>
      <xsl:when test="$position='right'">
        <!-- Same for odd, even, empty, and blank sequences -->
        <xsl:call-template name="draft.text"/>
      </xsl:when>
      <xsl:when test="$sequence = 'first'">
        <!-- nothing for first pages -->
      </xsl:when>
      <xsl:when test="$sequence = 'blank'">
        <!-- nothing for blank pages -->
      </xsl:when>
    </xsl:choose>
</xsl:template>

<!--
From: fo/pagesetup.xsl
Reason: Override colour
Version: 1.72
-->
<xsl:template name="head.sep.rule">
	<xsl:param name="pageclass"/>
	<xsl:param name="sequence"/>
	<xsl:param name="gentext-key"/>

	<xsl:if test="$header.rule != 0">
		<xsl:attribute name="border-bottom-width">0.5pt</xsl:attribute>
		<xsl:attribute name="border-bottom-style">solid</xsl:attribute>
		<xsl:attribute name="border-bottom-color">black</xsl:attribute>
	</xsl:if>
</xsl:template>

<!--
From: fo/pagesetup.xsl
Reason: Override colour
Version: 1.72
-->
<xsl:template name="foot.sep.rule">
	<xsl:param name="pageclass"/>
	<xsl:param name="sequence"/>
	<xsl:param name="gentext-key"/>

	<xsl:if test="$footer.rule != 0">
		<xsl:attribute name="border-top-width">0.5pt</xsl:attribute>
		<xsl:attribute name="border-top-style">solid</xsl:attribute>
		<xsl:attribute name="border-top-color">black</xsl:attribute>
	</xsl:if>
</xsl:template>

<xsl:param name="footnote.font.size">
	<xsl:value-of select="$body.font.master * 0.8"/><xsl:text>pt</xsl:text>
</xsl:param>
<xsl:param name="footnote.number.format" select="'1'"/>
<xsl:param name="footnote.number.symbols" select="''"/>
<xsl:attribute-set name="footnote.mark.properties">
	<xsl:attribute name="font-size">75%</xsl:attribute>
	<xsl:attribute name="font-weight">normal</xsl:attribute>
	<xsl:attribute name="font-style">normal</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="footnote.properties">
	<xsl:attribute name="padding-top">48pt</xsl:attribute>
	<xsl:attribute name="font-family"><xsl:value-of select="$body.fontset"/></xsl:attribute>
	<xsl:attribute name="font-size"><xsl:value-of select="$footnote.font.size"/></xsl:attribute>
	<xsl:attribute name="color">black</xsl:attribute>
	<xsl:attribute name="font-weight">normal</xsl:attribute>
	<xsl:attribute name="font-style">normal</xsl:attribute>
	<xsl:attribute name="text-align"><xsl:value-of select="$alignment"/></xsl:attribute>
	<xsl:attribute name="start-indent">0pt</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="footnote.sep.leader.properties">
	<xsl:attribute name="color">black</xsl:attribute>
	<xsl:attribute name="leader-pattern">rule</xsl:attribute>
	<xsl:attribute name="leader-length">1in</xsl:attribute>
</xsl:attribute-set>

<xsl:template match="author" mode="tablerow.titlepage.mode">
  <fo:table-row>
    <fo:table-cell>
	  <fo:block>
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'Author'"/>
        </xsl:call-template>
	  </fo:block>
    </fo:table-cell>
    <fo:table-cell>
	  <fo:block>
	    <xsl:call-template name="person.name">
          <xsl:with-param name="node" select="."/>
        </xsl:call-template>
	  </fo:block>
    </fo:table-cell>
    <fo:table-cell>
	  <fo:block>
	    <xsl:apply-templates select="email"/>
	  </fo:block>
    </fo:table-cell>
  </fo:table-row>
</xsl:template>

<xsl:template match="author" mode="titlepage.mode">
  <fo:block>
    <xsl:call-template name="person.name">
         <xsl:with-param name="node" select="."/>
    </xsl:call-template>
  </fo:block>
</xsl:template>

<xsl:param name="editedby.enabled">0</xsl:param>

<xsl:template match="editor" mode="tablerow.titlepage.mode">
  <fo:table-row>
    <fo:table-cell>
	  <fo:block>
	    <xsl:call-template name="gentext">
	      <xsl:with-param name="key" select="'Editor'"/>
	    </xsl:call-template>
	  </fo:block>
    </fo:table-cell>
    <fo:table-cell>
	  <fo:block>
        <xsl:call-template name="person.name">
          <xsl:with-param name="node" select="."/>
        </xsl:call-template>
	  </fo:block>
    </fo:table-cell>
    <fo:table-cell>
	  <fo:block>
	    <xsl:apply-templates select="email"/>
	  </fo:block>
    </fo:table-cell>
  </fo:table-row>
</xsl:template>

<xsl:template match="othercredit" mode="tablerow.titlepage.mode">
  <fo:table-row>
    <fo:table-cell>
	  <fo:block>
		<xsl:if test="@class">
	    <xsl:call-template name="gentext">
	      <xsl:with-param name="key" select="@class"/>
	    </xsl:call-template>
		</xsl:if>
	  </fo:block>
    </fo:table-cell>
    <fo:table-cell>
	  <fo:block>
        <xsl:call-template name="person.name">
          <xsl:with-param name="node" select="."/>
        </xsl:call-template>
	  </fo:block>
    </fo:table-cell>
    <fo:table-cell>
	  <fo:block>
	    <xsl:apply-templates select="email"/>
	  </fo:block>
    </fo:table-cell>
  </fo:table-row>
 </xsl:template>

<!--
From: fo/titlepage.xsl
Reason: 
Version:1.72
-->
<xsl:template name="verso.authorgroup">
  <fo:table table-layout="fixed" width="100%">
    <fo:table-column column-number="1" column-width="proportional-column-width(1)"/>
    <fo:table-column column-number="2" column-width="proportional-column-width(1)"/>
    <fo:table-column column-number="3" column-width="proportional-column-width(1)"/>
    <fo:table-body>
      <xsl:apply-templates select="author" mode="tablerow.titlepage.mode"/>
      <xsl:apply-templates select="editor" mode="tablerow.titlepage.mode"/>
      <xsl:apply-templates select="othercredit" mode="tablerow.titlepage.mode"/>
    </fo:table-body>
  </fo:table>
</xsl:template>

<xsl:template match="title" mode="book.titlepage.recto.auto.mode">
<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="book.titlepage.recto.style" text-align="center" font-size="34pt" space-before="18.6624pt" font-weight="bold" font-family="{$title.fontset}">
<xsl:call-template name="division.title">
<xsl:with-param name="node" select="ancestor-or-self::book[1]"/>
</xsl:call-template>
</fo:block>
</xsl:template>

<xsl:template match="subtitle" mode="book.titlepage.recto.auto.mode">
<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="book.titlepage.recto.style" text-align="center" font-size="14pt" space-before="30pt" font-family="{$title.fontset}">
<xsl:apply-templates select="." mode="book.titlepage.recto.mode"/>
</fo:block>
</xsl:template>

<xsl:template match="issuenum" mode="book.titlepage.recto.auto.mode">
<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="book.titlepage.recto.style" text-align="center" font-size="34pt" space-before="30pt" font-family="{$title.fontset}">
<xsl:apply-templates select="." mode="book.titlepage.recto.mode"/>
</fo:block>
</xsl:template>

<xsl:template match="author" mode="book.titlepage.recto.auto.mode">
  <fo:block xsl:use-attribute-sets="book.titlepage.recto.style" font-size="14pt" space-before="15.552pt">
    <xsl:call-template name="person.name">
         <xsl:with-param name="node" select="."/>
    </xsl:call-template>
  </fo:block>
</xsl:template>

<xsl:template name="book.titlepage.recto">
  <xsl:choose>
    <xsl:when test="bookinfo/productname">
<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="book.titlepage.recto.style" text-align="center" font-size="34pt" space-before="18.6624pt" font-weight="bold" font-family="{$title.fontset}">
	  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/productname"/>
	  <xsl:text> </xsl:text>
	  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/productnumber"/>
</fo:block>
    </xsl:when>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="bookinfo/title">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/title"/>
    </xsl:when>
    <xsl:when test="info/title">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/title"/>
    </xsl:when>
    <xsl:when test="title">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="title"/>
    </xsl:when>
  </xsl:choose>

  <xsl:choose>
    <xsl:when test="bookinfo/subtitle">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/subtitle"/>
    </xsl:when>
    <xsl:when test="info/subtitle">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/subtitle"/>
    </xsl:when>
    <xsl:when test="subtitle">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="subtitle"/>
    </xsl:when>
  </xsl:choose>

  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/corpauthor"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/corpauthor"/>

  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/authorgroup/author"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/authorgroup/author"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/author"/>
  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/author"/>

  <fo:block xsl:use-attribute-sets="book.titlepage.recto.style" color="black">
    <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/invpartnumber"/>
    <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/invpartnumber"/>
  </fo:block>
  <xsl:choose>
    <xsl:when test="bookinfo/pubdate|info/pubdate">
  <fo:block xsl:use-attribute-sets="book.titlepage.recto.style" color="black"> 
    <xsl:call-template name="gentext">
      <xsl:with-param name="key" select="'pubdate'"/>
	</xsl:call-template>
	<xsl:text>: </xsl:text>
    <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/pubdate"/>
    <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/pubdate"/>
  </fo:block>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template name="book.titlepage.verso">
  <xsl:choose>
    <xsl:when test="bookinfo/abstract">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="bookinfo/abstract"/>
    </xsl:when>
    <xsl:when test="info/abstract">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="info/abstract"/>
    </xsl:when>
  </xsl:choose>

</xsl:template>

<xsl:template name="book.titlepage3.recto">
  <xsl:choose>
    <xsl:when test="bookinfo/title">
      <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="bookinfo/title"/>
    </xsl:when>
    <xsl:when test="info/title">
      <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="info/title"/>
    </xsl:when>
    <xsl:when test="title">
      <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="title"/>
    </xsl:when>
  </xsl:choose>

 
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="bookinfo/authorgroup"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="info/authorgroup"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="bookinfo/author"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="info/author"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="bookinfo/othercredit"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="info/othercredit"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="bookinfo/copyright"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="info/copyright"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="bookinfo/legalnotice"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="info/legalnotice"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="bookinfo/publisher"/>
  <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="info/publisher"/>
</xsl:template>

<xsl:template name="book.titlepage.separator"><fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" break-after="page"/>
</xsl:template>

<xsl:template name="book.titlepage.before.recto">
</xsl:template>

<xsl:template name="book.titlepage.before.verso"><fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" break-after="page"/>
</xsl:template>

<xsl:template name="book.titlepage">
  <fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format">
    <xsl:call-template name="book.titlepage.before.recto"/>
    <fo:block><xsl:call-template name="book.titlepage.recto"/></fo:block>
    <xsl:call-template name="book.titlepage.separator"/>
    <!--fo:block><xsl:call-template name="book.titlepage.verso"/></fo:block>
    <xsl:call-template name="book.titlepage.separator"/>
    <fo:block><xsl:call-template name="book.titlepage3.recto"/></fo:block-->
    <fo:block><xsl:call-template name="book.titlepage3.recto"/></fo:block>
    <fo:block><xsl:call-template name="book.titlepage.verso"/></fo:block>
    <xsl:call-template name="book.titlepage.separator"/>
  </fo:block>
</xsl:template>

<!--
From: fo/qandaset.xsl
Reason: Id in list-item-label causes fop crash
Version:1.72
-->

<xsl:template match="question">
  <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>

  <xsl:variable name="entry.id">
    <xsl:call-template name="object.id">
      <xsl:with-param name="object" select="parent::*"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="deflabel">
    <xsl:choose>
      <xsl:when test="ancestor-or-self::*[@defaultlabel]">
        <xsl:value-of select="(ancestor-or-self::*[@defaultlabel])[last()]
                              /@defaultlabel"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$qanda.defaultlabel"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <fo:list-item id="{$entry.id}" xsl:use-attribute-sets="dash.list.item.spacing">
    <fo:list-item-label end-indent="label-end()">
      <xsl:choose>
        <xsl:when test="$deflabel = 'none'">
          <fo:block/>
        </xsl:when>
        <xsl:otherwise>
          <fo:block font-weight="bold">
            <xsl:apply-templates select="." mode="label.markup"/>
            <xsl:if test="$deflabel = 'number' and not(label)">
              <xsl:apply-templates select="." mode="intralabel.punctuation"/>
            </xsl:if>
          </fo:block>
        </xsl:otherwise>
      </xsl:choose>
    </fo:list-item-label>
    <fo:list-item-body start-indent="body-start()">
      <xsl:choose>
        <xsl:when test="$deflabel = 'none'">
          <fo:block font-weight="bold">
            <xsl:apply-templates select="*[local-name(.)!='label']"/>
          </fo:block>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="*[local-name(.)!='label']"/>
        </xsl:otherwise>
      </xsl:choose>
      <!-- Uncomment this line to get revhistory output in the question -->
      <!-- <xsl:apply-templates select="preceding-sibling::revhistory"/> -->
    </fo:list-item-body>
  </fo:list-item>
</xsl:template>

<!--
From: fo/qandaset.xsl
Reason: Id in list-item-label causes fop crash
Version:1.72
-->
<xsl:template match="answer">
  <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>
  <xsl:variable name="entry.id">
    <xsl:call-template name="object.id">
      <xsl:with-param name="object" select="parent::*"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="deflabel">
    <xsl:choose>
      <xsl:when test="ancestor-or-self::*[@defaultlabel]">
        <xsl:value-of select="(ancestor-or-self::*[@defaultlabel])[last()]
                              /@defaultlabel"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$qanda.defaultlabel"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <fo:list-item xsl:use-attribute-sets="fat.list.item.spacing">
    <fo:list-item-label end-indent="label-end()">
      <xsl:choose>
        <xsl:when test="$deflabel = 'none'">
          <fo:block/>
        </xsl:when>
        <xsl:otherwise>
          <fo:block font-weight="bold">
            <xsl:variable name="answer.label">
              <xsl:apply-templates select="." mode="label.markup"/>
            </xsl:variable>
            <xsl:copy-of select="$answer.label"/>
          </fo:block>
        </xsl:otherwise>
      </xsl:choose>
    </fo:list-item-label>
    <fo:list-item-body start-indent="body-start()">
      <xsl:apply-templates select="*[local-name(.)!='label']"/>
    </fo:list-item-body>
  </fo:list-item>
</xsl:template>
<!--
From: fo/block.xsl
Reason: formal para needs to be block to appear as a title
        remove runinhead.default.title.end.punct
Version:1.72
-->
<xsl:template match="formalpara/title|formalpara/info/title">
  <xsl:variable name="titleStr">
      <xsl:apply-templates/>
  </xsl:variable>
  <fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="section.title.properties section.title.level5.properties">
    <xsl:copy-of select="$titleStr"/>
  </fo:block>
</xsl:template>

<!--
From: fo/nline.xsl
Reason: Italicise package name
Version:1.72
-->
<xsl:template match="package">
  <xsl:call-template name="inline.italicseq"/>
</xsl:template>

<xsl:template match="command|filename|keycap|classname|literal">
  <xsl:call-template name="inline.boldmonoseq"/>
</xsl:template>

<xsl:template match="replaceable">
  <xsl:call-template name="inline.italicmonoseq"/>
</xsl:template>

<!--
From: fo/auttoc.xsl
Reason: Bold chaps
Version:1.72
-->

<xsl:template name="toc.line">
  <xsl:param name="toc-context" select="NOTANODE"/>

  <xsl:variable name="id">
    <xsl:call-template name="object.id"/>
  </xsl:variable>

  <xsl:variable name="label">
    <xsl:apply-templates select="." mode="label.markup"/>
  </xsl:variable>

  <fo:block xsl:use-attribute-sets="toc.line.properties"
            end-indent="{$toc.indent.width}pt"
            last-line-end-indent="-{$toc.indent.width}pt">
        <xsl:if test="local-name(.) = 'glossary' or local-name(.) = 'bibliography' or local-name(.) = 'preface' or local-name(.) = 'reference' or local-name(.) = 'chapter' or local-name(.) = 'article' or local-name(.) = 'appendix' or local-name(.) = 'index' ">
	  <xsl:attribute name="space-before.minimum">6pt</xsl:attribute>
	  <xsl:attribute name="space-before.optimum">6pt</xsl:attribute>
	  <xsl:attribute name="space-before.maximum">8pt</xsl:attribute>
	  <xsl:attribute name="font-weight">bold</xsl:attribute>
	  <xsl:attribute name="text-align">left</xsl:attribute>
        </xsl:if>
        <xsl:if test="local-name(.) = 'part' ">
	  <xsl:attribute name="space-before.minimum">18pt</xsl:attribute>
	  <xsl:attribute name="space-before.optimum">18pt</xsl:attribute>
	  <xsl:attribute name="space-before.maximum">24pt</xsl:attribute>
	  <xsl:attribute name="font-weight">bold</xsl:attribute>
	  <xsl:attribute name="text-align">left</xsl:attribute>
        </xsl:if>
    <fo:inline keep-with-next.within-line="always">
      <fo:basic-link internal-destination="{$id}">
    <!--xsl:message>
	<xsl:text>Local Name: </xsl:text>
        <xsl:value-of select="local-name(.)"/>
    </xsl:message-->
        <xsl:if test="$label != ''">
          <xsl:copy-of select="$label"/>
          <xsl:value-of select="$autotoc.label.separator"/>
        </xsl:if>
        <xsl:apply-templates select="." mode="titleabbrev.markup"/>
      </fo:basic-link>
    </fo:inline>
    <fo:inline keep-together.within-line="always">
      <xsl:text> </xsl:text>
      <xsl:choose>
      <xsl:when test="local-name(.) = 'glossary' or local-name(.) = 'bibliography' or local-name(.) = 'preface' or local-name(.) = 'chapter' or local-name(.) = 'reference' or local-name(.) = 'part' or local-name(.) = 'article' or local-name(.) = 'appendix' or local-name(.) = 'index'">
      <fo:leader leader-pattern="use-content"
                 leader-pattern-width="3pt"
                 leader-alignment="reference-area"
                 keep-with-next.within-line="always" white-space-collapse='false'>&#xa0;</fo:leader>
      </xsl:when>
      <xsl:otherwise>
      <fo:leader leader-pattern="dots"
                 leader-pattern-width="3pt"
                 leader-alignment="reference-area"
                 keep-with-next.within-line="always"/>
      </xsl:otherwise>
    </xsl:choose>
      <xsl:text> </xsl:text> 
      <fo:basic-link internal-destination="{$id}">
	  <xsl:attribute name="text-align">right</xsl:attribute>
        <fo:page-number-citation ref-id="{$id}"/>
      </fo:basic-link>
    </fo:inline>
  </fo:block>
</xsl:template>

<!--
From: fo/index.xsl
Reason: remove white space for indexterm anchors
Version:1.72
-->
<xsl:template match="indexterm" name="indexterm">
  <!-- Temporal workaround for bug in AXF -->
  <xsl:variable name="wrapper.name">
    <xsl:choose>
      <xsl:when test="$axf.extensions != 0">
        <xsl:call-template name="inline.or.block"/>
      </xsl:when>
      <xsl:otherwise>fo:wrapper</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="hidden.properties">
  <xsl:element name="{$wrapper.name}">
    <xsl:attribute name="id">
      <xsl:call-template name="object.id"/>
    </xsl:attribute>
    <xsl:choose>
      <xsl:when test="$xep.extensions != 0">
        <xsl:attribute name="rx:key">
          <xsl:value-of select="&primary;"/>
          <xsl:if test="@significance='preferred'"><xsl:value-of select="$significant.flag"/></xsl:if>
          <xsl:if test="secondary">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="&secondary;"/>
          </xsl:if>
          <xsl:if test="tertiary">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="&tertiary;"/>
          </xsl:if>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:comment>
          <xsl:call-template name="comment-escape-string">
            <xsl:with-param name="string">
              <xsl:value-of select="primary"/>
              <xsl:if test="secondary">
                <xsl:text>, </xsl:text>
                <xsl:value-of select="secondary"/>
              </xsl:if>
              <xsl:if test="tertiary">
                <xsl:text>, </xsl:text>
                <xsl:value-of select="tertiary"/>
              </xsl:if>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:comment>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:element>
  </fo:block>
</xsl:template>

<xsl:template name="formal.object.heading">
  <xsl:param name="object" select="."/>
  <xsl:param name="placement" select="'before'"/>

    <xsl:choose>
      <xsl:when test="$placement = 'before'">
	<fo:block xsl:use-attribute-sets="above.title.properties">
        	<xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>
		<xsl:apply-templates select="$object" mode="object.title.markup">
		      <xsl:with-param name="allow-anchors" select="1"/>
    		</xsl:apply-templates>
  	</fo:block>
      </xsl:when>
      <xsl:otherwise>
  	<fo:block xsl:use-attribute-sets="below.title.properties">
        	<xsl:attribute name="keep-with-previous.within-column">always</xsl:attribute>
  		<xsl:apply-templates select="$object" mode="object.title.markup">
  	    		<xsl:with-param name="allow-anchors" select="1"/>
  	  	</xsl:apply-templates>
  	</fo:block>
      </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="segtitle" mode="seglist-table">
  <fo:table-cell>
    <fo:block xsl:use-attribute-sets="above.title.properties" font-weight="bold">
      <xsl:apply-templates/>
    </fo:block>
  </fo:table-cell>
</xsl:template>

<xsl:template match="seglistitem" mode="seglist-table">
  <xsl:variable name="id">
    <xsl:call-template name="object.id"/>
  </xsl:variable>
  <fo:table-row id="{$id}">
    <xsl:apply-templates mode="seglist-table"/>
  </fo:table-row>
</xsl:template>

<xsl:template match="seg" mode="seglist-table">
  <fo:table-cell xsl:use-attribute-sets="table.cell.padding">
    <fo:block>
      <xsl:apply-templates/>
    </fo:block>
  </fo:table-cell>
</xsl:template>

<xsl:template name="process.image">
  <!-- When this template is called, the current node should be  -->
  <!-- a graphic, inlinegraphic, imagedata, or videodata. All    -->
  <!-- those elements have the same set of attributes, so we can -->
  <!-- handle them all in one place.                             -->

  <xsl:variable name="scalefit">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0">0</xsl:when>
      <xsl:when test="@contentwidth">0</xsl:when>
      <xsl:when test="@contentdepth and
                      @contentdepth != '100%'">0</xsl:when>
      <xsl:when test="@scale">0</xsl:when>
      <xsl:when test="@scalefit"><xsl:value-of select="@scalefit"/></xsl:when>
      <xsl:when test="@width or @depth">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="scale">
    <xsl:choose>
      <xsl:when test="$ignore.image.scaling != 0">0</xsl:when>
      <xsl:when test="@contentwidth or @contentdepth">1.0</xsl:when>
      <xsl:when test="@scale">
        <xsl:value-of select="@scale div 100.0"/>
      </xsl:when>
      <xsl:otherwise>1.0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="filename">
    <xsl:choose>
      <xsl:when test="local-name(.) = 'graphic'
                      or local-name(.) = 'inlinegraphic'">
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

  <xsl:variable name="content-type">
    <xsl:if test="@format">
      <xsl:call-template name="graphic.format.content-type">
        <xsl:with-param name="format" select="@format"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="bgcolor">
    <xsl:call-template name="dbfo-attribute">
      <xsl:with-param name="pis"
                      select="../processing-instruction('dbfo')"/>
      <xsl:with-param name="attribute" select="'background-color'"/>
    </xsl:call-template>
  </xsl:variable>

  <fo:external-graphic>
    <xsl:attribute name="src">
      <xsl:call-template name="fo-external-image">
        <xsl:with-param name="filename">
          <xsl:if test="$img.src.path != '' and
                        not(starts-with($filename, '/')) and
                        not(contains($filename, '://'))">
            <xsl:value-of select="$img.src.path"/>
          </xsl:if>
          <xsl:value-of select="$filename"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:attribute>

    <xsl:attribute name="width">
      <xsl:choose>
        <xsl:when test="$ignore.image.scaling != 0">auto</xsl:when>
        <xsl:when test="contains(@width,'%')">
          <xsl:value-of select="@width"/>
        </xsl:when>
        <xsl:when test="@width and not(@width = '')">
          <xsl:call-template name="length-spec">
            <xsl:with-param name="length" select="@width"/>
            <xsl:with-param name="default.units" select="'px'"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="not(@depth) and $default.image.width != ''">
          <xsl:call-template name="length-spec">
            <xsl:with-param name="length" select="$default.image.width"/>
            <xsl:with-param name="default.units" select="'px'"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>auto</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>

    <xsl:attribute name="height">
      <xsl:choose>
        <xsl:when test="$ignore.image.scaling != 0">auto</xsl:when>
        <xsl:when test="contains(@depth,'%')">
          <xsl:value-of select="@depth"/>
        </xsl:when>
        <xsl:when test="@depth">
          <xsl:call-template name="length-spec">
            <xsl:with-param name="length" select="@depth"/>
            <xsl:with-param name="default.units" select="'px'"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>auto</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>

    <xsl:attribute name="content-width">
      <xsl:choose>
        <xsl:when test="$ignore.image.scaling != 0">auto</xsl:when>
        <xsl:when test="contains(@contentwidth,'%')">
          <xsl:value-of select="@contentwidth"/>
        </xsl:when>
        <xsl:when test="@contentwidth">
          <xsl:call-template name="length-spec">
            <xsl:with-param name="length" select="@contentwidth"/>
            <xsl:with-param name="default.units" select="'px'"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="number($scale) != 1.0">
          <xsl:value-of select="$scale * 100"/>
          <xsl:text>%</xsl:text>
        </xsl:when>
        <xsl:when test="$scalefit = 1">scale-to-fit</xsl:when>
        <xsl:otherwise>auto</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>

    <xsl:attribute name="content-height">
      <xsl:choose>
        <xsl:when test="$ignore.image.scaling != 0">auto</xsl:when>
        <xsl:when test="contains(@contentdepth,'%')">
          <xsl:value-of select="@contentdepth"/>
        </xsl:when>
        <xsl:when test="@contentdepth">
          <xsl:call-template name="length-spec">
            <xsl:with-param name="length" select="@contentdepth"/>
            <xsl:with-param name="default.units" select="'px'"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="number($scale) != 1.0">
          <xsl:value-of select="$scale * 100"/>
          <xsl:text>%</xsl:text>
        </xsl:when>
        <xsl:when test="$scalefit = 1">scale-to-fit</xsl:when>
        <xsl:otherwise>auto</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>

    <xsl:if test="$content-type != ''">
      <xsl:attribute name="content-type">
        <xsl:value-of select="concat('content-type:',$content-type)"/>
      </xsl:attribute>
    </xsl:if>

    <xsl:if test="$bgcolor != ''">
      <xsl:attribute name="background-color">
        <xsl:value-of select="$bgcolor"/>
      </xsl:attribute>
    </xsl:if>

    <xsl:if test="@align">
      <xsl:attribute name="text-align">
        <xsl:value-of select="@align"/>
      </xsl:attribute>
    </xsl:if>

    <xsl:if test="@valign">
      <xsl:attribute name="display-align">
        <xsl:choose>
          <xsl:when test="@valign = 'top'">before</xsl:when>
          <xsl:when test="@valign = 'middle'">center</xsl:when>
          <xsl:when test="@valign = 'bottom'">after</xsl:when>
          <xsl:otherwise>auto</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:if>
  </fo:external-graphic>
</xsl:template>

<xsl:template match='xslthl:keyword'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.keyword.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:string'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.string.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:comment'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.comment.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:tag'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.tag.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:attribute'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.attribute.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:value'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.value.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:html'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.html.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:xslt'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.xslt.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:section'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.section.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:directive'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.directive.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match='xslthl:doctype'>
  <fo:inline><xsl:attribute name="color"><xsl:value-of select="$xslthl.doctype.color"/></xsl:attribute><xsl:apply-templates/></fo:inline>
</xsl:template>

<xsl:template match="varlistentry" mode="vl.as.blocks">
  <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>

  <fo:block id="{$id}"  
      keep-together.within-column="always" 
      keep-with-next.within-column="always">
    <xsl:apply-templates select="term"/>
  </fo:block>

  <fo:block xsl:use-attribute-sets="list.item.spacing" margin-left="0.25in">
    <xsl:apply-templates select="listitem"/>
  </fo:block>
</xsl:template>

<xsl:template match="segmentedlist" mode="seglist-table">
  <xsl:apply-templates select="title" mode="list.title.mode" />
  <fo:table>
    <fo:table-column column-number="1" column-width="34%"/>
    <fo:table-column column-number="2" column-width="66%"/>
    <fo:table-header start-indent="0pt" end-indent="0pt">
      <fo:table-row>
        <xsl:apply-templates select="segtitle" mode="seglist-table"/>
      </fo:table-row>
    </fo:table-header>
    <fo:table-body start-indent="0pt" end-indent="0pt">
      <xsl:apply-templates select="seglistitem" mode="seglist-table"/>
    </fo:table-body>
  </fo:table>
</xsl:template>


<xsl:template name="book.verso.title">
    <xsl:if test="following-sibling::bookinfo/productname | following-sibling::productname">
      <xsl:apply-templates select="(following-sibling::bookinfo/productname | following-sibling::productname)[1]" mode="book.verso.subtitle.mode"/>
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="(following-sibling::bookinfo/productnumber | following-sibling::productnumber)[1]" mode="book.verso.subtitle.mode"/>
      <xsl:text> </xsl:text>
    </xsl:if>

    <xsl:apply-templates mode="titlepage.mode"/>

    <xsl:if test="following-sibling::subtitle
                  |following-sibling::info/subtitle
                  |following-sibling::bookinfo/subtitle">
      <!--xsl:text>: </xsl:text-->
      <fo:block padding-bottom="24pt">
      <xsl:apply-templates select="(following-sibling::subtitle
                                   |following-sibling::info/subtitle
                                   |following-sibling::bookinfo/subtitle)[1]"
                           mode="book.verso.subtitle.mode"/>
	<xsl:apply-templates mode="titlepage.mode" select="(following-sibling::bookinfo/edition|following-sibling::edition)[1]"/>
      </fo:block>
    </xsl:if>
</xsl:template>

<xsl:template match="legalnotice" mode="book.titlepage.verso.auto.mode">
<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="book.titlepage.verso.style" padding-top="12pt" padding-bottom="24pt">
<xsl:apply-templates select="." mode="book.titlepage.verso.mode"/>
</fo:block>
</xsl:template>

<xsl:template match="email">
  <xsl:variable name="addr">
	<xsl:apply-templates/>
  </xsl:variable>

  <xsl:call-template name="inline.monoseq">
    <xsl:with-param name="content">
      <fo:inline keep-together.within-line="always" hyphenate="false">
          <fo:basic-link xsl:use-attribute-sets="xref.properties" external-destination="mailto:{$addr}">
        <xsl:if test="not($email.delimiters.enabled = 0)">
          <xsl:text>&lt;</xsl:text>
        </xsl:if>
        <xsl:value-of select="$addr"/>
        <xsl:if test="not($email.delimiters.enabled = 0)">
          <xsl:text>&gt;</xsl:text>
        </xsl:if>
          </fo:basic-link>
      </fo:inline>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template match="edition" mode="titlepage.mode">
<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format">
  <xsl:call-template name="gentext">
    <xsl:with-param name="key" select="'Edition'"/>
  </xsl:call-template>
  <xsl:call-template name="gentext.space"/>
  <xsl:apply-templates mode="titlepage.mode"/>
</fo:block>
</xsl:template>

<xsl:template name="article.titlepage.recto">
  <xsl:choose>
    <xsl:when test="articleinfo/productname">
<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:use-attribute-sets="book.titlepage.recto.style" text-align="center" font-size="34pt" space-before="18.6624pt" font-weight="bold" font-family="{$title.fontset}">
	  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="articleinfo/productname"/>
	  <xsl:text> </xsl:text>
	  <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="articleinfo/productnumber"/>
</fo:block>
    </xsl:when>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="articleinfo/title">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/title"/>
    </xsl:when>
    <xsl:when test="artheader/title">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/title"/>
    </xsl:when>
    <xsl:when test="info/title">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/title"/>
    </xsl:when>
    <xsl:when test="title">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="title"/>
    </xsl:when>
  </xsl:choose>

  <xsl:choose>
    <xsl:when test="articleinfo/subtitle">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/subtitle"/>
    </xsl:when>
    <xsl:when test="artheader/subtitle">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/subtitle"/>
    </xsl:when>
    <xsl:when test="info/subtitle">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/subtitle"/>
    </xsl:when>
    <xsl:when test="subtitle">
      <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="subtitle"/>
    </xsl:when>
  </xsl:choose>

  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/corpauthor"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/corpauthor"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/corpauthor"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/authorgroup"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/authorgroup"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/authorgroup"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/author"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/author"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/author"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/othercredit"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/othercredit"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/othercredit"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/releaseinfo"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/releaseinfo"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/releaseinfo"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/copyright"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/copyright"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/copyright"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/legalnotice"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/legalnotice"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/legalnotice"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/pubdate"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/pubdate"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/pubdate"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/revision"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/revision"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/revision"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/revhistory"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/revhistory"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/revhistory"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="articleinfo/abstract"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="artheader/abstract"/>
  <xsl:apply-templates mode="article.titlepage.recto.auto.mode" select="info/abstract"/>
</xsl:template>

<xsl:template match="comment[&comment.block.parents;]|remark[&comment.block.parents;]">
  <xsl:if test="$show.comments != 0">
    <fo:block font-style="italic" background-color="#ffff00">
      <xsl:call-template name="inline.charseq"/>
    </fo:block>
  </xsl:if>
</xsl:template>

<xsl:template match="comment|remark">
  <xsl:if test="$show.comments != 0">
    <fo:inline font-style="italic" background-color="#ffff00">
      <xsl:call-template name="inline.charseq"/>
    </fo:inline>
  </xsl:if>
</xsl:template>

<xsl:template match="orderedlist/listitem">
  <xsl:variable name="id"><xsl:call-template name="object.id"/></xsl:variable>

  <xsl:variable name="item.contents">
    <fo:list-item-label end-indent="label-end()" xsl:use-attribute-sets="orderedlist.label.properties">
      <fo:block>
        <xsl:apply-templates select="." mode="item-number"/>
      </fo:block>
    </fo:list-item-label>
    <fo:list-item-body start-indent="body-start()">
      <fo:block margin-left="6pt">
        <xsl:apply-templates/>
      </fo:block>
    </fo:list-item-body>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="parent::*/@spacing = 'compact'">
      <fo:list-item id="{$id}" xsl:use-attribute-sets="compact.list.item.spacing">
        <xsl:copy-of select="$item.contents"/>
      </fo:list-item>
    </xsl:when>
    <xsl:otherwise>
      <fo:list-item id="{$id}" xsl:use-attribute-sets="list.item.spacing">
        <xsl:copy-of select="$item.contents"/>
      </fo:list-item>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
