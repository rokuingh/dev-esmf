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
    print 'Restart = {0}'.format(restart)
    print 'Restart index = {0}\n'.format(restart_ind)

elif len(sys.argv) is not 1:
    raise SyntaxError("Usage:\n\tpython pushTix2SF.py <restart: (True or False)> <restart index: (#)>")

'''
PROJECT='esmf'

CONSUMER_KEY='5da2c9731aaacd3b2880'
CONSUMER_SECRET='d9ed8512ba582c7ef7ab6b34eb744d6c8a27df5dfe8e9c8f45029f8c951aa0880ebf26816ac0789e'

ACCESS_KEY='5a0bc582b8b6c6a38357'
ACCESS_SECRET='48d23fa34b56d8a1cba625c1de43906869c5b28b27100050ebda817dfcd46fbf150391543eb4fb1e'
'''
PROJECT='testesmfmigrati'

CONSUMER_KEY='592778c34012171b0d6d'
CONSUMER_SECRET='4f5399bd2d82c9e524e31cd0a75e64c4459da62adbb0ccc135cbc26596e0adb38a439d0d189debe9'

ACCESS_KEY='c45eb2be45cbe10b7680'
ACCESS_SECRET='4c720e9d9a68a2b581b93e8aca394615c1a50cc78e1bab0800845c63a73a90131c57e39eb8e72b8b'


URL_BASE='http://sourceforge.net/rest/'

consumer = oauth.Consumer(CONSUMER_KEY, CONSUMER_SECRET)
access_token = oauth.Token(ACCESS_KEY, ACCESS_SECRET)
client = oauth.Client(consumer, access_token)
client.ca_certs = certifi.where()


# create the ticket list from the gigantic XML file of ESMF tickets
tixlist = harvest_tix('esmf_export.xml')

'''
# test code to submit selected tickets
body = None
done = False
for tix in tixlist:
    if not done:
        if tix['ticket_form.labels'] == "NUOPC":
            newlist = [tix]
            done = True

newlist = []

for body in newlist:
    # submit a test ticket to the dummy archive
    url_tracker = URL_BASE + 'p/' + PROJECT + '/tickets/new'
    url_api = URL_BASE + 'p/' + PROJECT + '/tickets/perform_import' 
    response = client.request(url_tracker, 'POST', body=urlencode(body))
    print "Done. Response was:"
    print "\n"+str(response)+"\n"
    print body
# end of test code

# submit a bunch of blank tickets
blank_num = 10000
body = {
        # generic information
        'ticket_form.summary' : "",
        'ticket_form.description' : "",
        'ticket_form.status' : "Deleted",
        'ticket_form.assigned_to' : "",
        }

if not restart:
    for i in range(blank_num):
        print "Submitting blank ticket #{0}".format(i)
        # submit the test ticket to the dummy archive
        url_tracker = URL_BASE + 'p/' + PROJECT + '/tickets/new'
        url_api = URL_BASE + 'p/' + PROJECT + '/tickets/perform_import' 
        response = client.request(url_tracker, 'POST', body=urlencode(body))
'''

# push all 'real' tickets to sourceforge
ind = 0
for tix in tixlist:
    if restart and ind < restart_ind:
        ind += 1
        continue
    else:
        try:
            # submit the test ticket to the dummy archive
            response = client.request(
                URL_BASE + 'p/' + PROJECT + '/tickets3/new', 'POST',
                body=urlencode(tix))
            print "Ticket #{0} Done. Response was:".format(ind)
            print str(response)+"\n"
        except:
            print "\nTicket #{0} Failed!\n".format(ind)
        ind += 1

print "\nDONE!  {0} tickets were submitted.".format(ind)

