<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:df="http://dita2indesign.org/dita/functions"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:local="urn:ns:local-functions"
  exclude-result-prefixes="relpath df dita-ot map local"
  expand-text="yes"
  version="3.0">
  
  <xsl:import href="plugin:org.dita-community.common.xslt:xsl/relpath_util.xsl"/>
  <xsl:import href="plugin:org.dita-community.common.xslt:xsl/dita-support-lib.xsl"/>     
  <xsl:import href="../xsl/construct-key-spaces.xsl"/>
  
  <xsl:output indent="true"/>
  
  <xsl:preserve-space elements="keyspace-report"/>
  
  <xsl:template match="/">

    <xsl:variable name="testResult">
    <test-result>
      
      <xsl:variable name="df:keySpaces" as="map(*)">
        <xsl:call-template name="df:construct-key-spaces">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
        </xsl:call-template>
      </xsl:variable>               
      <resolution-tests>
        <keyscope-ids>{map:keys($df:keySpaces)  => string-join(', ')}</keyscope-ids>
        <!-- Scope-qualified keys: -->
        <xsl:variable name="mapContextTopic" as="element()"
          select="//*[@xtrc eq 'topicref:2;40:61']"
        />
        <xsl:sequence select="local:resolution-test($df:keySpaces, 'gloss-res.aikido', $mapContextTopic)"/>
        <xsl:sequence select="local:resolution-test($df:keySpaces, 'glossary.aikido', $mapContextTopic)"/>
        
        <!-- Within the glos-res keyscope: -->
        <xsl:variable name="mapContextGlossaryEntryResource" as="element()"
          select="//*[@xtrc eq 'keydef:1;11:53']"
        />
        <xsl:sequence select="local:resolution-test($df:keySpaces, 'aikido', $mapContextGlossaryEntryResource)"/>        

        <!-- Within the glossary keyscope: -->
        <xsl:variable name="mapContextGlossaryEntryNormal" as="element()"
          select="//*[@xtrc eq 'topicref:4;8:63']"
        />
        <xsl:sequence select="local:resolution-test($df:keySpaces, 'aikido', $mapContextGlossaryEntryNormal)"/>        
      </resolution-tests>
      <keyspace-report>
        <xsl:sequence select="df:report-key-spaces($df:keySpaces)"/>      
      </keyspace-report>
    </test-result>
    </xsl:variable>    
    <xsl:sequence select="$testResult"/>
    <xsl:if test="contains($testResult, 'FAILED')">
      <xsl:message>+[ERROR] Tests failed</xsl:message>
    </xsl:if>
  </xsl:template>
  
  <xsl:function name="local:resolution-test">
    <xsl:param name="df:keySpaces" as="map(*)"/>
    <xsl:param name="keyName" as="xs:string"/>
    <xsl:param name="mapContext" as="element()"/>
    
    <resolution-test>
      <keyname>{$keyName}</keyname>
      <xsl:variable name="resolvedKeyDefiner" as="element()?"
        select="df:resolveScopedKey($df:keySpaces, $mapContext, $keyName, false())"
      />
      <result>
        {if (exists($resolvedKeyDefiner))
        then 'PASSED' || ': ' || name($resolvedKeyDefiner) || ' keys="' || $resolvedKeyDefiner/@keys || '", href="' || $resolvedKeyDefiner/@href || '"' 
        else 'FAILED'
        }&#x0a;</result>
    </resolution-test>
    
  </xsl:function>
  
</xsl:stylesheet>