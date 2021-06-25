use strict;
use warnings;
use Test2::V0;

plan 2;

is eval {
  require Mana::Doc;
  Mana::Doc->import;
  1;
}, 1, 'Mana::Doc compiles';

is eval {
  require Mana::Doc::HTML;
  Mana::Doc::HTML->import;
  1;
}, 1, 'Mana::Doc::HTML compiles';

