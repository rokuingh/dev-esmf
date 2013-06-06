#!/usr/bin/env python

###############################################################################
#
#  Harvest the ticket info from an XML file exported from Sourceforge, try 2
#
# Ryan O'Kuinghttons
# June 6, 2013
#
###############################################################################

import xml.etree.ElementTree as ET

def get_id_et(self):
    return self.find('id').text

def generate_tix_body(tix):
    status_map = {'1':'open', '2':'closed', '3':'deleted', '4':'pending'}

    body = {
            'ticket_form.summary' : tix.find('summary').text,
            'ticket_form.description' : tix.find('details').text,
            'ticket_form.status' : status_map[tix.find('status_id').text],
            'ticket_form.assigned_to' : tix.find('assignee').text
            }
    return body

def harvest_tix(xmlfile):

    # harvest XML file
    tree = ET.parse(xmlfile)
    root = tree.getroot()

    # pull tickets out of the harvested file
    tixlist = root.findall(".//*tracker_item")

    # sort by id
    sorted_tixlist = sorted(tixlist, key=get_id_et)

    # count deleted tickets
    count = 0
    for item in sorted_tixlist:
        if item.find('status_id').text == '3':
            count = count + 1
    print "Deleted ticket count: "+str(count)

    # remove the items with status 'deleted'
    sorted_tixlist_without_deleted = [x for x in sorted_tixlist if x.find('status_id').text != '3']

    #import pdb; pdb.set_trace()

    return sorted_tixlist_without_deleted