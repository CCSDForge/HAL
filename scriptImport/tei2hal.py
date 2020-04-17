import requests
''' script python pour importer des notices via SWORD
SWORD HAL documentation : https://api.archives-ouvertes.fr/docs/sword
'''

url = 'https://api.archives-ouvertes.fr/sword/hal'
#url = 'https://api-preprod.archives-ouvertes.fr/sword/hal'

filepath = '../folderTei/teiFile.xml'

head = {
	'Packaging': 'http://purl.org/net/sword-types/AOfr',
   	'Content-Type': 'text/xml',
   	'X-Allow-Completion' :None
	}
# si pdf  : Content-Type : application/zip 

xmlfh = open(filepath, 'r', encoding='utf-8')
xmlcontent = xmlfh.read() #le xml doit être lu, sinon temps d'import très long
xmlcontent = xmlcontent.encode('UTF-8')

if len(xmlcontent) < 10 : 
	print('file not loaded')
	quit()

response = requests.post(url, headers = head, data = xmlcontent, auth=('login', 'mdp'))
print(response.text)

xmlfh.close()
