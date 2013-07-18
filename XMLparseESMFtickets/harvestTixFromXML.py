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

        # pull tickets out of the harvested file
        #tixlist_temp = root.findall(".//*tracker_item")

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

        # reset the ticketlist to include only the ticket we want
        tixlist_temp = bugs + supportreqs #+ featurereqs

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
        project_fet_groups = root[7][2].findall(".//*group")
        project_ops_groups = root[7][3].findall(".//*group")
        project_vnd_groups = root[7][4].findall(".//*group")
        project_aps_groups = root[7][5].findall(".//*group")
        project_nfr_groups = root[7][6].findall(".//*group")
        project_nsr_groups = root[7][7].findall(".//*group")
        bug_groups = {}
        req_groups = {}
        fet_groups = {}
        ops_groups = {}
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
        for group in project_ops_groups:
            ops_groups[group.find('group_name').text] = \
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
        project_bug_categories = root[7][0].findall(".//*category")
        project_req_categories = root[7][1].findall(".//*category")
        project_fet_categories = root[7][2].findall(".//*category")
        project_ops_categories = root[7][3].findall(".//*category")
        project_vnd_categories = root[7][4].findall(".//*category")
        project_aps_categories = root[7][5].findall(".//*category")
        project_nfr_categories = root[7][6].findall(".//*category")
        project_nsr_categories = root[7][7].findall(".//*category")
        bug_categories = {}
        req_categories = {}
        fet_categories = {}
        ops_categories = {}
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
        for category in project_ops_categories:
            ops_categories[category.find('category_name').text] = \
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
                                  bug_categories['Field']:'not defined',
                                  bug_categories['Grid - Old']:'Geometry Object',
                                  bug_categories['Repository']:'not defined',
                                  bug_categories['Multiple Categories']:'not defined',
                                  bug_categories['Website']:'not defined',
                                  bug_categories['Base']:'not defined',
                                  bug_categories['Util']:'not defined',
                                  bug_categories['I/O']:'I/O',
                                  bug_categories['Tests']:'not defined',
                                  bug_categories['LogErr']:'not defined',
                                  bug_categories['FieldBundle']:'not defined',
                                  bug_categories['State']:'Superstructure',
                                  bug_categories['General Documentation']:'not defined',
                                  bug_categories['Array - Old']:'not defined',
                                  bug_categories['DELayout']:'not defined',
                                  bug_categories['Non-ESMF']:'not defined',
                                  bug_categories['Route']:'not defined',
                                  bug_categories['Language Interface']:'not defined',
                                  bug_categories['InternalState']:'not defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 3']:'not defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 5']:'not defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 6']:'not defined',
                                  bug_categories['Config']:'not defined',
                                  bug_categories['DistGrid - New']:'not defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 13']:'not defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 14']:'not defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 4']:'not defined',
                                  bug_categories['PhysGrid']:'not defined',
                                  bug_categories['Regrid']:'Regrid',
                                  bug_categories['ZZ-EMPTY CATEGORY 7']:'not defined',
                                  bug_categories['Attribute']:'Attribute',
                                  bug_categories['Mesh']:'not defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 8']:'not defined',
                                  bug_categories['ArrayBundle']:'not defined',
                                  bug_categories['VM']:'not defined',
                                  bug_categories['Array - New']:'not defined',
                                  bug_categories['ZZ-EMPTY CATEGORY 12']:'not defined',
                                  bug_categories['AppDriver']:'not defined',
                                  bug_categories['Datatype']:'not defined',
                                  bug_categories['LocalArray']:'not defined',
                                  bug_categories['F90 Interface']:'not defined',
                                  bug_categories['LocStream']:'Geometry Object',
                                  bug_categories['Test Harness']:'not defined',
                                  bug_categories['Web Services']:'not defined',
                                  bug_categories['ESMP']:'ESMPy Interface Layer',
                                  # Category ID
                                  req_categories['DistGrid - New']:'not defined',
                                  req_categories['Yet Undetermined']:'not defined',
                                  req_categories['Build/Install']:'Build System',
                                  req_categories['Application Architecture']:'not defined',
                                  req_categories['Array - Old']:'not defined',
                                  req_categories['Base']:'not defined',
                                  req_categories['FieldBundle']:'not defined',
                                  req_categories['Non-ESMF']:'not defined',
                                  req_categories['Component']:'Superstructe',
                                  req_categories['DELayout']:'not defined',
                                  req_categories['General Documentation']:'not defined',
                                  req_categories['Field']:'not defined',
                                  req_categories['Grid - Old']:'not defined',
                                  req_categories['I/O']:'I/O',
                                  req_categories['State']:'Superstructure',
                                  req_categories['Time Manager']:'Time Manager',
                                  req_categories['Download']:'not defined',
                                  req_categories['AppDriver']:'not defined',
                                  req_categories['VM']:'not defined',
                                  req_categories['LogErr']:'not defined',
                                  req_categories['Regrid']:'Regrid',
                                  req_categories['Config']:'not defined',
                                  req_categories['Multiple Categories']:'not defined',
                                  req_categories['Tests']:'not defined',
                                  req_categories['Language Interface']:'not defined',
                                  req_categories['Attribute']:'Attribute',
                                  req_categories['Debugger']:'not defined',
                                  req_categories['Examples and Demos']:'not defined',
                                  req_categories['Datatype']:'not defined',
                                  req_categories['Util']:'not defined',
                                  req_categories['Website']:'not defined',
                                  req_categories['Repository']:'not defined',
                                  req_categories['Tutorial']:'not defined',
                                  req_categories['ArrayBundle']:'not defined',
                                  req_categories['Array - New']:'not defined',
                                  req_categories['Grid - New']:'not defined',
                                  req_categories['LocalArray']:'not defined',
                                  req_categories['Mesh']:'not defined',
                                  req_categories['Web Services']:'not defined',
                                  req_categories['ESMP']:'ESMPy Interface Layer',
                                  req_categories['NUOPC']:'NUOPC Layer',
                                  # add in a weird default value
                                  '100':'not defined',
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
    
        # TODO: if there are followups, get the submitter, date and id


        for tix in self.tixlist:

            body = {
                    # generic information
                    'ticket_form.summary' : 
                        tix.find('summary').text,
                    'ticket_form.description' : 
                        tix.find('details').text + self.gather_comments(tix),
                    'ticket_form.status' : 
                        self.status_map[tix.find('status_id').text],
                    'ticket_form.assigned_to' : 
                        self.member_map[tix.find('assignee').text],
                    # Custom fields
                    'ticket_form.custom_fields._old_ticket_number' : 
                        float(tix.find('id').text),
                    'ticket_form.custom_fields._priority' : 
                        'desirable',
                    'ticket_form.custom_fields._category' : 
                        self.group2category_map[tix.find('group_id').text],
                    'ticket_form.custom_fields._area' : 
                        self.category2area_map[tix.find('category_id').text],
                    'ticket_form.custom_fields._who' : 
                        self.gather_who_origin(tix)[0],
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
                        tix.find('submitter').text,
                    'ticket_form.custom_fields._original_closer' : 
                        tix.find('closer').text,
                    }

            self.body_list.append(body)

        return

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
        origin = 'external'
        keywords = ["NESII", "core", "ESMF", "internal", "Gerhard", \
                    "Cecelia DeLuca", "Peggy Li", "Fei Liu", \
                    "Ryan O'Kuinghttons", "Oehmke"]
        for key in keywords:
            if key.lower() in who.lower():
                origin = "internal"
        
        return who, origin

    @staticmethod
    def gather_weeks(ticket):
        import re
        # parse the estimated weeks to completion out of the ticket summary
        weeks = ''
        summary = ticket.find('summary').text
        '''
        try:
            print summary
        except:
            print "THIS TICKET HAD A NON ASCII CHARACTER!"
        '''
        # if LONG: is in the summary line
        if 'LONG:' in summary:
            # if there is a number of weeks in the summary line
            if re.search("\([0-9]+\)",summary):
                temp = summary.split("(")[-1]
                weeks = temp.split(")")[0]
            # default to 2
            else:
                weeks = 2

        # return empty string, or an integer value
        try:
            return int(weeks)
        except:
            return ''

    @staticmethod
    def get_id_et(ticket):
        return float(ticket.find('id').text)

    @staticmethod
    def time(ticket):
        submit_date = time.strftime("%Y/%m/%d %H:%M:%S", \
            time.localtime(float(ticket.find('submit_date').text)))
        close_date = time.strftime("%Y/%b/%d %H:%M:%S", \
            time.localtime(float(ticket.find('close_date').text)))

        if ticket.find('submit_date').text == '0':
            print "DING 111"
            submit_date = ""

        if ticket.find('close_date').text == '0':
            print "DING 222"
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
    harvester.remove_deleted()

    # generate the body dictionary for each ticket
    harvester.generate_body_list()

    #import pdb; pdb.set_trace()

    return harvester.body_list
