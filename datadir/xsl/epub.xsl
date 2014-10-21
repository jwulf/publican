<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:exsl="http://exslt.org/common"
	xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"
	version="1.0"
	exclude-result-prefixes="l exsl">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/epub/docbook.xsl"/>
<xsl:import href="defaults.xsl"/>
<xsl:import href="xhtml-common.xsl"/>
<xsl:param name="suppress.navigation" select="1"/>
<xsl:param name="tablecolumns.extensions" select="1"/>
<xsl:param name="epub.oebps.dir" select="'OEBPS/'"/> 
<xsl:param name="chunker.output.doctype-public" select="'-//W3C//DTD XHTML 1.1//EN'"/>
<xsl:param name="chunker.output.doctype-system" select="'http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd'"/>
<xsl:param name="html.stylesheet">Common_Content/css/epub.css</xsl:param>
<xsl:param name="html.stylesheet.print"></xsl:param>

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
part nop
</xsl:param>
<xsl:param name="chunk.section.depth" select="0"/>
<xsl:param name="chunk.first.sections" select="0"/>

<!-- Why is this spammed everywhere? It's not valid in most locations -->
<xsl:template name="generate.html.lang">
  <!--xsl:apply-templates select="." mode="html.lang.attribute"/-->
</xsl:template>

<!-- Added check for html.stylesheet.print -->
  <xsl:template name="opf.manifest">
    <xsl:element namespace="http://www.idpf.org/2007/opf" name="manifest">
      <xsl:element namespace="http://www.idpf.org/2007/opf" name="item">
        <xsl:attribute name="id"> <xsl:value-of select="$epub.ncx.toc.id"/> </xsl:attribute>
        <xsl:attribute name="media-type">application/x-dtbncx+xml</xsl:attribute>
        <xsl:attribute name="href"><xsl:value-of select="$epub.ncx.filename"/> </xsl:attribute>
      </xsl:element>

      <xsl:if test="contains($toc.params, 'toc')">
        <xsl:element namespace="http://www.idpf.org/2007/opf" name="item">
          <xsl:attribute name="id"> <xsl:value-of select="$epub.html.toc.id"/> </xsl:attribute>
          <xsl:attribute name="media-type">application/xhtml+xml</xsl:attribute>
          <xsl:attribute name="href">
            <xsl:call-template name="toc-href">
              <xsl:with-param name="node" select="/*"/>
            </xsl:call-template>
          </xsl:attribute>
        </xsl:element>
      </xsl:if>  

      <xsl:if test="$html.stylesheet != ''">
        <xsl:element namespace="http://www.idpf.org/2007/opf" name="item">
          <xsl:attribute name="media-type">text/css</xsl:attribute>
          <xsl:attribute name="id">css</xsl:attribute>
          <xsl:attribute name="href"><xsl:value-of select="$html.stylesheet"/></xsl:attribute>
        </xsl:element>
      </xsl:if>

      <xsl:if test="/*/*[cover or contains(name(.), 'info')]//mediaobject[@role='cover' or ancestor::cover]"> 
        <xsl:element namespace="http://www.idpf.org/2007/opf" name="item">
          <xsl:attribute name="id"> <xsl:value-of select="$epub.cover.id"/> </xsl:attribute>
          <xsl:attribute name="href"> 
            <xsl:value-of select="$epub.cover.html"/>
          </xsl:attribute>
          <xsl:attribute name="media-type">application/xhtml+xml</xsl:attribute>
        </xsl:element>
      </xsl:if>  

      <xsl:choose>
        <xsl:when test="$epub.embedded.fonts != '' and not(contains($epub.embedded.fonts, ','))">
          <xsl:call-template name="embedded-font-item">
            <xsl:with-param name="font.file" select="$epub.embedded.fonts"/> <!-- There is just one -->
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="$epub.embedded.fonts != ''">
          <xsl:variable name="font.file.tokens" select="str:tokenize($epub.embedded.fonts, ',')"/>
          <xsl:for-each select="exsl:node-set($font.file.tokens)">
            <xsl:call-template name="embedded-font-item">
              <xsl:with-param name="font.file" select="."/>
              <xsl:with-param name="font.order" select="position()"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>
      </xsl:choose>

      <!-- TODO: be nice to have a id="titlepage" here -->
      <xsl:apply-templates select="//part|
                                   //book[*[last()][self::bookinfo]]|
                                   //book[bookinfo]|
                                   /set|
                                   /set/book|
                                   //reference|
                                   //preface|
                                   //chapter|
                                   //bibliography|
                                   //appendix|
                                   //article|
                                   //glossary|
                                   //section|
                                   //sect1|
                                   //sect2|
                                   //sect3|
                                   //sect4|
                                   //sect5|
                                   //refentry|
                                   //colophon|
                                   //bibliodiv[title]|
                                   //index|
                                   //setindex|
                                   //graphic|
                                   //inlinegraphic|
                                   //mediaobject|
                                   //mediaobjectco|
                                   //inlinemediaobject" 
                           mode="opf.manifest"/>
      <xsl:call-template name="opf.calloutlist"/>
    </xsl:element>
</xsl:template>

<xsl:template name="gentext.template">
  <xsl:param name="context" select="'default'"/>
  <xsl:param name="name" select="'default'"/>
  <xsl:param name="origname" select="$name"/>
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>
  <xsl:param name="lang">
    <xsl:call-template name="l10n.language"/>
  </xsl:param>
  <xsl:param name="verbose" select="1"/>

  <xsl:choose>
    <xsl:when test="$empty.local.l10n.xml">
      <xsl:for-each select="$l10n.xml">  <!-- We need to switch context in order to make key() work -->
	<xsl:for-each select="document(key('l10n-lang', $lang)/@href)">

	  <xsl:variable name="localization.node"
			select="key('l10n-lang', $lang)[1]"/>

	  <xsl:if test="count($localization.node) = 0
			and $verbose != 0">
	    <xsl:message>
	      <xsl:text>No "</xsl:text>
	      <xsl:value-of select="$lang"/>
	      <xsl:text>" localization exists.</xsl:text>
	    </xsl:message>
	  </xsl:if>

	  <xsl:variable name="context.node"
			select="key('l10n-context', $context)[1]"/>

	  <xsl:if test="count($context.node) = 0
			and $verbose != 0">
	    <xsl:message>
	      <xsl:text>No context named "</xsl:text>
	      <xsl:value-of select="$context"/>
	      <xsl:text>" exists in the "</xsl:text>
	      <xsl:value-of select="$lang"/>
	      <xsl:text>" localization.</xsl:text>
	    </xsl:message>
	  </xsl:if>

	  <xsl:for-each select="$context.node">
	    <xsl:variable name="template.node"
			  select="(key('l10n-template-style', concat($context, '#', $name, '#', $xrefstyle))
				   |key('l10n-template', concat($context, '#', $name)))[1]"/>

	    <xsl:choose>
	      <xsl:when test="$template.node/@text">
		<xsl:value-of select="$template.node/@text"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:choose>
		  <xsl:when test="contains($name, '/')">
		    <xsl:call-template name="gentext.template">
		      <xsl:with-param name="context" select="$context"/>
		      <xsl:with-param name="name" select="substring-after($name, '/')"/>
		      <xsl:with-param name="origname" select="$origname"/>
		      <xsl:with-param name="purpose" select="$purpose"/>
		      <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
		      <xsl:with-param name="referrer" select="$referrer"/>
		      <xsl:with-param name="lang" select="$lang"/>
		      <xsl:with-param name="verbose" select="$verbose"/>
		    </xsl:call-template>
		  </xsl:when>
		  <xsl:when test="$verbose = 0">
		    <!-- silence -->
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:message>
		      <xsl:text>No template for "</xsl:text>
		      <xsl:value-of select="$origname"/>
		      <xsl:text>" (or any of its leaves) exists in the context named "</xsl:text>
		      <xsl:value-of select="$context"/>
		      <xsl:text>" in the "</xsl:text>
		      <xsl:value-of select="$lang"/>
		      <xsl:text>" localization.</xsl:text>
		    </xsl:message>
		  </xsl:otherwise>
		</xsl:choose>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each>
	</xsl:for-each>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
      <xsl:for-each select="$l10n.xml">  <!-- We need to switch context in order to make key() work -->
	<xsl:for-each select="document(key('l10n-lang', $lang)/@href)">

	  <xsl:variable name="local.localization.node"
			select="($local.l10n.xml//l:i18n/l:l10n[@language=$lang])[1]"/>

	  <xsl:variable name="localization.node"
			select="key('l10n-lang', $lang)[1]"/>

	  <xsl:if test="count($localization.node) = 0
			and count($local.localization.node) = 0
			and $verbose != 0">
	    <xsl:message>
	      <xsl:text>No "</xsl:text>
	      <xsl:value-of select="$lang"/>
	      <xsl:text>" localization exists.</xsl:text>
	    </xsl:message>
	  </xsl:if>

	  <xsl:variable name="local.context.node"
			select="$local.localization.node/l:context[@name=$context]"/>

	  <xsl:variable name="context.node"
			select="key('l10n-context', $context)[1]"/>

	  <xsl:if test="count($context.node) = 0
			and count($local.context.node) = 0
			and $verbose != 0">
	    <xsl:message>
	      <xsl:text>No context named "</xsl:text>
	      <xsl:value-of select="$context"/>
	      <xsl:text>" exists in the "</xsl:text>
	      <xsl:value-of select="$lang"/>
	      <xsl:text>" localization.</xsl:text>
	    </xsl:message>
	  </xsl:if>

	  <xsl:variable name="local.template.node"
			select="($local.context.node/l:template[@name=$name
								and @style
								and @style=$xrefstyle]
				|$local.context.node/l:template[@name=$name
								and not(@style)])[1]"/>

	  <xsl:choose>
	    <xsl:when test="$local.template.node/@text">
	      <xsl:value-of select="$local.template.node/@text"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:for-each select="$context.node">
		<xsl:variable name="template.node"
			      select="(key('l10n-template-style', concat($context, '#', $name, '#', $xrefstyle))
				       |key('l10n-template', concat($context, '#', $name)))[1]"/>

		<xsl:choose>
		  <xsl:when test="$template.node/@text">
		    <xsl:value-of select="$template.node/@text"/>
		  </xsl:when>
		  <xsl:otherwise>
		    <xsl:choose>
		      <xsl:when test="contains($name, '/')">
			<xsl:call-template name="gentext.template">
			  <xsl:with-param name="context" select="$context"/>
			  <xsl:with-param name="name" select="substring-after($name, '/')"/>
			  <xsl:with-param name="origname" select="$origname"/>
			  <xsl:with-param name="purpose" select="$purpose"/>
			  <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
			  <xsl:with-param name="referrer" select="$referrer"/>
			  <xsl:with-param name="lang" select="$lang"/>
			  <xsl:with-param name="verbose" select="$verbose"/>
			</xsl:call-template>
		      </xsl:when>
		      <xsl:when test="$verbose = 0">
			<!-- silence -->
		      </xsl:when>
		      <xsl:otherwise>
			<xsl:message>
			  <xsl:text>No template for "</xsl:text>
			  <xsl:value-of select="$origname"/>
			  <xsl:text>" (or any of its leaves) exists in the context named "</xsl:text>
			  <xsl:value-of select="$context"/>
			  <xsl:text>" in the "</xsl:text>
			  <xsl:value-of select="$lang"/>
			  <xsl:text>" localization.</xsl:text>
			</xsl:message>
		      </xsl:otherwise>
		    </xsl:choose>
		  </xsl:otherwise>
		</xsl:choose>
	      </xsl:for-each>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:for-each>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:if test="($draft.mode = 'yes' or ($draft.mode = 'maybe' and (ancestor-or-self::set | ancestor-or-self::book | ancestor-or-self::article)[1]/@status = 'draft'))">
    <xsl:text> [</xsl:text>
    <xsl:call-template name="gentext">
      <xsl:with-param name="key" select="'Draft'"/>
    </xsl:call-template>
    <xsl:text>]</xsl:text>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
