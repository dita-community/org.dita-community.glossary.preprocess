<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dita-community="http://org.dita-community"
  xmlns:gloss="http://org.dita-community/glossary"
  xmlns:dci18n="http://org.dita-community/i18n"
  xmlns:dci18nfunc="http://org.dita-community/i18n/saxon-extensions"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  
  exclude-result-prefixes="xs dita-community gloss dci18n dci18nfunc relpath"
  expand-text="yes"
  version="3.0">
  <!-- ========================================================
       Glossary preprocessing extension: Glossary Sorter
       
       This module manages sorting glossary entries using a
       local-aware sort.
       
       Implements mode "dita-community:glossary-sort" 
       
       Natively recognizes the following markup as being the
       root of a glossary to be sorted:
       
       - <glossarylist> (BookMap)
       - <topicref outputclass="glossarylist"> (any map type)
       
       Copyright (c) 2019 DITA Community Project
       
       ======================================================== -->
  
  <xsl:mode name="dita-community:glossary-sort"
    on-no-match="shallow-copy"
  />  
  
  <xsl:variable name="gloss:customCollatorUri" as="xs:string"
    select="'http://org.dita-community.i18n.zhCNawareCollator?lang=zh-CN'"
  />
  
  <xsl:variable name="gloss:defaultCollatorUri" as="xs:string"
    select="'http://www.w3.org/2005/xpath-functions/collation/codepoint'"
  />
  
  <xsl:variable name="gloss:collatorUri" as="xs:string"
    select="$gloss:customCollatorUri"
  />

  <xsl:template mode="dita-community:glossary-sort" 
    match="*[contains(@class, ' bookmap/glossarylist ')] | 
    *[contains(@class, ' map/topicref ')][tokenize(@outputclass, ' ') = ('glossarylist')]"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:message>+ [INFO] Glossary sort: Sorting the glossary...</xsl:message>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:glossary-sort: Have a glossary list topicref (<xsl:value-of select="concat(name(..), '/', name(.))"/>) starting...</xsl:message>
    </xsl:if>
    
    <!-- Groups and sorts the the direct-child topicrefs of the glossary list. This code assumes that the 
         topicrefs are not already grouped.
         
         There are a couple of ways this could work, including looking at the entire descendant map at this
         point and constructing a flat list of references but that could pose its own problems.
         
         To keep it simple, assuming that the children are the topicrefs to be sorted.
         
      -->
    
    <!-- 1: Get the topicrefs to be sorted 
    
            Topicrefs to topics
    -->
    
    <xsl:variable name="glossaryList" as="element()" select="."/>
    
    <xsl:variable name="topicrefsToSort" as="element()*" 
      select="*[contains(@class, ' map/topicref ')][@href ne ''][empty(@format) or (@format eq 'dita')]"
    />

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:glossary-sort: Found <xsl:value-of select="count($topicrefsToSort)"/> topicrefs to be sorted.</xsl:message>
    </xsl:if>
    
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, *[contains(@class, ' map/topicmeta ')]">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
      </xsl:apply-templates>
    
      <!-- 2: Group and sort the topics -->
      <!-- collation="{$gloss:collatorUri}" -->
      <xsl:for-each-group select="$topicrefsToSort" group-by="gloss:getGroupingKey(., $localDebug)">
        <xsl:sort select="current-grouping-key()"/>
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] dita-community:glossary-sort: [<xsl:value-of select="position()"/>] Grouping key="<xsl:value-of select="current-grouping-key()"/>"</xsl:message>
        </xsl:if>
        
        <xsl:variable name="grouping-topic-uri" as="xs:string" 
          select="gloss:getGroupingTopicURI(
          $glossaryList,
          current-grouping-key(),
          $doDebug)"
        />
        <xsl:call-template name="gloss:makeGroupingTopic">
          <xsl:with-param name="glossaryList" as="element()" select="$glossaryList"/>
          <xsl:with-param name="groupingTopicUri" as="xs:string" select="$grouping-topic-uri"/>
          <xsl:with-param name="groupingLabel" select="gloss:getGroupLabel(current-grouping-key(), $localDebug)"/>
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
        </xsl:call-template>
        <topicref class="+ map/topicref " href="{$grouping-topic-uri}">
          <xsl:if test="$gloss:glossgroup-toc-no">
            <xsl:attribute name="toc" select="'no'"/>
          </xsl:if>
          <xsl:if test="$localDebug">
            <xsl:message>+ [DEBUG] dita-community:glossary-sort: [<xsl:value-of select="position()"/>] Have <xsl:value-of select="count(current-group())"/> topics in this group.</xsl:message>
          </xsl:if>
          <xsl:apply-templates mode="#current" select="current-group()">
            <xsl:sort collation="{$gloss:collatorUri}" select="gloss:getPrimarySortKeyForTopicref(., 'first', $localDebug)"/>
            <!--<xsl:sort collation="{$gloss:collatorUri}" select="dci18n:getBaseSortKeyForTopicref(.)"/>-->
          </xsl:apply-templates>
        </topicref>
      </xsl:for-each-group>
    </xsl:copy>
    
    <xsl:message>+ [INFO] Glossary sort: Sorting done.</xsl:message>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:glossary-sort: <xsl:value-of select="concat(name(..), '/', name(.))"/> Done.</xsl:message>
    </xsl:if>
  </xsl:template>
  
  <!--
    Get the relative URI to use for the generated grouping topic
    for the specified grouping key.
    
    @param glossaryList Element in the map that contains the glossary being sorted
    @param groupingKey The grouping key for the group, e.g. "a"
    @param doDebug Turn debugging on or off.
    @return the URI, relative to the base URI of the glossaryList element,
    of the grouping topic.
    -->
  <xsl:function name="gloss:getGroupingTopicURI" as="xs:string">
    <xsl:param name="glossaryList" as="element()"/>
    <xsl:param name="groupingKey" as="xs:string"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="result" as="xs:string"
      select="'_glossPreprocess/_gloss_glossGroup_' || $groupingKey || '.dita'"
    />
    
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <!--
    Construct a glossgroup topic with the specified grouping label
    and return its URI relative to the provided glossaryList element
    @param glossaryList Element in the map that contains the glossary being sorted
    @param groupingKey The grouping key for the group, e.g. "a"
    @param groupingLabel The label to use as the title of the topic, e.g. "A"
    @param doDebug Turn debugging on or off.
    @return the URI, relative to the base URI of the glossaryList element,
    of the generated grouping topic.
    -->
  <xsl:template name="gloss:makeGroupingTopic">
    <xsl:param name="glossaryList" as="element()"/>
    <xsl:param name="groupingLabel"/>
    <xsl:param name="groupingTopicUri" as="xs:string"/>
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="resultURI" as="xs:string"
      select="relpath:newFile(relpath:getParent(string(base-uri($glossaryList))), $groupingTopicUri)"
    />
    
    <xsl:message>+ [INFO] gloss:makeGroupingTopic: Generating grouping topic "{$groupingTopicUri}"</xsl:message>
    
    <xsl:result-document href="{$resultURI}">
      <glossgroup class="+ topic/topic glossgroup/glossgroup " id="glossgroup">
        <title class="- topic/title "><xsl:sequence select="$groupingLabel"/></title>  
      </glossgroup>      
    </xsl:result-document>
    
  </xsl:template>
    
</xsl:stylesheet>