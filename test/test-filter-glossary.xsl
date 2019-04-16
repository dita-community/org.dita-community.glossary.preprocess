<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:df="http://dita2indesign.org/dita/functions"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:local="urn:ns:local-functions"
  xmlns:dita-community="http://org.dita-community"
  xmlns:gloss="http://org.dita-community/glossary"
  exclude-result-prefixes="relpath df dita-ot map local dita-community"
  expand-text="yes"
  version="3.0">
  
  <xsl:import href="plugin:org.dita-community.common.xslt:xsl/relpath_util.xsl"/>
  <xsl:import href="plugin:org.dita-community.common.xslt:xsl/dita-support-lib.xsl"/>     
  <xsl:import href="plugin:org.dita-community.i18n:xsl/i18n-utils.xsl"/>
  <xsl:import href="../xsl/construct-key-spaces.xsl"/>
  <xsl:import href="../xsl/glossary-utils.xsl"/>
  <xsl:import href="../xsl/glossary-filter.xsl"/>
  
  <xsl:output indent="true"/>
  
  <xsl:preserve-space elements="keyspace-report"/>
  
  <xsl:template match="/">

    <xsl:variable name="df:keySpaces" as="map(*)">
      <xsl:call-template name="df:construct-key-spaces">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="filtered-map">
      <xsl:apply-templates select="." mode="dita-community:glossary-filter">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
        <xsl:with-param name="df:keySpaces" as="map(*)" tunnel="yes" select="$df:keySpaces"/>
      </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:variable name="testResult">
      <test-result>
        <filtered-map>
          <xsl:sequence select="$filtered-map"/>
        </filtered-map>
      </test-result>
    </xsl:variable>
    
    <xsl:sequence select="$testResult"/>
  </xsl:template>
  
</xsl:stylesheet>