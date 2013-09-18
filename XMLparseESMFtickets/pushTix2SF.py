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

PROJECT='esmf'

CONSUMER_KEY='5da2c9731aaacd3b2880'
CONSUMER_SECRET='d9ed8512ba582c7ef7ab6b34eb744d6c8a27df5dfe8e9c8f45029f8c951aa0880ebf26816ac0789e'

ACCESS_KEY='5a0bc582b8b6c6a38357'
ACCESS_SECRET='48d23fa34b56d8a1cba625c1de43906869c5b28b27100050ebda817dfcd46fbf150391543eb4fb1e'

URL_BASE='http://sourceforge.net/rest/'

consumer = oauth.Consumer(CONSUMER_KEY, CONSUMER_SECRET)
access_token = oauth.Token(ACCESS_KEY, ACCESS_SECRET)
client = oauth.Client(consumer, access_token)
client.ca_certs = certifi.where()


# create the ticket list from the gigantic XML file of ESMF tickets
tixlist = harvest_tix('esmf_export.xml')

tixlist = list( tixlist[i] for i in [36, 38, 56, 60, 68, 69, 74, 85, 99, 101, 
                                     111, 116, 121, 148, 152, 191, 201, 245, 
                                     265, 271, 279, 282, 296, 303, 304, 309, 
                                     313, 326, 327, 329, 332, 338, 340, 343, 
                                     344, 346, 347, 350, 353, 354, 359, 362, 
                                     370, 376, 377, 384, 401, 408, 414, 430, 
                                     444, 446, 449, 451, 461, 468, 469, 472, 
                                     474, 475, 480, 484, 489, 493, 496, 497, 
                                     523, 533, 539, 541, 554, 560, 566, 570, 
                                     575, 576, 586, 593, 598, 604, 631, 650, 
                                     655, 669, 670, 697, 706, 714, 722, 758, 
                                     759, 764, 768, 793, 796, 798, 814, 818, 
                                     855, 873, 907, 911, 926, 953, 994, 999, 
                                     1021, 1024, 1039, 1043, 1044, 1045, 1047, 
                                     1048, 1052, 1054, 1055, 1057, 1059, 1061, 
                                     1062, 1065, 1066, 1073, 1074, 1077, 1087, 
                                     1092, 1099, 1105, 1111, 1125, 1134, 1146, 
                                     1150, 1151, 1159, 1167, 1173, 1183, 1184, 
                                     1195, 1198, 1200, 1202, 1221, 1223, 1225, 
                                     1227, 1232, 1240, 1241, 1243, 1244, 1248, 
                                     1249, 1250, 1259, 1264, 1272, 1274, 1278, 
                                     1288, 1290, 1292, 1304, 1308, 1310, 1312, 
                                     1313, 1329, 1334, 1337, 1373, 1375, 1381, 
                                     1391, 1393, 1407, 1409, 1416, 1417, 1419, 
                                     1424, 1440, 1460, 1488, 1494, 1518, 1525, 
                                     1544, 1564, 1568, 1570, 1577, 1595, 1607, 
                                     1609, 1617, 1618, 1622, 1667, 1678, 1683, 
                                     1695, 1697, 1698, 1699, 1701, 1703, 1706, 
                                     1709, 1710, 1717, 1720, 1725, 1726, 1746, 
                                     1766, 1770, 1818, 1821, 1826, 1830, 1833, 
                                     1839, 1845, 1850, 1862, 1871, 1874, 1893, 
                                     1899, 1904, 1917, 1927, 1934, 1972, 1979, 
                                     1981, 1984, 1985, 1988, 2003, 2053, 2092, 
                                     2139, 2191, 2198, 2206, 2237, 2253, 2256, 
                                     2313, 2320, 2322, 2327, 2335, 2338, 2347, 
                                     2351, 2364, 2370, 2379, 2380, 2382, 2395, 
                                     2396, 2398, 2404, 2405, 2412, 2420, 2423, 
                                     2425, 2448, 2451, 2456, 2457, 2476, 2477, 
                                     2541, 2575, 2599, 2606, 2607, 2639, 2660, 
                                     2688, 2700, 2710, 2714, 2715, 2716, 2718, 
                                     2719, 2739, 2752, 2766, 2771, 2778, 2779, 
                                     2791, 2802, 2806, 2832, 2836, 2865, 2877, 
                                     2883, 2905, 2907, 2908, 2910, 2912, 2920, 
                                     2921, 2922, 2931, 2939, 2948, 2956, 2985, 
                                     3000, 3021, 3022, 3024, 3027, 3032, 3043, 
                                     3066, 3070, 3076, 3079, 3094, 3100, 3103, 
                                     3116] )

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
                URL_BASE + 'p/' + PROJECT + '/tickets/new', 'POST',
                body=urlencode(tix))
            print "Ticket #{0} Done. Response was:".format(ind)
            print str(response)+"\n"
        except:
            print "\nTicket #{0} Failed!\n".format(ind)
        ind += 1

print "\nDONE!  {0} tickets were submitted.".format(ind)

