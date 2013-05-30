#!/usr/bin/env python

###############################################################################
#
#  Harvest the ticket info from an XML file exported from Sourceforge
#
# Ryan O'Kuinghttons
# May 30, 2013
#
###############################################################################

def strip_carets(line, tag):
    new_line = line.split("<"+tag+">")[1]
    line = new_line.split("</"+tag+">")[0]
    return line

class Followup(object):
    def __init__(self):
        self.id = 0
        self.submitter = ""
        self.date = 0
        self.details = ""

    def read(self, line):
        if "<id>" in line:
            self.id = strip_carets(line, "id")
        if "<submitter>" in line:
            self.submitter = strip_carets(line, "submitter")
        if "<date>" in line:
            self.date = strip_carets(line, "date")
        if "<details>" in line:
            self.details = strip_carets(line, "details")

class Attachment(object):
    def __init__(self):
        self.url = ""
        self.id = 0
        self.filename = ""
        self.description = ""
        self.filesize = 0
        self.filetype = ""
        self.date = 0
        self.submitter = ""

    def read(self, line):
        if "<url>" in line:
            self.url = strip_carets(line, "url")
        if "<id>" in line:
            self.id = strip_carets(line, "id")
        if "<filename>" in line:
            self.filename = strip_carets(line, "filename")
        if "<description>" in line:
            self.description = strip_carets(line, "description")
        if "<filesize>" in line:
            self.filesize = strip_carets(line, "filesize")
        if "<filetype>" in line:
            self.filetype = strip_carets(line, "filetype")
        if "<date>" in line:
            self.date = strip_carets(line, "date")
        if "<submitter>" in line:
            self.submitter = strip_carets(line, "submitter")

class HistoryEntry(object):
    def __init__(self):
        self.id = 0
        self.field_name = ""
        self.old_value = 0
        self.date = 0
        self.updator = ""

    def read(self, line):
        if "<id>" in line:
            self.id = strip_carets(line, "id")
        if "<field_name>" in line:
            self.field_name = strip_carets(line, "field_name")
        if "<old_value>" in line:
            self.old_value = strip_carets(line, "old_value")
        if "<date>" in line:
            self.date = strip_carets(line, "date")
        if "<updator>" in line:
            self.updator = strip_carets(line, "updator")

class Ticket(object):
    def __init__(self):
        self.url = ""
        self.id = 0
        self.status_id = 0
        self.category_id = 0
        self.group_id = 0
        self.resolution_id = 0
        self.submitter = ""
        self.assignee = ""
        self.closer = ""
        self.submit_date = 0
        self.close_date = 0
        self.priority = 0
        self.summary = ""
        self.details = ""
        self.is_private = False
        
        self.followups = []
        self.attachments = []
        self.history_entries = []

        self.followup_run = False
        self.followup = 0

        self.attachment_run = False
        self.attachment = 0

        self.history_entry_run = False
        self.history_entry = 0

    def get_id(self):
        return self.id

    def read(self, line):
        if "<url>" in line:
            self.url = strip_carets(line, "url")
        if "<id>" in line:
            self.id = strip_carets(line, "id")
        if "<status_id>" in line:
            self.status_id = strip_carets(line, "status_id")
        if "<category_id>" in line:
            self.category_id = strip_carets(line, "category_id")
        if "<group_id>" in line:
            self.group_id = strip_carets(line, "group_id")
        if "<resolution_id>" in line:
            self.resolution_id = strip_carets(line, "resolution_id")
        if "<submitter>" in line:
            self.submitter = strip_carets(line, "submitter")
        if "<assignee>" in line:
            self.assignee = strip_carets(line, "assignee")
        if "<closer>" in line:
            self.closer = strip_carets(line, "closer")
        if "<submit_date>" in line:
            self.submit_date = strip_carets(line, "submit_date")
        if "<close_date>" in line:
            self.close_date = strip_carets(line, "close_date")
        if "<priority>" in line:
            self.priority = strip_carets(line, "priority")
        if "<summary>" in line:
            self.summary = strip_carets(line, "summary")
        if "<details>" in line:
            self.details = strip_carets(line, "details")
        if "<is_private>" in line:
            self.is_private = strip_carets(line, "is_private")

        # followup
        if self.followup_run:
            self.followup.read(line)

        if "<followup>" in line:
            # start a new followup entry
            self.followup_run = True
            # create a new followup entry
            self.followup = Followup()

        if "</followup>" in line:
            # end a followup entry
            self.followup_run = False
            # add a followup entry to the list
            self.followups.append(self.followup)

        # attachment
        if self.attachment_run:
            self.attachment.read(line)

        if "<attachment>" in line:
            # start a new attachment entry
            self.attachment_run = True
            # create a new attachment entry
            self.attachment = Attachment()
            #print "Attachment - id = "+str(self.id)

        if "</attachment>" in line:
            # end a attachment entry
            self.attachment_run = False
            # add a attachment entry to the list
            self.attachments.append(self.attachment)

        # history entry
        if self.history_entry_run:
            self.history_entry.read(line)

        if "<history_entry>" in line:
            # start a new history entry
            self.history_entry_run = True
            # create a new history entry
            self.history_entry = HistoryEntry()

        if "</history_entry>" in line:
            # end a history entry
            self.history_entry_run = False
            # add a history entry to the list
            self.history_entries.append(self.history_entry)

# xmlfile - XML format file containing esmf ticket info
def harvest_tix(xmlfile):
    ticketlist = []
    # open the file
    XMLFILE = open(xmlfile)

    # generic handle to a ticket object
    ticket = 0
    ticket_run = False

    # iterate through the gigantic xml file
    for line in XMLFILE:

        if "<tasks>" in line:
            return ticketlist

        # read a ticket line if a ticket is active
        if ticket_run:
            ticket.read(line)

        # beginning of a new ticket
        if '<tracker_item>' in line:
            # start ticket_run
            ticket_run = True
            # create a new ticket
            ticket = Ticket()

        # end of a new ticket
        if '</tracker_item>' in line:
            # end ticket_run
            ticket_run = False
            # add ticket to ticket list
            ticketlist.append(ticket)
            print "TICKET #"+str(len(ticketlist))+\
                ", Sourceforge id: "+str(ticket.id)

    return ticketlist

if __name__ == '__main__':
    import sys

    tixlist = harvest_tix('esmf_export.xml')

    # sort by id
    print "Sorting the ticketlist by Sourceforge id..."
    sortedtixlist = sorted(tixlist, key=Ticket.get_id)

    #import pdb; pdb.set_trace()
