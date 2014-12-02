<?xml version='1.0'?>

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
		xmlns:rx="http://www.renderx.com/XSL/Extensions"
                xmlns:stbl="http://nwalsh.com/xslt/ext/com.nwalsh.saxon.Table"
                xmlns:xtbl="com.nwalsh.xalan.Table"
                xmlns:ptbl="http://nwalsh.com/xslt/ext/xsltproc/python/Table"
		xmlns:exsl="http://exslt.org/common"
                exclude-result-prefixes="exsl ptbl xtbl stbl">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl"/>
<xsl:param name="use.extensions" select="1"/>
<xsl:param name="tablecolumns.extension" select="0"/>
<xsl:param name="fop.extensions" select="0"/>
<xsl:param name="fop1.extensions" select="1"/>
<xsl:param name="linenumbering.extension" select="0"/>
<xsl:param name="callouts.extension" select="0"/>
<xsl:param name="highlight.source" select="0"/>

</xsl:stylesheet>

