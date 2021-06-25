#!/usr/script/perl
use strict;
use warnings;
use Test2::V0;
use Mana::Doc;

plan 11;

my $pod = <<'POD_EOF';
=pod

=head1 NAME

in-memory - In memory string for pod-parsing tests

=cut

POD_EOF
my $pod_file = 't/test.pod';
my $html = Mana::Doc->new(target => 'HTML');

local $@ = "";
ok defined eval {
  $html->parse(\$pod);
  1;
}, 'Mana::Doc->parse parses in-memory strings', "error: $@";

ok defined eval {
  open FH, '<', $pod_file
      or die q/couldn't open file test.pod/;
  $html->parse(\*FH);
  close FH;
  1;
}, 'Mana::Doc->parse parses bareword filehandles', "error: $@";

ok defined eval {
  open my $fh, '<', $pod_file
      or die q/couldn't open file test.pod/;
  $html->parse($fh);
  1;
}, 'Mana::Doc->parse parses variable filehandles', "error: $@";

ok defined eval {
  $html->parse([split /^/, $pod]);
  1;
}, 'Mana::Doc->parse parses array of strings as lines', "error: $@";

ok !defined eval {
  $html->parse('croak_on_this');
  1;
}, 'Mana::Doc->parse croaks on non-existent file';

ok !defined eval {
  $html->parse({hash => 'ref', good => 0});
  1;
}, 'Mana::Doc->parse croaks on hash-ref';

ok !defined eval {
  $html->parse('bad');
  $html->source;
}, 'Mana::Doc->source is undef after failed parse';

is eval {
  $html->parse(\$pod);
  $html->source;
}, 'in-memory', 'Mana::Doc->source reports in-memory strings', "error: $@";

like eval {
  open FH, '<', $pod_file
      or die q/couldn't open file test.pod/;
  $html->parse(\*FH);
  close FH;
  $html->source;
}, qr/^filehandle: GLOB\([^)]+\)/, 'Mana::Doc->source reports bareword filehandles', "error: $@";

like eval {
  open my $fh, '<', $pod_file
      or die q/couldn't open file test.pod/;
  $html->parse($fh);
  $html->source;
}, qr/^filehandle: GLOB\([^)]+\)/, 'Mana::Doc->source reports variable filehandles', "error: $@";

is eval {
  $html->parse([ split /^/, $pod ]);
  $html->source;
}, 'array of lines', 'Mana::Doc->source reports array of lines', "error: $@";
