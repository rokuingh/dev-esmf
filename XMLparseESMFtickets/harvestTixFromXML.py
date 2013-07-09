#!/usr/bin/env python

###############################################################################
#
#  Harvest the ticket info from an XML file exported from Sourceforge, try 2
#
# Ryan O'Kuinghttons
# June 6, 2013
#
###############################################################################

class TicketHarvester(object):
    def __init__(self, xmlfile):
        import xml.etree.ElementTree as ET
        
        # harvest XML file
        tree = ET.parse(xmlfile)
        root = tree.getroot()


        # pull out the project members
        #project_members = root.findall(".//*projectmember")
        #self.members = {}
        #for member in project_members:
        #    self.members[member.find('user_name').text] = \
        #        member.find('user_id').text

        # unknown member cpboulder needs to be added manually
        #self.members['cpboulder'] = 'Unknown User'
        #self.members['jwolfe'] = 'Unknown User'
        #self.members['nscollins'] = 'Unknown User'
        #self.members['nobody'] = 'Unknown User'
        #self.members['rfaincht'] = 'Unknown User'
        #self.members['flanigan'] = 'Unknown User'

        # pull tickets out of the harvested file
        tixlist_temp = root.findall(".//*tracker_item")
    
        # sort by id and save to class
        self.tixlist = sorted(tixlist_temp, key=self.get_id_et)

        # allocate body_list
        self.body_list = []

    def count_deleted(self):
        self.deleted_count = 0
        for item in self.tixlist:
            if item.find('status_id').text == '3':
                self.deleted_count += 1
        print "Deleted ticket count: "+str(self.deleted_count)
        return self.deleted_count

    def generate_body_list(self):
        status_map = {'1':'open', '2':'closed', '3':'deleted', '4':'pending'}
        group_id_map = {
                        '1':'<empty>', 
                        '2':'documentation', 
                        '3':'<empty>', 
                        '4':'<empty>', 
                        '5':'code-organization/clean-up', 
                        '6':'test needed', 
                        '7':'<empty>', 
                        '8':'API clean-up', 
                        '9':'<empty>', 
                        '10':'feature', 
                        '11':'<empty>', 
                        '12':'<empty>', 
                        '13':'vendor'
                        }
        # TODO: generate a map of the SF user ids
    
    # allura Tracker API
    #
    # ticket_form.summary - ticket title
    # ticket_form.description - ticket description
    # ticket_form.status - ticket status
    # ticket_form.assigned_to - username of ticket assignee
    # ticket_form.labels - comma-separated list of ticket labels
    # ticket_form.attachment - (optional) attachment
    # ticket_form.custom field name - custom field value
    #
    # for custom fields
    # ticket_form.custom_fields._my_field
    
    
        for tix in self.tixlist:
            body = {
                    'ticket_form.summary' : tix.find('summary').text,
                    'ticket_form.description' : tix.find('details').text,
                    'ticket_form.status' : status_map[tix.find('status_id').text],
                    'ticket_form.assigned_to' : tix.find('assignee').text,
                    #'ticket_form.labels' : group_id_map[tix.find('group_id').text]
                    'ticket_form.custom_fields._old_ticket_number' : tix.find('id').text,
                    'ticket_form.custom_fields._priority' : 'desirable',
                    'ticket_form.custom_fields._original_creation_date' : tix.find('submit_date').text,
                    'ticket_form.custom_fields._original_close_date' : tix.find('close_date').text,
                    'ticket_form.custom_fields._original_creator' : tix.find('submitter').text,
                    'ticket_form.custom_fields._original_closer' : tix.find('closer').text,
                    }

            self.body_list.append(body)

        return

    @staticmethod
    def get_id_et(ticket):
        return ticket.find('id').text

    def remove_deleted(self):
        # remove the items with status 'deleted'
        tixlist_without_deleted = \
            [x for x in self.tixlist if x.find('status_id').text != '3']
        self.tixlist = tixlist_without_deleted


def harvest_tix(xmlfile):

    harvester = TicketHarvester(xmlfile)

    # optionally remove deleted tickets
    harvester.remove_deleted()

    # generate the body dictionary for each ticket
    harvester.generate_body_list()

    #import pdb; pdb.set_trace()

    print 'body list size = '+str(len(harvester.body_list))
    print 'ticket list size = '+str(len(harvester.tixlist))

    return harvester.body_list
