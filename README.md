Kraken TTY Logging Framework
================================

Ktty Registry Spec
------------------

A ktty_registry will be stored somewhere in the home dir maybe

how to set the title
`echo -en "\033]0;New terminal title\a"`

ktty_registry (fixed width):

| id[8] | open[2] | tty[24]     | log_file[32]        | tty_cd[32] (unique/nullable) | pid[8] | label[48]      | command_segment[remainder]
| ---   | ---     | ---         | ---                 | ---                          | ---    | ---            | ---
| 1     | x       | /dev/pts/22 | /tmp/tmp.HV5ZXN5zwk | term_1                       | 1337   | production log | tee
| 2     |         | /dev/pts/23 | /tmp/tmp.AD34zsdFaw | term_2                       | 13232  | test log       | awk -F '{print $1}'

* `open` indicates that the terminal is available to recieve a stream.
* `tty` indicates the unix device file corresponding to the current terminal
* `log_file` is the file from which logging information is being sourced
* `tty_cd` is a user facing code which identifies the terminal
* `pid` indicates the single process spawned by the piped command
* `label` supplies the terminal with a title
* `command_segment` as the inner user specified portion of the command which filters output from the log file. see [command construction](#cmd_const)

* Sets the terminal title to `OPEN - $TTY`
* [re-]initialize record:
    * `open` is `false`
    * `tty` is set to `$TTY`
    * `tty_cd` is set if specified
    * `pid`, `label` and `command` are empty

`kill` can be run from the effected terminal to kill the pid outputting to it.

`unregister` kills the pid and removes it

`unregister_all` kills all pids and clears the file

1. when a process is created, the record will be marked closed.

A _locked_ state means that nothing can change (EXCEPT LABEL).

**Valid states**:

| id | open | tty       | log_file  | tty_cd | pid       | label | command_segment | meaning
|--- | ---  | ---       | ---       | ---    | ---       | ---   | ---             | ---
| 1  | ?    | populated | ?         | ?      | ?         | ?     | ?               | Registered (minimum setup to exist)
| 1  | X    | populated | ?         | ?      | null      | ?     | ?               | Open -> Registered
| 1  |      | populated | ?         | ?      | ?         | ?     | ?               | Locked -> Registered
| 1  |      | populated | populated | ?      | populated | ?     | ?               | In\_Use -> Locked (_process autolocks_)

Ktty Shell Spec
----------

* p pause         : pause
* r resume        : resume
* e edit          : edit command line
* c color         : color add or remove
* q quit          : unregister the terminal and leave the shell
* h help          : show key
* (anything else) : [silence]

For the shell I installed Term::ReadLine::Perl noting that it supplied `preput` support in the features.
I then installed Term::ReadKey to suppress an error

Here is an example of the prompt working with staring input.

```perl
use Term::ReadLine;
$term = new Term::ReadLine 'ProgramName';
$term->readline('prompt>', 'starting value');
```


Ktty Query functions
---------------

Query language will be a bunch of awk functions that can be included with `@include`

<a name="cmd_const"></a>
Command Construction
--------------------

Whenever ktty spawns a process to send log output, it constructs a piped shell script using a few parameters:

```bash
tail -n0 -f $log_file | tee | colorize $color_map > $tty
```

Ktty allows the user to provide a command either from the script that spawns the process or from the recieving terminal,
which allows filtering of input. to allow for this, part of the command above is made dynamic. The `tee` part can be substituted for
an arbitrary pipe sequence.

Usage: 
-------

* 11 - register a terminal using a code 1
* 12 - register another terminal using code 2
* 13 - register yet another with no code
* 14 - register yet another with no code

a terminal should never be accepting multiple log streams

log streams can be spawned from an external shell.
* one log stream is provided without a code. defaults to tty 13
* another is given code 2, defaulting to 12
* and another with no code, defaulting to 14


Must be from tty:

```bash
ktty reg # enters a shell. allowing the user to type different short commands for pause, resume, etc.
ktty pause # just kills the process
ktty resume # resumes by starting a new process by sourcing from the registry
ktty unreg # kills process and removes from registry
ktty reg $cd 
```

May be from anywhere:

```bash
ktty kill_all
ktty unreg_all
ktty reg -f [file|tty]
ktty $tmp_file
ktty $tmp_file $cd
```

Features
--------

~~Colored grep~~
grep is not really the correct choice here

I'm thinking perl would be a good choice.

TODO
====

Set up public command line functions as stubs

[proof of concept mode] figure out how to set up awk based api

[implement] implement awk functions

