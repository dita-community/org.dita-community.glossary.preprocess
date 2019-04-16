<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:df="http://dita2indesign.org/dita/functions"  
  xmlns:dita-community="http://org.dita-community"
  xmlns:gloss="http://org.dita-community/glossary"
  xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"  
  exclude-result-prefixes="xs dita-community gloss dita-ot map df"
  version="2.0">
  <!-- ========================================================
       Glossary preprocessing extension.
       
       Extends base 
       
       Copyright (c) 2019 DITA Community Project
       
       ======================================================== -->
  
  <!--
    Turn glossary generation on.
    
    When true() and a recognized glossary list marker element is found (e.g.,
    <glossarylist/>), then the glossary will be generated. 
    
    If glossary filtering is turned on then the glossary will reflect those
    glossary entries used directly or indirectly from normal-role, non-glossary-entry
    topics.
    
    If glossary filtering is turned off then all glossary entry topics referenced
    by the map will be used to construct the generated glossary.
    -->
  <xsl:param name="dita-community:generate-glossary" as="xs:string" select="'false'"/>
  <xsl:variable name="gloss:generate-glossary" as="xs:boolean"
    select="matches($dita-community:generate-glossary, 'yes|true|on|1', 'i')"
  />
  
  <!--
    Turn glossary sorting on.
    
    Recognized glossary lists will be sorted automatically when this is 
    true(), otherwise they will not be sorted.
    -->
  <xsl:param name="dita-community:sort-glossary" as="xs:string" select="'false'"/>
  <xsl:variable name="gloss:sort-glossary" as="xs:boolean"
    select="matches($dita-community:sort-glossary, 'yes|true|on|1', 'i') 
            or $gloss:generate-glossary"
  />

  <!--
    Turn glossary filtering on
    
    When filtering is on, the normal-role glossary entries found or generated
    will be limited to those glossary entries used directly or indirectly by
    normal-role non-glossary-entry topics.
    -->
  <xsl:param name="dita-community:filter-glossary" as="xs:string" select="'false'"/>
  <xsl:variable name="gloss:filter-glossary" as="xs:boolean"
    select="matches($dita-community:filter-glossary, 'yes|true|on|1', 'i')"
  />
  
  <!-- FIXME: Make this a runtime parameter and document it -->
  <xsl:variable name="gloss:glossgroup-toc-no" as="xs:boolean" select="true()"/>
  
  <!-- FIXME: Make this a runtime parameter and document it -->
  <xsl:variable name="gloss:glossentry-toc-no" as="xs:boolean" select="true()"/>
  
  <xsl:import href="plugin:org.dita-community.common.xslt:xsl/relpath_util.xsl"/>
  <xsl:import href="plugin:org.dita-community.common.xslt:xsl/dita-support-lib.xsl"/>   
  <xsl:import href="plugin:org.dita-community.i18n:xsl/i18n-utils.xsl"/>
  
  <xsl:import href="glossary-utils.xsl"/>
  <xsl:import href="glossary-sorter.xsl"/>
  <xsl:import href="glossary-filter.xsl"/>
  <xsl:import href="glossary-generation.xsl"/>
  <xsl:import href="link-report.xsl"/>
  <xsl:import href="construct-key-spaces.xsl"/>
  
  <xsl:template match="/">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:message>+ [INFO] DITA Community glossary preprocessing:</xsl:message>
    <xsl:message>+ [INFO]   filter-glossary: <xsl:value-of select="$gloss:filter-glossary"/> (<xsl:value-of select="$dita-community:filter-glossary"/>)</xsl:message>
    <xsl:message>+ [INFO]   generate-glossary: <xsl:value-of select="$gloss:generate-glossary"/> (<xsl:value-of select="$dita-community:generate-glossary"/>)</xsl:message>
    <xsl:message>+ [INFO]   sort-glossary: <xsl:value-of select="$gloss:sort-glossary"/> (<xsl:value-of select="$dita-community:sort-glossary"/>)</xsl:message>
    
    <xsl:variable name="effectiveInitialGlossaryMap" as="document-node()">
      <xsl:choose>
        <xsl:when test="$gloss:generate-glossary">
          <xsl:if test="$localDebug or $debug">
            <xsl:message>+ [DEBUG]   Generate glossary is on: applying templates in mode dita-community:generate-glossary...</xsl:message>
          </xsl:if>
          <xsl:apply-templates select="." mode="dita-community:generate-glossary">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="$localDebug or $debug">
            <xsl:message>+ [DEBUG]   Generate glossary is off: Using initial input map.</xsl:message>
          </xsl:if>
          <xsl:sequence select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- Generate the filtered map and, optionally, a link report -->
    <xsl:variable name="filteredMapDocs" as="document-node()+">
      <xsl:choose>
        <xsl:when test="$gloss:filter-glossary">
          <xsl:if test="$localDebug">
            <xsl:message>+ [DEBUG] glossary preprocess: gloss:filter-glossary is true, constructing key spaces...</xsl:message>
          </xsl:if>
          <xsl:variable name="df:keySpaces" as="map(*)">
            <xsl:call-template name="df:construct-key-spaces">
              <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
              <xsl:with-param name="rootMap" as="document-node()" select="$effectiveInitialGlossaryMap"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="$localDebug">
            <xsl:message>+ [DEBUG] glossary preprocess: Applying templates in mode dita-community:glossary-filter....</xsl:message>
          </xsl:if>
          <xsl:apply-templates select="$effectiveInitialGlossaryMap" mode="dita-community:glossary-filter">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
            <xsl:with-param name="df:keySpaces" as="map(*)" tunnel="yes" select="$df:keySpaces"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="$localDebug">
            <xsl:message>+ [DEBUG] glossary preprocess: gloss:filter-glossary is false, using effective initial map.</xsl:message>
          </xsl:if>
          <xsl:sequence select="$effectiveInitialGlossaryMap"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="filteredMap" as="document-node()" select="$filteredMapDocs[1]"/>
    <xsl:variable name="linkReport" as="document-node()?" select="$filteredMapDocs[2]"/>
    
    <xsl:if test="exists($linkReport)">
      <xsl:if test="$localDebug">
        <xsl:message>+ [DEBUG] glossary preprocess: Have a link report, calling dita-community:save-link-report...</xsl:message>
      </xsl:if>
      <xsl:call-template name="dita-community:save-link-report">
        <xsl:with-param name="linkReport" as="document-node()" select="$linkReport"/>
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
      </xsl:call-template>
    </xsl:if>
        
    <xsl:choose>
      <xsl:when test="$gloss:sort-glossary">
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] #default: glossary-sorter: Applying templates in mode dita-community:glossary-sort...</xsl:message>
        </xsl:if>
        <xsl:apply-templates select="$filteredMap" mode="dita-community:glossary-sort">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
        </xsl:apply-templates>
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] #default: glossary-sorter: After mode dita-community:glossary-sort.</xsl:message>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] #default: glossary-sorter: gloss:sort-glossary is false, applying templates in #default mode to the filtered map...</xsl:message>
        </xsl:if>
        <!-- NOTE: This is a replacement for what would otherwise be an xsl:next-match -->
        <xsl:apply-templates select="$filteredMap/node()">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

</xsl:stylesheet>