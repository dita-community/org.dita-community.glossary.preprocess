<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dita-community="http://org.dita-community"
  xmlns:gloss="http://org.dita-community/glossary"
  xmlns:dci18n="http://org.dita-community/i18n"
  xmlns:dci18nfunc="http://org.dita-community/i18n/saxon-extensions"
  xmlns:relpath="http://dita2indesign/functions/relpath"  
  xmlns:df="http://dita2indesign.org/dita/functions"
  
  exclude-result-prefixes="xs dita-community gloss dci18n dci18nfunc df relpath"
  version="2.0">
  <!-- ========================================================
       Link Reporter
       
       Given a set of linking elements from topics referenced
       in the context of a resolved map, generates a report 
       of the links.
       
       Intended to be used during the keyref preprocessing phase
       against a resolved map.
       
       Because this happens during keyref processing, it does
       not reflect the result of chunking, conref, or filtering.
       
       The result is a DITA topic.
       
       Copyright (c) 2019 DITA Community Project
       
       ======================================================== -->
  
  <!--
    Generate a report of a set of links.
    
    The context node is a resolved map.
    @param links List, possibly empty, of linking elements. Links
    are any elements that exhibit @href or @keyref attributes.
    @param doDebug Turns debugging on or off.
    -->
  <xsl:template name="dita-community:make-link-report" as="document-node()">
    <xsl:param name="links" as="element()*"/>
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="true() or $doDebug"/>
        
    <xsl:variable name="mapName" as="xs:string" select="relpath:getName(base-uri(.))"/>
    
    <xsl:document>
      <topic id="link-report">
        <title>Link Report for <xsl:value-of select="$mapName"/></title>
        <body>
          <xsl:choose>
            <xsl:when test="exists($links)">
              <xsl:call-template name="dita-community:make-link-report-body">
                <xsl:with-param name="links" as="element()+" select="$links"/>
                <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <p>No links found.</p>
            </xsl:otherwise>
          </xsl:choose>          
        </body>
      </topic>
    </xsl:document>    
  </xsl:template>
  
  <xsl:template name="dita-community:make-link-report-body">
    <xsl:param name="links" as="element()*"/>
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>

    <xsl:variable name="mapName" as="xs:string" select="relpath:getName(base-uri(.))"/>
    <xsl:variable name="mapDir" as="xs:string" select="relpath:getParent(base-uri(.))"/>
    
    <xsl:variable name="linkTypes" as="xs:string*"
      select="distinct-values(for $link in $links return name($link))"
    />
    <xsl:variable name="targetUris" as="xs:string*"
      >
      <xsl:variable name="normalized-uris" as="xs:string*">
        <xsl:for-each select="$links">          
          <xsl:variable name="link" as="element()" select="."/>
          <xsl:variable name="hrefString" as="xs:string" select="@href"/>
          <xsl:sequence select="string(resolve-uri($hrefString, string(base-uri($link))))"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="distinct-uris" as="xs:string*" select="distinct-values($normalized-uris)"
      />
      <xsl:sequence select="
        for $uri in $distinct-uris
        return relpath:getRelativePath($mapDir, $uri)
        "/>
    </xsl:variable>
    <xsl:variable name="targetKeys" as="xs:string*"
      select="sort(distinct-values(for $link in $links return tokenize(string($link/@keyref), '/')[1]))"
    />
    
    <xsl:variable name="topicURIs" as="xs:string*"
      select="distinct-values(for $e in $links return document-uri(root($e)))"
    />
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:make-link-report-body:  topicURIs: <xsl:value-of select="string-join($topicURIs, ', ')"/></xsl:message>
    </xsl:if>
    
    <xsl:variable name="topics" as="document-node()*"
        select="
        $links/root()
        "
    />

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:make-link-report-body:  Have: <xsl:value-of select="count($topics)"/> unique topics</xsl:message>
    </xsl:if>
    
    <section spectitle="Summary">
      <simpletable>
        <strow>
          <stentry>Total Links:</stentry>
          <stentry><xsl:value-of select="count($links)"/></stentry>
        </strow>
        <strow>
          <stentry>Link Types</stentry>
          <stentry>
            <dl>
              <xsl:for-each select="$linkTypes">
                <xsl:variable name="linktype" as="xs:string" select="."/>
                <dlentry>
                  <dt><xsl:value-of select="."/></dt>
                  <dd><xsl:value-of select="count($links[name(.) eq $linktype])"/></dd>
                </dlentry>
              </xsl:for-each>                    
            </dl>
          </stentry>
        </strow>
        <strow>
          <stentry>Target URIs</stentry>
          <stentry>
            <ul>
              <xsl:for-each select="$targetUris">
                <li><xsl:value-of select="."/></li>
              </xsl:for-each>                    
            </ul>
          </stentry>
        </strow>
        <strow>
          <stentry>Target Keys</stentry>
          <stentry>
            <ul>
              <xsl:for-each select="$targetKeys">
                <li><xsl:value-of select="."/></li>
              </xsl:for-each>                    
            </ul>
          </stentry>
        </strow>
      </simpletable>
    </section>
    <section spectitle="Links By Referencing Topic">
      <table>
        <tgroup cols="5">   
          <colspec/>
          <colspec colwidth="6em"/>
          <colspec colwidth="20em"/>
          <colspec colwidth="8em"/>
          <colspec/>
          <thead>
            <row>
              <entry>Topic</entry>
              <entry>Link Type</entry>
              <entry>Link Text</entry>
              <entry>Keyref</entry>
              <entry>HREF</entry>
            </row>
          </thead>
          <tbody>
            <xsl:for-each select="$topics">
              <xsl:variable name="topic" as="element()" select="./*"/>
              <xsl:variable name="linksInTopic" as="element()+"
                select="$links[root(.) is root($topic)]"
              />
              <row>
                <entry morerows="{count($linksInTopic) - 1}">
                  <xsl:value-of select="df:getNavtitleForTopic($topic)"/>
                  <p><xsl:value-of select="relpath:getRelativePath($mapDir, base-uri($topic))"/></p>
                </entry>
                <entry>
                  <xsl:value-of select="name($linksInTopic[1])"/>
                </entry>
                <entry>
                  <xsl:value-of select="$linksInTopic[1]"/>
                </entry>
                <entry>
                  <xsl:value-of select="$linksInTopic[1]/@keyref"/>
                </entry>
                <entry>
                  <xsl:value-of select="$linksInTopic[1]/@href"/>
                </entry>
              </row>
              <xsl:for-each select="$linksInTopic[position() gt 1]">
                <row>
                  <entry><xsl:value-of select="name(.)"/></entry>
                  <entry><xsl:value-of select="."/></entry>
                  <entry><xsl:value-of select="@keyref"/></entry>
                  <entry><xsl:value-of select="./@href"/></entry>
                </row>
              </xsl:for-each>
            </xsl:for-each>
          </tbody>
        </tgroup>
      </table>
    </section>    
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:make-link-report-body: Done</xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  <!--
    Context node is the input map.
    -->
  <xsl:template name="dita-community:save-link-report">
    <xsl:param name="linkReport" as="document-node()"/>
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:variable name="localDebug" as="xs:boolean" select="true() or $debug"/>
    
    <xsl:variable name="baseUri" as="xs:string" select="string(base-uri(.))"/>
    <xsl:variable name="parentDir" as="xs:string" select="relpath:getParent(base-uri(.))"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:save-link-report: baseUri="<xsl:value-of select="$baseUri"/>"</xsl:message>      
    </xsl:if>
        
    <xsl:variable name="mapName" as="xs:string" select="relpath:getNamePart($baseUri)"/>
    
    <xsl:variable name="resultURI" as="xs:string" 
      select="relpath:newFile($parentDir, concat($mapName, '_link_report.dita'))"
    />
        
    <xsl:message>+ [INFO] dita-community:save-link-report: Saving link report to "<xsl:value-of select="$resultURI"/>"</xsl:message>
    <xsl:result-document href="{$resultURI}"
      doctype-public="-//OASIS//DTD DITA Topic//EN"
      doctype-system="topic.dtd"
      >
      <xsl:sequence select="$linkReport"/>
    </xsl:result-document>
  </xsl:template>
</xsl:stylesheet>