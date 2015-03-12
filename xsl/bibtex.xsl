<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:php="http://php.net/xsl"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:tei="http://www.tei-c.org/ns/1.0">
	<xsl:output method="text" encoding="utf-8" indent="no" />
	<xsl:param name="convLatex" select="'yes'"/>

	<xsl:template match="/tei:TEI">
		<xsl:apply-templates select="tei:text/tei:body/tei:listBibl/tei:biblFull" />
	</xsl:template>

	<xsl:template match="tei:biblFull">
		<!-- calcul du type HAL -->
		<xsl:variable name="type" select="./tei:profileDesc/tei:textClass/tei:classCode[@scheme='halTypology']/@n" />
		<xsl:variable name="type_bibtex">
			<xsl:choose>
				<xsl:when test="$type='ART'">
					<xsl:text>article</xsl:text>
				</xsl:when>
				<xsl:when test="$type='REPORT'">
					<xsl:text>techreport</xsl:text>
				</xsl:when>
				<xsl:when test="$type='OTHER'">
					<xsl:text>misc</xsl:text>
				</xsl:when>
				<xsl:when test="$type='COMM'">
					<xsl:text>inproceedings</xsl:text>
				</xsl:when>
				<xsl:when test="$type='PRES_CONF'">
					<xsl:text>misc</xsl:text>
				</xsl:when>
				<xsl:when test="$type='COUV'">
					<xsl:text>incollection</xsl:text>
				</xsl:when>
				<xsl:when test="$type='OUV'">
					<xsl:text>book</xsl:text>
				</xsl:when>
				<xsl:when test="$type='DOUV'">
					<xsl:variable name="title">
						<xsl:copy-of select="./tei:titleStmt/tei:title" />
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="starts-with($title,'Proceeding') or starts-with($title,'Actes') or ./tei:sourceDesc/tei:biblStruct/tei:monogr/tei:meeting/tei:title !=''">
							<xsl:text>proceedings</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>book</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$type='PATENT'">
					<xsl:text>patent</xsl:text>
				</xsl:when>
				<xsl:when test="$type='UNDEFINED'">
					<xsl:text>unpublished</xsl:text>
				</xsl:when>
				<xsl:when test="$type='THESE' or $type='HDR'">
					<xsl:text>phdthesis</xsl:text>
				</xsl:when>
				<xsl:when test="$type='LECTURE'">
					<xsl:text>unpublished</xsl:text>
				</xsl:when>
				<xsl:when test="$type='MEM'">
					<xsl:text>mastersthesis</xsl:text>
				</xsl:when>
				<xsl:when test="$type='POSTER'">
					<xsl:text>misc</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>misc</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:text>@</xsl:text>
		<xsl:value-of select="$type_bibtex" />
		<xsl:text>{</xsl:text>
		<xsl:value-of select="./tei:publicationStmt/tei:idno[@type='halBibtex']" />
		<xsl:text>,</xsl:text>
		<!-- affichage du type si IMAGE/SON/MAP/VIDEO -->
		<xsl:if test="$type='VIDEO' or $type='IMG' or $type='MAP' or $type='SON'">
			<xsl:text>&#xA;  TYPE = {</xsl:text>
			<xsl:value-of select="./tei:profileDesc/tei:textClass/tei:classCode[@scheme='halTypology']" />
			<xsl:text>},</xsl:text>
		</xsl:if>
		<!-- affichage des champs title et author -->
		<xsl:apply-templates select="tei:titleStmt" />
		<!-- affichage des infos sur tei:publicationStmt -->
		<xsl:apply-templates select="tei:publicationStmt" />
		<xsl:apply-templates select="tei:notesStmt/tei:note[@type='commentary' ]" mode="note" />
		<xsl:if test="$type='OTHER'">
			<xsl:apply-templates
				select="tei:notesStmt/tei:note[@type='description']"
				mode="note" />
		</xsl:if>
		<xsl:apply-templates
			select="tei:notesStmt/tei:note[@type='report' or @type='lecture']"
			mode="type" />
		<!-- affichage des infos de monogr -->
		<xsl:apply-templates select="tei:sourceDesc/tei:biblStruct/tei:monogr">
			<xsl:with-param
				name="type_bibtex"
				select="$type_bibtex" />
		</xsl:apply-templates>
		<!-- Traitement de la date -->
		<xsl:apply-templates select="tei:editionStmt/tei:edition[@type='current']/tei:date[@type='whenProduced']" />
		<!-- doi -->
		<xsl:apply-templates select="tei:sourceDesc/tei:biblStruct/tei:idno[@type='doi']" mode="doi" />
		<!-- keywords -->
		<xsl:apply-templates select="tei:profileDesc/tei:textClass/tei:keywords" />
		<!-- Affichage du type pour certains types de docs -->
		<xsl:apply-templates select="./tei:profileDesc/tei:textClass/tei:classCode[@scheme='halTypology']" mode="type" />
        <!-- FICHIER PRICIPAL PDF -->
        <xsl:if test="not($type='VIDEO' or $type='IMG' or $type='MAP' or $type='SON') and tei:editionStmt/tei:edition[@type='current']/tei:ref[@type='file' and @n='1']">
            <xsl:text>&#xA;  PDF = {</xsl:text>
            <xsl:value-of select="tei:editionStmt/tei:edition[@type='current']/tei:ref[@type='file' and @n='1']/@target" />
            <xsl:text>},</xsl:text>
        </xsl:if>
        <!-- Private TAG HAL -->
        <xsl:text>&#xA;  HAL_ID = {</xsl:text>
        <xsl:value-of select="tei:publicationStmt/tei:idno[@type='halId']" />
        <xsl:text>},</xsl:text>
        <xsl:text>&#xA;  HAL_VERSION = {</xsl:text>
        <xsl:value-of select="tei:editionStmt/tei:edition[@type='current']/@n" />
        <xsl:text>},</xsl:text>
        <xsl:text>&#xA;}</xsl:text>
		<xsl:text>&#xA;</xsl:text>
	</xsl:template>

	<!--Affichage title et author title : attention, double accolade pour protéger les majuscules -->
	<xsl:template match="tei:titleStmt">
		<!-- titre -->
		<xsl:text>&#xA;  TITLE = {{</xsl:text>
		<xsl:call-template name="affiche_val">
			<xsl:with-param name="val"><xsl:value-of select="string(./tei:title)" /></xsl:with-param>
		</xsl:call-template>
		<xsl:text>}},</xsl:text>
		<!-- auteurs -->
		<xsl:text>&#xA;  AUTHOR = {</xsl:text>
		<xsl:for-each select="./tei:author/tei:persName">
			<xsl:variable
				name="pos"
				select="position()" />
			<xsl:choose>
				<xsl:when test="$pos=1">
					<xsl:call-template name="affiche_val">
						<xsl:with-param name="val"><xsl:value-of select="./tei:surname" /></xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> and </xsl:text>
					<xsl:call-template name="affiche_val">
						<xsl:with-param name="val"><xsl:value-of select="./tei:surname" /></xsl:with-param>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>, </xsl:text>
			<xsl:call-template name="affiche_val">
				<xsl:with-param name="val"><xsl:value-of select="./tei:forename[@type='first']" /></xsl:with-param>
			</xsl:call-template>
			<xsl:if test="string-length(./tei:forename[@type='middle'])!=0">
				<xsl:text>, </xsl:text>
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="./tei:forename[@type='middle']" /></xsl:with-param>
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>
		<xsl:text>},</xsl:text>
	</xsl:template>

	<!--Affichage publicationStm -->
	<xsl:template match="tei:publicationStmt">
		<xsl:text>&#xA;  URL = {</xsl:text>
		<xsl:value-of select="./tei:idno[@type='halUri']" />
		<xsl:text>},</xsl:text>
	</xsl:template>
	<!-- champ note selon type -->
	<xsl:template match="tei:note" mode="note">
		<xsl:text>&#xA;  NOTE = {</xsl:text>
		<xsl:call-template name="affiche_val">
			<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
		</xsl:call-template>
		<xsl:text>},</xsl:text>
	</xsl:template>
	<!-- type de rapport, mémoire -->
	<xsl:template match="tei:note" mode="type">
		<xsl:text>&#xA;  TYPE = {</xsl:text>
		<xsl:call-template name="affiche_val">
			<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
		</xsl:call-template>
		<xsl:text>},</xsl:text>
	</xsl:template>

	<!-- info bibliographique monogr ... -->
	<xsl:template match="tei:monogr">
		<xsl:param name="type_bibtex" />
		<!-- affichage des infos de monogr/title (journal/bookitle) -->
		<xsl:apply-templates
			select="./tei:title"
			mode="title">
			<xsl:with-param
				name="type_bibtex"
				select="$type_bibtex" />
		</xsl:apply-templates>
		<!-- info conférence -->
		<xsl:apply-templates select="./tei:meeting">
			<xsl:with-param
				name="type_bibtex"
				select="$type_bibtex" />
		</xsl:apply-templates>
		<!-- organization -->
		<xsl:apply-templates
			select="./tei:respStmt"
			mode="organization" />
		<!-- number -->
		<xsl:choose>
			<xsl:when test="$type_bibtex='patent' and string-length(./tei:idno[@type='patentNumber'])!=0">
				<xsl:apply-templates select="./tei:idno[@type='patentNumber']" mode="number" />
			</xsl:when>
			<xsl:when test="$type_bibtex='phdthesis'">
				<xsl:apply-templates select="./tei:idno[@type='nnt']" mode="number" />
			</xsl:when>
			<xsl:when test="$type_bibtex='techreport' and string-length(./tei:idno[@type='reportNumber'])!=0">
				<xsl:apply-templates select="./tei:idno[@type='reportNumber']" mode="number" />
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
		<!-- ville/pays pour PATENT,IMG,MAP,LECTURE -->
		<xsl:call-template name="affiche_address">
			<xsl:with-param name="country">
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="./tei:country" /></xsl:with-param>
				</xsl:call-template>
			</xsl:with-param>
			<xsl:with-param name="town">
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="./tei:settlement" /></xsl:with-param>
				</xsl:call-template>
			</xsl:with-param>
		</xsl:call-template>
		<!-- scientificEditor -->
		<xsl:apply-templates select="." mode="scientificEditor" />
		<!-- publisher -->
		<xsl:apply-templates select="./tei:imprint" mode="publisher" />
		<!-- page -->
		<xsl:apply-templates select="./tei:imprint/tei:biblScope" />
		<!-- authorityInstitution -->
		<xsl:apply-templates select="."	mode="authorityInstitution">
			<xsl:with-param name="type_bibtex"	select="$type_bibtex" />
		</xsl:apply-templates>

	</xsl:template>

	<!-- journal, booktitle ... -->
	<xsl:template
		match="tei:title"
		mode="title">
		<xsl:param name="type_bibtex" />
		<xsl:choose>
			<xsl:when test="@level='j' and $type_bibtex='article'">
				<xsl:text>&#xA;  JOURNAL = {{</xsl:text>
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
				</xsl:call-template>
				<xsl:text>}},</xsl:text>
			</xsl:when>
			<xsl:when test="@level='m' and $type_bibtex='incollection'">
				<xsl:text>&#xA;  BOOKTITLE = {{</xsl:text>
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
				</xsl:call-template>
				<xsl:text>}},</xsl:text>
			</xsl:when>
			<xsl:otherwise />
		</xsl:choose>
	</xsl:template>
	<!-- conference info -->
	<xsl:template match="tei:meeting">
		<!-- conferenceTitle -->
		<xsl:param name="type_bibtex" />
		<xsl:choose>
		<xsl:when test="$type_bibtex='proceedings' or $type_bibtex='inproceedings'">
			<xsl:if test="not(. = './tei:title')">
				<xsl:text>&#xA;  BOOKTITLE = {{</xsl:text>
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="./tei:title" /></xsl:with-param>
				</xsl:call-template>
				<xsl:text>}},</xsl:text>
			</xsl:if>
			<xsl:call-template name="affiche_address">
				<xsl:with-param name="country">
					<xsl:call-template name="affiche_val">
						<xsl:with-param name="val"><xsl:value-of select="./tei:country" /></xsl:with-param>
					</xsl:call-template>
				</xsl:with-param>
				<xsl:with-param name="town">
					<xsl:call-template name="affiche_val">
						<xsl:with-param name="val"><xsl:value-of select="./tei:settlement" /></xsl:with-param>
					</xsl:call-template>
				</xsl:with-param>
			</xsl:call-template>

		</xsl:when>
		<xsl:when test="$type_bibtex='misc'">
			<xsl:if test="not(. = './tei:title')">
				<xsl:text>&#xA;  HOWPUBLISHED = {{</xsl:text>
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="./tei:title" /></xsl:with-param>
				</xsl:call-template>
				<xsl:text>}},</xsl:text>
			</xsl:if>
		</xsl:when>
		<xsl:otherwise />
		</xsl:choose>
	</xsl:template>

	<!-- organization, plusieurs valeurs possibles séparées par and -->
	<xsl:template
		match="tei:respStmt"
		mode="organization">
		<xsl:for-each select="./tei:name">
			<xsl:variable
				name="pos"
				select="position()" />
			<xsl:choose>
				<xsl:when test="$pos=1">
					<xsl:text>&#xA;  ORGANIZATION = {{</xsl:text>
					<xsl:call-template name="affiche_val">
						<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> and </xsl:text>
					<xsl:call-template name="affiche_val">
						<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="$pos = last()">
				<xsl:text>}},</xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<!-- scientificEditor plusieurs valeurs possibles séparées par and -->
	<xsl:template
		match="tei:monogr"
		mode="scientificEditor">
		<xsl:for-each select="./tei:editor">
			<xsl:variable
				name="pos"
				select="position()" />
			<xsl:choose>
				<xsl:when test="$pos=1">
					<xsl:text>&#xA;  EDITOR = {</xsl:text>
					<xsl:call-template name="affiche_val">
						<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> and </xsl:text>
					<xsl:call-template name="affiche_val">
						<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="$pos = last()">
				<xsl:text>},</xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

    <!-- publisher : le 1er publisher est celui défini dans le document s'il y a aussi celui du référentiel qui est renseigné -->
    <xsl:template match="tei:imprint" mode="publisher">
        <xsl:if test="./tei:publisher">
            <xsl:text>&#xA;  PUBLISHER = {{</xsl:text>
            <xsl:call-template name="affiche_val">
                <xsl:with-param name="val"><xsl:value-of select="./tei:publisher[position()=1]" /></xsl:with-param>
            </xsl:call-template>
            <xsl:text>}},</xsl:text>
        </xsl:if>
    </xsl:template>

	<!-- page, serie, issue, volume -->
	<xsl:template match="tei:biblScope">
		<xsl:variable name="nom_champ">
			<xsl:choose>
				<xsl:when test="./@unit='pp'">
					<xsl:text>&#xA;  PAGES</xsl:text>
				</xsl:when>
				<xsl:when test="./@unit='serie'">
					<xsl:text>&#xA;  SERIES</xsl:text>
				</xsl:when>
				<xsl:when test="./@unit='volume'">
					<xsl:text>&#xA;  VOLUME</xsl:text>
				</xsl:when>
				<xsl:when test="./@unit='issue'">
					<xsl:text>&#xA;  NUMBER</xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="string-length($nom_champ)!=0">
			<xsl:text />&#xA;  <xsl:value-of select="$nom_champ"/><xsl:text> = {</xsl:text>
			<xsl:call-template name="affiche_val">
				<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
			</xsl:call-template>
		<xsl:text>},</xsl:text>
	</xsl:if>
</xsl:template>
<!-- type THESE ou HDR-->
<xsl:template match="tei:classCode" mode="type">
	<xsl:if test="./@n='THESE' or ./@n='HDR'">
		<xsl:text>&#xA;  TYPE = {</xsl:text>
		<xsl:call-template name="affiche_val">
			<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
		</xsl:call-template>
		<xsl:text>},</xsl:text>
	</xsl:if>
</xsl:template>


<!-- institution plusieurs valeurs possibles séparées par and
	INSTITUTION pour les REPORT ou SCHOOL pour these et hdr-->
<xsl:template match="tei:monogr" mode="authorityInstitution">
	<xsl:param name="type_bibtex"/>
	<xsl:variable name="nom_champ">
		<xsl:choose>
			<xsl:when test="$type_bibtex='phdthesis' or $type_bibtex='mastersthesis'">
				<xsl:text>&#xA;  SCHOOL</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&#xA;  INSTITUTION</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:for-each select="./tei:authority[@type='institution']">
		<xsl:variable name="pos" select="position()"/>
		<xsl:choose>
			<xsl:when test="$pos=1">
				<xsl:value-of select="$nom_champ"/><xsl:text> = {{</xsl:text>
			<xsl:call-template name="affiche_val">
				<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
			</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> ; </xsl:text>
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="$pos = last()">
			<xsl:text>}},</xsl:text>
		</xsl:if>
	</xsl:for-each>
</xsl:template>

<!-- doi -->
<xsl:template match="tei:idno" mode="doi">
	<xsl:text>&#xA;  DOI = {</xsl:text>
  	<xsl:value-of select="php:function('Ccsd_Tools::protectUnderscore', string(.))" />
	<xsl:text>},</xsl:text>
</xsl:template>

<!-- nnt,patentid -->
<xsl:template match="tei:idno" mode="number">
	<xsl:text>&#xA;  NUMBER = {</xsl:text>
	<xsl:call-template name="affiche_val">
		<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
	</xsl:call-template>
	<xsl:text>},</xsl:text>
</xsl:template>

<!-- affiche l'année et le mois -->
<xsl:template match="tei:date">
	<xsl:choose>
		<xsl:when test="contains(substring-after(.,'-'),'-')">
			<xsl:text>&#xA;  YEAR = {</xsl:text>
			<xsl:value-of select="substring-before(.,'-')"/>
			<xsl:text>},</xsl:text>
			<xsl:call-template name="affiche_month">
				<xsl:with-param name="month"><xsl:value-of select="substring-before(substring-after(.,'-'),'-')"/></xsl:with-param>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="contains(.,'-')">
			<xsl:text>&#xA;  YEAR = {</xsl:text>
			<xsl:value-of select="substring-before(.,'-')"/>
			<xsl:text>},</xsl:text>
			<xsl:call-template name="affiche_month">
				<xsl:with-param name="month"><xsl:value-of select="substring-after(.,'-')"/></xsl:with-param>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>&#xA;  YEAR = {</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>},</xsl:text>
		</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- keywords, plusieurs valeurs possibles séparées par ; -->
<xsl:template match="tei:keywords">
	<xsl:for-each select="./tei:term">
		<xsl:variable name="pos" select="position()"/>
		<xsl:choose>
			<xsl:when test="$pos=1">
				<xsl:text>&#xA;  KEYWORDS = {</xsl:text>
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> ; </xsl:text>
				<xsl:call-template name="affiche_val">
					<xsl:with-param name="val"><xsl:value-of select="." /></xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="$pos = last()">
			<xsl:text>},</xsl:text>
		</xsl:if>
	</xsl:for-each>
</xsl:template>

<!-- affiche le mois selon le numero : ATTENTION sans les accolades à cause du latex-->

<xsl:template name="affiche_month">
  <xsl:param name="month"/>
	<xsl:choose>
			<xsl:when test="$month = '01'"><xsl:text>&#xA;  MONTH = </xsl:text>Jan<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '02'"><xsl:text>&#xA;  MONTH = </xsl:text>Feb<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '03'"><xsl:text>&#xA;  MONTH = </xsl:text>Mar<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '04'"><xsl:text>&#xA;  MONTH = </xsl:text>Apr<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '05'"><xsl:text>&#xA;  MONTH = </xsl:text>May<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '06'"><xsl:text>&#xA;  MONTH = </xsl:text>Jun<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '07'"><xsl:text>&#xA;  MONTH = </xsl:text>Jul<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '08'"><xsl:text>&#xA;  MONTH = </xsl:text>Aug<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '09'"><xsl:text>&#xA;  MONTH = </xsl:text>Sep<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '10'"><xsl:text>&#xA;  MONTH = </xsl:text>Oct<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '11'"><xsl:text>&#xA;  MONTH = </xsl:text>Nov<xsl:text>,</xsl:text></xsl:when>
			<xsl:when test="$month = '12'"><xsl:text>&#xA;  MONTH = </xsl:text>Dec<xsl:text>,</xsl:text></xsl:when>
	</xsl:choose>
</xsl:template>
<!-- affiche une adresse -->
<xsl:template name="affiche_address">
  <xsl:param name="country"/>
  <xsl:param name="town"/>
<xsl:choose>
	<xsl:when test="not(string-length($country)=0) and not(string-length($town)=0)">
		<xsl:text>&#xA;  ADDRESS = {</xsl:text><xsl:value-of select="$town"/><xsl:text>, </xsl:text><xsl:value-of select="$country"/><xsl:text>},</xsl:text>
	</xsl:when>
	<xsl:when test="not(string-length($country)=0)">
		<xsl:text>&#xA;  ADDRESS = {</xsl:text><xsl:value-of select="$country"/><xsl:text>},</xsl:text>
	</xsl:when>
	<xsl:when test="not(string-length($town)=0)">
		<xsl:text>&#xA;  ADDRESS = {</xsl:text><xsl:value-of select="$town"/><xsl:text>},</xsl:text>
	</xsl:when>
	<xsl:otherwise/>
</xsl:choose>
</xsl:template>
<!-- affiche une valeur en latex -->
<xsl:template name="affiche_val">
  <xsl:param name="val"/>
  <xsl:choose>
  	<xsl:when test="$convLatex='yes'">
  		<xsl:value-of select="php:function('Ccsd_Tools::decodeLatex', string($val))" />
  	</xsl:when>
  	<xsl:otherwise>
  		<xsl:value-of select="php:function('Ccsd_Tools::protectLatex', string($val))" />
  	</xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
