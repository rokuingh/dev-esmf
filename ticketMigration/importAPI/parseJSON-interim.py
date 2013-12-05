#!/usr/bin/env python

###############################################################################
#
# Massage a JSON file to hold correct tickets
# 
# json validator: http://www.jsoneditoronline.org/
#
# Use this script on the tickets-interim.json file exported from the ESMF sourceforge 
# tracker to modify some fields for import into a new tracker.  It can be used
# as part 2 of a 3 part workflow to create ESMF tickets compatible with the
# new sourceforge trackers in a new format, and merge them with the currently
# active tickets-interim tracker.
#
#
# input: tickets-interim.json
# output: tickets-interim-mod.json
#
# Ryan O'Kuinghttons
# October 2, 2013
#
###############################################################################


def modify_close_date(json, field, new_field):
    import time
    json = json.splitlines(True)
    json_mod = ""
    for line in json:
        if field in line:
            #"_original_close_date": "2001/Nov/14 10:39:58",
            #"__close_date": "2001/11/14 10:39:58",
            #
            # use the above template to modify the close date
            field_val = line.split(": \"", 1)[1]
            field_val = field_val.rstrip("\",\n")
            if field_val:
                json_mod += "    \""+new_field+"\": \""+field_val+"\",\n"
        else:
            json_mod += line

    return json_mod

def remove_field(json, field):
    json = json.splitlines(True)
    json_mod = ""
    for line in json:
        if field in line:
            pass
        else:
            json_mod += line

    return json_mod

def remove_microseconds(json, field):
    json = json.splitlines(True)
    json_mod = ""
    for line in json:
        if field in line:
            field_val = line.split(".")[0]
            if '"\n' not in field_val:
                field_val = field_val+"\"\n"
            json_mod += field_val
        else:
            json_mod += line

    return json_mod

def remove_comma_from_field(json, field):
    json = json.splitlines(True)
    json_mod = ""
    for line in json:
        if field in line:
            line_minus_comma = line.rsplit(",")[0] + "\n"
            json_mod += line_minus_comma
        else:
            json_mod += line

    return json_mod

def add_comma_to_field(json, field):
    json = json.splitlines(True)
    json_mod = ""
    for line in json:
        if field in line:
            line_plus_comma = line.rsplit("\n")[0] + ",\n"
            json_mod += line_plus_comma
        else:
            json_mod += line

    return json_mod

def replace_field(json, old_field, new_field):
    json = json.splitlines(True)
    runbuff = False
    buff = ""
    new_field_val = ""
    json_mod = ""
    # iterate through the gigantic xml file
    for line in json:
        if '"'+old_field+'":' in line:
            old_field_val = line.rsplit(":")[1]
            old_field_val = old_field_val.rstrip(",\n")
            if old_field_val != " \"\"":
                new_line = "  \""+new_field+"\": "+str(old_field_val)+",\n"
                json_mod += new_line
            else :
                new_line = "  \""+new_field+"\": "+str(new_field_val)+",\n"
                json_mod += new_line
            json_mod += buff
            buff = ""
            runbuff = False
        elif runbuff:
            buff += line
        else:
            # have to hack the search because of similar search fields
            if '"'+new_field+'":' in line:
                new_field_val = line.rsplit(":")[1]
                new_field_val = new_field_val.rstrip(",\n")
                runbuff = True
            else:
                json_mod += line

    return json_mod

# must be run before "_old_ticket_number" field is replaced
def record_old_ticket_number(json):
    json = json.splitlines(True)
    runbuff = False
    buff = ""
    description = ''
    tixnum = 0
    json_mod = ""
    tixnumlist = []
    # iterate through the gigantic xml file
    for line in json:
        if '"ticket_num":' in line:
            # get the ticket number
            tixnum = line.rsplit(":")[1]
            tixnum = tixnum.rstrip(",\n")
            if tixnum != " null":
                tixnum = int(tixnum)
                if tixnum < 20000:
                    tixnumlist.append(tixnum)
            if runbuff:
                buff += line
            else:
                json_mod += line
        elif '"_old_ticket_number":' in line:
            # get the ticket number
            tixnum = line.rsplit(":")[1]
            tixnum = tixnum.rstrip(",\n")
            if tixnum != " null":
                tixnum = int(tixnum)
                if tixnum < 20000:
                    tixnumlist.append(tixnum)
            if tixnumlist:
                oldtixnums = "Interim ticket number: "
                for num in tixnumlist:
                    oldtixnums += str(num) + ", "
                oldtixnums = oldtixnums.rstrip(', ')
                oldtixnums += "\\n\\n"
                # modify the description line and add buffer to file
                description = oldtixnums + description
            # write out the new description line
            description = '  "description": ' + '"' + description + '",\n'
            buff = description + buff
            json_mod += buff
            json_mod += line
            buff = ""
            runbuff = False
            tixnumlist[:] = []
        elif runbuff:
            buff += line
        else:
            # have to hack the search because of similar search fields
            if '"description":' in line:
                description = line.rsplit(': "')[1]
                description = description.rstrip('",\n')
                runbuff = True
            else:
                json_mod += line

    return json_mod

def replace_field_alreves(json, old_field, new_field):
    json = json.splitlines(True)
    runbuff = False
    buff = ""
    old_field_val = ""
    json_mod = ""
    # iterate through the gigantic xml file
    for line in json:
        if '"'+new_field+'":' in line:
            json_mod += buff
            if old_field_val != " \"\"":
                new_field_val = "  \""+new_field+"\": "+str(old_field_val)+"\n"
                json_mod += new_field_val
            else:
                json_mod += line
            buff = ""
            runbuff = False
        elif runbuff:
            buff += line
        else:
            # have to hack the search because of similar search fields
            if '"'+old_field+'":' in line:
                old_field_val = line.split(":", 1)[1]
                old_field_val = old_field_val.rstrip(",\n")
                runbuff = True
            else:
                json_mod += line

    return json_mod

def read_file(jsonfile):
    with open(jsonfile, 'r') as f:
        read_data = f.read()
    return read_data

def write_file(json, jsonfile):
    with open(jsonfile, 'w') as f:
        f.write(json)


if __name__ == '__main__':

    json = read_file('tickets-interim.json')

    json = remove_field(json, '"reported_by_id":')

    json = record_old_ticket_number(json)

    json = replace_field(json, '_old_ticket_number', 'ticket_num')

    json = replace_field(json, '_original_creator', 'reported_by')
    
    json = replace_field_alreves(json, '_original_creation_date', 'created_date')

    json = modify_close_date(json, '"_original_close_date":', "_close_date")

    json = remove_comma_from_field(json, '"_origin":')

    json = remove_microseconds(json, '"created_date":')

    write_file(json, "tickets-interim-mod.json")
