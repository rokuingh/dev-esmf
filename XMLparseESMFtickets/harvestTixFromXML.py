#!/usr/bin/env python

###############################################################################
#
#  Harvest the ticket info from an XML file exported from Sourceforge
#
# Ryan O'Kuinghttons
# June 6, 2013
#
###############################################################################

# TODO: separate tickets from different trackers

class TicketHarvester(object):
    def __init__(self, xmlfile):
        import xml.etree.ElementTree as ET
        
        # harvest XML file
        tree = ET.parse(xmlfile)
        root = tree.getroot()

        # pull tickets out of the harvested file
        tixlist_temp = root.findall(".//*tracker_item")

        # pull tickets out of the individual trackers
        bugs = root[7][0].findall(".//tracker_item")
        supportreqs = root[7][1].findall(".//tracker_item")
        featurereqs = root[7][2].findall(".//tracker_item")
        operations = root[7][3].findall(".//tracker_item")
        vendorbugs = root[7][4].findall(".//tracker_item")
        applicationissues = root[7][5].findall(".//tracker_item")
        NUOPCfeaturereqs = root[7][6].findall(".//tracker_item")
        NUOPCsupportreqs = root[7][7].findall(".//tracker_item")

        '''
        # Print the number of tickets in each old tracker
        print "Bugs                   = {0}".format(len(bugs))
        print "Support requests       = {0}".format(len(supportreqs))
        print "Feature requests       = {0}".format(len(featurereqs))
        print "Operations             = {0}".format(len(operations))
        print "Vendor bugs            = {0}".format(len(vendorbugs))
        print "Application issues     = {0}".format(len(applicationissues))
        print "NUOPC feature requests = {0}".format(len(NUOPCfeaturereqs))
        print "NUOPC support requests = {0}".format(len(NUOPCsupportreqs))
        '''

        # reset the ticketlist to only include bugs and support requests
        tixlist_temp = bugs + supportreqs

        # sort the ticket list by id and add to the TicketHarvester
        self.tixlist = sorted(tixlist_temp, key=self.get_id_et)

        # get the project members and make the member map
        #   - submitter, assignee, and closer are all tracked by user_name
        project_members = root.findall(".//*projectmember")
        self.member_map = {}
        for member in project_members:
            self.member_map[member.find('user_name').text] = \
                member.find('user_name').text
        # add in the deleted project members
        self.member_map['cpboulder'] = 'Unknown User'
        self.member_map['jwolfe'] = 'Unknown User'
        self.member_map['nscollins'] = 'Unknown User'
        self.member_map['nobody'] = 'Unknown User'
        self.member_map['rfaincht'] = 'Unknown User'
        self.member_map['flanigan'] = 'Unknown User'

        # get the group_ids
        project_bug_groups = root[7][0].findall(".//*group")
        project_req_groups = root[7][1].findall(".//*group")
        bug_groups = {}
        req_groups = {}
        for group in project_bug_groups:
            bug_groups[group.find('group_name').text] = \
                group.find('id').text
        for group in project_req_groups:
            req_groups[group.find('group_name').text] = \
                group.find('id').text
        # make the group2category_map
        self.group2category_map = {
                                   # Bugs
                                   bug_groups['Memory Corruption/Leak']:'bug',
                                   bug_groups['Fix Behavior']:'bug',
                                   bug_groups['Documentation']:'documentation',
                                   bug_groups['Increase Robustness/Handle Error']:
                                       'bug',
                                   bug_groups['Performance Optimization']:'bug',
                                   bug_groups['Organization/Cleanup']:
                                       'code clean-up',
                                   bug_groups['Test or Example Needed']:
                                       'test needed',
                                   bug_groups['ZZ-EMPTY GROUP 1']:'',
                                   bug_groups['Standardization']:'API clean-up',
                                   bug_groups['Solution Unclear']:'bug',
                                   bug_groups['Add Functionality']:'feature',
                                   bug_groups['ZZ-EMPTY GROUP 2']:'',
                                   bug_groups['Memory Optimization']:'bug',
                                   bug_groups['Vendor Problem']:'vendor',
                                   # Support Requests
                                   req_groups['Needs Assistance']:'help',
                                   req_groups['ZZ-EMPTY GROUP 4']:'help',
                                   req_groups['ZZ-EMPTY GROUP 5']:'help',
                                   req_groups['ZZ-EMPTY GROUP 3']:'help',
                                   req_groups['ZZ-EMPTY GROUP 6']:'help',
                                   req_groups['Possible Problem']:'help',
                                   req_groups['Solution Unclear']:'help',
                                   req_groups['ZZ-EMPTY GROUP 2 ']:'help',
                                   req_groups['ZZ-EMPTY GROUP 1']:'help',
                                   req_groups['Simple Information/Action Request']:'help',
                                   # add in a weird default value
                                   '100':'',
                                  }

        # make the category2area_map
        project_categories = root.findall(".//*category")
        categories = {}
        for category in project_categories:
            categories[category.find('category_name').text] = \
                category.find('id').text
        self.category2area_map = {
                                  # Bugs
                                  categories['Component']:'Superstructure',
                                  categories['Time Manager']:'Time Manager',
                                  categories['Grid - New']:'Geometry Object',
                                  categories['Build/Install']:'Build System',
                                  categories['Field']:'not defined',
                                  categories['Grid - Old']:'Geometry Object',
                                  categories['Repository']:'not defined',
                                  categories['Multiple Categories']:'not defined',
                                  categories['Website']:'not defined',
                                  categories['Base']:'not defined',
                                  categories['Util']:'not defined',
                                  categories['I/O']:'I/O',
                                  categories['Tests']:'not defined',
                                  categories['LogErr']:'not defined',
                                  categories['FieldBundle']:'not defined',
                                  categories['State']:'Superstructure',
                                  categories['General Documentation']:'not defined',
                                  categories['Array - Old']:'not defined',
                                  categories['DELayout']:'not defined',
                                  categories['Non-ESMF']:'not defined',
                                  categories['Route']:'not defined',
                                  categories['Language Interface']:'not defined',
                                  categories['InternalState']:'not defined',
                                  categories['ZZ-EMPTY CATEGORY 3']:'not defined',
                                  categories['ZZ-EMPTY CATEGORY 5']:'not defined',
                                  categories['ZZ-EMPTY CATEGORY 6']:'not defined',
                                  categories['Config']:'not defined',
                                  categories['DistGrid - New']:'not defined',
                                  categories['ZZ-EMPTY CATEGORY 13']:'not defined',
                                  categories['ZZ-EMPTY CATEGORY 14']:'not defined',
                                  categories['ZZ-EMPTY CATEGORY 4']:'not defined',
                                  categories['PhysGrid']:'not defined',
                                  categories['Regrid']:'Regrid',
                                  categories['ZZ-EMPTY CATEGORY 7']:'not defined',
                                  categories['Attribute']:'Attribute',
                                  categories['Mesh']:'not defined',
                                  categories['ZZ-EMPTY CATEGORY 8']:'not defined',
                                  categories['ArrayBundle']:'not defined',
                                  categories['VM']:'not defined',
                                  categories['Array - New']:'not defined',
                                  categories['ZZ-EMPTY CATEGORY 12']:'not defined',
                                  categories['AppDriver']:'not defined',
                                  categories['Datatype']:'not defined',
                                  categories['LocalArray']:'not defined',
                                  categories['F90 Interface']:'not defined',
                                  categories['LocStream']:'Geometry Object',
                                  categories['Test Harness']:'not defined',
                                  categories['Web Services']:'not defined',
                                  categories['ESMP']:'ESMPy Interface Layer'
                                 }

        # make the status_map
        self.status_map = {
                      '1':'open', 
                      '2':'closed', 
                      '3':'deleted', 
                      '4':'pending'
                     }

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
                    # generic information
                    'ticket_form.summary' : tix.find('summary').text,
                    'ticket_form.description' : tix.find('details').text,
                    'ticket_form.status' : 
                        self.status_map[tix.find('status_id').text],
                    'ticket_form.assigned_to' : 
                        self.member_map[tix.find('assignee').text],
                    # labels are tricky
                    #'ticket_form.labels' : 'blah,blah,blah'
                    # Custom fields
                    'ticket_form.custom_fields._old_ticket_number' : 
                        tix.find('id').text,
                    'ticket_form.custom_fields._priority' : 'desirable',
                    'ticket_form.custom_fields._category' : 
                        self.group2category_map[tix.find('group_id').text],
                    #'ticket_form.custom_fields._area' : 
                    #    self.category2area_map[tix.find('category_id').text],
                    # proposed custom fields to track old required information
                    #'ticket_form.custom_fields._original_creation_date' : 
                    #    tix.find('submit_date').text,
                    #'ticket_form.custom_fields._original_close_date' : 
                    #    tix.find('close_date').text,
                    #'ticket_form.custom_fields._original_creator' : 
                    #    tix.find('submitter').text,
                    #'ticket_form.custom_fields._original_closer' : 
                    #    tix.find('closer').text,
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

    return harvester.body_list
