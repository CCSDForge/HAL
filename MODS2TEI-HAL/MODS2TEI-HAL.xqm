xquery version '3.0' ;

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace m = 'http://www.loc.gov/mods/v3';

(:
: @version 0.1 
: @since 2016-10-09
: @author Philippe Pons, Ingénieur d'étude chargé de l'édition de corpus numériques au Centre de Recherche sur les civilisations de l'Asie Orientale (CRCAO UMR8155, CNRS)
: Ce document est distribué par le CRCAO sous la licence https://creativecommons.org/licenses/by-nc-sa/3.0/fr/
:
: Ce script a pour but de passer des références bibliographiques de Zotero (ou de Juris-M) exportées en MODS au format TEI conforme au schéma AOfr de l'API SWORD-HAL.
:
:)

(: 
: Renseigner les informations sur l'auteur des références et sur la base de données utilisées. OBLIGATOIRE
:)
declare variable $forename := "David"; (: donner le prénom de l'auteur du document :)
declare variable $surname := "Simplot-Ryl"; (: donner le nom de famille de l'auteur du document :)
declare variable $bdd := "simplot"; (: donner le nom de la base de donnée :)

(:  
: Renseigner les informations sur le déposant des références. OBLIGATOIRE
:)
declare variable $forename_depositor := "Alain"; (: donner le prénom du déposant du document sur HAL :)
declare variable $surname_depositor := "Monteil"; (: donner le nom du déposant du document sur HAL :)

(:
: @param élément(s) titleInfo
: @param options de type chaîne de caractère pour définir le niveau de titre en fonction du contexte: dans l'élément titleStmt, titre de niveau analytic ou monographique.
: @return un titre mis en forme en TEI-HAL, en fonction du contexte (défini par l'option).
:)
declare function local:getTitles($node as element(m:titleInfo)*, $options as xs:string?) {    
  for $title in $node
  let $lang := if ($title/@xml:lang) then ($title/@xml:lang) else local:getLang($title/ancestor::m:mods/m:language)
  return
    switch ($options)
    case ($options[. = 'titleStmt']) return 
       if ($title[not(@type = 'abbreviated')])
       then <title xml:lang="{$lang}">{ normalize-space($title[not(@type = 'abbreviated')]/m:title) }</title>
       else ()
    case ($options[. = 'analytic']) return
      if ($title[@type = 'abbreviated'])
      then ()
      else <title xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    case ($options[. = "book"]) return <title xml:lang="{$lang}">{ normalize-space($node[1]/m:title) }</title>
    case ($options[. = 'journalArticle']) return <title level="j" xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    case ($options[. = 'magazineArticle']) return <title level="j" xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    case ($options[. = 'monogr']) return <title level="m" xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    case ($options[. = 'newspaperArticle']) return <title level="j" xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    default return <title>{ normalize-space($title/m:title) }</title>
};

(:
: @return le nom de l'auteur de la référence bibliographique tel qu'il doit apparait dans le titleStmt.
: l'attribut @role est toujours "aut", et l'auteur est par défaut celui qui est donné en variable au début de ce script.
: Le nom et les informations complémentaires sur cet auteur (courriel, etc.) sont extraits de la base de données "auteurs" (par comparaison entre le nom donné en variable et les noms dans la bdd "auteurs").
:)
declare function local:getAut() {
  for $auteurs in db:open('auteurs')//tei:person/tei:persName
  where $auteurs/tei:surname = $surname and $auteurs/tei:forename = $forename
  return
    <author role="aut">
      <persName>
        <forename type="first">{ normalize-space($forename) }</forename>
        <surname>{ normalize-space($surname) }</surname>
      </persName>
      {local:getComplementAuthor($auteurs)}
    </author>
};        

(:
: @return cette fonction permet de signaler le "déposant" dans HAL de la référence.
: @error vérifier que le nom et le prénom du déposant sont suffisants
:)
declare function local:getDepositor($node as element()*) {
  <author role="depositor">
    <persName>
      <forename>{ normalize-space($forename_depositor) }</forename>
      <surname>{ normalize-space($surname_depositor) }</surname>
    </persName>
  </author>
};

(:
: @param élément(s) name
: @param options de type chaîne de caractère 
: @return cette fonction permet de définir le rôle des auteurs, en fonction de l'option: 
: auteur ("aut"), contributeur ("ctb"), éditeur ("edt"), traducteur ("trl").
: Pour les éditeurs, le traitement varie selon le contexte (défini par l'option).
: @error si les auteurs n'ont que "traducteur" comme responsabilité, l'import dans HAL risque de ne pas fonctionner.
:)
declare function local:getAuthors($node as element(m:name)*, $options as xs:string) {
  for $name in $node
  let $role := $name/m:role/m:roleTerm
  return
    switch ($role)
    case ($role[. = 'aut']) return 
      <author role="aut">{ local:getName($name), local:getIdAuthor($name) }</author>
    case ($role[. = 'ctb']) return
      <author role="ctb">{ local:getName($name), local:getIdAuthor($name) }</author>
    case ($role[. = 'edt']) return
      switch ($options) 
      case ($options[. = "titulaires"]) return <author role="edt">{ local:getName($name), local:getIdAuthor($name) }</author> 
      case ($options[. = "analytic"]) return <author role="edt">{ local:getName($name), local:getIdAuthor($name) }</author> 
      default return local:getEditorScientific($name)
    case ($role[. = 'trl']) return
      <author role="trl">{ local:getName($name), local:getIdAuthor($name) }</author>
    default return $name
};

(:
: @param élément(s) name
: @return cette fonction permet de mettre en forme l'identifiant HAL et la structure de référence d'un auteur identifié dans la base "auteurs".
: @error si le nom de l'auteur dans la référence Zotero est différent du nom dans la base "auteurs", ces informations ne seront pas ajoutées et l'import dans HAL risque de ne pas fonctionner.
:)
declare function local:getIdAuthor($node as element(m:name)) {
  for $auteur in db:open('auteurs')//tei:person/tei:persName
  where $node/m:namePart[@type = "family"][contains(., $auteur/tei:surname)] and $node/m:namePart[@type = "given"][contains(., $auteur/tei:forename)]
  return
    ($auteur/tei:idno[@type="halauthorid"], $auteur/tei:affiliation[@ref])
};

(:
: @param élément(s) name
: @return cette fonction permet de mettre en forme les Noms et Prénoms des auteurs.
: @error le nom ET le prénom doivent être obligatoirement renseignés.
:)
declare function local:getName($node as element(m:name)*) { 
  <persName>{
    switch ($node)
    case ($node[@type = 'personal']) return
      (if ($node/m:namePart[@type = 'given'])
      then 
        for $forename in $node/m:namePart[@type = 'given'] 
        return local:getForename($forename)
      else 
        <forename type="first"/>,
      for $surname in $node/m:namePart[@type = 'family'] 
      return local:getSurname($surname))
    case ($node[@type = "corporate"]) return 
      (<forename type="first"/>,
      for $orgname in $node/m:namePart
      return  <surname>{ normalize-space($orgname) }</surname>)
    default return normalize-space($node)
  }</persName>
};

(:
: @param élément(s) name
: @return cette fonction gère l'affichage des éditeurs scientifiques dans le <monogr>. 
:)
declare function local:getEditorScientific($node as element(m:name)*) {
  <editor>{ concat( normalize-space($node/m:namePart[@type = 'given']), ' ', normalize-space($node/m:namePart[@type = 'family'])) }</editor>
};

(:
: @param élément(s) namePart
: @return cette fonction gère l'encodage du prénom
:)
declare function local:getForename($node as element(m:namePart)*) {
  <forename>{ normalize-space($node[@type = 'given']) }</forename> 
};

(:
: @param élément(s) namePart
: @return cette fonction gère l'encodage du nom de famille
:)
declare function local:getSurname($node as element(m:namePart)*) {
  if ($node[@type = 'family']) 
  then <surname>{ normalize-space($node[@type = 'family']) }</surname>
  else ()
};

(:
: @param élément(s) name
: @return cette fonction permet d'intégrer les éléments spécifiques à un auteur:
: son adresse mail, son idhal, son identifiant halauthor, et son affiliation.
: Ces informations sont collectées dans la base "auteurs", après comparaison du nom / prénom dans la base et des variables nom /prénom en tête de ce script.
:)
declare function local:getComplementAuthor($node as element(tei:persName)*) {
  let $auteur := $node
  return
    (if ($auteur/tei:email) then <email>{ normalize-space($auteur/tei:email) }</email> else (),
    if ($auteur/tei:idno[@type = 'idhal']) then
      for $idhal in $auteur/tei:idno[@type = 'idhal']
      return <idno type='idhal'>{ normalize-space($idhal) }</idno> else (),
    if ($auteur/tei:idno[@type = 'halauthorid']) then
      for $halauthorid in $auteur/tei:idno[@type = 'halauthorid']
      return <idno type='halauthorid'>{ normalize-space($halauthorid) }</idno> else (),
    if ($auteur/tei:idno[@type = 'ORCID']) then
      for $orcid in $auteur/tei:idno[@type = 'ORCID']
      return <idno type='ORCID'>{ normalize-space($orcid) }</idno> else (),
    if ($auteur/tei:affiliation[@ref]) then 
      for $affiliation in $auteur/tei:affiliation[@ref]
      return
        <affiliation ref="{ normalize-space($affiliation/@ref) }"/> else () )
};

(:
: @return cette fonction donne la date à laquelle la référence a été écrite, pour l'indiquer dans le editionStmt > edition > date.
:)
declare function local:getwhenWritten($node as element()*, $option as xs:string?) {
  switch ($option)
  case ($option[. = 'book']) return <date type="whenWritten">{ normalize-space($node/m:originInfo/m:copyrightDate) }</date>
  case ($option[. = 'bookSection']) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:originInfo/m:copyrightDate) }</date>
  case ($option[. = 'conferencePaper']) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateCreated) }</date>
  case ($option[. = 'dictionaryEntry']) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateCreated) }</date>
  case ($option[. = 'encyclopediaArticle']) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateCreated) }</date>
  case ($option[. = 'journalArticle']) return 
    if ($node/m:relatedItem/m:part/m:date)
    then <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date>
    else <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateIssued) }</date>
  case ($option[. = "magazineArticle"]) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date>
  case ($option[. = 'newspaperArticle']) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date>
  default return ()
    
};

(:
: @return cette fonction renvoie la date de la référence, telle qu'elle est donnée dans le imprint > date
:)
declare function local:getDate($node as element(m:mods)*, $option as xs:string?) {
  switch ($option)
  case ($option[. = 'book']) return <date type="datePub">{ normalize-space($node/m:originInfo/m:copyrightDate) }</date>
  case ($option[. = 'bookSection']) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:originInfo/m:copyrightDate) }</date>
  case ($option[. = 'conferencePaper']) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateCreated) }</date>
  case ($option[. = 'dictionaryEntry']) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateCreated) }</date>
  case ($option[. = 'encyclopediaArticle']) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateCreated) }</date>
  case ($option[. = "journalArticle"]) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date>
  case ($option[. = "magazineArticle"]) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date>
  case ($option[. = "newspaperArticle"]) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date> 
  default return ()
    
};

(:
: @param élément mods
: @param options de type chaîne de caractère pour définir le type de publication dont il est question (book, bookSection, etc.)
: @return cette fonction permet de construire correctement le niveau analytic de la référence en fonction du type de la publication.
:)
declare function local:getAnalytic($node as element(m:mods), $options as xs:string) {
  switch ($options)
  case ($options[. = 'book']) return 
    ( local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, 'analytic') )
  case ($options[. = 'bookSection']) return 
    ( local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  case ($options[. = 'conferencePaper']) return 
    ( local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  case ($options[. = 'dictionaryEntry']) return 
    ( local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  case ($options[. = 'encyclopediaArticle']) return 
    ( local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  case ($options[. = 'journalArticle']) return
    (local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  case ($options[. = 'magazineArticle']) return
    (local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  case ($options[. = 'newspaperArticle']) return
    (local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  default return () 
};

(:
: @param élément mods
: @param options de type chaîne de caractère pour définir le type de publication dont il est question (book, bookSection, etc.)
: @return cette fonction permet de construire correctement le niveau monographique (monogr) de la référence en fonction du type de la publication.
:)
declare function local:getMonogr($node as element(m:mods)*, $options as xs:string) {
  switch ($options)
  case ($options[. = 'book']) return
    (local:getTitles($node/m:titleInfo[1], 'book'),
    if ($node/m:name/m:role/m:roleTerm = 'edt') then local:getAuthors($node/m:name[m:role/m:roleTerm = 'edt'], '') else (),
    local:getImprint($node/m:originInfo, $options) )
  case ($options[. = 'bookSection']) return 
    (local:getTitles($node/m:relatedItem/m:titleInfo, 'monogr'),
    local:getAuthors($node/m:relatedItem/m:name, ''), 
    if ($node/m:relatedItem/m:originInfo) then local:getImprint($node/m:relatedItem/m:originInfo, $options) else ())
  case ($options[. = 'conferencePaper']) return 
    (local:getTitles($node/m:relatedItem/m:titleInfo, 'monogr'),
    local:getAuthors($node/m:relatedItem/m:name, ''), 
    if ($node/m:relatedItem/m:originInfo) then local:getImprint($node/m:relatedItem/m:originInfo, $options) else ())
  case ($options[. = 'dictionaryEntry']) return 
    (local:getTitles($node/m:relatedItem/m:titleInfo, 'monogr'),
    local:getAuthors($node/m:relatedItem/m:name, ''), 
    if ($node/m:relatedItem/m:originInfo) then local:getImprint($node/m:relatedItem/m:originInfo, $options) else ())
  case ($options[. = 'encyclopediaArticle']) return 
    (local:getTitles($node/m:relatedItem/m:titleInfo, 'monogr'),
    local:getAuthors($node/m:relatedItem/m:name, ''), 
    if ($node/m:relatedItem/m:originInfo) then local:getImprint($node/m:relatedItem/m:originInfo, $options) else ())
  case ($options[. = "journalArticle"]) return
    (local:getTitles($node/m:relatedItem/m:titleInfo[1], 'journalArticle'),
    if ($node/m:relatedItem/m:name) then local:getAuthors($node/m:relatedItem/m:name, '') else (),
    local:getImprint($node/m:relatedItem, $options) )
  case ($options[. = "magazineArticle"]) return
    (local:getTitles($node/m:relatedItem/m:titleInfo[1], 'magazineArticle'),
    if ($node/m:relatedItem/m:name) then local:getAuthors($node/m:relatedItem/m:name, '') else (),
    local:getImprint($node/m:relatedItem, $options) )
  case ($options[. = "newspaperArticle"]) return
    (local:getTitles($node/m:relatedItem/m:titleInfo[1], 'newspaperArticle'),
    if ($node/m:relatedItem/m:name) then local:getAuthors($node/m:relatedItem/m:name, '') else (),
    local:getImprint($node/m:relatedItem, $options) )    
  default return ()
};

(:
: @param élément(s)
: @param options de type chaîne de caractère pour définir le type de publication dont il est question (book, bookSection, etc.)
: @return cette fonction permet de construire correctement les informations relatives à la publication (imprint) de la référence en fonction de son type.
:)
declare function local:getImprint($node as element()*, $options as xs:string) {
  <imprint>{
    switch ($options)
    case ($options[. = "book"]) return
      (if ($node/m:publisher) then local:getPublisher($node/m:publisher) else (),
      if ($node/m:place) then local:getPubPlace($node/m:place) else (),
      if ($node/parent::node()/m:part) then local:getBiblScope($node/parent::node()/m:part) else (),
      if ($node/ancestor::m:mods/m:physicalDescription) then local:getExtent($node/ancestor::m:mods/m:physicalDescription) else (),
      local:getDate($node/ancestor::m:mods, $options) )
    case ($options[. = "bookSection"]) return
      (if ($node/m:publisher) then local:getPublisher($node/m:publisher) else (),
      if ($node/m:place) then local:getPubPlace($node/m:place) else (),
      if ($node/parent::node()/m:part) then local:getBiblScope($node/parent::node()/m:part) else (),
      local:getDate($node/ancestor::m:mods, $options) )
    case ($options[. = "conferencePaper"]) return
      (if ($node/m:publisher) then local:getPublisher($node/m:publisher) else (),
      if ($node/m:place) then local:getPubPlace($node/m:place) else (),
      if ($node/parent::node()/m:part) then local:getBiblScope($node/parent::node()/m:part) else (),
      local:getDate($node/ancestor::m:mods, $options) )
    case ($options[. = "dictionaryEntry"]) return
      (if ($node/m:publisher) then local:getPublisher($node/m:publisher) else (),
      if ($node/m:place) then local:getPubPlace($node/m:place) else (),
      if ($node/parent::node()/m:part) then local:getBiblScope($node/parent::node()/m:part) else (),
      local:getDate($node/ancestor::m:mods, $options) )
    case ($options[. = "encyclopediaArticle"]) return
      (if ($node/m:publisher) then local:getPublisher($node/m:publisher) else (),
      if ($node/m:place) then local:getPubPlace($node/m:place) else (),
      if ($node/parent::node()/m:part) then local:getBiblScope($node/parent::node()/m:part) else (),
      local:getDate($node/ancestor::m:mods, $options) )
    case ($options[. = "journalArticle"]) return
      ( local:getBiblScope($node/m:part),
      if ($node/m:part/m:date) then local:getDate($node/ancestor::m:mods, $options) else () )
    case ($options[. = "magazineArticle"]) return
      ( local:getBiblScope($node/m:part),
      if ($node/m:part/m:date) then local:getDate($node/ancestor::m:mods, $options) else () )
    case ($options[. = "newspaperArticle"]) return
      (if ($node/m:originInfo/m:publisher) then local:getPublisher($node/m:originInfo/m:publisher) else (), 
      if ($node/m:part) then local:getBiblScope($node/m:part) else (),
      if ($node/m:part/m:date) then local:getDate($node/ancestor::m:mods, $options) else () )
   default return ()
  }</imprint>
};

(:
: @param element(s) place
: @return cette fonction donne le lieu de publication (pour un livre ou un chapitre de livre)
:)
declare function local:getPubPlace($node as element(m:place)*) {
  for $place in $node
  return 
    <pubPlace>{ normalize-space($place) }</pubPlace>
};

(:
: @param element(s) publisher
: @return cette fonction donne l'éditeur commercial d'une publication (pour un livre ou un chapitre de livre)
:)
declare function local:getPublisher($node as element(m:publisher)*) {
  for $publisher in $node
  return 
    <publisher>{ normalize-space($publisher) }</publisher>
};

(:
: @param element(s) language
: @return cette fonction donne la langue de référence de la publication
:)
declare function local:getLang($node as element(m:language)*) {
  let $lang := $node/m:languageTerm
  return 
    normalize-space($lang)
};


(:
: @param element(s) 
: @return cette fonction tente de donner la langue d'un élément particulier de la référence, qui peut être différent de la langue générale de la notice (par exemple, note du résumé etc.)
: @error si la langue dans la notice n'est pas renseigné, la langue proposée par défaut peut-être fautive.
:)
declare function local:getLanguage($node) {
  if ($node/@lang) 
  then $node/@lang 
  else 
    if ($node/parent::m:mods//m:name/m:namePart[1]/@lang)
    then $node/parent::m:mods//m:name/m:namePart[1]/@lang 
    else 'fr'
};

(:
: @param element(s) 
: @return cette fonction permet de donner les mots clefs relatifs à une référence, que ce soit:
: - les mots clefs d'un auteur (dans la base "auteurs")
: - ou enfin les mots clefs déjà donnés dans la référence Zotero-Mods
:)
declare function local:getKeywords($node as element()*) {
  if (local:getPersonalKeywords($node) or $node/m:subject)
  then
    <keywords scheme="author">
      { local:getPersonalKeywords($node) }
      {for $key in $node/m:subject
      return
        <term xml:lang="{ local:getLanguage($node[1]) }">{ normalize-space($key) }</term>}
    </keywords>
  else ()
};

(:
: @param element mods
: @return cette fonction sélectionne les mots clefs spécifiques à un auteur, et les insère dans la référence
:)
declare function local:getPersonalKeywords($node as element(m:mods)) {
  for $auteur in db:open('auteurs')//tei:person/tei:persName
  where $auteur/tei:surname = $surname and $auteur/tei:forename = $forename
  return
    if ($auteur/tei:term[not(@key)])
    then 
      for $keyword in $auteur/tei:term[not(@key)]
      return
        $keyword
    else ()
};

(:
: @param élément(s) abstract
: @return cette fonction renvoie le résumé de la référence
: @error la langue définie pour le résumé peut être fautive
:)
declare function local:getAbstract($node as element(m:abstract)*) {
  let $lang := local:getLang($node/ancestor::m:mods/m:language)
  return
    if ($node)
    then
      <abstract xml:lang="{$lang}">{ normalize-space($node) }</abstract>
    else ()
};

(:
: @param élément(s) part
: @return cette fonction permet de mettre en forme les numérotations d'une référence (volume, pages, etc.)
:)
declare function local:getBiblScope($node as element(m:part)*) {
  local:getDetail($node/m:detail),
  local:getPages($node/m:extent)   
};

(:
: @param élément(s) detail
: @return cette fonction permet de mettre en forme les numérotations d'une référence de type "issue" et "volume".
:)
declare function local:getDetail($node as element(m:detail)*) {
  for $biblScope in $node
  let $unit := $biblScope/@type
  return 
    switch ($unit)
    case ($unit[. = "issue"]) return <biblScope unit="issue">{ normalize-space( $biblScope ) }</biblScope>
    case ($unit[. = "volume"]) return <biblScope unit="volume">{ normalize-space( $biblScope ) }</biblScope>
    default return <biblScope unit="{ $unit }">{ normalize-space( $biblScope ) }</biblScope>
};

(:
: @param élément(s) detail
: @return cette fonction permet de mettre en forme les numéros de page d'une référence.
:)
declare function local:getPages($node as element(m:extent)*) {
  for $page in $node
  let $unit := $page/@unit
  return
    if ($unit = 'pages') 
    then
      if ($page/m:start = $page/m:end)
      then <biblScope unit="pp">{ local:getStartPage($page/m:start) }</biblScope>
      else <biblScope unit="pp">{ concat(local:getStartPage($page/m:start), '-', local:getEndPage($page/m:end)) }</biblScope>
    else 
      <biblScope unit='{ $unit }'>{ concat(local:getStartPage($page/m:start), '-', local:getEndPage($page/m:end)) }</biblScope>
};

(:
: @param élément start
: @return cette fonction permet de mettre en forme le premier numéro de page d'une référence.
:)
declare function local:getStartPage($node as element(m:start)*) {
  normalize-space($node)
};

(:
: @param élément end
: @return cette fonction permet de mettre en forme le dernier numéro de page d'une référence.
:)
declare function local:getEndPage($node as element(m:end)*) {
  normalize-space($node)
};

(:
: @param élément physicalDescription
: @return cette fonction permet de donner le nombre de pages d'une référence.
:)
declare function local:getExtent($node as element(m:physicalDescription)*) {
  for $extent in $node/m:extent
  return
    <biblScope unit="pp">{ normalize-space($extent) }</biblScope>
};

(:
: @param élément note
: @return cette fonction permet de donner les notes attenantes à une référence.
:)
declare function local:getNotes($node as element(m:note)*) {
  for $note in $node 
  return
    <note type="commentary">{ normalize-space($note) }</note>
};

(:
: @param élément location
: @return cette fonction permet de donner le lien hypertexte vers la référence si elle est disponible en ligne.
:)
declare function local:getLocation($node as element(m:location)*) {
  for $location in $node
  return
    <ref type="publisher">{ normalize-space($location) }</ref>
};

(:
: @param élément mods
: @return cette fonction permet de donner les domaines de recherche propre à un chercheur si l'on dispose de l'information dans la base "auteurs".
:)
declare function local:getClassCode($node as element(m:mods)*) {
  for $auteur in db:open('auteurs')//tei:person/tei:persName
  where $auteur/tei:surname = $surname and $auteur/tei:forename = $forename
  return
    if ($auteur/tei:term[@key]) 
    then 
      for $term in $auteur/tei:term[@key]
      return
        <classCode scheme="halDomain" n="{ $term/@n }">{ normalize-space($term) }</classCode>
    else ()
};

(:
: @return cette fonction permet de définir la typologie HAL d'une référence (Book, etc.).
:)
declare function local:getHalTypology($node as xs:string) {
  switch ($node)
  case ($node[. = "book"]) return <classCode scheme="halTypology" n="OUV">Books</classCode>
  case ($node[. = "bookSection"]) return <classCode scheme="halTypology" n="COUV">Book section</classCode>
  case ($node[. = "dictionaryEntry"]) return <classCode scheme="halTypology" n="COUV">Book section</classCode>
  case ($node[. = "conferencePaper"]) return <classCode scheme="halTypology" n="COUV">Book section</classCode>
  case ($node[. = "encyclopediaEntry"]) return <classCode scheme="halTypology" n="COUV">Book section</classCode>
  case ($node[. = "journalArticle"]) return <classCode scheme="halTypology" n="ART">Journal articles</classCode> 
  case ($node[. = "magazineArticle"]) return <classCode scheme="halTypology" n="ART">Journal articles</classCode>
  case ($node[. = "newspaperArticle"]) return <classCode scheme="halTypology" n="ART">Journal articles</classCode>
  default return ()
};

(:
: @param élément mods
: @return cette fonction permet de construire les références complètes.
:)
declare function local:getBiblFull($node as element(m:mods)*, $options as xs:string) {
  for $bibl in $node
  let $genre := $options
  return
    <biblFull>
      <titleStmt>{ 
        local:getTitles($bibl/m:titleInfo, 'titleStmt'), 
        local:getAut(),
        local:getDepositor($bibl/m:name)
      }</titleStmt>
      <editionStmt>
        <edition>
          {local:getwhenWritten($bibl, $genre)}
        </edition>
      </editionStmt>
        <notesStmt>{
          local:getNotes($node/m:note),
          <note type="audience" n="1">Non spécifiée</note>,
          <note type="popular" n="0">No</note>,
          <note type="peer" n="1">Yes</note>
        }</notesStmt>
      <sourceDesc>
        <biblStruct>
          <analytic>{
            local:getAnalytic($bibl, $genre)
          }</analytic>
          <monogr>{
            local:getMonogr($bibl, $genre)
          }</monogr>
          { if ($bibl/m:location) then local:getLocation($bibl/m:location) else () }
        </biblStruct>
      </sourceDesc>
      <profileDesc>{
        <langUsage>
          <language ident="{ local:getLang($bibl/m:language) }"/>
        </langUsage>,
        <textClass>
          { local:getKeywords($bibl) }
          { local:getClassCode($bibl) }
          { local:getHalTypology($options) }
        </textClass>,
        local:getAbstract($bibl/m:abstract)
      }</profileDesc>
    </biblFull>
};

(:
: @param élément mods
: @return cette fonction permet de construire le document TEI complet dans le fichier /static/ dans BaseX.
: @return le document créé porte le nom: nom.xml avec nom = $surname
:)
let $doc :=
  <TEI xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:hal="http://hal.archives-ouvertes.fr/"
        xsi:schemaLocation="http://www.tei-c.org/ns/1.0 https://api.archives-ouvertes.fr/documents/aofr-sword.xsd">
    <text>
      <body>
        <listBibl>{
          for $bibl at $n in db:open($bdd)/m:modsCollection/m:mods
          let $genre := $bibl/m:genre[@authority='zotero' or @authority='local']
          where not($bibl//m:location/m:url[contains(., "hal")] or $bibl/m:note[contains(., "hal")])
          let $fileName := concat($surname, $n, ".xml")
          return
            local:getBiblFull($bibl, $genre)
        }</listBibl>
      </body>
    </text>
  </TEI>
return
  file:write(concat(file:current-dir(), '/webapp/static/', $surname, ".xml"), $doc)


  







