# Mana::Doc(::.*)?
requires 'perl',         'v5.10';
requires 'Pod::Simple',  '3.42';
requires 'HTML::Escape', '1.10';
requires 'Readonly',     '2.00';
requires 'Carp',         '0';
requires 'version',      '0';
requires 'strict',       '0';
requires 'warnings',     '0';
requires 'utf8',         '0';
# manadoc
requires 'Getopt::Long', '2.52';
requires 'Pod::Usage',   '2.01';

on test => sub {
  requires 'Test2::Suite', '0.000140';
};
