<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
    version="1.0">
	
	<xsl:output
		method="xml"
		indent="yes"
		encoding="UTF-8"
        omit-xml-declaration="yes"/>
	<!-- Pour les affiliations -->
	<xsl:key name="affiliation" match="/tei:TEI/tei:text/tei:body/tei:listBibl/tei:biblFull/tei:titleStmt/tei:author/tei:affiliation" use="@ref" />

	<xsl:template match="/">
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="tei:TEI">
		<oai_dc:dc>
			<dc:publisher>HAL CCSD</dc:publisher>
			<xsl:apply-templates select="tei:text/tei:body/tei:listBibl/tei:biblFull" />
			<xsl:apply-templates select="tei:text/tei:back/tei:listOrg[@type='projects']/tei:org" />
		</oai_dc:dc>
	</xsl:template>
	<xsl:template match="tei:biblFull">
		<!-- calcul du type HAL -->
		<xsl:variable name="type" select="./tei:profileDesc/tei:textClass/tei:classCode[@scheme='halTypology']/@n" />
		<xsl:apply-templates select="tei:titleStmt/tei:title" mode="biblFull"/>
		<xsl:apply-templates select="tei:titleStmt/tei:author" />
		<!-- affiliation pas dans author pour éviter les doublons -->
		<xsl:for-each select="tei:titleStmt/tei:author/tei:affiliation[generate-id() = generate-id(key('affiliation',@ref)[1])]">
			<xsl:apply-templates select="."/>
		</xsl:for-each>
		<!--  funding : contrat, financement hors projets -->
		<xsl:apply-templates select="tei:titleStmt/tei:funder[not(@ref)]" mode="funding"/>
		<xsl:apply-templates select="tei:notesStmt/tei:note" />
		<xsl:apply-templates select="tei:sourceDesc/tei:biblStruct/tei:monogr" />
		<!-- identifiant -->
		<xsl:apply-templates select="tei:publicationStmt/tei:idno[@type='halId']" mode="identifier"/>		
		<xsl:apply-templates select="tei:publicationStmt/tei:idno[@type='halUri']" mode="identifier"/>
		<xsl:apply-templates select="tei:editionStmt/tei:edition[@type='current']/tei:ref[@type='file']" mode="identifier"/>
		<xsl:apply-templates select="tei:publicationStmt/tei:idno[@type='halUri'] | tei:publicationStmt/tei:idno[@type='halRef']" mode="source"/>
		<xsl:apply-templates select="tei:sourceDesc/tei:biblStruct/tei:idno" mode="identifier"/>
		<xsl:apply-templates select="tei:sourceDesc/tei:biblStruct/tei:ref"/>
		<xsl:apply-templates select="tei:profileDesc/tei:langUsage/tei:language" />
		<xsl:apply-templates select="tei:profileDesc/tei:textClass/tei:keywords/tei:term" mode="keywords"/>
		<xsl:apply-templates select="tei:profileDesc/tei:textClass/tei:classCode"/>
		<xsl:apply-templates select="tei:profileDesc/tei:abstract"/>
		<xsl:apply-templates select="tei:profileDesc/tei:particDesc/tei:org" />
		
		<!-- date -->
        <xsl:apply-templates select="tei:editionStmt/tei:edition[@type='current']/tei:date[@type='whenProduced']" />
		<xsl:apply-templates select="tei:sourceDesc/tei:biblStruct/tei:series/tei:editor" />
		<xsl:apply-templates select="tei:sourceDesc/tei:biblStruct/tei:series/tei:title " mode="source"/>
	</xsl:template>

	<!--  author -->
	<xsl:template match="tei:author">
		<dc:creator>
			<xsl:value-of select="tei:persName/tei:surname" />
			<xsl:text>, </xsl:text>
			<xsl:value-of select="tei:persName/tei:forename[@type='first']" />
			<xsl:if test="string-length(tei:persName/tei:forename[@type='middle'])!=0">
				<xsl:text>, </xsl:text>
				<xsl:value-of select="./tei:forename[@type='middle']" />
			</xsl:if>
		</dc:creator>
	</xsl:template>

	<!-- dc:description : comment, description, ... -->
	<xsl:template match="tei:note[@type='commentary']|tei:note[@type='description']|tei:note[@type='lecture']">
		<dc:description>
			<xsl:value-of select="." />
		</dc:description>
	</xsl:template>	
	
	<!-- dc:description : audience -->
	<xsl:template match="tei:note[@type='audience']">
		<xsl:choose>
			<xsl:when test="@n=2">
			<dc:description>
				<xsl:text>International audience</xsl:text>
			</dc:description>
			</xsl:when>
			<xsl:when test="@n=3">
			<dc:description>
				<xsl:text>National audience</xsl:text>
			</dc:description>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:template>	
	
	<!-- éléments de monogr -->
	<xsl:template match="tei:monogr">
		<xsl:apply-templates select="tei:idno[@type='nnt'] | tei:idno[@type='isbn'] 
			| tei:idno[@type='patentNumber'] | tei:idno[@type='reportNumber']" mode="identifier"/>
		<xsl:apply-templates select="tei:title"  mode="source"/>
		<xsl:apply-templates select="tei:meeting" />
		<xsl:apply-templates select="tei:respStmt/tei:resp" mode="organization"/>
		<!-- ville/pays pour PATENT,IMG,MAP,LECTURE -->
		<xsl:call-template name="affiche_address">
			<xsl:with-param name="country">
				<xsl:value-of select="./tei:country" />
			</xsl:with-param>
			<xsl:with-param name="town">
				<xsl:value-of select="./tei:settlement" />
			</xsl:with-param>
		</xsl:call-template>
		<xsl:apply-templates select="./tei:editor" />
		<xsl:apply-templates select="./tei:imprint/tei:publisher" />
		<xsl:apply-templates select="./tei:authority" />
	</xsl:template>
	
	<!-- éléments de meeting -->
	<xsl:template match="tei:meeting">
		<!-- conferenceTitle -->
		<xsl:apply-templates select="tei:title"  mode="source"/>
		<xsl:call-template name="affiche_address">
			<xsl:with-param name="country">
				<xsl:value-of select="./tei:country" />
			</xsl:with-param>
			<xsl:with-param name="town">
				<xsl:value-of select="./tei:settlement" />
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>	
		
	<!-- identifiant -->
	<xsl:template match="tei:idno|tei:ref" mode="identifier">
		<dc:identifier>
			<xsl:choose>
				<xsl:when test="./@type='patentNumber'">
					<xsl:text>Patent N° : </xsl:text>
	            </xsl:when>
				<xsl:when test="./@type='reportNumber'">
					<xsl:text>Report N° : </xsl:text>
	            </xsl:when>
	            <xsl:when test="./@type='halId'" />
	            <xsl:when test="./@type='halUri'" />
	            <xsl:when test="./@type='file'" />
	            <xsl:otherwise>
					<xsl:value-of select="translate(./@type,
	                                'abcdefghijklmnopqrstuvwxyz',
	                                'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
					<xsl:text> : </xsl:text>
	            </xsl:otherwise>
        	</xsl:choose>
            <xsl:choose>
                <xsl:when test="./@type='file'">
                    <xsl:value-of select="@target"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="." />
                </xsl:otherwise>
            </xsl:choose>
        </dc:identifier>
	</xsl:template>	
	
	<!-- idno source -->
	<xsl:template match="tei:idno" mode="source">
		<dc:source>
			<xsl:value-of select="." />		
		</dc:source>
	</xsl:template>
	
	<!-- titre du document -->
	<xsl:template match="tei:title" mode="biblFull">
		<xsl:choose>
			<xsl:when test="not(./@type='sub')">
				<dc:title>
					<xsl:attribute name="xml:lang"><xsl:value-of select="./@xml:lang"/></xsl:attribute>
					<xsl:value-of select="." />
				</dc:title>
			</xsl:when>
			<xsl:when test="./@type='sub'">
				<xsl:variable name="lang"><xsl:value-of select="./@xml:lang"/></xsl:variable>
				<dc:title>
					<xsl:attribute name="xml:lang"><xsl:value-of select="$lang"/></xsl:attribute>
					<xsl:value-of select="../tei:title[@xml:lang=$lang][not(@type)]"/>
					<xsl:text> : </xsl:text>
					<xsl:value-of select="." />
				</dc:title>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- titre associé à monogr -->
	<xsl:template match="tei:title" mode="source">
		<dc:source>
			<xsl:value-of select="." />
		</dc:source>
	</xsl:template>
	
	<!-- conferenceOrganizer -->
	<xsl:template match="tei:name" mode="organization">
		<dc:contributor>
			<xsl:value-of select="." />
		</dc:contributor>
	</xsl:template>	
	
	<!-- scientificEditor et seriesEditor -->
	<xsl:template match="tei:editor" >
		<dc:contributor>
			<xsl:value-of select="." />
		</dc:contributor>
	</xsl:template>	

	<!-- publisher -->
	<xsl:template match="tei:publisher" >
		<dc:publisher>
			<xsl:value-of select="." />
		</dc:publisher>
	</xsl:template>	
	
	<!-- affiche la date et supprime éventuellement l'heure-->
	<xsl:template match="tei:date">
		<dc:date>
		<xsl:choose>
			<xsl:when test="contains(.,' ')">
				<xsl:value-of select="substring-before(.,' ')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
		</dc:date>
	</xsl:template>
	
	<!-- dc:authority : authorityInstitution, director -->
	<xsl:template match="tei:authority[@type='institution']|tei:authority[@type='supervisor']">
		<dc:contributor>
			<xsl:value-of select="." />
		</dc:contributor>
	</xsl:template>	
	
	<!-- ref -->
	<xsl:template match="tei:ref[@type='publisher']">
		<dc:source >
			<xsl:value-of select="." />
		</dc:source >
	</xsl:template>	

	<!-- language -->
	<xsl:template match="tei:language">
		<dc:language >
			<xsl:value-of select="./@ident" />
		</dc:language >
	</xsl:template>	
	
	<!-- keywords -->
	<xsl:template match="tei:term" mode="keywords">
		<dc:subject>
			<xsl:attribute name="xml:lang"><xsl:value-of select="./@xml:lang"/></xsl:attribute>
			<xsl:value-of select="." />
		</dc:subject>
	</xsl:template>	
	
	<!-- classifications -->
	<xsl:template match="tei:classCode">
		<xsl:choose>
			<xsl:when test="./@scheme='acm' or ./@scheme='jel' or ./@scheme='acm'">
				<dc:subject>
				<xsl:value-of select="translate(./@scheme,
                                'abcdefghijklmnopqrstuvwxyz',
                                'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
				<xsl:text> : </xsl:text>
				<xsl:value-of select="." />		
       		</dc:subject>
            </xsl:when>
			<xsl:when test="./@scheme='halDomain'">
				<dc:subject>
				<xsl:text>[</xsl:text>
				<xsl:value-of select="translate(./@n,
                                'abcdefghijklmnopqrstuvwxyz',
                                'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
				<xsl:text>] </xsl:text>
				<xsl:value-of select="." />		
				</dc:subject>
            </xsl:when>
			<xsl:when test="./@scheme='classification'">
            	<dc:subject>
				<xsl:value-of select="." />		
				</dc:subject>
            </xsl:when>
			<xsl:when test="./@scheme='halTypology'">
            	<dc:type>
				<xsl:value-of select="." />		
				</dc:type>
            </xsl:when>
            <xsl:otherwise/>
       	</xsl:choose>
	</xsl:template>	

	<!-- abstract -->
	<xsl:template match="tei:abstract">
		<dc:description>
			<xsl:attribute name="xml:lang"><xsl:value-of select="./@xml:lang"/></xsl:attribute>
			<xsl:value-of select="." />
		</dc:description>
	</xsl:template>	
	
	<!-- funding : contrat, financement-->
	<xsl:template match="tei:funder" mode="funding">
		<dc:contributor>
		<xsl:value-of select="."/>
		</dc:contributor>
	</xsl:template>	
	
	<!-- collaboration -->
	<xsl:template match="tei:org[@type='consortium']">
		<dc:contributor>
			<xsl:value-of select="." />
		</dc:contributor>
	</xsl:template>	
	
	<!-- anrProject-->
	<xsl:template match="tei:org[@type='anrProject']">
		<dc:contributor>
			<xsl:if test="not(contains(tei:idno[@type='anr'],'ANR'))">
				<xsl:text>ANR : </xsl:text>
			</xsl:if>
			<xsl:for-each select="./tei:orgName|tei:idno[@type='anr']|./tei:desc ">
		        <xsl:value-of select="."/>
		        <xsl:if test="not(position() = last())">, </xsl:if>
        	</xsl:for-each>
			<xsl:if test="string-length(./tei:date[@type='start'])!=0">
				<xsl:text>(</xsl:text>
				<xsl:apply-templates select="./tei:date[@type='start']" mode="year"/>
				<xsl:text>)</xsl:text>
			</xsl:if>
		</dc:contributor>
	</xsl:template>	
	<!-- europeanProject-->
	<xsl:template match="tei:org[@type='europeanProject']">
		<dc:contributor>
			<xsl:text>European Project : </xsl:text>
			<xsl:for-each select="./tei:orgName|tei:idno[@type='program']|tei:idno[@type='number']|tei:idno[@type='call'] ">
		        <xsl:value-of select="."/>
		        <xsl:if test="not(position() = last())">, </xsl:if>
        	</xsl:for-each>
			<xsl:if test="string-length(./tei:date[@type='start'])!=0">
				<xsl:text>(</xsl:text>
				<xsl:apply-templates select="./tei:date[@type='start']" mode="year"/>
				<xsl:text>)</xsl:text>
			</xsl:if>
		</dc:contributor>
	</xsl:template>	
	
	<!-- affiliation -->
	<xsl:template match="tei:affiliation" >
		<xsl:variable name="structid"><xsl:value-of select="substring-after(./@ref,'#')" /></xsl:variable>
		<dc:contributor>
			<xsl:apply-templates select="//tei:back/tei:listOrg[@type='structures']/tei:org[@xml:id=$structid]" mode="structure" />
		</dc:contributor>
	</xsl:template>	

	<!-- structure-->
	<xsl:template match="tei:org" mode="structure">
		<xsl:value-of select="./tei:orgName[not(@type)]"/>
		<xsl:if test="string-length(./tei:orgName[@type='acronym'])!=0">
	        <xsl:text> (</xsl:text><xsl:value-of select="./tei:orgName[@type='acronym']"/><xsl:text>)</xsl:text>
       	</xsl:if>
       	<!-- Calcul des tutelles -->
       	<!-- <xsl:variable name="listStruct">
		<xsl:apply-templates select="tei:listRelation"/>    
		</xsl:variable>
		<xsl:value-of select="$listStruct"></xsl:value-of>  
		<xsl:call-template name="item-tokenize">
    		<xsl:with-param name="list" select="$listStruct" />
    		<xsl:with-param name="delimiter" select="';'"/>
		</xsl:call-template> 	 -->
		<!-- calcul d'abord de la variable avec toutes les struct d'une branche -->
       	<xsl:if test="./tei:listRelation">
       		<xsl:text> ; </xsl:text>
       		<xsl:variable name="nomVariable">var</xsl:variable>
			<xsl:for-each select="./tei:listRelation/tei:relation">
<!-- 				<xsl:variable name="listStruct">
		        	<xsl:apply-templates select="." mode="calcStruc"/>
		        </xsl:variable>
		        <xsl:text>-</xsl:text><xsl:value-of select="$listStruct"></xsl:value-of><xsl:text>-</xsl:text>
 -->		        
 				<xsl:apply-templates select="." mode="affiche"/>
		        <xsl:if test="not(position() = last())"> - </xsl:if>
 			</xsl:for-each>
       	</xsl:if>
	</xsl:template>
	
	<xsl:template match="tei:relation" mode="calcStruc">
		<xsl:variable name="structid"><xsl:value-of select="substring-after(./@active,'#')" /></xsl:variable>
	    <xsl:text>[</xsl:text><xsl:value-of select="$structid" /><xsl:text>]</xsl:text>
	    <xsl:apply-templates select="//tei:back/tei:listOrg[@type='structures']/tei:org[@xml:id=$structid]/tei:listRelation" />
	</xsl:template>	
	
	<xsl:template match="tei:relation" mode="affiche">
		<xsl:variable name="structid"><xsl:value-of select="substring-after(./@active,'#')" /></xsl:variable>
		<xsl:if test="./@type='UMR'">
			<xsl:value-of select="./@name"></xsl:value-of>
			<xsl:text> : </xsl:text>
		</xsl:if>
		<xsl:apply-templates select="//tei:back/tei:listOrg[@type='structures']/tei:org[@xml:id=$structid]" mode="structure" />
	</xsl:template>	
	
	<!-- calcul la liste des tutelles non institution -->
	<xsl:template match="tei:listRelation" >
		<xsl:for-each select="./tei:relation">
			<xsl:variable name="structid"><xsl:value-of select="substring-after(./@active,'#')" /></xsl:variable>
	        <xsl:text>[</xsl:text><xsl:value-of select="$structid"></xsl:value-of><xsl:text>]</xsl:text>
	        <xsl:apply-templates select="//tei:back/tei:listOrg[@type='structures']/tei:org[@xml:id=$structid]/tei:listRelation" />
       	</xsl:for-each>
	</xsl:template>	
	
	<!-- affiche une adresse -->
	<xsl:template name="affiche_address">
	  <xsl:param name="country"/>
	  <xsl:param name="town"/>
	  <xsl:if test="string-length($country)!=0 and string-length($town)!=0">
		<dc:coverage >
		<xsl:choose>
			<xsl:when test="not(string-length($country)=0) and not(string-length($town)=0)">
				<xsl:value-of select="$town"/><xsl:text>, </xsl:text><xsl:value-of select="$country"/>
			</xsl:when>
			<xsl:when test="not(string-length($country)=0)">
				<xsl:value-of select="$country"/>
			</xsl:when>
			<xsl:when test="not(string-length($town)=0)">
				<xsl:value-of select="$town"/>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	  </dc:coverage >
	  </xsl:if>
	</xsl:template>	
	
	<!-- affiche une année étant donnée une date-->
	<xsl:template match="tei:date" mode="year">
		<xsl:choose>
			<xsl:when test="contains(.,'-')">
				<xsl:value-of select="substring-before(.,'-')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- split une chaine -->
<xsl:template name="item-tokenize">
    <xsl:param name="list" />
    <xsl:param name="delimiter" />
    <xsl:variable name="newlist">
        <xsl:choose>
            <xsl:when test="contains($list, $delimiter)"><xsl:value-of select="normalize-space($list)" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat( normalize-space($list), $delimiter )"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="first" select="substring-before($newlist, $delimiter)" />
    <xsl:variable name="remaining" select="substring-after($newlist, $delimiter)" />
    <xsl:element name="newitem"><xsl:value-of select="$first"/></xsl:element>
    <xsl:if test="$remaining">
        <xsl:call-template name="item-tokenize">
            <xsl:with-param name="list" select="$remaining" />
            <xsl:with-param name="delimiter"><xsl:value-of select="$delimiter"/></xsl:with-param>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

	<!-- Pour le reste -->
   	<xsl:template match="*"/>
</xsl:stylesheet>
