<?php
/*
 * Ce script prend en entrée un fichier xml au format TEI-HAL, 
 * découpe la TEI en un fichier par biblFull, copie le fichier dans xmlSword 
 * et lance l'import Sword
 * usage : php ImportParLotSword.php -f=fichier_tei.xml -u=HALLogin -p=HALPassword
 * Installation :
 *  ATTENTION, Modifier la variable $SWORD_API_URL et choisir 
 *  - API prod ou preprod
 *  - instance de depôt (remplacer inria par xxx)
 * 	Créer un sous répertoire : xmlSword dans le lequel seront copiés tous les xml utilisés pour l'import Sword
 */ 
$SWORD_API_URL= 'https://api-preprod.archives-ouvertes.fr/sword/inria';
// en prod $SWORD_API_URL= 'https://api.archives-ouvertes.fr/sword/inria';

  function createXpathTEI($domTei) {
	$xpath = new DOMXPath($domTei);
	$xpath->registerNamespace('', "http://www.tei-c.org/ns/1.0");
	$xpath->registerNamespace('tei', "http://www.tei-c.org/ns/1.0");
	$xpath->registerNamespace('hal', "http://hal.archives-ouvertes.fr/");
	$xpath->registerNamespace('xml', "http://www.w3.org/XML/1998/namespace");
	return $xpath;
	}
//récupération des arguments
$options = getopt("f:u:p:",array("required:","required:","required:"));	
if(!(isset($options['f']) && !empty($options['f']) &&
	isset($options['p']) && !empty($options['p']) &&
	isset($options['u']) && !empty($options['u'] )))
{
	exit("Il manque un argument\nUsage : php ImportParLotSword.php -f=fichier_tei.xml -u=HALLogin -p=HALPassword\n");
}
$fileName=$options['f'];
$HAL_USER=$options['u'];
$HAL_PASSWD=$options['p'];
//Est-ce que le fichier qui contient la TEI existe ?
if (!file_exists ( $fileName ))
{
	exit("ERREUR: Le fichier $fileName n'existe pas\n");
}
	
print "========================================================\n";
print "Traitement du fichier : $fileName\n";

$domInterstTei = new DOMDocument();
$domInterstTei->load($fileName); 
$biblFulls = $domInterstTei->getElementsByTagName('biblFull');
if ($biblFulls->length >= 1) {
	print "nb de document=".$biblFulls->length."\n";
	$numXml=0;
	foreach($biblFulls as $biblFull)
	{
    	$xml = new DOMDocument('1.0', 'utf-8');
    	$xml->formatOutput = true;
    	$xml->substituteEntities = true;
    	$xml->preserveWhiteSpace = false;
    	//racine TEI
    	$root = $xml->createElement('TEI');
    	$root->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns', 'http://www.tei-c.org/ns/1.0');
    	$root->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns:hal', 'http://hal.archives-ouvertes.fr/');
    	$xml->appendChild($root);
    	// //////////////////////
    	// text //
    	// //////////////////////
    	$text = $xml->createElement('text');
		$root->appendChild($text);
    	// //////////////////////
    	// text>body>listBibl //
    	// //////////////////////
    	$body = $xml->createElement('body');
		$text->appendChild($body);
    	$lb = $xml->createElement('listBibl');   
		$body->appendChild($lb);
		$bibFullCopy = $xml->importNode($biblFull, true);
		$lb->appendChild($bibFullCopy);
		$nomfic="./xmlSword/".basename($fileName,'.xml')."$numXml.xml";
		$numXml++;
		print "Fichier xml = $nomfic\n";
		$ret=$xml->save($nomfic);
		$xmlContenu=$xml->saveXML();
		$curl = curl_init($SWORD_API_URL );
		curl_setopt($curl, CURLOPT_POST, true);
		curl_setopt($curl, CURLOPT_HEADER, false);
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($curl, CURLINFO_HEADER_OUT, true);
		curl_setopt($curl, CURLOPT_TIMEOUT, 15);
		curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 10);
		$headers=array();
		$headers[]='X-Packaging: http://purl.org/net/sword-types/AOfr';
		$headers[]='Content-Type: text/xml';

		curl_setopt($curl, CURLOPT_HTTPHEADER, $headers);
		curl_setopt($curl, CURLOPT_POSTFIELDS, $xmlContenu);
		curl_setopt($curl, CURLOPT_USERPWD, "$HAL_USER:$HAL_PASSWD");
		$return = curl_exec($curl);
		$httpcode = curl_getinfo($curl,CURLINFO_HTTP_CODE);
		if($return ==FALSE)
		{
			if ($httpcode==401)
				$errStr="Problème d'authentification, mot de passe incorrect.\n";
			else
				$errStr="Problème avec l'API sword, contactez le support technique (erreur http=$httpcode)";
			exit ("ERREUR  : ".$errStr);
		}
		$code = curl_getinfo($curl, CURLINFO_HTTP_CODE);
		try {
		$entry = new \SimpleXMLElement($return);
			$entry->registerXPathNamespace('atom', 'http://www.w3.org/2005/Atom');
			$entry->registerXPathNamespace('sword', 'http://purl.org/net/sword/terms');
			$entry->registerXPathNamespace('hal', 'http://hal.archives-ouvertes.fr/');
			if ( in_array($code, array(200, 201, 202)) ) {
				$id = $entry->id;
				$passwdRes=$entry->xpath('hal:password');
				if (!empty($passwdRes) and is_array($passwdRes) and !empty($passwdRes[0][0]))
				{
					$passwd=$passwdRes[0][0];
				}
				else {
					$passwd='Unknown';
				}
				$linkAttribute=$entry->link->attributes();
				if (!empty($linkAttribute) && isset($linkAttribute['href']) && !empty($linkAttribute['href']))
					$link=$linkAttribute['href'];
				else
				{
					$link="unknown";
				}
				print ("OK : id=>$id,passwd=>$passwd,link=> $link \n");
			} else {
				$err=$entry->xpath('/sword:error/sword:verboseDescription');
				$summaries=$entry->xpath('/sword:error/atom:summary');
				var_dump($summaries[0]);
				print ("ERREUR : Pb sword : ".$err[0][0]."\n");
			}
		} catch (Exception $e) {
			return ("ERREUR : Erreur Web service  : ".$e->getMessage()."\n");
		}
	}
}
else
{
	exit("ERREUR: Le fichier $fileName n'a pas de document\n");
}


		
	

