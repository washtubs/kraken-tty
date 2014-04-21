use Term::ReadLine;
$term = new Term::ReadLine 'ProgramName';
$term->readline('prompt>', 'starting value');
#$f = $term->Features;
#%derefd = %$f;
#for my $key (sort keys %derefd) {
    #print "$key => $derefd{$key}\n";
#}
#$derefd{"preput"}=1;
#$term->Features = \%derefd;
#$term->readline('prompt>', 'starting value');
