<?php

//$content est une page web contenant au minimum une balise HAL
//[HAL](url haltool)[/HAL]
//Pour construire une url Haltools, aller sur https://haltools.archives-ouvertes.fr/?action=export
//Documentation de haltools : https://iww.inria.fr/hal/aide/spip.php?rubrique59
function traitement_HAL($content)
{
	//Correction du probleme de lien relatif au css de HAL, on le remplace par un lien absolu
	$content = preg_replace('/css=\.\.(.)*?/','css=https://haltools.inria.fr/$1', $content);

	//Remplacement des balises HAL par le contenu de la page, fonctionne pour le domaine inria et inrialpes
	if(preg_match("/\[HAL\]http(s)?:\/\/haltools.inria(lpes)?.fr((.|\n)*?)\[\/HAL\]/",$content,$matches))
	{
		//Récupération paramètres de l'url http://haltools.inria.fr/... 
		$options_url=$matches[3];
		//Assemblement nouvelle url
		$url = 'http://haltools.inria.fr'.$options_url;
		//Nettoyage de l'url si besoin (&amp; -> &, ' ' -> '')
		$url_sans_espace=str_replace(' ', '',$url);
		$url_propre=str_replace('&amp;', '&',$url_sans_espace);
		//Récupération du contenu de la page
		$s=preg_replace('/\n/',' ',file_get_contents($url_propre));
		//Remplacement dans le contenu
		$content = preg_replace('/\[HAL\]http(s)?:\/\/haltools.inria(lpes)?.fr((.|\n)*?)\[\/HAL\]/',$s, $content);
	}
	return $content;
}

?>
