#!/usr/bin/env bash
registry=sample_registry
std_temp=$(mktemp)
# Public Interface

function register() {
    awk '@include "include.awk"; {print_current_record()} END { map["locked"]=" "; map["tty"]="'"$TTY"'"; map["tty_cd"]="'"$TTY_CD"'"; print insert(map) ; }' $registry > $std_temp
    mv $std_temp sample_registry
}

function unregister() {
    if [ ! -z "$ID" ]
    then
        awk '@include "include.awk"; { if(current_map["id"]!="'"$ID"'") {print_current_record()} }' $registry > $std_temp
    elif [ ! -z "$TTY" ]
    then
        awk '@include "include.awk"; { if(current_map["tty"]!="'"$TTY"'") {print_current_record()} }' $registry > $std_temp
    fi
    mv $std_temp sample_registry
}

function update() {
# updateable values
#  log_file  | tty_cd | label | command_segment 
    if [ ! -z "$ID" ]
    then
        lookup_col="id"
        lookup_val=$ID
    elif [ ! -z "$TTY" ]
    then
        lookup_col="tty"
        lookup_val=$TTY
    fi
    VALUE=$(echo $VALUE | sed 's/"/\\"/g') # FIXME double quotes work but this is still very unsecure. think injects.
    awk '@include "include.awk"; { \
        if(current_map["'"$lookup_col"'"]=="'"$lookup_val"'") { \
            if (current_map["locked"]=="" || "'"$COLUMN"'"=="label"  \
                || ("'"$COLUMN"'"=="locked" && current_map["pid"]=="") \
                || ("'"$COLUMN"'"=="pid" && current_map["locked"]=="X")){ \
                current_map["'"$COLUMN"'"]="'"$VALUE"'";  \
            }  \
            else { \
                print "ERROR: tried to update locked record." > "/dev/stderr" \
            }  \
            print_current_record() \
        }  \
        else { \
            print_current_record() \
        } }' $registry > $std_temp
    mv $std_temp sample_registry

}

function get() { #public update function
    COLUMN=$1
    if [ ! -z "$ID" ]
    then
        awk '@include "include.awk"; { if(current_map["id"]=="'"$ID"'") { printf current_map["'"$COLUMN"'"] } }' $registry
    elif [ ! -z "$TTY" ]
    then
        awk '@include "include.awk"; { if(current_map["tty"]=="'"$TTY"'") { printf current_map["'"$COLUMN"'"]; exit; } }' $registry
    fi
    
}

function status() { #public update function
    COLUMN=$1
    if [ ! -z "$ID" ]
    then
        awk '@include "include.awk"; { if(current_map["id"]=="'"$ID"'") { printf derive_state() } }' $registry
    elif [ ! -z "$TTY" ]
    then
        awk '@include "include.awk"; { if(current_map["tty"]=="'"$TTY"'") { printf derive_state(); exit; } }' $registry
    fi
    
}

function set_field() { #public update function
    field=$1
    VALUE=$2
    if [ $field == "title" ] 
    then
        echo -en "\033]0;$VALUE\a" > $TTY
        COLUMN="label" update
    elif [ $field == "log" ]
    then
        COLUMN="log_file" update
    elif [ $field == "code" ]
    then
        COLUMN="tty_cd" update
    elif [ $field == "command" ]
    then
        echo $VALUE
        COLUMN="command_segment" update
    fi
}

function lock() {
    COLUMN="locked"; VALUE="X" update
}

function unlock() {
    COLUMN="locked"; VALUE="" update
}

function pause() {
    if [ ! -z "$ID" ]
    then
        kill -9 $(awk '@include "include.awk"; { if(current_map["id"]=="'"$ID"'" && current_map["pid"]!="") {printf current_map["pid"]} }' $registry)
        COLUMN="pid" VALUE="" update
    elif [ ! -z "$TTY" ]
    then
        kill -9 $(awk '@include "include.awk"; { if(current_map["tty"]=="'"$TTY"'" && current_map["pid"]!="") {printf("%s ",current_map["pid"])} }' $registry)
        COLUMN="pid" VALUE="" update
    fi
}

function resume() {
    if [ ! -z "$ID" ]
    then
        if [ "$(get locked)" == "X" ]
        then
            log_file=$(get log_file)
            tty=$(get tty)
            command_segment=$(get command_segment)
            eval "tail -n0 -f $log_file | $command_segment > $tty &disown" 
            COLUMN="pid" VALUE="$!" update
        fi
    elif [ ! -z "$TTY" ]
    then
        ids=$(mktemp)
        awk '@include "include.awk"; {if (current_map["tty"]=="'"$TTY"'") {print current_map["id"]}}' $registry > $ids
        while read ID
        do
            #echo "id" $ID $(get locked)
            if [ "$(get locked)" == "X" ]
            then
                log_file=$(get log_file)
                tty=$(get tty)
                command_segment=$(get command_segment)
                eval "tail -n0 -f $log_file | $command_segment > $tty &disown" 
                COLUMN="pid" VALUE="$!" update
            fi
        done < $ids
        rm $ids
    fi

}

#function killall() {

#}

#function clean() { # leave terminals registered with there codes, but everything else gets set back to default

#}

#function cleanall() { # leave terminals registered with there codes, but everything else gets set back to default

#}

command=$1
shift
for arg in "${array[@]}"; do
   echo "$arg"
done
if [ $command == "register" ]
then
    register "$1" "$2" "$3"
elif [ $command == "unregister" ]
then
    unregister "$1" "$2" "$3"
elif [ $command == "update" ]
then
    update "$1" "$2" "$3"
elif [ $command == "pause" ]
then
    pause "$1" "$2" "$3"
elif [ $command == "resume" ]
then
    resume "$1" "$2" "$3"
elif [ $command == "get" ]
then
    get "$1" "$2" "$3"
elif [ $command == "set" ]
then
    set_field "$1" "$2" "$3"
elif [ $command == "lock" ]
then
    lock "$1" "$2" "$3"
elif [ $command == "unlock" ]
then
    unlock "$1" "$2" "$3"
elif [ $command == "status" ]
then
    status "$1" "$2" "$3"
fi
