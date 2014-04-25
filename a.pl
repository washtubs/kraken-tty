use Term::ReadLine;

chomp($tty = `tty`);
$ENV{"TTY"}=$tty;
chomp($id = `ktty register`);
$ENV{"ID"}=$id;
chomp($record_str = `ktty get-all`);
@record_arr = split(",",$record_str);
($id, $locked, $tty, $log_file, $tty_cd, $pid, $label, $command_segment) = @record_arr;

$green="\e[1;32m";
#print `tput cuf 1`;
$reset="\033[0m";
$term = new Term::ReadLine 'ProgramName';
$term->readline("$green$tty$reset \[$id\] ktty>  ",$command_segment);
#$f = $term->Features;
#%derefd = %$f;
#for my $key (sort keys %derefd) {
    #print "$key => $derefd{$key}\n";
#}
#$derefd{"preput"}=1;
#$term->Features = \%derefd;
#$term->readline('prompt>', 'starting value');
