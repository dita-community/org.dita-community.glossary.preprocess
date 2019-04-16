<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:df="http://dita2indesign.org/dita/functions"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"
  xmlns:gloss="http://org.dita-community/glossary"
  xmlns:dci18n="http://org.dita-community/i18n"
  xmlns:dci18nfunc="http://org.dita-community/i18n/saxon-extensions"  
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  exclude-result-prefixes="xs df relpath dita-ot gloss map"
  expand-text="yes"
  version="3.0">
  <!-- ===========================================================
       Glossary Processing Utilities
       
       Modes and functions common to all glossary processing.
       =========================================================== -->
  
  <!-- For a topicref that has an @href value and that has a format of "dita",
       attempt to resolve it to a topic and return the topic element.
       
       If excludeClass is specified, include all topics except those excluded.
       If includeClass is specified (and excludeClass is not), include only
       those topics with the specified class.
       
       For each topicref that can be resolved, constructs a map with the
       topicref and the topic.
       
       map{
         'topicref' : element(),
         'topic' : element()?
       }
    -->
  <xsl:template mode="gloss:get-topics-for-topicrefs" 
    match="*[df:isTopicRefToTopic(.)]" as="map(*)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>    
    <xsl:param name="processDescendantTopicrefs" as="xs:boolean" tunnel="yes" select="true()"/>
    <xsl:param name="excludeClass" as="xs:string?" tunnel="yes" select="()"/>
    <xsl:param name="includeClass" as="xs:string?" tunnel="yes" select="()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() and $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:get-topics-for-topicrefs: Handling topicref with href "{@href}"</xsl:message>
      <xsl:message>+ [DEBUG] gloss:get-topics-for-topicrefs:   processDescendantTopicrefs="{$processDescendantTopicrefs}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="topicref" as="element()" select="."/>
    
    <!-- FIXME: Probably need to use the keyspaces to resolve the topicrefs -->
    <xsl:variable name="topic" as="element()?"
      select="df:resolveTopicRef(., false())"
    />
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:get-topics-for-topicrefs:   Got a topic: {exists($topic)} ({$topic/@class})</xsl:message>
    </xsl:if>
    
    <xsl:choose>
      <xsl:when test="exists($excludeClass) and contains($topic/@class, $excludeClass)">
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] gloss:get-topics-for-topicrefs:   Excluding the topic with class "{$excludeClass}"</xsl:message>
        </xsl:if>
        <!-- Excluding this topic -->
      </xsl:when>
      <xsl:when test="exists($includeClass) and contains($topic/@class, $includeClass)">
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] gloss:get-topics-for-topicrefs:   Including the topic with class "{$includeClass}"</xsl:message>
        </xsl:if>
        <!-- Including this topic -->
        <xsl:sequence select="map{'topic' : $topic, 'mapContext' : $topicref}"/>
      </xsl:when>
      <xsl:when test="empty($includeClass)">
        <!-- If no includeClass and we get here, then topic was neither explicitly excluded or included -->
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] gloss:get-topics-for-topicrefs:   Returning the topic</xsl:message>
        </xsl:if>
        <!-- Not excluded -->
        <xsl:sequence select="map{'mapContext' : $topicref, 'topic' : $topic}"/>    
      </xsl:when>
      <xsl:otherwise>
        <!-- Must not be explicitly included -->
      </xsl:otherwise>
    </xsl:choose>    
    
    <xsl:if test="$processDescendantTopicrefs">
      <xsl:next-match>
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:next-match>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template mode="gloss:get-topics-for-topicrefs" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:apply-templates mode="#current" select="*[contains(@class, ' map/topicref ')]">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  
  <!-- ============================================
       Get links from topics
       
       Result is a sequence of maps, one for each
       link containing the link element and the
       map context for the link.
       
       map{
         'link' : element(),
         'mapContext' : element()
       }
       ============================================ -->
  
  <xsl:template mode="gloss:get-links-from-topics" match="*[contains(@class, ' topic/topic ')]" as="map(*)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:apply-templates mode="#current" select="*">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="gloss:get-links-from-topics" as="map(*)*"
    match="
    *[contains(@class, ' topic/body ')] |
    *[contains(@class, ' topic/title ')] |
    *[contains(@class, ' topic/shortdesc ')] |
    *[contains(@class, ' topic/abstract ')]
    ">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:apply-templates mode="#current" 
      select=".//*[@keyref or @href]">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- If an element within a link-allowing context has @keyref or @href it
       must be a link of some sort to a local-scope DITA topic.
       
    -->
  <xsl:template mode="gloss:get-links-from-topics" as="map(*)*" 
    match="*[@keyref or @href]
            [not(contains(@class, ' topic/image '))]
            [not(contains(@class, ' topic/object '))]
            [empty(@format) or (@format = ('dita'))]
            [not(@scope = ('peer', 'external'))]"
  >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="mapContext" as="element()" tunnel="yes"/>
        
    <xsl:sequence select="map{'link' : ., 'mapContext' : $mapContext}"/>
    <xsl:next-match>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:next-match>
  </xsl:template>
  
  <xsl:template mode="gloss:get-links-from-topics" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:apply-templates mode="#current" select="*">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- Get the grouping key for a topic.
       @param context Topic to get the grouping key for
       @param doDebug Turn debugging on or off
       @return The grouping key, i.e., a letter of the alphabet or
       locale-specific equivalent or "NUMERIC" if no other group
       can be determined.
       NOTE: This is a placeholder for a more complete locale-aware
       grouping mechanism that relies on configuration files to
       map characters to groups. It will work for most latin-based
       languages.
     -->
  <xsl:function name="gloss:getGroupingKey" as="xs:string">
    <xsl:param name="context" as="element()"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false()"/>
    
    <xsl:variable name="navtitle" as="xs:string" select="df:getNavtitleForTopicref($context)"/>
   
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:getGroupingKey(): navtitle="{$navtitle}"</xsl:message>
    </xsl:if>
    <xsl:variable name="firstChar" as="xs:string" select="substring($navtitle, 1, 1)"/>
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:getGroupingKey(): firstChar="{$firstChar}"</xsl:message>
    </xsl:if>
    <xsl:variable name="result" as="xs:string">
      <xsl:choose>
        <xsl:when test="matches($firstChar, '\w')">
          <xsl:sequence select="lower-case($firstChar)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="'NUMERIC'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:getGroupingKey(): returning "{$result}s"</xsl:message>
    </xsl:if>
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <!-- Get the grouping label for a given grouping key.
       @param groupKey The group key value (e.g., "a", "NUMERIC")
       @param doDebug Turn debugging on or off
       @return The grouping label. 
       NOTE: This is a placeholder for a more complete locale-aware
       grouping mechanism that relies on configuration files to
       define group labels. It will work for most latin-based
       languages.

     -->
  <xsl:function name="gloss:getGroupLabel" as="xs:string">
    <xsl:param name="groupKey" as="xs:string"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    <xsl:variable name="result" as="xs:string">
      <xsl:choose>
        <xsl:when test="$groupKey eq 'NUMERIC'">
          <xsl:sequence select="'Numeric'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="upper-case($groupKey)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  
  <!-- Enhancement of the version in i18n-utils.xsl, which
       does not use the dita-support-lib functions.
    
       Get the primary sort key for the specified topicref. 
    
       The primary sort key is either the first sort-as value,
       if present, or the base sort key for the referenced
       topic.

       @param topicref The topicref whose referenced topic provides the sort key data.
       @param sortEnglish One of 'first', 'last', 'together'. Determines how English
       text is sorted relative to non-English (non-latin alphabet) text.
       @debug Turns debug messages on or off
       @return The primary sort key string.
    -->
  <xsl:function name="gloss:getPrimarySortKeyForTopicref">
    <xsl:param name="topicref" as="element()"/>
    <xsl:param name="sortEnglish" as="xs:string"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="topic" as="element()?"
      select="df:resolveTopicRef($topicref)"
    />
    <xsl:variable name="sort-as" as="xs:string?"
      select="
      if (exists($topic))
      then (dci18n:getSortAsForTopic($topic, false()))
      else ()
      "
    />
    <xsl:variable name="navtitle" as="xs:string"
      select="df:getNavtitleForTopicref($topicref)"
    />
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gloss:getPrimarySortKeyForTopicref(): navtitle="{$navtitle}"</xsl:message>
    </xsl:if>
    <xsl:variable name="sortKey"
      select="
      if (exists($sort-as) and $sort-as ne '')
      then $sort-as
      else lower-case(normalize-space($navtitle))
      "
    />
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gloss:getPrimarySortKeyForTopicref(): returning "{$sortKey}"</xsl:message>
    </xsl:if>
    <xsl:sequence select="$sortKey"/>
  </xsl:function>
  
  <!--
    Determine of the specified topicref is a topicref to a glossary entry topic.
    @param context topicref to be evaluated
    @return true() if the topicref is to a glossary entry topic.
    -->
  <xsl:function name="gloss:isTopicrefToGlossaryEntry" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:sequence select="gloss:isTopicrefToGlossaryEntry($context, false())"/>
  </xsl:function>
  
  <!--
    Determine of the specified topicref is a topicref to a glossary entry topic.
    @param context topicref to be evaluated
    @param doDebug turn debugging on or off
    @return true() if the topicref is to a glossary entry topic.
    -->
  <xsl:function name="gloss:isTopicrefToGlossaryEntry" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="result" as="xs:boolean">
      <xsl:choose>
        <xsl:when test="df:isTopicRef($context)">
          <xsl:variable name="topic" as="element()?" select="df:resolveTopicRef($context, $doDebug)"/>
          <xsl:if test="$doDebug">
            <xsl:message>+ [DEBUG] gloss:isTopcrefToGlossaryEntry(): keyref="{$context/@keyref}", href="<xsl:value-of
              select="$context/@href"/>"</xsl:message>
            <xsl:message>+ [DEBUG] gloss:isTopcrefToGlossaryEntry(): topic exists: {exists($topic)}</xsl:message>
            <xsl:if test="exists($topic)">
              <xsl:message>+ [DEBUG] gloss:isTopcrefToGlossaryEntry(): topic class: {$topic/@class}</xsl:message>        
            </xsl:if>
          </xsl:if>
          <xsl:sequence
            select="
              exists($topic) and
              contains($topic/@class, ' glossentry/glossentry ')
            "
          />                  
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="false()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <!--
    Determine of the specified topicref is a topicref to a glossary group topic.
    @param context topicref to be evaluated
    @return true() if the topicref is to a glossary group topic.
    -->
  <xsl:function name="gloss:isTopicrefToGlossaryGroup" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:sequence select="gloss:isTopicrefToGlossaryGroup($context, false())"/>
  </xsl:function>
  
  <!--
    Determine of the specified topicref is a topicref to a glossary group topic.
    @param context topicref to be evaluated
    @param doDebug turn debugging on or off
    @return true() if the topicref is to a glossary group topic.
    -->
  <xsl:function name="gloss:isTopicrefToGlossaryGroup" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="result" as="xs:boolean">
      <xsl:choose>
        <xsl:when test="df:isTopicRef($context)">
          <xsl:variable name="topic" as="element()?" select="df:resolveTopicRef($context, $doDebug)"/>
          <xsl:if test="$doDebug">
            <xsl:message>+ [DEBUG] gloss:isTopcrefToGlossaryGroup(): keyref="{$context/@keyref}", href="<xsl:value-of
              select="$context/@href"/>"</xsl:message>
            <xsl:message>+ [DEBUG] gloss:isTopcrefToGlossaryGroup(): topic exists: {exists($topic)}</xsl:message>
            <xsl:if test="exists($topic)">
              <xsl:message>+ [DEBUG] gloss:isTopcrefToGlossaryGroup(): topic class: {$topic/@class}</xsl:message>        
            </xsl:if>
          </xsl:if>
          <xsl:sequence
            select="
            exists($topic) and
            contains($topic/@class, ' glossgroup/glossgroup ')
            "
          />                  
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="false()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="$result"/>
  </xsl:function>
  
</xsl:stylesheet>