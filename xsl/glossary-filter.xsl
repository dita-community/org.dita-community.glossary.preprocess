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
       Glossary preprocessing extension: Glossary Filter
       
       This module filters glossary topicrefs to reflect only
       those glossary entries referenced directly or indirectly
       from normal-role topics.
       
       Implements mode "dita-community:glossary-filter" 
       
       Natively recognizes the following markup as being the
       root of a glossary to be sorted:
       
       - <glossarylist> (BookMap)
       - <topicref outputclass="glossarylist"> (any map type)
       
       Copyright (c) 2019 DITA Community Project
       
       ======================================================== -->
  
  <xsl:mode name="dita-community:glossary-filter"
    on-no-match="shallow-copy"
  />
  
  <!-- 
    Filters the input map based on the links.
    
    @return The filtered map and the link report. The link report, if generated,
    is the second document in the retured sequence.
    -->
  <xsl:template mode="dita-community:glossary-filter" match="/" as="document-node()+">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="df:keySpaces" as="map(*)" tunnel="yes"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:variable name="normalRoleTopicrefs" as="element()*"
      select="/*//*[df:isNormalRoleTopicRef(.)]"
    />
    
    <xsl:message>+ [INFO] Gathering normal-role topics in order to evaluate links to glossary entries...</xsl:message>

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:glossary-filter: Have <xsl:value-of select="count($normalRoleTopicrefs)"/> normal-role topicrefs.</xsl:message>
    </xsl:if>
    
    <!--
      Sequence of maps that contain the topicref and the target topic.
      -->
    <xsl:variable name="normalRoleTopics" as="map(*)*">
      <xsl:apply-templates select="$normalRoleTopicrefs" mode="gloss:get-topics-for-topicrefs">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
        <xsl:with-param name="processDescendantTopicrefs" as="xs:boolean" tunnel="yes" select="false()"/>
        <xsl:with-param name="excludeClass" as="xs:string?" tunnel="yes" select="' glossentry/glossentry '"/>
        <xsl:with-param name="df:keySpaces" as="map(*)" tunnel="yes" select="$df:keySpaces"/>          
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$localDebug">
      <xsl:message>
        + [DEBUG] dita-community:glossary-filter: Have <xsl:value-of select="count($normalRoleTopics)"/> normal-role topics that are not glossary entries.
      </xsl:message>
      <!--      <xsl:for-each select="$normalRoleTopics">
        <xsl:message>+ [DEBUG] [<xsl:value-of select="position()"/>] <xsl:value-of select="df:getNavtitleForTopic(.)"/> (<xsl:value-of select="base-uri(.)"/>)</xsl:message>
      </xsl:for-each>
-->
    </xsl:if>
    <xsl:variable name="glossaryTopics" as="map(*)*">
      <xsl:apply-templates select="$normalRoleTopicrefs" mode="gloss:get-topics-for-topicrefs">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
        <xsl:with-param name="processDescendantTopicrefs" as="xs:boolean" tunnel="yes" select="false()"/>
        <xsl:with-param name="includeClass" as="xs:string?" tunnel="yes" select="' glossentry/glossentry '"/>
        <xsl:with-param name="df:keySpaces" as="map(*)" tunnel="yes" select="$df:keySpaces"/>          
      </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:glossary-filter: Have <xsl:value-of select="count($glossaryTopics)"/> normal-role glossary topics.</xsl:message>
<!--      <xsl:for-each select="$glossaryTopics">
        <xsl:message>+ [DEBUG] [<xsl:value-of select="position()"/>] <xsl:value-of select="df:getNavtitleForTopic(.)"/> (<xsl:value-of select="base-uri(.)"/>)</xsl:message>
      </xsl:for-each>
-->    </xsl:if>
    
    <!-- 
      Sequence of maps, one for each link, containing the link element
      and the topicref that establishes the map context.
      
      map{
        'link'       : element(),
        'mapContext' : element()
      }
      -->
    <xsl:variable name="links" as="map(*)*">
      <xsl:call-template name="gloss:get-links-from-topics">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="topics" as="map(*)*" select="$normalRoleTopics"/>
        <xsl:with-param name="df:keySpaces" as="map(*)" tunnel="yes" select="$df:keySpaces"/>
      </xsl:call-template>
    </xsl:variable>       
    
    <xsl:if test="$localDebug">
      <xsl:message>
+ [DEBUG] dita-community:glossary-filter: Have {count($links)} links:</xsl:message>
 <!--     <xsl:for-each select="$links">
        <xsl:variable name="map" as="map(*)" select="."/>
        <xsl:variable name="link" as="element()" select="map:get($map, 'link')"/>
        <xsl:message>+ [DEBUG]   [{position()}] {name($link)} {if (exists($link/@keyref)) 
          then ' keyref=&quot;' || $link/@keyref || '&quot;'
          else ()} href="{$link/@href}" {
          if (not(matches($link, '^\s*$'))) 
          then '&quot;' || normalize-space($link) || '&quot;'  
          else ''}</xsl:message>
      </xsl:for-each>        
 -->   
    </xsl:if>
    
    <xsl:variable name="directlyUsedGlossaryEntries" as="map(*)*">
      <xsl:call-template name="gloss:get-topics-for-links">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="links" as="map(*)*" select="$links"/>
        <xsl:with-param name="df:keySpaces" as="map(*)" tunnel="yes" select="$df:keySpaces"/>                  
      </xsl:call-template>
    </xsl:variable>    

    <xsl:message>+ [INFO] dita-community:glossary-filter: Have {count($directlyUsedGlossaryEntries)} directly-used glossary entries</xsl:message>
    
    <xsl:variable name="indirectlyUsedGlossaryEntries" as="map(*)*">
      <xsl:call-template name="gloss:getIndirectlyUsedGlossaryEntries">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="directlyUsedGlossaryEntries" as="map(*)*" select="$directlyUsedGlossaryEntries"/>
        <xsl:with-param name="df:keySpaces" as="map(*)" tunnel="yes" select="$df:keySpaces"/>                  
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:message>+ [INFO] dita-community:glossary-filter: Have {count($indirectlyUsedGlossaryEntries)} indirectly-used glossary entries</xsl:message>

    <xsl:variable name="usedGlossaryEntries" as="map(*)*"
      select="($directlyUsedGlossaryEntries, $indirectlyUsedGlossaryEntries)"
    />
    
    <xsl:message>+ [INFO] dita-community:glossary-filter: Have {count($usedGlossaryEntries)} total used glossary entries</xsl:message>
    
    <xsl:variable name="rootElem" as="element()" select="/*"/>
    <xsl:document>
      <xsl:sequence select="node()[. &lt;&lt; $rootElem]"/>
      <xsl:if test="$localDebug">
        <xsl:message>+ [DEBUG] dita-community:glossary-filter: applying templates to map in mode dita-community:glossary-filter...</xsl:message>
      </xsl:if>
      <xsl:comment>[DEBUG] applying templates to map in mode dita-community:glossary-filter</xsl:comment>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug or $localDebug"/>
        <xsl:with-param name="usedGlossaryEntries" as="map(*)*" tunnel="yes" 
          select="$usedGlossaryEntries"
        />
      </xsl:apply-templates>
      <xsl:comment>[DEBUG] After applying templates in mode dita-community:glossary-filter</xsl:comment>
      <xsl:if test="$localDebug">
        <xsl:message>+ [DEBUG] dita-community:glossary-filter: After applying templates to map in mode dita-community:glossary-filter.</xsl:message>
      </xsl:if>
      <xsl:sequence select="node()[. &gt;&gt; $rootElem]"/>
    </xsl:document>
    
    <!-- Make the link report -->
    <!-- WEK: Link report turns out to not be that useful and I don't want to support it at this time. -->
<!--    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:glossary-filter: Calling make-link-report...</xsl:message>
    </xsl:if>
    <xsl:call-template name="dita-community:make-link-report">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="links" as="element()*" select="$links"/>
    </xsl:call-template>
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:glossary-filter: After make-link-report.</xsl:message>
    </xsl:if>
-->    
    
  </xsl:template>
  
  <!-- 
    Given a set of topics, find all links in those topics that point outside
    the topics that contain them.
    @param topics sequence of maps with the topic elements and their map contexts
    @param doDebug Turn debugging on or off.
    @return Sequence of maps, one for each link, with the link and its map context.
    -->
  <xsl:template name="gloss:get-links-from-topics" as="map(*)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="topics" as="map(*)*"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:get-links-from-topics: Starting. Have {count($topics)} topics to evaluate.</xsl:message>
    </xsl:if>
    
    <xsl:for-each select="$topics">
      <xsl:variable name="map" as="map(*)" select="."/>
      <xsl:variable name="topic" as="element()" select="map:get($map, 'topic')"/>
      <xsl:variable name="mapContext" as="element()" select="map:get($map, 'mapContext')"/>
      <xsl:if test="$localDebug">
        <xsl:message>+ [DEBUG] gloss:get-links-from-topics:  Applying templates to topic {df:getNavtitleForTopic($topic)} in mode gloss:get-links-from-topics.</xsl:message>
        <xsl:message>+ [DEBUG] gloss:get-links-from-topics:  Map context: {name($mapContext)} [{$mapContext/@xtrc}]</xsl:message>
      </xsl:if>
      
      <xsl:apply-templates mode="gloss:get-links-from-topics" select="$topic">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="mapContext" as="element()" tunnel="yes" select="$mapContext"/>
      </xsl:apply-templates>        
    </xsl:for-each>
    
  </xsl:template>
  
  <!-- 
    Given a set of links, resolve them to their topics.
    @param links sequence of maps with the link elements and their map contexts
    @param doDebug Turn debugging on or off.
    @return Sequence of maps, one for each resolved topic, with the topic and its map
    context (normally the key definition that points directly to the topic, if it's
    initially referenced by key, or the map element if it's a direct URI reference).
    -->  
  <xsl:template name="gloss:get-topics-for-links">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="links" as="map(*)*"/>    
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:get-topics-for-links: Starting. Have {count($links)} links</xsl:message>
    </xsl:if>
    
    <xsl:for-each select="$links">
      <xsl:variable name="map" as="map(*)" select="."/>
      <xsl:apply-templates select="map:get($map, 'link')" mode="gloss:get-glossary-entries-for-links">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="mapContext" as="element()" tunnel="yes" select="map:get($map, 'mapContext')"/>
      </xsl:apply-templates>
    </xsl:for-each>

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:get-topics-for-links: Done.</xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  <!-- If the topicref is to a used glossary entry, keep it, otherwise ignore it. -->
  <xsl:template mode="dita-community:glossary-filter" match="*[gloss:isTopicrefToGlossaryEntry(.)]" priority="10">  
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="usedGlossaryEntries" as="map(*)*" tunnel="yes"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:variable name="target" as="element()*"
      select="df:resolveTopicRef(., $doDebug)"
    />
    
    <xsl:choose>
      <xsl:when test="exists($target intersect $usedGlossaryEntries?topic)">
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] dita-community:glossary-filter: Topicref to glossary entry, entry is used, keeping it.</xsl:message>
        </xsl:if>
        <xsl:next-match>
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:next-match>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] dita-community:glossary-filter: Topicref to glossary entry, entry is not used, filtering it out (but not its child topicrefs).</xsl:message>
        </xsl:if>
        <!-- Not a reference to a used glossary entry, filter it out -->
        <xsl:apply-templates select="*[contains(@class, ' map/topicref ')]" mode="#current">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>                  
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>  </xsl:template>
  
  <!--
    If the glossary group is empty after filtering then filter it out too.
   -->
  <xsl:template mode="dita-community:glossary-filter" match="*[gloss:isTopicrefToGlossaryGroup(.)]">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
        
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] dita-community:glossary-filter: Glossary group "{df:getNavtitleForTopicref(.)}"</xsl:message>
    </xsl:if>    

    <xsl:variable name="descendantTopicrefs" as="element()*">
      <xsl:apply-templates mode="#current" select="*[contains(@class, ' map/topicref ')]">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="empty($descendantTopicrefs)">
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] dita-community:glossary-filter: topicref to glossary group - All descendants filtered out, filtering group out too.</xsl:message>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] dita-community:glossary-filter: topicref to glossary group - Have descendants filtered out, keeping the group.</xsl:message>
        </xsl:if>
        
        <xsl:copy copy-namespaces="false">
          <!-- Handle non-topicref descendants normally -->
          <xsl:apply-templates mode="#current" select="@*, node()[not(contains(@class, ' map/topicref '))]">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:apply-templates>
          <xsl:sequence select="$descendantTopicrefs"/>
          <!-- NOTE: This will not preserve any non-element nodes that follow the child topicrefs, i.e., processing instructions,
                     but there shouldn't be any of those anyway.
            -->
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template mode="dita-community:glossary-filter" match="/*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:copy copy-namespaces="no">
      <xsl:attribute name="xml:base" select="base-uri(.)"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Context element should be some form of link -->
  <xsl:template mode="gloss:get-glossary-entries-for-links" match="*" as="map(*)?">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="df:keySpaces" as="map(*)" tunnel="yes"/>
    <xsl:param name="mapContext" as="element()" tunnel="yes"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:if test="$localDebug">
      
      <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links: --------------------------------------</xsl:message>
      <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links: Handling element {name(.)}</xsl:message>
      <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links:   keyref="{@keyref}"</xsl:message>
      <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links:   href  ="{@href}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="keydef" as="element()?"
      select="
      if (exists(@keyref))
      then df:getKeydefForKeyref($df:keySpaces, $mapContext, @keyref, false())
      else ()
      "
    />

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links:  Have a keydef: {exists($keydef)}</xsl:message>
    </xsl:if>
    
    <!-- NOTE: At this point in the preprocessing, the link should always have an @href
               value that points to the target, so the keydef is only needed
               to capture the map context, not resolve the link.
      -->
    <xsl:variable name="targetURI" as="xs:string?"
      select="string(@href)"
    />    

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links:  targetURI="{$targetURI}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="target" as="element()?"
      select="df:resolveTopicElementRef(., $targetURI, false())"
    />
    
    <xsl:choose>
      <xsl:when test="exists($target)">
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links:  Got target element: {name($target)}</xsl:message>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="contains($target/@class, ' glossentry/glossentry ')">
            <xsl:if test="$localDebug">
              <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links:  Target element is a glossary entry, returning it.</xsl:message>
            </xsl:if>
            <xsl:sequence select="map{'topic' : $target, 'mapContext' : ($keydef, $mapContext)[1]}"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$localDebug">
              <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links:  Target element is not a glossary entry, returning nothing.</xsl:message>
            </xsl:if>
            <!-- Not a glossary entry, ignore it -->
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$localDebug">
          <xsl:message>+ [DEBUG] gloss:get-glossary-entries-for-links:  Did not get a target element, returning nothing.</xsl:message>
        </xsl:if>
        <!-- No target, nothing to do -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Give a set of glossary entries, find all the links in those glossary
       entries and then return the glossary entries linked by those links,
       if any.
       
       Repeat until no more links are found.
    -->
  <xsl:template name="gloss:getIndirectlyUsedGlossaryEntries" as="map(*)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="directlyUsedGlossaryEntries" as="map(*)*"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="$doDebug or false()"/> 
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:getIndirectlyUsedGlossaryEntries: Starting. Have {count($directlyUsedGlossaryEntries)} directly-used glossary entries.</xsl:message>
    </xsl:if>

    <xsl:call-template name="gloss:_getIndirectlyUsedGlossaryEntries">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="directlyUsedGlossaryEntries" as="map(*)*" select="$directlyUsedGlossaryEntries"/>
      <xsl:with-param name="indirectlyUsedGlossaryEntries" as="map(*)*" select="()"/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- Recursive template to get references to glossary entries from the directly-used glossary entries -->
  <xsl:template name="gloss:_getIndirectlyUsedGlossaryEntries" as="map(*)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="directlyUsedGlossaryEntries" as="map(*)*"/>
    <xsl:param name="indirectlyUsedGlossaryEntries" as="map(*)*"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="$doDebug or false()"/> 
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:_getIndirectlyUsedGlossaryEntries: Starting. Have {count($directlyUsedGlossaryEntries)} directly-used glossary entries.</xsl:message>
    </xsl:if>
    
    <!-- Get the links from the directly-used glossary entires, get the glossary
         entries from those, and recurse.
      -->
    
    <xsl:variable name="links" as="map(*)*">
      <xsl:call-template name="gloss:get-links-from-topics">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="topics" as="map(*)*" select="$directlyUsedGlossaryEntries"/>
      </xsl:call-template>      
    </xsl:variable>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:_getIndirectlyUsedGlossaryEntries: Have {count($links)} links:</xsl:message>
      <xsl:for-each select="$links">        
        <xsl:message>+ [DEBUG]     {name(.?link)} keyref="{.?link/@keyref}"</xsl:message>
      </xsl:for-each>
    </xsl:if>
    
    <xsl:variable name="newIndirectGlossaryEntries" as="map(*)*">
      <xsl:for-each select="$links">
        <xsl:apply-templates select=".?link" mode="gloss:get-glossary-entries-for-links">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="mapContext" as="element()" tunnel="yes" select=".?mapContext"/>
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:variable>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:_getIndirectlyUsedGlossaryEntries: Have {count($newIndirectGlossaryEntries)} newIndirectGlossaryEntries.</xsl:message>
    </xsl:if>
    
    <xsl:variable name="directGlossaryTopics" as="element()*"
      select="$directlyUsedGlossaryEntries?topic"
    />

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:_getIndirectlyUsedGlossaryEntries: Have {count($directGlossaryTopics)} directGlossaryTopics.</xsl:message>
    </xsl:if>
    
    <xsl:variable name="newTopics" as="map(*)*"
      select="
      for $map in $newIndirectGlossaryEntries
      return 
      let $newTopic := map:get($map, 'topic')
      return if (exists($newTopic except ($directGlossaryTopics, $indirectlyUsedGlossaryEntries?topic)))
      then $map
      else ()
      "
    />

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] gloss:_getIndirectlyUsedGlossaryEntries: Have {count($directGlossaryTopics)} directGlossaryTopics.</xsl:message>
    </xsl:if>
    
    <xsl:choose>
      <xsl:when test="empty($newTopics)">
        <xsl:sequence select="$indirectlyUsedGlossaryEntries"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="gloss:_getIndirectlyUsedGlossaryEntries">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="directlyUsedGlossaryEntries" as="map(*)*" select="$newTopics"/>
          <xsl:with-param name="indirectlyUsedGlossaryEntries" as="map(*)*" select="($indirectlyUsedGlossaryEntries, $newTopics)"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
</xsl:stylesheet>