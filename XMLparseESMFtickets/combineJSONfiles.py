#!/usr/bin/env python

###############################################################################
#
# combine two esmf json files
# 
# json validator: http://www.jsoneditoronline.org/
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


def buffer_tickets(json, old=False):
    json = json.splitlines(True)
    ticket_list = []
    ticket_num = 0
    buff = ""
    date = None
    go = False

    for line in json:
        if not go:
            if old:
                if '{\n' == line:
                    go = True
            else:
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

def write_file(tickets, infile, jsonoutfile):
    IF = open(infile, 'r')
    OF = open(jsonoutfile, 'w')

    # buffer until we get to the line to delete
    buff = []
    buff.append('{"tickets": [{\n')
    for ticket in tickets:
        buff.append(ticket.buff)

    # pop the last line of the file
    del buff[-1]

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

if __name__ == '__main__':

    oldtickets = read_file('esmf-mod.json')
    newtickets = read_file('tickets-interim-mod.json')

    oldtix = buffer_tickets(oldtickets, True)
    newtix = buffer_tickets(newtickets)

    concatlist = oldtix+newtix

    sortedlist = sorted(concatlist, key=Ticket.get_date)

    write_file(sortedlist, 'tickets-interim-mod.json', 'tickets-new.json')
