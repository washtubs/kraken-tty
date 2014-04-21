@include "include.awk"
{
    #print extract("command_segment")
    #print current_map["tty"]
    #print current_map["id"]
    print $0
}

END{
    #record insertion
    map["id"]="44"
    map["open"]="X"
    map["tty"]="/dev/pts/43"
    map["log_file"]=""
    map["tty_cd"]=""
    map["pid"]=""
    map["label"]=""
    map["command_segment"]="tee"
    insert_record(map)
    }
