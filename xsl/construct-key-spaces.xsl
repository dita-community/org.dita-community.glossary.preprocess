<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:df="http://dita2indesign.org/dita/functions"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  exclude-result-prefixes="relpath df dita-ot map"
  expand-text="yes"
  version="3.0">
  <!-- =============================================================
       Constructs a map of key spaces, one for the anonymous root
       scope and one for each of the named scopes, if any.
       
       The result is a sequence of maps, where the key is the
       keyscope-defining element's identifier (e.g., generate-id()
       applied to the element).
       
       Each map represents a key space map where the key
       is the unqualified key within the scope and the value
       is a map representing the key definition and resource,
       if any.
       
       Each key space also points to its parent key scope,
       if any (the root key scope does not have a parent).
       
       To look up a key: 
       1. get the topicref that establishes the map context of the reference
       2. Walk the keyscope-to-parent references to get the list
          of ancestor key scopes.
       3. Walk the list of key scopes, starting with the root,
          and attempt to resolve the key. The first resolution
          result is the effective key definition.                 
       
       TO DO: Add the ability to do condition-aware lookup,
       where an additional parameter is the set of active
       DITAVAL conditions and the effective key definition
       is the first found that also satisfies the specified
       conditions.
       
       NOTE: This process is currently implementeds to work with
       the map that is the input to the keyref process, meaning
       a fully-resolved, unfiltered map that still has the
       intermediate dita-ot:submap elements that hold keyscopes
       defined on maprefs and submaps.
       
       As of OT 3.3 the intermediate map represents submaps like
       so:
       
             <submap 
                 class="+ map/topicref mapgroup-d/topicgroup ditaot-d/submap " 
                 dita-ot:orig-class="+ map/topicref mapgroup-d/mapref " 
                 dita-ot:orig-format="ditamap" 
                 dita-ot:orig-href="glossary/aikido-master-glossary-keydefs-en.ditamap" 
                 dita-ot:submap-DITAArchVersion="1.3" 
                 dita-ot:submap-cascade="merge" 
                 dita-ot:submap-class="- map/map " 
                 dita-ot:submap-domains="(map mapgroup-d) (topic abbrev-d) (topic delay-d) a(props deliveryTarget) (map ditavalref-d) (map glossref-d) (topic hazard-d) (topic hi-d) (topic indexing-d) (topic markup-d) (topic pr-d) (topic relmgmt-d) (topic sw-d) (topic ui-d) (topic ut-d) (topic markup-d xml-d)"
                 dita-ot:submap-keyscope="gloss-res" 
                 dita-ot:submap-lang="en" 
                 keyscope="gloss-res" 
                >

        So the key scope names are captured here for submap topicrefs and
        the maps they reference.
       
       ============================================================= -->
  
  
  <xsl:template name="df:construct-key-spaces" as="map(*)">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="rootMap" as="document-node()"/>
        
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-spaces: Starting...</xsl:message>
    </xsl:if>

    <!-- Map of keyscope-defining elements to key scope maps.
      
         The key is the generate-id() value for the keyscope-defining
         element.
         
      -->
    <xsl:variable name="keySpaces" as="map(*)*">      
      
      <xsl:for-each select="$rootMap/*, $rootMap/.//*[@keyscope]" >
        <!-- Each keyspace is map that relates the key space ID
             to the key space data.
          -->
        <xsl:call-template name="df:construct-key-space">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
        </xsl:call-template>
      </xsl:for-each>
      
    </xsl:variable>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-spaces: $keySpaces variable constructed. </xsl:message>
    </xsl:if>
    
    <xsl:variable name="result" as="map(*)"
      select="map:merge($keySpaces, map{ 'duplicates' : 'combine'})"
    />
    <xsl:sequence select="$result"/>
  </xsl:template>
  
  <!-- Construct a single key scope map for a single key scope 
  
       Context is a scope-defining element (map or topicref).
  -->
  <xsl:template name="df:construct-key-space" as="map(*)">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space: Starting..., context is {name(.)}</xsl:message>
    </xsl:if>

    <xsl:variable name="this" as="element()" select="."/>

    <xsl:variable name="base-parent-keyscope" as="element()?"
      select="(ancestor::*[@keyscope])[last()]"
    />
    
    <xsl:variable name="parent-keyscope" as="element()?"
      select="
      if (exists($base-parent-keyscope))
      then $base-parent-keyscope
      else
      if (not(/* is .))
      then /*
      else ()
      "
    />

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space: parent-keyscope exists: {exists($parent-keyscope)}</xsl:message>
    </xsl:if>
    
    <!-- Should only have no @keyscope if the context is the root map element -->
    <xsl:variable name="scopeNames" as="xs:string+"
      select="
      if (exists(@keyscope))
      then tokenize(@keyscope, '\s+')
      else '#root'
      "
    />

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space: scopeNames: "{$scopeNames => string-join('", "')}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="scopeID" as="xs:string" select="generate-id(.)"/>      
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space: scopeID: "{$scopeID}"</xsl:message>
    </xsl:if>

    <xsl:map-entry key="$scopeID">
      <xsl:map>
        <xsl:map-entry key="'parent-keyscope-id'" 
          select="
          if (exists($parent-keyscope))
          then generate-id($parent-keyscope)
          else ()
          "
        />
        <xsl:map-entry key="'parent-keyscope-definer'" select="$parent-keyscope"/>
        <xsl:map-entry key="'keyscope-definer'" select="."/>
        <xsl:map-entry key="'scope-names'" select="$scopeNames"/>
        <xsl:map-entry key="'fully-qualified-scope-names'" select="df:get-qualified-key-scope-names($this, $doDebug)"/>
        <xsl:map-entry key="'keyspace'">
          <xsl:variable name="mapEntries" as="map(*)*">
            <!-- Construct a map of key names to key-defining elements.
              
                 The key name is the key name qualified relative to this key space,
                 meaning the key names reflect any descendant key scopes but no
                 ancestor key scopes.                 
              -->
            <xsl:if test="$localDebug">
              <xsl:message>+ [DEBUG] df:construct-key-space: Applying templates in mode df:construct-key-space to child topicrefs...</xsl:message>
            </xsl:if>            
            <xsl:apply-templates mode="df:construct-key-space"
                select="*[contains(@class, ' map/topicref ') or contains(@class, ' ditaot-d/submap ')]" 
              >
              <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
              <xsl:with-param name="keyScopeQualifier" as="xs:string?" tunnel="yes" select="()"/>
            </xsl:apply-templates>
          </xsl:variable>
          <xsl:sequence select="map:merge($mapEntries, map{'duplicates' : 'combine'})"/>
        </xsl:map-entry>
        
      </xsl:map>
    </xsl:map-entry>
    
  </xsl:template>
  
  <xsl:template mode="df:construct-key-space" match="*[@keyscope]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="keyScopeQualifier" as="xs:string?" tunnel="yes"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space: keyscope-definer: @keyscope="{@keyscope}"</xsl:message>
      <xsl:message>+ [DEBUG] df:construct-key-space: keyScopeQualifier="{$keyScopeQualifier}"</xsl:message>
    </xsl:if>            
    
    <xsl:variable name="newScopeQualifier" as="xs:string?"
      select="($keyScopeQualifier, string(@keyscope)) => string-join(.)"
    />
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space: newScopeQualifier="{$newScopeQualifier}"</xsl:message>
    </xsl:if>            
    
    <xsl:next-match>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
      <xsl:with-param name="keyScopeQualifier" as="xs:string?" tunnel="yes" select="$newScopeQualifier"/>
    </xsl:next-match>
    
  </xsl:template>
  
  <!--
    Create map entry for each @keys value, qualified by the key scope qualifier,
    that maps the qualified key name to this element.
    
    The value is actually a sequence of key defining elements. This allows
    for both reporting duplicate definitions and selection of definitions
    based on filtering.
    
    @param keyScopeQualifier The qualified name, starting at the root scope of
    the key space. Does not end in ".".
    -->
  <xsl:template mode="df:construct-key-space" match="*[@keys]" as="map(*)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="keyScopeQualifier" as="xs:string?" tunnel="yes"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() or $doDebug"/>

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space: Topicref with @keys: keys="{@keys}"</xsl:message>
      <xsl:message>+ [DEBUG] df:construct-key-space: keyScopeQualifer="{$keyScopeQualifier}"</xsl:message>
    </xsl:if>            
    
    <xsl:variable name="this" as="element()" select="."/>
    
    <xsl:variable name="keyNames" as="xs:string+"
      select="tokenize(@keys, '\s+')"
    />

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space: keyNames="{$keyNames}"</xsl:message>
    </xsl:if>            
    
    <xsl:variable name="qualifiedKeyNames" as="xs:string*"
      select="
      if (exists($keyScopeQualifier))
      then $keyNames ! ($keyScopeQualifier || '.' || .)
      else $keyNames
      "
    />

    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space:   qualified key names: "{$qualifiedKeyNames => string-join('", "')}"</xsl:message>
    </xsl:if>        
    
    <xsl:sequence 
      select="
        $qualifiedKeyNames ! map:entry(., $this) 
      "
    />
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space:   Applying templates to direct-child topicrefs in current mode...</xsl:message>
    </xsl:if>            

    <xsl:apply-templates mode="#current" 
      select="*[contains(@class, ' map/topicref ') or contains(@class, ' ditaot-d/submap ')]">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
    </xsl:apply-templates>
    
  </xsl:template>
  
  <!--
    Fallback for non-key-defining topicrefs.
    -->
  <xsl:template mode="df:construct-key-space" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="localDebug" as="xs:boolean" select="false() and $doDebug"/>
    
    <xsl:if test="$localDebug">
      <xsl:message>+ [DEBUG] df:construct-key-space: Fallback, applying templates to direct-child topicrefs...</xsl:message>
    </xsl:if>            
    
    <xsl:apply-templates mode="#current" 
      select="*[contains(@class, ' map/topicref ') or contains(@class, ' ditaot-d/submap ')]">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$localDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!--
    Determine the fully-qualified key scope name of the current element. 
    
    The root (anonymous) scope name is "#root".
    
    @param context The element to get the key scope for. Must be an element within a DITA map.
    @param doDebug Turn debugging on or off.
    @return The fully-qualified scope name. If there are no explicit scope names then the
    scope name will be "#root".
    -->
  <xsl:function name="df:get-qualified-key-scope-names" as="xs:string+">
    <xsl:param name="context" as="element()"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="scopeNames" as="xs:string+"
      select="
      if ($context/self::* is root($context)/*)
      then '#root'
      else tokenize($context/@keyscope, '\s+')"
    />

    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="$scopeNames = ('#root')">
          <xsl:sequence select="$scopeNames"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="ancestorScopeNames" as="xs:string*"
            select="$context/ancestor::*[@keyscope][1] ! df:get-qualified-key-scope-names(., $doDebug)"
          />
          
          <xsl:sequence  
            select="
              for $ancestorScopeName in $ancestorScopeNames
              return $scopeNames ! ($ancestorScopeName || '.' || .)
            "
          />          
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <!-- 
    Gets the ultimate effective key-defining topicref for a key.
    @param keySpaces The keyspaces map to use in resolving the key.
    @param mapContext The topicref that establishes the map context of the 
    key reference. If the reference is from a topicref then this is the 
    topicref making the reference, otherwise it is the topicref that
    references the topic (or descendant topic of the referenced topic)
    that contains the key reference. Automatically recurses through
    intermediate key references.
    @param keyName The key name to resolve
    @return The key-defining topicref, if found, otherwise an empty sequence.
    -->
  <xsl:function name="df:resolveScopedKey" as="element()?">
    <xsl:param name="keySpaces" as="map(*)"/>
    <xsl:param name="mapContext" as="element()"/>
    <xsl:param name="keyName" as="xs:string"/>
    
    <xsl:sequence select="df:resolveScopedKey($keySpaces, $mapContext, $keyName, false())"/>
  </xsl:function>
  
  <!-- 
    Gets the ultimate effective key-defining topicref for a key.
    @param keySpaces The keyspaces map to use in resolving the key.
    @param mapContext The topicref that establishes the map context of the 
    key reference. If the reference is from a topicref then this is the 
    topicref making the reference, otherwise it is the topicref that
    references the topic (or descendant topic of the referenced topic)
    that contains the key reference. Automatically recurses through
    intermediate key references.
    @param keyName The key name to resolve
    @param doDebug Turn debugging on or off
    @return The key-defining topicref, if found, otherwise an empty sequence.
    -->
  <xsl:function name="df:resolveScopedKey" as="element()?">
    <xsl:param name="keySpaces" as="map(*)"/>
    <xsl:param name="mapContext" as="element()"/>
    <xsl:param name="keyName" as="xs:string"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] df:resolveScopedKey(): keyName="{$keyName}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="parentScopeDefiner" as="element()"
      select="(root($mapContext)/*, $mapContext/ancestor-or-self::*[@keyscope][1])[last()]"
    />
    
    <xsl:variable name="scopeID" as="xs:string"
      select="generate-id($parentScopeDefiner)"
    />
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] df:resolveScopedKey(): scopeID="{$scopeID}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="scopeIDs" as="xs:string+"
      select="df:getAncestorKeyScopeIDs($keySpaces, $scopeID, (), $doDebug and false())"
    />
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] df:resolveScopedKey(): scopeIDs="{$scopeIDs => string-join(', ')}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="result" as="element()?"
      select="df:resolveScopedKeyForScopeID($keySpaces, $scopeIDs, $keyName, $doDebug)"
    />
    
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
  <!-- 
    Gets the list, from highest to nearest, of ancestor scope IDs. The ID 
    of the root scope is always first and the specified ID is always last.
    @param keySpaces
    @param scopeID
    @param doDebug
    @return List of scope IDs, from highest to nearest
    -->
  <xsl:function name="df:getAncestorKeyScopeIDs" as="xs:string+">
    <xsl:param name="keySpaces" as="map(*)"/>
    <xsl:param name="scopeID" as="xs:string"/>
    <xsl:param name="accumulatedIDs" as="xs:string*"/>
    <xsl:param name="doDebug" as="xs:boolean"/>

    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] df:getAncestorKeyScopeIDs(): scopeID="{$scopeID}"</xsl:message>
      <xsl:message>+ [DEBUG] df:getAncestorKeyScopeIDs(): accumulatedIDs="{$accumulatedIDs => string-join(', ')}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="keySpace" as="map(*)"
      select="map:get($keySpaces, $scopeID)"
    />
    <xsl:variable name="parentScopeID" as="xs:string?"
      select="map:get($keySpace, 'parent-keyscope-id')"
    />
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] df:getAncestorKeyScopeIDs(): parentScopeID="{$parentScopeID}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="result" as="xs:string*"
      select="
      if (exists($parentScopeID))
      then df:getAncestorKeyScopeIDs($keySpaces, $parentScopeID, ($scopeID, $accumulatedIDs), $doDebug)
      else ($scopeID, $accumulatedIDs)
      "
    />
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] df:getAncestorKeyScopeIDs(): returning="{$result => string-join(', ')}"</xsl:message>
    </xsl:if>
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
  <!-- 
    Attempts to resolve the spified key name in the specified
    key scope. If the key is not found, calls itself recursively
    with the next key scope ID.
    @param keySpaces The keyspaces map to use in resolving the key.
    @param scopeID The unique ID of the key scope to resolve against.
    @param keyName The key name to resolve
    @param remainingScopes List, possibly empty, of key scope IDs
    @param doDebug Turn debugging on or off
    @return The key-defining topicref, if found, otherwise an empty sequence.
    -->
  <xsl:function name="df:resolveScopedKeyForScopeID" as="element()?">
    <xsl:param name="keySpaces" as="map(*)"/>
    <xsl:param name="scopeIDs" as="xs:string*"/>
    <xsl:param name="keyName" as="xs:string"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] df:resolveScopedKeyForScopeID(): keyName="{$keyName}"</xsl:message>
      <xsl:message>+ [DEBUG] df:resolveScopedKeyForScopeID(): scopeIDs={$scopeIDs => string-join(', ')}</xsl:message>
    </xsl:if>
    
    <xsl:variable name="result" as="element()?">
    <xsl:choose>
      <xsl:when test="empty($scopeIDs)">
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] df:resolveScopedKeyForScopeID(): No more scopes to check, returning ()</xsl:message>
        </xsl:if>
        <xsl:sequence select="()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="scopeID" as="xs:string"
          select="head($scopeIDs)"
        />
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] df:resolveScopedKeyForScopeID(): scopeID="{$scopeID}"</xsl:message>
        </xsl:if>
        <xsl:variable name="keySpace" as="map(*)"
          select="map:get($keySpaces, $scopeID)"
        />
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] df:resolveScopedKeyForScopeID(): have key space for ID {$scopeID}: {exists($keySpace)}</xsl:message>
        </xsl:if>
        
        <xsl:variable name="keyDefs" as="map(*)"
          select="map:get($keySpace, 'keyspace')"
        />
        
        <xsl:variable name="keyDefinition" as="element()?"
          select="map:get($keyDefs, $keyName)[1]"
        />
        <xsl:sequence
          select="
          if (exists($keyDefinition))
          then $keyDefinition
          else df:resolveScopedKeyForScopeID($keySpaces, tail($scopeIDs), $keyName, $doDebug)
          "
        />
      </xsl:otherwise>
    </xsl:choose>    
    </xsl:variable>
    
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
  <xsl:function name="df:getKeydefForKeyref" as="element()?">
    <xsl:param name="keySpaces" as="map(*)"/>
    <xsl:param name="mapContext" as="element()"/>
    <xsl:param name="keyref" as="attribute()"/><!-- @keyref, @conkeyref -->
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="keyname" as="xs:string?"
      select="
      if (contains($keyref, '/'))
      then tokenize($keyref, '/')[1]
      else string($keyref)
      "
    />
    
    <xsl:variable name="result" as="element()?"
      select="df:resolveScopedKey($keySpaces, $mapContext, $keyname, $doDebug)"
    />
    
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <!-- 
    Contructs a report of the key spaces in the specified key scapes map.
    @param keyspaces Map of scope names to key spaces.
    @return The report
    -->
  <xsl:function name="df:report-key-spaces">
    <xsl:param name="keyspaces" as="map(*)"/>
    
    <xsl:variable name="scopeKeys" as="xs:string+"
      select="map:keys($keyspaces)"
    />
    
    <xsl:variable name="rootSpaces" as="map(*)+">
      <xsl:for-each select="$scopeKeys">
        <xsl:variable name="key" as="xs:string" select="."/>
        <xsl:variable name="scope" as="map(*)" select="map:get($keyspaces, $key)"/>
        <xsl:if test="empty(map:get($scope, 'parent-keyscope-definer'))">
          <xsl:sequence select="$scope"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>            
    
    <xsl:text>Keyspace Report&#x0a;</xsl:text>

    <!-- FIXME: Report the key spaces as a tree -->
    <xsl:for-each select="$scopeKeys ! map:get($keyspaces, .)">
      <xsl:text>&#x0a;</xsl:text>
      <xsl:sequence select="df:report-key-space(.)"/>
    </xsl:for-each>
    
  </xsl:function>
  
  <xsl:function name="df:report-key-space">
    <xsl:param name="keyspace" as="map(*)"/>
    
    <xsl:variable name="parentKeyscopeDefiner" as="element()?"
      select="map:get($keyspace, 'parent-keyscope-definer')"
    />
    
    <xsl:text>--------------------------------------------------------------------&#x0a;</xsl:text>
    <xsl:text>Key space: {$keyspace?scope-names => string-join(', ')}&#x0a;</xsl:text>
    <xsl:text>Parent key scope: {
      if (exists($parentKeyscopeDefiner))
      then (generate-id($parentKeyscopeDefiner))
      else 'No parent keyscope'}&#x0a;</xsl:text>
    <xsl:text>Fully-qualified scope names:: {$keyspace?fully-qualified-scope-names => string-join(', ')}&#x0a;</xsl:text>
    <xsl:text>Key definitions:&#x0a;</xsl:text>
    <xsl:for-each select="map:keys($keyspace?keyspace)">
      <xsl:variable name="position" as="xs:integer" select="position()"/>
      <xsl:variable name="keySpaceMap" as="map(*)" select="$keyspace?keyspace"/>
      <xsl:variable name="keyName" as="xs:string" select="."/>
      <xsl:variable name="keyDefs" as="element()+" select="map:get($keySpaceMap, $keyName)"/>
      <xsl:text>[{format-integer($position, '###')}] {$keyName}:&#x0a;</xsl:text>
      <xsl:for-each select="$keyDefs">
        <xsl:text>      [{position()}] {name(.)}&#x0a;</xsl:text>
        <xsl:text>            href="{@href}"&#x0a;</xsl:text>
        <xsl:text>            keys="{@keys}"&#x0a;</xsl:text>
        <xsl:text>            linktext="{normalize-space(.//linktext)}"&#x0a;</xsl:text>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:function>
  
  
  
</xsl:stylesheet>