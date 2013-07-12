#!/usr/bin/env python

import sys

from urllib import urlencode
import oauth2 as oauth
import certifi
from harvestTixFromXML import harvest_tix

# get the arguments
restart = False
restart_ind = 0

if len(sys.argv) is 3:
    restart = bool(sys.argv[1])
    restart_ind = int(sys.argv[2])
elif len(sys.argv) is not 1:
    raise SyntaxError("Usage:\n\tpython pushTix2SF.py <restart: (True or False)> <restart index: (#)>")

print 'Restart = {0}'.format(restart)
print 'Restart index = {0}'.format(restart_ind)


# advance api access
#http://allura.sourceforge.net/migration.html

PROJECT='testesmfmigrati'

CONSUMER_KEY='3a3069ed662030e15794'
CONSUMER_SECRET='049681debe988488ce9d784ca154437f1890aa5153bcd59d020d9c9aeda627d2bb24f86e8e50b4f9'

ACCESS_KEY='af7f752dc0969bf30bcd'
ACCESS_SECRET='ccd39ea358694ec6ba4e21a716a954a33b1f68ed5c33bdea6ec477e387a45da9ec5073c8babd7e3e'

URL_BASE='http://sourceforge.net/rest/'

#API Ticket: tckc8a15688ad3d323ade16
#Secret Key: 915d0d399f8957631e5e8a9c39b646799f609aa2939b08bdea5ebe0a4344df4a133bbd22b6181e76

#ACCESS_KEY='tckc8a15688ad3d323ade16'
#ACCESS_SECRET='915d0d399f8957631e5e8a9c39b646799f609aa2939b08bdea5ebe0a4344df4a133bbd22b6181e76'


consumer = oauth.Consumer(CONSUMER_KEY, CONSUMER_SECRET)
access_token = oauth.Token(ACCESS_KEY, ACCESS_SECRET)
client = oauth.Client(consumer, access_token)
client.ca_certs = certifi.where()


# create the ticket list from the gigantic XML file of ESMF tickets
tixlist = harvest_tix('esmf_export.xml')

'''
# sumbit 100 blank tickets
body = {
        # generic information
        'ticket_form.summary' : "blank",
        'ticket_form.description' : "blank",
        'ticket_form.status' : "closed",
        'ticket_form.assigned_to' : "nobody"
        }

for i in range(100):
    print "Submitting ticket #{0}".format(i)
    # submit the test ticket to the dummy archive
    url_tracker = URL_BASE + 'p/' + PROJECT + '/tickets/new'
    url_api = URL_BASE + 'p/' + PROJECT + '/tickets/perform_import' 
    response = client.request(url_tracker, 'POST', body=urlencode(body))
    print "Done.  Response was:"
    print "\n"+str(response)+"\n"
'''

'''
done = False
for tix in tixlist:
    if not done:
        if tix['ticket_form.custom_fields._estimated_weeks_to_completion'] == 2:
            body = tix
            done = True

# submit the test ticket to the dummy archive
url_tracker = URL_BASE + 'p/' + PROJECT + '/tickets/new'
url_api = URL_BASE + 'p/' + PROJECT + '/tickets/perform_import' 
response = client.request(url_tracker, 'POST', body=urlencode(body))
print "Done. Response was:"
print "\n"+str(response)+"\n"
print body
'''

ind = 0
# push all tickets to sourceforge
for tix in tixlist:
    if restart and ind < restart_ind:
        ind += 1
        continue
    else:
        try:
            # submit the test ticket to the dummy archive
            response = client.request(
                URL_BASE + 'p/' + PROJECT + '/tickets/new', 'POST',
                body=urlencode(tix))
            print "Ticket #{0} Done. Response was:".format(ind)
            print str(response)+"\n"
        except:
            print "\nTicket #{0} Failed!\n".format(ind)
        ind += 1

