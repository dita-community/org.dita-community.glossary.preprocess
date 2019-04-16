<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dita-community="http://org.dita-community"
  xmlns:gloss="http://org.dita-community/glossary"
  xmlns:dci18n="http://org.dita-community/i18n"
  xmlns:dci18nfunc="http://org.dita-community/i18n/saxon-extensions"
  xmlns:df="http://dita2indesign.org/dita/functions"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"    
  exclude-result-prefixes="xs dita-community gloss dci18n dci18nfunc df map"
  expand-text="yes"
  version="3.0">
  <!-- ========================================================
       Glossary preprocessing extension: Glossary Generation
       
       This module generates a glossary navigation structure
       from the resource-only topicrefs to glossary entries
       when there is also an empty <glossarylist> element in 
       the publication.
       
       Implements mode "dita-community:glossary-generation" 
       
       Natively recognizes the following markup as being the
       point at which to generate the glossary:
       
       - <glossarylist> (BookMap)
       - <topicref outputclass="glossarylist"> (any map type)
       
       Copyright (c) 2019 DITA Community Project
       
       ======================================================== -->  
  
  <!-- Name to use for topicrefs to glossary entries when the original
       topicref was <keyref>
    -->
  <xsl:param name="gloss:default-glossentry-topicref-tagname" as="xs:string"
    select="'topicref'"
  />
  
  <xsl:mode name="gloss:generate-glossary"
    on-no-match="shallow-copy"        
  />
  
  <xsl:template mode="dita-community:generate-glossary" match="/" as="document-node()+">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:variable name="glossaryLists" as="element()*"
      select="//*[contains(@class, ' bookmap/glossarylist ') or @outputclass eq 'glossarylist']"
    />
    
    <xsl:choose>
      <xsl:when test="exists($glossaryLists) and 
        (some $element in $glossaryLists satisfies empty($element/*[contains(@class, ' map/topicref ')]))">
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] dita-community:generate-glossary: Have at least one empty glossarylist element, generating glossary.</xsl:message>
        </xsl:if>
        <xsl:if test="count($glossaryLists) gt 1">
          <xsl:message>+ [WARN] Glossary generation: Have {count($glossaryLists)} empty glossary list elements, using the first one in the document.</xsl:message>
        </xsl:if>
        <xsl:message>+ [INFO] Generate glossary: Found empty glossary list element, generating glossary...</xsl:message>
        <xsl:call-template name="gloss:_doGlossaryGeneration">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="glossaryList" as="element()" tunnel="yes"
            select="($glossaryLists[empty(*[contains(@class, ' map/topicref ')])])[1]"
          />
        </xsl:call-template>
        <xsl:message>+ [INFO] Generate glossary: Glossary generation done.</xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>+ [WARN] Glossary generation was requested but no empty glossary list elements were found in the map. Glossary not generated.</xsl:message>
        <xsl:sequence select="."/>
      </xsl:otherwise>
    </xsl:choose>
    
    
  </xsl:template>
  
  <!--
    Do the glossary generation. Context is the root map document node.
    -->  
  <xsl:template name="gloss:_doGlossaryGeneration" as="document-node()" >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:message>+ [INFO] Generate glossary: Gathering resource-only topicrefs to glossary entries in order to generate glossary...</xsl:message>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:variable name="glossaryEntryTopicrefs" as="element()*"
      select="//*[contains(@class, ' map/topicref ')][@processing-role eq 'resource-only'][gloss:isTopicrefToGlossaryEntry(.)]"
    />
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:generate-glossary: Have {count($glossaryEntryTopicrefs)
        } resource-only topcirefs to glossary entries</xsl:message>
    </xsl:if>    
    
    <xsl:choose>
      <xsl:when test="empty($glossaryEntryTopicrefs)">
        <xsl:message>+ [INFO] Generate glossary: Not resource-only references to glossary entries found, cannot generate a glossary.</xsl:message>
        <xsl:sequence select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] dita-community:generate-glossary: Generating glossary...</xsl:message>
        </xsl:if>    
        <xsl:document>
          <xsl:apply-templates mode="gloss:generate-glossary">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
            <xsl:with-param name="glossaryEntryTopicrefs" as="element()*" tunnel="yes" select="$glossaryEntryTopicrefs"/>
          </xsl:apply-templates>
        </xsl:document>        
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] dita-community:generate-glossary: Glossary generation done.</xsl:message>
        </xsl:if>    
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template mode="gloss:generate-glossary" match="/*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:copy copy-namespaces="no">
      <xsl:attribute name="xml:base" select="base-uri(.)"/>
      <xsl:apply-templates mode="#current" select="@*, node()">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="gloss:generate-glossary" 
    match="*[contains(@class, ' bookmap/glossarylist ')
             or (@outputclass eq 'glossarylist')]"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="glossaryList" as="element()" tunnel="yes"/>
    <xsl:param name="glossaryEntryTopicrefs" as="element()*" tunnel="yes"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:generate-glossary: Have a glossary list element</xsl:message>
    </xsl:if>
    
    <xsl:choose>
      <xsl:when test=". is $glossaryList">
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] gloss:generate-glossary: Glossary list element is the one chosen to generate, doing generation.</xsl:message>
        </xsl:if>
        <xsl:copy copy-namespaces="no">
          <xsl:apply-templates mode="#current" select="@*, *[contains(@class, ' map/topicmeta ')]">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:apply-templates>
          <xsl:apply-templates mode="gloss:resource-only2normal-role" select="$glossaryEntryTopicrefs">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] gloss:generate-glossary: Glossary list element is not the one chosen to generate, treating it normally.</xsl:message>
        </xsl:if>
        <xsl:next-match>
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:next-match>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <!--
    Suppress resource-only topicrefs to glossary entries at their original location.
    -->
  <xsl:template mode="gloss:generate-glossary" 
    match="*[contains(@class, ' map/topicref ')]
            [@processing-role eq 'resource-only']
            [gloss:isTopicrefToGlossaryEntry(.)]
          ">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() and $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:generate-glossary: Resource-only topicref to glossary entry ({@href}), removing from its original location.</xsl:message>
    </xsl:if>
    <!-- Suppress, will be remade into a normal-role topicref -->
    
    <xsl:apply-templates select="*[contains(@class, ' map/topicref ')]" mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    
  </xsl:template>
  
  <!-- ===========================================================
       Resource-only to normal role mode
       
       =========================================================== -->
  
  <xsl:template mode="gloss:resource-only2normal-role" match="*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() and $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:resource-only2normal-role: Handling resource-only topicref @keys="{@keys}, @href="{@href}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="newTagName" as="xs:string"
      select="
      if (name(.) eq 'keydef')
      then $gloss:default-glossentry-topicref-tagname
      else name(.)
      "
    />
    
    <xsl:element name="{$newTagName}">
      <xsl:if test="$gloss:glossentry-toc-no">
        <xsl:attribute name="toc" select="'no'"/>
      </xsl:if>
      <xsl:attribute name="processing-role" select="'normal'"/>
      <xsl:apply-templates select="@* except (@processing-role)" mode="gloss:generate-glossary">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
      <xsl:apply-templates mode="gloss:generate-glossary">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:element> 
    
  </xsl:template>
  
</xsl:stylesheet>