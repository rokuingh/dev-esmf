#CONSUMER_KEY = '3a3069ed662030e15794'
#CONSUMER_SECRET = '049681debe988488ce9d784ca154437f1890aa5153bcd59d020d9c9aeda627d2bb24f86e8e50b4f9'
CONSUMER_KEY='tckc8a15688ad3d323ade16'
CONSUMER_SECRET='915d0d399f8957631e5e8a9c39b646799f609aa2939b08bdea5ebe0a4344df4a133bbd22b6181e76'

REQUEST_TOKEN_URL = 'https://sourceforge.net/rest/oauth/request_token'
AUTHORIZE_URL = 'https://sourceforge.net/rest/oauth/authorize'
ACCESS_TOKEN_URL = 'https://sourceforge.net/rest/oauth/access_token'

import oauth2 as oauth
import certifi
from urllib2 import urlparse
import webbrowser

consumer = oauth.Consumer(CONSUMER_KEY, CONSUMER_SECRET)
client = oauth.Client(consumer)
client.ca_certs = certifi.where()

# Step 1: Get a request token. This is a temporary token that is used for 
# having the user authorize an access token and to sign the request to obtain 
# said access token.

resp, content = client.request(REQUEST_TOKEN_URL, 'GET')
if resp['status'] != '200':
    raise Exception("Invalid response %s." % resp['status'])

request_token = dict(urlparse.parse_qsl(content))

# these are intermediate tokens and not needed later
#print "Request Token:"
#print "    - oauth_token        = %s" % request_token['oauth_token']
#print "    - oauth_token_secret = %s" % request_token['oauth_token_secret']
#print 

# Step 2: Redirect to the provider. Since this is a CLI script we do not 
# redirect. In a web application you would redirect the user to the URL
# below, specifying the additional parameter oauth_callback=<your callback URL>.

webbrowser.open("%s?oauth_token=%s" % (
        AUTHORIZE_URL, request_token['oauth_token']))

# Since we didn't specify a callback, the user must now enter the PIN displayed in 
# their browser.  If you had specified a callback URL, it would have been called with 
# oauth_token and oauth_verifier parameters, used below in obtaining an access token.
oauth_verifier = raw_input('What is the PIN? ')

# Step 3: Once the consumer has redirected the user back to the oauth_callback
# URL you can request the access token the user has approved. You use the 
# request token to sign this request. After this is done you throw away the
# request token and use the access token returned. You should store this 
# access token somewhere safe, like a database, for future use.
token = oauth.Token(request_token['oauth_token'],
    request_token['oauth_token_secret'])
token.set_verifier(oauth_verifier)
client = oauth.Client(consumer, token)
client.ca_certs = certifi.where()

resp, content = client.request(ACCESS_TOKEN_URL, "GET")
access_token = dict(urlparse.parse_qsl(content))

print "Access Token:"
print "    - oauth_token        = %s" % access_token['oauth_token']
print "    - oauth_token_secret = %s" % access_token['oauth_token_secret']
print
print "You may now access protected resources using the access tokens above." 
print