<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:php="http://php.net/xsl"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:tei="http://www.tei-c.org/ns/1.0">

	<xsl:output method="text" 
		encoding="utf-8" 
		indent="no"/>
	<!-- Pour les affiliations -->
	<xsl:key name="affiliation" match="/tei:TEI/tei:text/tei:body/tei:listBibl/tei:biblFull/tei:titleStmt/tei:author/tei:affiliation" use="@ref" />
	

	<xsl:template match="/tei:TEI">
		<xsl:apply-templates select="tei:text/tei:body/tei:listBibl/tei:biblFull"/>
	</xsl:template>

	<xsl:template match="tei:biblFull">
		<!-- calcul du type HAL -->
		<xsl:variable name="type"
			select="normalize-space(./tei:profileDesc/tei:textClass/tei:classCode[@scheme='halTypology']/@n)"/>
		<xsl:variable name='type_endnote'>
			<xsl:choose>
				<xsl:when test="$type='ART'">
					<xsl:text>Journal Article</xsl:text>
				</xsl:when>
				<xsl:when test="$type='REPORT' or $type='OTHERREPORT'">
					<xsl:text>Report</xsl:text>
				</xsl:when>
				<xsl:when test="$type='COMM'">
					<xsl:text>Conference Proceedings</xsl:text>
				</xsl:when>
				<xsl:when test="$type='COUV'">
					<xsl:text>Book Section</xsl:text>
				</xsl:when>
				<xsl:when test="$type='OUV'">
					<xsl:text>Book</xsl:text>
				</xsl:when>
				<xsl:when test="$type='DOUV'">
					<xsl:variable name="title">
						<xsl:copy-of select="./tei:titleStmt/tei:title"/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when
							test="starts-with($title,'Proceeding') or starts-with($title,'Actes') or ./tei:sourceDesc/tei:biblStruct/tei:monogr/tei:meeting/tei:title !=''">
							<xsl:text>Conference Proceedings</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>Edited Book</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$type='PATENT'">
					<xsl:text>Patent</xsl:text>
				</xsl:when>
				<xsl:when test="$type='THESE' or $type='HDR'">
					<xsl:text>Thesis</xsl:text>
				</xsl:when>
				<xsl:when test="$type='LECTURE'">
					<xsl:text>Course</xsl:text>
				</xsl:when>
				<xsl:when test="$type='UNDEFINED' or $type='OTHER' or $type='POSTER' or $type='MINUTES' or $type='NOTE' or $type='PRESCONF'">
					<xsl:text>Unpublished work</xsl:text>
				</xsl:when>
				<xsl:when test="$type='MEM'">
					<xsl:text>Master thesis</xsl:text>
				</xsl:when>
				<xsl:when test="$type='VIDEO' or $type='SON'">
					<xsl:text>Audiovisual Material</xsl:text>
				</xsl:when>
				<xsl:when test="$type='IMG'">
					<xsl:text>Figure</xsl:text>
				</xsl:when>
				<xsl:when test="$type='MAP'">
					<xsl:text>Map</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>Unpublished work</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:text>&#xA;&#xA;%0 </xsl:text>
		<xsl:value-of select="normalize-space($type_endnote)"/>

		<!-- affichage des champs title et author -->
		<xsl:apply-templates select="tei:titleStmt"/>
		<!-- commentaire et description -->
		<xsl:apply-templates select="tei:notesStmt/tei:note"/>
		
		<!-- affichage des infos de monogr -->
		<xsl:apply-templates select="tei:sourceDesc/tei:biblStruct/tei:monogr">
			<xsl:with-param name="type_endnote" select="$type_endnote"/>
		</xsl:apply-templates>
		<!-- Traitement de la date -->
		<xsl:apply-templates
			select="tei:editionStmt/tei:edition[@type='current']/tei:date[@type='whenProduced']"/>
		<!-- doi, issn, isbn, number -->
		<xsl:apply-templates select="tei:sourceDesc/tei:biblStruct/tei:idno"/>
		<!-- keywords -->
		<xsl:apply-templates select="tei:profileDesc/tei:textClass/tei:keywords"/>
		<!-- classification/domain -->
		<xsl:apply-templates select="tei:profileDesc/tei:textClass/tei:classCode"/>
		<!-- Affichage du type pour certains types de docs -->
		<xsl:apply-templates
			select="./tei:profileDesc/tei:textClass/tei:classCode[@scheme='halTypology']"
			mode="type"/>
		
		<!-- résumé -->
		<xsl:apply-templates select="tei:profileDesc/tei:abstract"/>
		<!-- language -->
		<xsl:apply-templates select="tei:profileDesc/tei:langUsage/tei:language"/>
		<!-- collaboration -->
		<xsl:apply-templates select="tei:profileDesc/tei:particDesc/tei:org[@type='consortium']" mode="consortium"/>
		
		<!-- FICHIER PRICIPAL PDF -->
		<xsl:apply-templates select="tei:editionStmt/tei:edition[@type='current']/tei:ref[@type='file']"/>
		<!-- Private TAG HAL halId, halUri-->		
		<xsl:apply-templates select="tei:publicationStmt/tei:idno"/>
	</xsl:template>

	<!--Affichage title et author title : attention, double accolade pour protéger les majuscules -->
	<xsl:template match="tei:titleStmt">
		<!-- titre -->
		<xsl:value-of select="concat('&#xA;%T ',normalize-space(tei:title))"/>
		<!-- affiliation pas dans author pour éviter les doublons -->
		<xsl:for-each select="tei:author/tei:affiliation[generate-id()
			= generate-id(key('affiliation',@ref)[1])]">
			<xsl:apply-templates select="."/>
		</xsl:for-each>
		<!-- auteurs -->
		<xsl:for-each
			select="tei:author/tei:persName">
			<xsl:value-of select="concat('&#xA;%A ',normalize-space(tei:surname))"/>
			<xsl:text>, </xsl:text>
			<xsl:value-of select="normalize-space(tei:forename[@type='first'])"/>
			<xsl:if test="tei:forename[@type='middle']">
				<xsl:text>, </xsl:text>
				<xsl:value-of select="normalize-space(tei:forename[@type='middle'])"/>
			</xsl:if>
		</xsl:for-each>
		<!--funder -->
		<xsl:apply-templates select="tei:funder"/>
	</xsl:template>

	<!-- champ note -->
	<xsl:template match="tei:note[@type='commentary']|tei:note[@type='description']">
		<xsl:value-of select="concat('&#xA;%Z ',normalize-space())"/>
	</xsl:template>
	<xsl:template match="tei:note"/>
	<!-- type de rapport, mémoire -->
	<!--xsl:template match="tei:note" mode="type">
		<xsl:text>&#xA;  TYPE = {</xsl:text>
		<xsl:call-template name="affiche_val">
			<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
		</xsl:call-template>
		<xsl:text>},</xsl:text>
	</xsl:template -->

	<!-- info bibliographique monogr ... -->
	<xsl:template match="tei:monogr">
		<xsl:param name="type_endnote"/>
		<!-- idno -->
		<xsl:apply-templates select="tei:idno" />
		<!-- affichage des infos de monogr/title (journal/bookitle) -->
		<xsl:apply-templates select="tei:title" />
		<!-- info conférence -->
		<xsl:apply-templates select="tei:meeting">
			<xsl:with-param name="type_endnote" select="$type_endnote"/>
		</xsl:apply-templates>
		
		<!-- ville/pays pour PATENT,IMG,MAP,LECTURE -->
		<xsl:call-template name="affiche_address"/>

		<!-- scientificEditor -->
		<xsl:apply-templates select="." mode="scientificEditor"/>
		<!-- publisher -->
		<xsl:apply-templates select="./tei:imprint"/>
		<!-- page, serie, issue, volume [pour serie on met Volume ? ] -->
		<xsl:apply-templates select="./tei:imprint/tei:biblScope"/>
		<!-- authority -->
		<xsl:apply-templates select="./tei:authority" />
			
	</xsl:template>

	<!-- journal, booktitle ... -->
	<xsl:template match="tei:title" >
		<xsl:choose>
			<xsl:when test="@level='j'">
				<xsl:value-of select="concat('&#xA;%J ',normalize-space(.))"/>
			</xsl:when>
			<xsl:when test="@level='m'">
				<xsl:value-of select="concat('&#xA;%B ',normalize-space(.))"/>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:template>

	<!-- conference info -->
	<xsl:template match="tei:meeting">
		<!-- conferenceTitle -->
		<xsl:param name="type_endnote"/>
		<xsl:if test="tei:title">
			<xsl:value-of select="concat('&#xA;%B ',normalize-space(tei:title))"/>
		</xsl:if>
		<xsl:call-template name="affiche_address"/>
	</xsl:template>

	<!-- scientificEditor plusieurs valeurs possibles -->
	<xsl:template match="tei:monogr" mode="scientificEditor">
		<xsl:for-each select="tei:editor">
			<xsl:value-of select="concat('&#xA;%E ',normalize-space())"/>
		</xsl:for-each>
	</xsl:template>
	<!-- funder (collaboration)-->
	<xsl:template match="tei:funder[not(@ref)]">
		<xsl:value-of select="concat('&#xA;%Z ',normalize-space())"/>
	</xsl:template>
	
	<!-- publisher : le 1er publisher est celui défini dans le document s'il y a aussi celui du référentiel qui est renseigné -->
	<xsl:template match="tei:imprint">
		<xsl:if test="./tei:publisher">
			<xsl:value-of select="concat('&#xA;%I ',normalize-space(tei:publisher[position()=1]))"/>
		</xsl:if>
		<xsl:if test="./tei:pubPlace">
			<xsl:value-of select="concat('&#xA;%C ',normalize-space(tei:pubPlace))"/>
		</xsl:if>	
	</xsl:template>

	<xsl:template match="tei:abstract">
		<xsl:value-of select="concat('&#xA;%X ',normalize-space())"/>
	</xsl:template>
	
	<xsl:template match="tei:ref">
		<xsl:value-of select="concat('&#xA;%2 ',./@target)"/>
	</xsl:template>
	
	<!-- authority -->
	<xsl:template match="tei:authority[@type='jury']|tei:authority[@type='supervisor']">
		<xsl:value-of select="concat('&#xA;%Z ',normalize-space())"/>
	</xsl:template>
	<xsl:template match="tei:authority[@type='institution']">
		<xsl:value-of select="concat('&#xA;%I ',normalize-space())"/>
	</xsl:template>
	<xsl:template match="tei:authority"/>
		
	<xsl:template match="tei:language">
		<xsl:value-of select="concat('&#xA;%G ',normalize-space())"/>
	</xsl:template>
	<!-- Collaboration -->
	<xsl:template match="tei:org" mode="consortium">
		<xsl:value-of select="concat('&#xA;%Z ',normalize-space())"/>
	</xsl:template>
	
	<!-- affiliation -->
	<xsl:template match="tei:affiliation" >
		<xsl:variable name="structid"><xsl:value-of select="substring-after(./@ref,'#')" /></xsl:variable>
		<xsl:text>&#xA;%+ </xsl:text>
		<xsl:apply-templates select="//tei:back/tei:listOrg[@type='structures']/tei:org[@xml:id=$structid]" mode="structure" />
	</xsl:template>	
	
	<!-- structure-->
	<xsl:template match="tei:org" mode="structure">
		<xsl:value-of select="./tei:orgName[not(@type)]"/>
		<xsl:if test="string-length(./tei:orgName[@type='acronym'])!=0">
			<xsl:text> (</xsl:text><xsl:value-of select="./tei:orgName[@type='acronym']"/><xsl:text>)</xsl:text>
		</xsl:if>
		
	</xsl:template>
			
	
	<!-- page, serie, issue, volume [pour serie on met Volume ? ]-->
	<xsl:template match="tei:biblScope">
		<xsl:variable name="nom_champ">
			<xsl:choose>
				<xsl:when test="./@unit='pp'">
					<xsl:text>&#xA;%P </xsl:text>
				</xsl:when>
				<xsl:when test="./@unit='serie'">
					<xsl:text>&#xA;%N </xsl:text>
				</xsl:when>
				<xsl:when test="./@unit='volume'">
					<xsl:text>&#xA;%V </xsl:text>
				</xsl:when>
				<xsl:when test="./@unit='issue'">
					<xsl:text>&#xA;%N </xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="string-length($nom_champ)!=0">
			<xsl:value-of select="concat($nom_champ, normalize-space(.))"/>
		</xsl:if>
	</xsl:template>
	
	<!-- classification -->
	<xsl:template match="tei:classCode[@scheme='classification']|tei:classCode[@scheme='halDomain']">
		<xsl:value-of select="concat('&#xA;%Z ', normalize-space())"/>
	</xsl:template>
	<xsl:template match="tei:classCode"/>
	


	<!-- doi -->
	<xsl:template match="tei:idno[@type='doi']">
		<xsl:value-of select="concat('&#xA;%R ', normalize-space())"/>
	</xsl:template>
	<!-- arxiv -->
	<xsl:template match="tei:idno[@type='arxiv']|tei:idno[@type='bibcode']|tei:idno[@type='localRef']">
		<xsl:value-of select="concat('&#xA;%Z ', normalize-space())"/>
	</xsl:template>
	<!-- pubmed -->
	<xsl:template match="tei:idno[@type='pubmed']">
		<xsl:value-of select="concat('&#xA;%M ', normalize-space())"/>
	</xsl:template>
	
	<!-- issn -->
	<xsl:template match="tei:idno[@type='issn']|tei:idno[@type='isbn']" >
		<xsl:value-of select="concat('&#xA;%@ ', normalize-space())"/>
	</xsl:template>
	<!-- halId -->
	<xsl:template match="tei:idno[@type='halId']|tei:idno[@type='nnt']">
		<xsl:value-of select="concat('&#xA;%L ', normalize-space())"/>
	</xsl:template>	
	<!-- halUri -->
	<xsl:template match="tei:idno[@type='halUri']">
		<xsl:value-of select="concat('&#xA;%U ', normalize-space())"/>
	</xsl:template>		
	<xsl:template match="tei:idno[@type='patentNumber']|tei:idno[@type='reportNumber']">
		<xsl:value-of select="concat('&#xA;%N ', normalize-space())"/>
	</xsl:template>

	<!-- autres idno -->
	<xsl:template match="tei:idno"/>	

	<!-- affiche la date de production %8=date complete, %D=année -->
	<xsl:template match="tei:date">
		<xsl:value-of select="concat('&#xA;%8 ', normalize-space())"/>
		<xsl:choose>
			<xsl:when test="contains(.,'-')">
				<xsl:text>&#xA;%D </xsl:text>
				<xsl:value-of select="substring-before(.,'-')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&#xA;%D </xsl:text>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- keywords, plusieurs valeurs possibles séparées par ; -->
	<xsl:template match="tei:keywords">
		<xsl:for-each select="./tei:term">
			<xsl:value-of select="concat('&#xA;%K ', normalize-space())"/>
		</xsl:for-each>
	</xsl:template>

	<!-- affiche le mois selon le numero : ATTENTION sans les accolades à cause du latex-->

	<xsl:template name="affiche_month">
		<xsl:param name="month"/>
		<xsl:choose>
			<xsl:when test="$month = '01'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Jan<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '02'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Feb<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '03'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Mar<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '04'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Apr<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '05'"
				><xsl:text>&#xA;  MONTH = </xsl:text>May<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '06'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Jun<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '07'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Jul<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '08'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Aug<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '09'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Sep<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '10'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Oct<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '11'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Nov<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '12'"
				><xsl:text>&#xA;  MONTH = </xsl:text>Dec<xsl:text>,</xsl:text></xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- affiche une adresse -->
	<xsl:template name="affiche_address">
		<xsl:choose>
			<xsl:when test="tei:settlement and tei:country">
				<xsl:text>&#xA;%C </xsl:text>
				<xsl:value-of select="normalize-space(tei:settlement)"/>
				<xsl:text>, </xsl:text>
				<xsl:value-of select="normalize-space(tei:country)"/>
			</xsl:when>
			<xsl:when test="tei:country">
				<xsl:text>&#xA;%C </xsl:text>
				<xsl:value-of select="normalize-space(tei:country)"/>
			</xsl:when>
			<xsl:when test="tei:settlement">
				<xsl:text>&#xA;%C </xsl:text>
				<xsl:value-of select="normalize-space(tei:settlement)"/>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>
