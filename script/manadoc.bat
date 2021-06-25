@rem = '--*-Perl-*--
@set "ErrorLevel="
@if "%OS%" == "Windows_NT" @goto WinNT
@perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
@set ErrorLevel=%ErrorLevel%
@goto endofperl
:WinNT
@perl -x -S %0 %*
@set ErrorLevel=%ErrorLevel%
@if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" @goto endofperl
@if %ErrorLevel% == 9009 @echo You do not have Perl in your PATH.
@goto endofperl
@rem ';
#!/usr/script/perl
#line 16
use v5.10;
use strict;
use warnings;
use utf8;
use version; our $VERSION = version->declare('v0.1');

use Getopt::Long qw/
    &VersionMessage
    &HelpMessage
    :config
    auto_help
    auto_version
    bundling
    gnu_compat
    no_auto_abbrev
    no_bundling_override
    no_getopt_compat
    no_ignore_case
    no_ignore_case_always
    no_require_order
/;
use Pod::Usage;
use Mana::Doc;

my %config = (
    target => 'HTML',
    output => undef
);
GetOptions(
    'help|?|h'   => sub {HelpMessage(-msg => 'manadoc - Mana::Doc command line interface')},
    'version|v'  => sub {VersionMessage(-msg => "manadoc - Mana::Doc command line interface\n")},
    'target|T=s' => \$config{target},
    'output|o=s' => \$config{output},
) or pod2usage(-verbose => 1, -exitval => 2);

for my $file (@ARGV) {
  my $doc = Mana::Doc->new(%config);
  $doc->parse($file);
  $doc->run;
}

__END__

=pod

=head1 NAME

manadoc - Mana::Doc command line interface

=head1 SYNOPSIS

manadoc [-?vT] <files...>

=head1 OPTIONS

=over 2

=item B<-?>, B<-h>, B<--help>

Print short usage help and stop processing.

=item B<-v>, B<--version>

Print version information and stop processing.

=item B<-T> I<target>, B<--target>=I<tgt>

Sets the output target to I<tgt>. Default is C<HTML>.

=back

=head1 DESCRIPTION

The B<manadoc> script uses the Mana::Doc module to convert files from POD
or Mana::Doc format to different markup formats.

=cut
__END__
:endofperl
@set "ErrorLevel=" & @goto _undefined_label_ 2>NUL || @"%COMSPEC%" /d/c @exit %ErrorLevel%