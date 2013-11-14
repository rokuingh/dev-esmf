#!/usr/bin/env python

###############################################################################
#
# combine two esmf json files
# 
# json validator: http://www.jsoneditoronline.org/
#
# Use this script on the files that come out of the parseJSON2.py and 
# parseJSON-interim.py scripts.  This file can be used
# as part 3 of a 3 part workflow to create ESMF tickets compatible with the
# new sourceforge trackers in a new format, and merge them with the currently
# active tickets-interim tracker.
#
# input: tickets.json and tickets-interim.json
# output: tickets-new.json
#
# Ryan O'Kuinghttons
# October 22, 2013
#
###############################################################################

class Ticket(object):
    def __init__(self, buff, ticket_num, date):
        self.buff = buff
        self.num = ticket_num
        self.date = date
    def get_date(self):
        return self.date
    def get_ticket_num(self):
        return self.num


def buffer_tickets(json, old=False):
    json = json.splitlines(True)
    ticket_list = []
    ticket_num = 0
    buff = ""
    date = None
    go = False

    for line in json:
        if not go:
            if '{"tickets": [{\n' == line:
                go = True
        else:

            # end
            if '}],\n' == line:
                # add the separator to the buffer and write the last ticket
                buff += "},{\n"
                ticket = Ticket(buff, ticket_num, date)
                buff = ""
                ticket_list.append(ticket)
                go == False
            else:
                # buffer the line, separator goes at the end of a ticket
                buff += line

                # buffer a ticket
                if "},{\n" in line:
                    ticket = Ticket(buff, ticket_num, date)
                    buff = ""
                    ticket_list.append(ticket)
                # save ticket_num
                elif '"ticket_num"' in line:
                    ticket_num = line.rsplit(":")[1]
                    try:
                        ticket_num = int(ticket_num.rstrip(",\n"))
                    except:
                        ticket_num = 0
                # save created_date
                elif '  "created_date"' in line:
                    import time
                    # old ticket tracker had different time format
                    if old:
                        date = line.split(":  \"", 1)[1]
                        date = date.rstrip("\",\n")
                        date = time.strftime("%Y-%m-%d %H:%M:%S", \
                                            time.strptime(date, "%Y/%m/%d %H:%M:%S"))
                    else:
                        date = line.split(": \"", 1)[1]
                        date = date.rstrip("\",\n")
                        date = time.strftime("%Y-%m-%d %H:%M:%S", \
                                            time.strptime(date, "%Y-%m-%d %H:%M:%S"))

    return ticket_list

def read_file(jsonfile):
    with open(jsonfile, 'r') as f:
        read_data = f.read()
    return read_data

def write_combined_file(tickets, infile, jsonoutfile):
    IF = open(infile, 'r')
    OF = open(jsonoutfile, 'w')

    # buffer until we get to the line to delete
    buff = []
    buff.append('{"tickets": [{\n')
    for ticket in tickets:
        buff.append(ticket.buff)

    # pop the last line of the file (an extra ticket separator)
    splitme = buff[-1]
    del buff[-1]
    saveme = splitme.split('},{')[0]
    buff.append(saveme)

    # write what we have
    for lines in buff:
        OF.write(lines)

    writelines = False
    for line in IF:
        if writelines:
            OF.write(line)
        # start of footer case
        elif "}],\n" in line:
            OF.write(line)
            writelines = True

    IF.close()
    OF.close()

def read_file(jsonfile):
    with open(jsonfile, 'r') as f:
        read_data = f.read()
    return read_data

# must be called after list has been combined
def renumber_new_tickets(json, maxtixnum):
    json = json.splitlines(True)
    json_mod = ""
    buff = ""
    maxnum = maxtixnum
    for line in json:
        # EOF
        if "]}" == line:
            json_mod += buff
            json_mod += line
        elif '"ticket_num":' in line:
            val = line.rsplit(":")[1]
            if 'null' in val:
                val = None
            else:
                val = int(val.rstrip(",\n"))
            if val < 10000:
                new_line = "  \"ticket_num\":  "+str(maxnum+1)+",\n"
                maxnum += 1
                buff += new_line
                continue
        # buffer the line
        buff += line 

    return json_mod

def write_file(json, jsonfile):
    with open(jsonfile, 'w') as f:
        f.write(json)


if __name__ == '__main__':

    oldtickets = read_file('tickets-mod.json')
    newtickets = read_file('tickets-interim-mod.json')

    oldtix = buffer_tickets(oldtickets, True)
    newtix = buffer_tickets(newtickets)

    concatlist = oldtix+newtix

    sortedlist = sorted(concatlist, key=Ticket.get_date)

    write_combined_file(sortedlist, 'tickets-mod.json', 'tickets-new.json')

    # get max ticket and renumber the unnumbered tickets from there..
    maxtix = max(concatlist, key=Ticket.get_ticket_num)
    maxtixnum = maxtix.num
    
    json = read_file('tickets-new.json')

    json = renumber_new_tickets(json, maxtixnum)

    write_file(json, "tickets-new.json")

