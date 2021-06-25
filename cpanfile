requires 'perl', 'v5.10';
requires 'Pod::Simple', '3.42';
requires 'HTML::Escape', '1.10';
requires 'Carp', '0';
requires 'version', '0';
requires 'strict', '0';
requires 'warnings', '0';
requires 'parent', '0';
requires 'utf8', '0';

on test => sub {
  requires 'Test2::Suite', '0.96';
};
