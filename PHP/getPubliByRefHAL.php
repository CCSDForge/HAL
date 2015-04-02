<?php
include_once('isLesia.php');
include_once('strings.php');
include_once('ref_externes.php');
include_once('parseAffiliation.php');

/* Retrouve un nom de pays en anglais à partir de son countryCode (fr, en) */
function getCountryFromCode($country_code) {
	/* memoisation de la requête */
	static $countries = null;
	
	if ($countries == null) {
		$countries = array();
		$res = fopen(APP_PATH . '/src/countryInfo.csv', 'r');
		if ($res === false) return false;
		while (($data = fgetcsv($res, 1000, "\t")) !== false) {
			if (substr($data[0],0,1) == '#') continue;
			/* le 4è champ est le nom du pays en anglais */
			$countries[strtolower($data[0])] = $data[4];
		}
	}
	return isset($countries[strtolower($country_code)]) ? $countries[strtolower($country_code)] : '';
}

/* piqué là : http://www.phpro.org/examples/Convert-Object-To-Array-With-PHP.html 
 * fonction pour transformer n'importe quel objet en tableau PHP
 * */
function objectToArray( $object ) {
	if( !is_object( $object ) && !is_array( $object ) ) {
		return $object;
	}
	if( is_object( $object ) ) {
		$object = get_object_vars( $object );
	}
	return array_map( 'objectToArray', $object );
}

/* envoie la liste des affiliations trouvées à parseAffiliations
 * et repositionne le origine_affiliation
 */
function getAffiliations($affiliations) {
	$ret = array();
	foreach($affiliations as $key => $aff) {
		$new_aff = parseAffiliation($aff['origine_affiliation'], ';');
		//error_log($new_aff['nb_resultats']);
		//error_log(print_r($new_aff[0], true));
		if (intval($new_aff['nb_resultats']) >= 1 && isset($new_aff[0])) {
			$ret[$key] = $new_aff[0];
			$ret[$key]['origine_affiliation'] = $aff['origine_affiliation'];
		}
	}
	return $ret;
}

/* remplace à la volée les affiliations brutes par celles parsées pour chaque
 * affiliation de chaque auteur
 */
function fixAffiliations(&$auteurs, $labos) {
	foreach ($auteurs as $key_auteur => $auteur) {
		if (isset($auteur['affiliations'])) {
			foreach($auteur['affiliations'] as $key_aff => $affiliation) {
				$id = isset($labos[$affiliation['id']]) 
					? $affiliation['id']
					: null;
				if ($id) {
					$auteurs[$key_auteur]['affiliations'][$key_aff] = $labos[$id];
				}
			}
		}
	}
}

/* transforme les principaux attributs bruts trouvés dans le tableau
 * envoyé par HAL en attributs utilisés par Publesia
 */
function rosettise($publi) {
	$ret = array();
	$rosette = array(
			'title_s/0' => 'titre',
			'abstract_s/0' => 'resume',
			'conferenceTitle_s' => 'titre_conference',
			'conferenceStartDate_s' => 'date_conference',
			'city_s' => 'lieu_conference',
			'halId_s' => 'ref_hal',
			'docType_s' => 'code_type',
			'scientificEditor_s/0' => 'editeur_scientifique',
			'bookTitle_s' => 'titre_ouvrage',
			'journalTitle_s' => 'nom_revue',
			'page_s' => 'pagination',
			'doiId_s' => 'ref_doi',
			'volume_s' => 'volume',
			'page_s' => 'pagination',
			'producedDateY_i' => 'annee',
			'journalPublisher_s' => 'editeur_scientifique'
	);
	
	$rosette_types = array(
			'ART' => 'ACL',
			'COMM' => 'COM',
			'THESE' => 'THS',
			'COUV' => 'OSC',
			'PATENT' => 'BREV',
			'DOUV' => 'DO',
			'HDR' => 'HDR',
			'OUV' => 'OS',
	);
	
	foreach ($rosette as $src => $dest) {
		$splitted = explode('/', $src);
		if (count($splitted) > 1 && isset($publi[$splitted[0]][$splitted[1]])) {
			$ret[$dest] = $publi[$splitted[0]][$splitted[1]];
		}
		if (count($splitted) == 1 && isset($publi[$splitted[0]]))  {
			$ret[$dest] = $publi[$splitted[0]];
		}
	}
	
	/* type de publication */
	if (isset($rosette_types[$ret['code_type']]))
		$ret['code_type'] = $rosette_types[$ret['code_type']];
	else 
		$ret['code_type'] = 'AP';
	
	/* année */
	if (isset($ret['date_conference'])) $ret['annee'] = substr($ret['date_conference'], 0, 4);
	
	/* collection */
	$coll = array();
	foreach ($publi['collCodeName_fs'] as $codeName) {
		$line = explode('_FacetSep_', $codeName);
		$coll[] = sprintf("%s (%s)", $line[1], $line[0]);
	}
	$ret['collection'] = implode(';', $coll);
	
	return $ret;
}

function getAuteurs($publi) {
	$auth_field_list = array(
			'authId_i' => 'hal_id',
			'authLastName_s' => 'nom',
			'authFirstName_s' => 'prenom',
	);
	
	/* création des auteurs */
	$tmp = array();
	foreach ($auth_field_list as $src => $dest) {
		$cpt_auteur = 0;
		foreach ($publi[$src] as $val) {
			if (empty($tmp[$cpt_auteur])) $tmp[$cpt_auteur] = array();
			$tmp[$cpt_auteur++][$dest] = $val;
		}
	}
	
	/* remise en forme des auteurs */
	$tmp2 = array();
	foreach ($tmp as $key => $auteur) {
		unset($auteur[$key]);
		$tmp2[$auteur['hal_id']] = $auteur;
	}
	
	/* récupération des laboratoires */
	$laboratoires = array();
	/* IDs */
	foreach($publi['labStructId_i'] as $structId) {
		if (empty($laboratoires[$structId])) 
			$laboratoires[$structId] = array('id' => $structId);
		else {
			/* pour gérer les doublons
			 * on doit passer par une boucle en cas de triples ou plus
			 * */
			for ($cpt = 0 ; true ; $cpt++) {
				$key = sprintf("skip-%d", $cpt);
				if (empty($laboratoires[$key])) {
					$laboratoires[$key] = array('skip-id' => $structId);
					break;
				}
			}
		}
	}
	/* Noms */
	foreach($publi['labStructIdName_fs'] as $structName) {
		$line = explode('_FacetSep_', $structName);
		$laboratoires[$line[0]]['nom'] = $line[1]; 
	}
	/* Adresses */
	$keys = array_keys($laboratoires);
	$cpt_adresses = 0;
	for ($cpt = 0 ; $cpt < count($publi['labStructValid_s']) ;  $cpt++) {
		if ($publi['labStructValid_s'][$cpt] == 'VALID') {
			$laboratoires[$keys[$cpt]]['adresse'] = $publi['labStructAddress_s'][$cpt_adresses++];
		} else {
			$laboratoires[$keys[$cpt]]['adresse'] = '';
		}
	}
	/* Pays */
	$keys = array_keys($laboratoires);
	for ($cpt = 0 ; $cpt < count($publi['labStructCountry_s']) ;  $cpt++) {
		$laboratoires[$keys[$cpt]]['pays'] = getCountryFromCode($publi['labStructCountry_s'][$cpt]);
	}
	/* All together */
	foreach ($laboratoires as $key => $labo) {
		/* suppression des labos en doublon */
		if (substr($key, 0, 5) == 'skip-') {
			unset($laboratoires[$key]);
			continue;
		}
		$laboratoires[$key]['origine_affiliation'] = $labo['nom'];
		$laboratoires[$key]['origine_affiliation'] .= ($labo['adresse'] == '')
			? '' 
			: ' ; ' . $labo['adresse'];
		$laboratoires[$key]['origine_affiliation'] .= ($labo['pays'] == '')
			? '' 
			: ' ; ' . $labo['pays'];
	}
	
	/* récupération de l'affiliation */
	foreach($publi['authIdHasStructure_fs'] as $auth_struct) {
		$line = explode('_JoinSep_', $auth_struct);
		$auth = explode('_FacetSep_', $line[0]);
		$hal_id = $auth[0];
		
		$struct = explode('_FacetSep_', $line[1]);
		$struct = array('id' => $struct[0], 'origine_affiliation' => $struct[1]);
		
		if (isset($laboratoires[$struct['id']])) {
			if (empty($tmp2[$hal_id]['affiliations']))
				$tmp2[$hal_id]['affiliations'] = array();
			
			$tmp2[$hal_id]['affiliations'][] = $laboratoires[$struct['id']];
		}
	}
	
	/* dernière remise en forme des auteurs: 1-indexed*/
	$cpt_auteur = 1;
	$auteurs = array();
	foreach ($tmp2 as $auteur) {
		$auteurs[$cpt_auteur++] = $auteur;
	}
	
	/* à transmettre à la fonction pour parser les affiliations */
	$auteurs['laboratoires'] = $laboratoires;
	
	return $auteurs;
}

function getPubliByRefHAL($refHAL, $version = 1) {
	$ret = null;
	
	$url = sprintf(
			"http://api.archives-ouvertes.fr/search/?wt=json&q=halId_s:\"%s\"&q=version_i:\"%d\"&fl=*",
			$refHAL,
			$version);
	$hal = url($url);
	$hal = json_decode($hal);
	$hal = objectToArray($hal);
	
	if (isset($hal['response']['docs'][0])) {
		$publi = $hal['response']['docs'][0];
		$ret = rosettise($publi);
		$ret['auteur'] = getAuteurs($publi);
	}
	
	/* transcodage latin1 */
	array_walk_recursive($ret, function(&$value, $key) {
		if (is_array($value) == false) {
			$value = iconv('UTF-8', 'ISO-8859-1', $value);
		}
	});
	
	/* parseAffiliations */
	$laboratoires_parsed = getAffiliations($ret['auteur']['laboratoires']);
	unset($ret['auteur']['laboratoires']);
	fixAffiliations($ret['auteur'], $laboratoires_parsed);
		
	return $ret;
}
?>
