from urllib import urlencode
import oauth2 as oauth
import certifi
from harvestTixFromXML2 import harvest_tix, generate_tix_body

# advance api access
#http://allura.sourceforge.net/migration.html

PROJECT='testesmfmigrati'

CONSUMER_KEY='3a3069ed662030e15794'
CONSUMER_SECRET='049681debe988488ce9d784ca154437f1890aa5153bcd59d020d9c9aeda627d2bb24f86e8e50b4f9'

ACCESS_KEY='af7f752dc0969bf30bcd'
ACCESS_SECRET='ccd39ea358694ec6ba4e21a716a954a33b1f68ed5c33bdea6ec477e387a45da9ec5073c8babd7e3e'

URL_BASE='http://sourceforge.net/rest/'

consumer = oauth.Consumer(CONSUMER_KEY, CONSUMER_SECRET)
access_token = oauth.Token(ACCESS_KEY, ACCESS_SECRET)
client = oauth.Client(consumer, access_token)
client.ca_certs = certifi.where()

# create the ticket list from the gigantic XML file of ESMF tickets
tixlist = harvest_tix('esmf_export.xml')

# TODO: use the import api
#   - 72 hour time limit
#   - adds the ability to set the creation date and user

# test
body = generate_tix_body(tixlist[41])
print body
# submit the test ticket to the dummy archive
response = client.request(
    URL_BASE + 'p/' + PROJECT + '/tickets/new', 'POST',
    body=urlencode(body))
print "Done.  Response was:"
print response

'''
# push all tickets to sourceforge
for tix in tixlist:
    try:
        body = generate_tix_body(tix)
        # submit the test ticket to the dummy archive
        response = client.request(
            URL_BASE + 'p/' + PROJECT + '/tickets/new', 'POST',
            body=urlencode(body))
    except:
        print "ticket #"+str(tix.find.('id').text)
'''