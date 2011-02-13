<?php
//$XPATH = '//table[@class="embedded" and @width="100%"]/tr[position() > 3 and position() < last()]';
$XPATH = '//table[@class="embedded" and @width="100%"]/tbody[1]/tr[position() > 1]';
$XPATHS = array(
	'title' => 'td[2]/a[1]/b[1]',
	'size' => 'td[5]/nobr[1]',
	'torrent_file_url' => 'td[2]/a[3]',
	'details_url' => 'td[2]/a[1]',
	'seeds_count' => 'td[6]/nobr[1]/b[1]/font[1]',
);
$CODE="cp1251";

function getXMLByDataHTML($data)
{
    $doc = new DOMDocument();
    $doc->strictErrorChecking = FALSE;
    @$doc->loadHTML($data);
    $xml = simplexml_import_dom($doc);
    return $xml;
}

$html = file_get_contents('page.html');
#$html = iconv($CODE, 'utf8', $html);
$html = mb_convert_encoding($html,'HTML-ENTITIES', $CODE);
$xml = getXMLByDataHTML($html);
$search_results = $xml->xpath($XPATH);
//var_dump($search_results);

$torrents = array();
foreach ($search_results as $key=>$value)
{
	$tmp_array = array();
	foreach ($XPATHS as $xpath_key => $xpath_value)
	{
		$tmp_array[$xpath_key] = $value->xpath($xpath_value);
	}
	$torrents[] = $tmp_array;
}
var_dump($torrents[0]);

