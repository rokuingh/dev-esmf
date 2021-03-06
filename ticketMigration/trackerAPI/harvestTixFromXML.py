#!/usr/bin/env python

###############################################################################
#
#  Harvest the ticket info from an XML file exported from Sourceforge
#
# Ryan O'Kuinghttons
# June 6, 2013
#
###############################################################################

import time
# to convert from epoch to local time
# time.strftime("%a, %d %b %Y %H:%M:%S +0000", time.localtime(epoch)) 
#   Replace time.localtime with time.gmtime for GMT time.

class TicketHarvester(object):
    def __init__(self, xmlfile):
        import xml.etree.ElementTree as ET
        
        # harvest XML file
        tree = ET.parse(xmlfile)
        root = tree.getroot()

        # get the project members and make the member map
        #   - submitter, assignee, and closer are all tracked by user_name
        project_members = root.findall(".//*projectmember")
        self.member_map = {}
        for member in project_members:
            self.member_map[member.find('user_name').text] = \
                member.find('user_name').text
        # add in the deleted project members
        self.member_map['cpboulder'] = ''
        self.member_map['jwolfe'] = ''
        self.member_map['nscollins'] = ''
        self.member_map['nobody'] = ''
        self.member_map['rfaincht'] = ''
        self.member_map['flanigan'] = ''
        self.member_map['sujay'] = ''
        self.member_map['sf-robot'] = ''
        self.member_map['jplpan'] = ''
        self.member_map['swartzbr'] = ''
        self.member_map['seastham'] = ''
        self.member_map['krb19711'] = ''
        self.member_map['platipodium'] = ''
        self.member_map['jaokalebo'] = ''

        # get the group_ids
        project_bug_groups = root[7][0].findall(".//*group")
        project_req_groups = root[7][1].findall(".//*group")
        project_fet_groups = root[7][2].findall(".//*group")
        project_vnd_groups = root[7][4].findall(".//*group")
        project_aps_groups = root[7][5].findall(".//*group")
        project_nfr_groups = root[7][6].findall(".//*group")
        project_nsr_groups = root[7][7].findall(".//*group")
        bug_groups = {}
        req_groups = {}
        fet_groups = {}
        vnd_groups = {}
        aps_groups = {}
        nfr_groups = {}
        nsr_groups = {}
        for group in project_bug_groups:
            bug_groups[group.find('group_name').text] = \
                group.find('id').text
        for group in project_req_groups:
            req_groups[group.find('group_name').text] = \
                group.find('id').text
        for group in project_fet_groups:
            fet_groups[group.find('group_name').text] = \
                group.find('id').text
        for group in project_vnd_groups:
            vnd_groups[group.find('group_name').text] = \
                group.find('id').text
        for group in project_aps_groups:
            aps_groups[group.find('group_name').text] = \
                group.find('id').text
        for group in project_nfr_groups:
            nfr_groups[group.find('group_name').text] = \
                group.find('id').text
        for group in project_nsr_groups:
            nsr_groups[group.find('group_name').text] = \
                group.find('id').text
        # make the group2category_map
        self.group2category_map = {
                                   # Bugs
                                   bug_groups['Memory Corruption/Leak']:'Bug',
                                   bug_groups['Fix Behavior']:'Bug',
                                   bug_groups['Documentation']:'Documentation',
                                   bug_groups['Increase Robustness/Handle Error']:
                                       'Bug',
                                   bug_groups['Performance Optimization']:'Bug',
                                   bug_groups['Organization/Cleanup']:
                                       'Code Clean-Up',
                                   bug_groups['Test or Example Needed']:
                                       'Test Needed',
                                   bug_groups['ZZ-EMPTY GROUP 1']:'Bug',
                                   bug_groups['Standardization']:'API Clean-Up',
                                   bug_groups['Solution Unclear']:'Bug',
                                   bug_groups['Add Functionality']:'Feature',
                                   bug_groups['ZZ-EMPTY GROUP 2']:'Bug',
                                   bug_groups['Memory Optimization']:'Bug',
                                   bug_groups['Vendor Problem']:'Vendor',
                                   # Support Requests
                                   req_groups['Needs Assistance']:'Help',
                                   req_groups['ZZ-EMPTY GROUP 4']:'Help',
                                   req_groups['ZZ-EMPTY GROUP 5']:'Help',
                                   req_groups['ZZ-EMPTY GROUP 3']:'Help',
                                   req_groups['ZZ-EMPTY GROUP 6']:'Help',
                                   req_groups['Possible Problem']:'Help',
                                   req_groups['Solution Unclear']:'Help',
                                   req_groups['ZZ-EMPTY GROUP 2 ']:'Help',
                                   req_groups['ZZ-EMPTY GROUP 1']:'Help',
                                   req_groups['Simple Information/Action Request']:'Help',
                                   # Feature Requests
                                   fet_groups['Add Code Capability']:'Feature',
                                   fet_groups['Port to New Platform']:'Feature',
                                   fet_groups['Add Other Capability']:'Feature',
                                   # Vendor Bugs - "Vendor"
                                   # Application Issues - "Help"
                                   # NUOPC Feature Requests - "Feature"
                                   # NUOPC Support Requests - "Help"
                                   # default value
                                   '100':'',
                                  }

        # make the category2area_map
        project_bug_categories = root[7][0].findall(".//*category")
        project_req_categories = root[7][1].findall(".//*category")
        project_fet_categories = root[7][2].findall(".//*category")
        project_vnd_categories = root[7][4].findall(".//*category")
        project_aps_categories = root[7][5].findall(".//*category")
        project_nfr_categories = root[7][6].findall(".//*category")
        project_nsr_categories = root[7][7].findall(".//*category")
        bug_categories = {}
        req_categories = {}
        fet_categories = {}
        vnd_categories = {}
        aps_categories = {}
        nfr_categories = {}
        nsr_categories = {}
        for category in project_bug_categories:
            bug_categories[category.find('category_name').text] = \
                category.find('id').text
        for category in project_req_categories:
            req_categories[category.find('category_name').text] = \
                category.find('id').text
        for category in project_fet_categories:
            fet_categories[category.find('category_name').text] = \
                category.find('id').text
        for category in project_vnd_categories:
            vnd_categories[category.find('category_name').text] = \
                category.find('id').text
        for category in project_aps_categories:
            aps_categories[category.find('category_name').text] = \
                category.find('id').text
        for category in project_nfr_categories:
            nfr_categories[category.find('category_name').text] = \
                category.find('id').text
        for category in project_nsr_categories:
            nsr_categories[category.find('category_name').text] = \
                category.find('id').text
        self.category2area_map = {
                                  # Bugs
                                  bug_categories['Component']:'Superstructure',
                                  bug_categories['Time Manager']:'Time Manager',
                                  bug_categories['Grid - New']:'Geometry Object',
                                  bug_categories['Build/Install']:'Build System',
                                  bug_categories['Field']:'Not Defined',
                                  bug_categories['Grid - Old']:'Geometry Object',
                                  bug_categories['Repository']:'Not Defined',
                                  bug_categories['Multiple Categories']:'Not Defined',
                                  bug_categories['Website']:'Not Defined',
                                  bug_categories['Base']:'Not Defined',
                                  bug_categories['Util']:'Not Defined',
                                  bug_categories['I/O']:'I/O',
                                  bug_categories['Tests']:'Not Defined',
                                  bug_categories['LogErr']:'Not Defined',
                                  bug_categories['FieldBundle']:'Not Defined',
                                  bug_categories['State']:'Superstructure',
                                  bug_categories['General Documentation']:'Not Defined',
                                  bug_categories['Array - Old']:'Not Defined',
                                  bug_categories['DELayout']:'Not Defined',
                                  bug_categories['Non-ESMF']:'Not Defined',
                                  bug_categories['Route']:'Not Defined',
                                  bug_categories['Language Interface']:'Not Defined',
                                  bug_categories['InternalState']:'Not Defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 3']:'Not Defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 5']:'Not Defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 6']:'Not Defined',
                                  bug_categories['Config']:'Not Defined',
                                  bug_categories['DistGrid - New']:'Not Defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 13']:'Not Defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 14']:'Not Defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 4']:'Not Defined',
                                  bug_categories['PhysGrid']:'Not Defined',
                                  bug_categories['Regrid']:'Regrid',
                                  bug_categories['ZZ-EMPTY CATEGORY 7']:'Not Defined',
                                  bug_categories['Attribute']:'Attribute',
                                  bug_categories['Mesh']:'Geometry Object',
                                  bug_categories['ZZ-EMPTY CATEGORY 8']:'Not Defined',
                                  bug_categories['ArrayBundle']:'Not Defined',
                                  bug_categories['VM']:'Not Defined',
                                  bug_categories['Array - New']:'Not Defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 12']:'Not Defined',
                                  bug_categories['AppDriver']:'Not Defined',
                                  bug_categories['Datatype']:'Not Defined',
                                  bug_categories['LocalArray']:'Not Defined',
                                  bug_categories['F90 Interface']:'Not Defined',
                                  bug_categories['LocStream']:'Geometry Object',
                                  bug_categories['Test Harness']:'Not Defined',
                                  bug_categories['Web Services']:'Not Defined',
                                  bug_categories['ESMP']:'ESMPy Interface Layer',
                                  # Category ID
                                  req_categories['DistGrid - New']:'Not Defined',
                                  req_categories['Yet Undetermined']:'Not Defined',
                                  req_categories['Build/Install']:'Build System',
                                  req_categories['Application Architecture']:'Not Defined',
                                  req_categories['Array - Old']:'Not Defined',
                                  req_categories['Base']:'Not Defined',
                                  req_categories['FieldBundle']:'Not Defined',
                                  req_categories['Non-ESMF']:'Not Defined',
                                  req_categories['Component']:'Superstructure',
                                  req_categories['DELayout']:'Not Defined',
                                  req_categories['General Documentation']:'Not Defined',
                                  req_categories['Field']:'Not Defined',
                                  req_categories['Grid - Old']:'Geometry Object',
                                  req_categories['I/O']:'I/O',
                                  req_categories['State']:'Superstructure',
                                  req_categories['Time Manager']:'Time Manager',
                                  req_categories['Download']:'Not Defined',
                                  req_categories['AppDriver']:'Not Defined',
                                  req_categories['VM']:'Not Defined',
                                  req_categories['LogErr']:'Not Defined',
                                  req_categories['Regrid']:'Regrid',
                                  req_categories['Config']:'Not Defined',
                                  req_categories['Multiple Categories']:'Not Defined',
                                  req_categories['Tests']:'Not Defined',
                                  req_categories['Language Interface']:'Not Defined',
                                  req_categories['Attribute']:'Attribute',
                                  req_categories['Debugger']:'Not Defined',
                                  req_categories['Examples and Demos']:'Not Defined',
                                  req_categories['Datatype']:'Not Defined',
                                  req_categories['Util']:'Not Defined',
                                  req_categories['Website']:'Not Defined',
                                  req_categories['Repository']:'Not Defined',
                                  req_categories['Tutorial']:'Not Defined',
                                  req_categories['ArrayBundle']:'Not Defined',
                                  req_categories['Array - New']:'Not Defined',
                                  req_categories['Grid - New']:'Geometry Object',
                                  req_categories['LocalArray']:'Not Defined',
                                  req_categories['Mesh']:'Geometry Object',
                                  req_categories['Web Services']:'Not Defined',
                                  req_categories['ESMP']:'ESMPy Interface Layer',
                                  req_categories['NUOPC']:'NUOPC Layer',
                                  # Feature Requests
                                  fet_categories['Array - Old']:'Not Defined',
                                  fet_categories['AppDriver']:'Not Defined',
                                  fet_categories['Attribute']:'Attribute',
                                  fet_categories['Base']:'Not Defined',
                                  fet_categories['Build/Install']:'Build System',
                                  fet_categories['Component']:'Superstructure',
                                  fet_categories['Config']:'Not Defined',
                                  fet_categories['DELayout']:'Not Defined',
                                  fet_categories['DistGrid - New']:'Not Defined',
                                  fet_categories['Field']:'Not Defined',
                                  fet_categories['FieldBundle']:'Not Defined',
                                  fet_categories['General Documentation']:'Not Defined',
                                  fet_categories['Grid - Old']:'Geometry Object',
                                  fet_categories['I/O']:'I/O',
                                  fet_categories['Language Interface']:'Not Defined',
                                  fet_categories['LogErr']:'Not Defined',
                                  fet_categories['Multiple Categories']:'Not Defined',
                                  fet_categories['PhysGrid']:'Not Defined',
                                  fet_categories['Regrid']:'Regrid',
                                  fet_categories['Route']:'Not Defined',
                                  fet_categories['State']:'Superstructure',
                                  fet_categories['Time Manager']:'Time Manager',
                                  fet_categories['Util']:'Not Defined',
                                  fet_categories['VM']:'Not Defined',
                                  fet_categories['Website']:'Not Defined',
                                  fet_categories['Repository']:'Not Defined',
                                  fet_categories['ArrayBundle']:'Not Defined',
                                  fet_categories['Array - New']:'Not Defined',
                                  fet_categories['Grid - New']:'Geometry Object',
                                  fet_categories['LocalArray']:'Not Defined',
                                  fet_categories['Mesh']:'Geometry Object',
                                  fet_categories['Test Harness']:'Not Defined',
                                  fet_categories['Web Services']:'Not Defined',
                                  fet_categories['XGrid']:'Geometry Object',
                                  fet_categories['Container']:'Not Defined',
                                  # Vendor Bugs - none
                                  # Application Issues - none
                                  # NUOPC Feature Requests - none
                                  # NUOPC Support Requests
                                  nsr_categories['Applying NUOPC layer']:'NUOPC Layer',
                                  nsr_categories['Bug in NUOPC layer']:'NUOPC Layer',
                                  # default value
                                  '100':'',
                             }

        # make the status_map
        self.status_map = {
                      '1':'Open', 
                      '2':'Closed', 
                      '3':'Deleted', 
                      '4':'Pending'
                     }

        # allocate body_list
        self.body_list = []

        # pull tickets out of the individual trackers
        self.bugs = root[7][0].findall(".//tracker_item")
        self.supportreqs = root[7][1].findall(".//tracker_item")
        self.featurereqs = root[7][2].findall(".//tracker_item")
        #self.operations = root[7][3].findall(".//tracker_item")
        self.vendorbugs = root[7][4].findall(".//tracker_item")
        self.applicationissues = root[7][5].findall(".//tracker_item")
        self.NUOPCfeaturereqs = root[7][6].findall(".//tracker_item")
        self.NUOPCsupportreqs = root[7][7].findall(".//tracker_item")

        # Print the number of tickets in each old tracker
        print "Bugs                   = {0}".format(len(self.bugs))
        print "Support requests       = {0}".format(len(self.supportreqs))
        print "Feature requests       = {0}".format(len(self.featurereqs))
        #print "Operations             = {0}".format(len(operations))
        print "Vendor bugs            = {0}".format(len(self.vendorbugs))
        print "Application issues     = {0}".format(len(self.applicationissues))
        print "NUOPC feature requests = {0}".format(len(self.NUOPCfeaturereqs))
        print "NUOPC support requests = {0}".format(len(self.NUOPCsupportreqs))
        
        # remove open support requests
        self.supportreqslessopen = []
        for tix in self.supportreqs:
            if tix.find('status_id').text == '1':
                pass
            else:
                self.supportreqslessopen.append(tix)

        # reset the ticketlist to include only the tickets we want
        #self.tixlist = bugs + supportreqslessopen + featurereqs

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
    
        # TODO: if there are followups, get the submitter, date and id


        for tix in self.bugs:
            self.create_body(tix, category="Bug")

        for tix in self.featurereqs:
            self.create_body(tix, category="Feature")

        for tix in self.supportreqslessopen:
            self.create_body(tix, category="Help")

        for tix in self.vendorbugs:
            self.create_body(tix, category="Vendor")

        for tix in self.applicationissues:
            self.create_body(tix, category="Help")

        for tix in self.NUOPCfeaturereqs:
            self.create_body(tix, category="Feature", label="NUOPC")

        for tix in self.NUOPCsupportreqs:
            self.create_body(tix, category="Help", label="NUOPC")

        # sort the body list by id 
        self.body_list_sorted = sorted(self.body_list, key=self.get_id)



    def create_body(self, tix, category=None, label=None):    
        body = {
                # generic information
                'ticket_form.summary' : 
                    (tix.find('summary').text).encode("ASCII", "replace"),
                'ticket_form.description' : 
                    (tix.find('details').text + self.gather_comments(tix)).encode("ASCII", "replace"),
                'ticket_form.status' : 
                    self.status_map[tix.find('status_id').text],
                'ticket_form.assigned_to' : 
                    self.member_map[tix.find('assignee').text],
                'ticket_form.labels' : '',
                # Custom fields
                'ticket_form.custom_fields._old_ticket_number' : 
                    int(tix.find('id').text),
                'ticket_form.custom_fields._priority' : 
                    'Desirable',
                'ticket_form.custom_fields._category' : 
                    self.group2category_map[tix.find('group_id').text],
                'ticket_form.custom_fields._area' : 
                    self.category2area_map[tix.find('category_id').text],
                'ticket_form.custom_fields._who' : 
                    (self.gather_who_origin(tix)[0]).encode("ASCII", "replace"),
                'ticket_form.custom_fields._origin' : 
                    self.gather_who_origin(tix)[1],
                'ticket_form.custom_fields._estimated_weeks_to_completion' : 
                    self.gather_weeks(tix),
                # proposed custom fields to track old required information
                'ticket_form.custom_fields._original_creation_date' : 
                    self.time(tix)[0],
                'ticket_form.custom_fields._original_close_date' : 
                    self.time(tix)[1],
                'ticket_form.custom_fields._original_creator' : 
                    self.member_map[tix.find('submitter').text],
                'ticket_form.custom_fields._original_closer' : 
                    self.member_map[tix.find('closer').text],
                }
        # set the category and label default values
        if body['ticket_form.custom_fields._category'] == '':
            body['ticket_form.custom_fields._category'] = category
        if label != None:
            body['ticket_form.labels'] = label

        self.body_list.append(body)

    @staticmethod
    def gather_comments(ticket):
        # grab the followups
        followups = ticket.findall(".//followup")
        comments = ''
        if followups:
            for followup in followups:
                # TODO: handle non-unicode characters better
                try:
                    comments += "\n---\n{0}\n{1}\n{2}\n---\n".format(
                        followup.find('submitter').text,
                        time.strftime("%a, %d %b %Y %H:%M:%S", \
                            time.localtime(float(followup.find('date').text))),
                        followup.find('details').text)
                except:
                    comments +="\n---\nComment excluded because it contained non \
                              unicode characters!\n---\n"
        return comments

    @staticmethod
    def gather_who_origin(ticket):
        # parse the who line out of the ticket details
        who = ''
        searchstrings = ['Who:', 'From:']
        #TODO: handle these exceptions
        #exceptions = ['From Peggy:', "Ryan O'Kuinghttons"]
        details = ticket.find('details').text
        line = details.split('\n',1)[0]
        
        # case insensitive search for for searchstrings in first line of details
        for string in searchstrings:
            if string.lower() in line.lower():
                who = line.split(":")[-1]

        # internal
        origin = 'External'
        keywords = ["NESII", "core", "ESMF", "internal", "Gerhard", \
                    "Cecelia DeLuca", "Peggy Li", "Fei Liu", \
                    "Ryan O'Kuinghttons", "Oehmke"]
        for key in keywords:
            if key.lower() in who.lower():
                origin = "Internal"
        
        return who, origin

    @staticmethod
    def gather_weeks(ticket):
        import re
        # parse the estimated weeks to completion out of the ticket summary
        weeks = ''
        summary = ticket.find('summary').text
        # remove spaces and periods from beginning and end of summary
        summary = summary.strip(" .")

        # regular number in parenttheses at end of summary
        if  re.search("\([0-9]+\)$", summary):
            temp = summary.split("(")[-1]
            weeks = int(temp.split(")")[0])
        # weird double number in parenttheses at end of summary
        elif re.search("\([0-9]+/[0-9]+\)$",summary):
            temp = summary.split("(")[-1]
            temp = temp.split(")")[0]
            one,two = temp.split("/")
            weeks = int(one) + int(two)
        # question mark in parenttheses at end of summary
        elif re.search("LONG",summary):
            weeks = 2
        # LONG
        elif re.search("\(?\)",summary):
            weeks = 2
        else:
            weeks = ""

        return weeks

    @staticmethod
    def get_id(ticket):
        return ticket['ticket_form.custom_fields._old_ticket_number']

    @staticmethod
    def time(ticket):
        submit_date = time.strftime("%Y/%m/%d %H:%M:%S", \
            time.localtime(float(ticket.find('submit_date').text)))
        close_date = time.strftime("%Y/%m/%d %H:%M:%S", \
            time.localtime(float(ticket.find('close_date').text)))

        if ticket.find('submit_date').text == '0':
            submit_date = ""

        if ticket.find('close_date').text == '0':
            close_date = ""        

        return submit_date, close_date

    def remove_deleted(self):
        # remove the items with status 'deleted'
        tixlist_without_deleted = \
            [x for x in self.tixlist if x.find('status_id').text != '3']
        self.tixlist = tixlist_without_deleted

def harvest_tix(xmlfile):

    harvester = TicketHarvester(xmlfile)

    # optionally remove deleted tickets
    #harvester.remove_deleted()

    # generate the body dictionary for each ticket
    harvester.generate_body_list()

    #import pdb; pdb.set_trace()

    return harvester.body_list_sorted
