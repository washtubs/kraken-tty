BEGIN{

    if (QUERY=="") 
        QUERY=0

    if (ALWAYS_EXTRACT_MAP=="")
        ALWAYS_EXTRACT_MAP=1

    if (VALIDATE=="")
        VALIDATE=0
    else if (VALIDATE)
        ALWAYS_EXTRACT_MAP=1

    field_lengths["id"]=8
    field_lengths["open"]=2
    field_lengths["tty"]=24
    field_lengths["log_file"]=32
    field_lengths["tty_cd"]=32
    field_lengths["pid"]=8
    field_lengths["label"]=48
    field_lengths["command_segment"]=0

    field_order[0]="id"
    field_order[1]="open"
    field_order[2]="tty"
    field_order[3]="log_file"
    field_order[4]="tty_cd"
    field_order[5]="pid"
    field_order[6]="label"
    field_order[7]="command_segment"

    id_modulus=256
    max_id=0
    }

function validate() {
    # check for duplicate ids
    if (current_map["id"] in ids)
        print "ERROR: duplicate id "current_map["id"]
    else
        ids[current_map["id"]]=1
    # check for duplicate tty_cds
    if (current_map["tty_cd"] in tty_cds)
        print "ERROR: duplicate tty_cd "current_map["tty_cd"]
    else
        tty_cds[current_map["tty_cd"]]=1
    state = derive_state()
    if (state=="invalid")
        print "Invalid state! "current_map["open"],current_map["tty"],
        current_map["log_file"],current_map["pid"],current_map["command_segment"]

    
}

# TODO update valid states in readme
derive_state() {
    if (ALWAYS_EXTRACT_MAP==0)
        extract_map()
    if (current_map["pid"]=="")
        in_use=0
    else
        in_use=1
    if (current_map["open"]=="X")
        open=1 #open
    else
        open=0 #locked
    if (current_map["command_segment"]!="" &&  # TODO: ensure validity as well
        current_map["tty"]!="" && # TODO: ensure validity as well
        current_map["log_file"]!="" && # TODO: ensure validity as well
        !open) 
        {
            state="ready"
            if (in_use)
                state="running"
        }
    #for below checks, since it's not ready, it better not be in use
    else if (!open && !in_use)
        state="locked" # but not ready
    else if (open && !in_use)
        state = "open" # but not ready
    else 
        state="invalid"
    return state
}

function trim(str) {
    #print "before "str
    gsub(/^[ \t]*/,"",str)
    gsub(/[ \t]*$/,"",str)
    #print "after  "str
    return str
}


function get_start(field_name) {
    position=1
    for (i in field_order) {
        if (field_name!=field_order[i])
            position+=field_lengths[field_order[i]]
        else
            return position
    }
}

function extract(field_name) {
    if (field_name=="command_segment")
        ex = substr($0,get_start(field_name))
    else
        ex =  substr($0,get_start(field_name),field_lengths[field_name])
    ex = trim(ex)
    return ex
}

function extract_map() {
    for (i in current_map) #clear it out
        delete current_map[i]
    for (i in field_order) { #load it up
        current_name=field_order[i]
        current_map[current_name]=extract(current_name)
    }
}

function print_record(record_map) {
    for (i in field_order) {
        field_name=field_order[i]
        printf ("%"field_lengths[field_name]"s",record_map[field_name])
    }
    printf "\n"
}

function insert_record(map) {
    if (!end)
        print "You may only insert records in the end block."
    else {
        map["id"] = (max_id+1)%id_modulus
        print_record(map)
    }
}

ALWAYS_EXTRACT_MAP{
    extract_map()
}

VALIDATE{
    validate()
}

{
    # TODO make it so this only happens when an insert is called?
    # get max id
    id=extract("id")+0
    if ( id > max_id)
        max_id = id
}

END{
    end=1
}
