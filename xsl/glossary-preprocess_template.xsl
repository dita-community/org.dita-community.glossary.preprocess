<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs"
  version="2.0">
  <!-- ========================================================
       Glossary preprocessing extension.
       
       Copyright (c) 2019 DITA Community Project
       
       ======================================================== -->
  
  <xsl:import href="plugin:org.dita-community.glossary.preprocess:xsl/glossary-preprocessImpl.xsl"/>
  <dita:extension 
    id="org.dita-community.glossary.preprocess.xsl" 
    behavior="org.dita.dost.platform.ImportXSLAction" 
    xmlns:dita="http://dita-ot.sourceforge.net"
  />
  
</xsl:stylesheet>