#!/usr/bin/env python2
# -*- coding: utf-8 -*-
from curses import *
import readline
import cmd
import subprocess
import os

##### imported from other shell

setupterm("xterm")
def get_string(*args):
    return tparm(tigetstr(args[0]),*args[1::]);


# The Formatstack is the other class that is capable of printing to the terminal. 
# the difference is that it does not effect the cursor position

#modified so that they return strings rather than print.
class FormatStack:
    ti = []
    @staticmethod
    def push(tparms):
        if (not (tparms[0] in FormatStack.ti)):
            FormatStack.ti.append(tparms[0])
        return get_string(*tparms)
    @staticmethod
    def pop():
        return ({
            "setf":get_string(*["setf",9]),
            "setb":get_string(*["setb",9]),
            "bold":get_string(*["sgr0"]), #TODO theres no way to turn off fucking bold lmao. shut them all down!
            "smul":get_string(*["rmul"])
        }[FormatStack.ti.pop()]
        )
    @staticmethod
    def clear():
        FormatStack.ti = []
        sys.stdout.write(get_string("sgr0"))

fs = FormatStack()

readline.parse_and_bind('tab: complete')
readline.parse_and_bind('set editing-mode vi')
#### end import

id_stack = []

def push_id(id):
    id_stack.append(id)
    os.environ['ID'] = id_stack[-1]

def pop_id():
    if id_stack:
        id_stack.pop()
    if id_stack:
        os.environ['ID'] = id_stack[-1]
    else:
        os.environ['ID'] = ""

selector =-1
def select():
    direction = "right"
    global selector
    if direction == "right":
        selector = ((selector + 2) % (len(registry) + 1) - 1)
    #elif direction == "left":
        #selector = ((selector) % (len(registry) + 1) - 1)

    if selector == -1:
        pop_id()
    else:
        for index,id in enumerate(registry):
            if index == selector:
                pop_id()
                push_id(id)
    return(txt + "asd")


def syscall(*params):
    proc = subprocess.Popen(*params, stdout=subprocess.PIPE, shell=False)
    return proc.communicate()

def env(): #returns the selected id or "tty"
    global id_stack
    if id_stack:
        return id_stack[-1]
    else:
        return "tty"

class KttyRecord:
    def sync_values(self):
        push_id(self.id)
        (out, err)=syscall(["ktty","get-all"])
        (
        #note id is left unupdated
        _dummy        , self.locked          , self.tty   ,
        self.log_file , self.tty_cd          , self.pid   ,
        self.label    , self.command_segment , self.state
        ) = out.split(",")
        pop_id()
    def __init__(self, id=0):
        if id==0:
            (out, err)=syscall(["ktty","register"])
            self.id = out.rstrip()
            push_id(self.id) #automatically switch to that record when registering for the first time
        else:
            self.id = str(id)
        self.sync_values()

registry = {}

def register_new_ids():
    (out, err) = syscall(["ktty","get","id"])
    ids = out.split(",")
    for id in ids:
        if id not in registry:
            ktty = KttyRecord(id)
            registry[ktty.id] = ktty

def sync_dirty_ids():
    return


def initialize():
    (out, err)=syscall("tty")
    os.environ['TTY'] = out.rstrip()

    #check if we have any records registered already
    (out, err) = syscall(["ktty","get","id"])
    if out == "": #nothing exists, so register a new one.
        ktty=KttyRecord()
        registry[ktty.id] = ktty
    else: #gather these up
        register_new_ids()


def hi(asd,gg,hfg,xcvx):
    print( "hi")
    return ["asd","fds"]

initialize()
#readline.set_completer(hi)
#readline.set_completion_display_matches_hook(hi)
#print readline.get_completer_delims()
#print readline.get_completion_type()

#readline.set_pre_input_hook(build_prompt)

#cmd = cmd.Cmd()
##cmd.preloop = build_prompt
#cmd.prompt = prompt
#cmd.complete_default = hi


class Kttysh(cmd.Cmd):
    def completedefault(self,text, line, begidx, endidx):
        readline.redisplay()
        select()
        #print( "hi")
        return []
    def build_prompt(self):
        print "hi"
        default_color=9
        running_color=3
        ready_color=2
        locked_color=4
        unlocked_color=5
        invalid_color=6

        #start with the tty or alternatively tty_cd
        for id in registry:
            tty_cd = registry[id].tty_cd  
            break #just get the first one as it should be the same for all
        if tty_cd == "":
            label = os.environ['TTY']
        else:
            label = tty_cd
        if env() == "tty":
            label = fs.push(["bold"]) + label + fs.pop()

        id_list = "["
        delim = ""
        for id in registry:
            color = ({
            "running":running_color,
            "ready":ready_color,
            "locked":locked_color,
            "unlocked":unlocked_color,
            "invalid":invalid_color
            }
            [registry[id].state])
            colored_id = fs.push(["setf",color]) + id + fs.pop()
            if env() == id:
                colored_id = fs.push(["bold"]) + colored_id + fs.pop()
            id_list = id_list + delim + colored_id
            delim = ", "
        id_list = id_list + "]"
        self.prompt = label + " " + id_list + " » "
    def preloop(self):
        prompt = self.build_prompt()

kttysh = Kttysh()
kttysh.cmdloop()

readline.set_pre_input_hook(kttysh.build_prompt)

#while True:
    #line = raw_input(prompt)
    #if line == 'stop':
        #break
    #print( ">>> " + line)

    #post()
    # register_new_ids
    # sync_dirty_ids
