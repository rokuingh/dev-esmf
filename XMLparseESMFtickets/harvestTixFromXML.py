#!/usr/bin/env python

###############################################################################
#
#  Harvest the ticket info from an XML file exported from Sourceforge
#
# Ryan O'Kuinghttons
# May 30, 2013
#
###############################################################################

def collect_field(line, XMLFILE, tag):
    line_read = ""
    tag_start = "<"+tag+">"
    tag_end = "</"+tag+">"

    # remove the XML tag and save the rest of the line
    line_capture = line.split(tag_start)[1]
    if tag_end in line:
        line_capture = line_capture.split(tag_end)[0]
        line_read += line_capture
        return line_read

    # if tag_end is not in the line, we have a multi-line field:
    line_read += line_capture

    # find the current file position and start iteration from there
    while tag_end not in line:
        # add new lines to the line_read
        line_read += line
        print next(XMLFILE)
        line = next(XMLFILE)

    # capture the line containing the ending tag
    line_capture = line.split("</"+tag+">")[0]
    line_read += line_capture

    return line_read

class Followup(object):
    def __init__(self):
        self.fields = {
                       "id" : 0,
                       "submitter" : "",
                       "date" : 0,
                       "details" : ""
        }

    def read(self, line, XMLFILE):
        for key, value in self.fields.items():
            tag = "<"+key+">"
            if tag in line:
                value = collect_field(line, XMLFILE, key)
                self.fields[key] = value


class Attachment(object):
    def __init__(self):
        self.fields = {
                       "url" : "",
                       "id" : 0,
                       "filename" : "",
                       "description" : "",
                       "filesize" : 0,
                       "filetype" : "",
                       "date" : 0,
                       "submitter" : ""
        }

    def read(self, line, XMLFILE):
        for key, value in self.fields.items():
            tag = "<"+key+">"
            if tag in line:
                value = collect_field(line, XMLFILE, key)
                self.fields[key] = value
                # return done
                return True

class HistoryEntry(object):
    def __init__(self):
        self.fields = {
                       "id" : 0,
                       "field_name" : "",
                       "old_value" : 0,
                       "date" : 0,
                       "updater" : ""
        }

    def read(self, line, XMLFILE):
        for key, value in self.fields.items():
            tag = "<"+key+">"
            if tag in line:
                value = collect_field(line, XMLFILE, key)
                self.fields[key] = value



class Ticket(object):
    def __init__(self):
        self.fields = {"url" : "",
                       "id" : 0,
                       "status_id" : 0,
                       "category_id" : 0,
                       "group_id" : 0,
                       "resolution_id" : 0,
                       "submitter" : "",
                       "assignee" : "",
                       "closer" : "",
                       "submit_date" : 0,
                       "close_date" : 0,
                       "priority" : 0,
                       "summary" : "",
                       "details" : "",
                       "is_private" : False
        }
        
        self.followups = []
        self.attachments = []
        self.history_entries = []

        self.followup_run = False
        self.followup = 0

        self.attachment_run = False
        self.attachment = 0

        self.history_entry_run = False
        self.history_entry = 0

        self.body = 0

    def get_id(self):
        return self.fields.get('id')

    def read(self, line, XMLFILE):
        for key, value in self.fields.items():
            tag = "<"+key+">"
            if tag in line:
                value = collect_field(line, XMLFILE, key)
                self.fields[key] = value

        # followup
        if "</followup>" in line:
            # add a followup entry to the list
            self.followups.append(self.followup)
            # end a followup entry
            self.followup_run = False

        elif self.followup_run:
            self.followup.read(line, XMLFILE)

        elif "<followup>" in line:
            # start a new followup entry
            self.followup_run = True
            # create a new followup entry
            self.followup = Followup()


        # attachment
        if "</attachment>" in line:
            # add a attachment entry to the list
            self.attachments.append(self.attachment)
            # end a attachment entry
            self.attachment_run = False

        elif self.attachment_run:
            self.attachment.read(line, XMLFILE)

        elif "<attachment>" in line:
            # start a new attachment entry
            self.attachment_run = True
            # create a new attachment entry
            self.attachment = Attachment()
            #print "Attachment - id = "+str(self.id)

        # history entry
        if "</history_entry>" in line:
            # add a history entry to the list
            self.history_entries.append(self.history_entry)
            # end a history entry
            self.history_entry_run = False

        elif self.history_entry_run:
            self.history_entry.read(line, XMLFILE)

        elif "<history_entry>" in line:
            # start a new history entry
            self.history_entry_run = True
            # create a new history entry
            self.history_entry = HistoryEntry()


        # generate the body
        self.body = {
                    'ticket_form.summary' : self.fields.get('summary'),
                    'ticket_form.description' : self.fields.get('details'),
                    'ticket_form.status' : self.fields.get('status_id'),
                    'ticket_form.assigned_to' : self.fields.get('assignee')
                    }

# xmlfile - XML format file containing esmf ticket info
def harvest_tix(xmlfile):
    ticketlist = []
    # open the file
    XMLFILE = open(xmlfile)

    # generic handle to a ticket object
    ticket_run = False

    # iterate through the gigantic xml file
    for line in XMLFILE:
    #while True:
    #    line = XMLFILE.readline()
    #    line = line.rstrip()
    #    if not line: continue

        if "<tasks>" in line:
            return ticketlist

        # end of a ticket
        if '</tracker_item>' in line:
            # add ticket to ticket list
            ticketlist.append(ticket)
            # end ticket_run
            ticket_run = False
            print "TICKET #"+str(len(ticketlist))+\
                ", Sourceforge id: "+str(ticket.fields.get('id'))

        # read a ticket line if a ticket is active
        elif ticket_run:
            ticket.read(line, XMLFILE)

        # beginning of a new ticket
        elif '<tracker_item>' in line:
            # start ticket_run
            ticket_run = True
            # create a new ticket
            ticket = Ticket()


    return ticketlist

if __name__ == '__main__':

    tixlist = harvest_tix('esmf_export.xml')

    # sort by id
    print "Sorting the ticketlist by Sourceforge id..."
    sortedtixlist = sorted(tixlist, key=Ticket.get_id)

    import pdb; pdb.set_trace()
