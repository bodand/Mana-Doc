package Mana::Doc::HTML;

use v5.10;
use strict;
use warnings;
use utf8;
use version; our $VERSION = version->declare('v0.1.1');

use HTML::Escape qw/escape_html/;
use Pod::Simple::SimpleTree;
require Carp;

my $dbg_tab = 0;
my $css_text = <<'CSS_EOF';
:root {
  --shadow-border: #f5f5f5;
  --shadow-purple: #6000b5;
  --shadow-blue:   #01cdff;
  --shadow-green:  #1dff89;
  --shadow-yellow: #d7d243;
  --shadow-pink:   #8843d7;

  --header-shadow: 3px 3px 1px 1px;
  --border-width: 1px;

  --bg-color: #1d1f21;
  --fg-color: #c5c8c6;
  --pale-fg-color: #696969;
}

html, body {
  margin: 0;
  padding: 0;
  background-color: var(--bg-color);
  color: var(--fg-color);
}

a:link, a:visited, a:active {
  color: var(--shadow-blue);
  text-decoration: none;
}

.pod_content {
  font-family: "IBM Plex Serif", serif;
}

.pod_format_C, .pod_code {
  font-family: "IBM Plex Mono", monospace;
}

.pod_verbatim {
  padding: 10px;
  width: 84%;
  margin: 25px auto;
  background-color: var(--bg-color);
  border: var(--border-width) solid var(--shadow-border);
  box-shadow: 7px 7px 3px 1px var(--shadow-purple);
}

.pod_format_B {
  font-weight: bold;
}

.pod_format_I {
  font-style: italic;
}

.pod_header {
  font-family: "IBM Plex Sans", sans-serif;
  width: min-content;
  margin: 10px 12px;
  padding: 5px 20px;
  border: var(--border-width) solid var(--shadow-border);
}

.pod_header_1 {
  box-shadow: var(--header-shadow) var(--shadow-blue);
}

.pod_header_2 {
  box-shadow: var(--header-shadow) var(--shadow-green);
}

.pod_paragraph {
  padding: 5px 20px;
}

.pod_format_H {
  color: var(--pale-fg-color);
}

.pod_list_header {
  width: max-content;
  margin: 0 40px;
  border: var(--border-width) solid var(--shadow-border);
  box-shadow: var(--header-shadow) var(--shadow-yellow);
}

.pod_table {
  width: max-content;
  margin: 10px 12px;
  padding: 5px 20px;
  border: var(--border-width) solid var(--shadow-border);
  box-shadow: var(--header-shadow) var(--shadow-pink);
}

.pod_table_cell {
  padding: 1px 15px;
}

._pod_table_head_bar {
  width: 70%;
  margin: 0 auto;
  color: var(--shadow-border);
}

.pod_header a, .pod_list_header a {
  color: var(--fg-color);
}
CSS_EOF

sub new :prototype($%) {
  my $class = shift;
  if (@_ % 2 != 0) {
    Carp::croak("incorrect arity of arguments passed to constructor of @{[ __PACKAGE__ ]}");
  }
  my %opts = (@_);
  my $output = undef;

  if (ref($opts{output}) eq 'SCALAR'
      || ref($opts{output}) eq 'ARRAY'
      || ref($opts{output}) eq 'GLOB') {
    $output = $opts{output};
  }
  elsif (ref($opts{output}) eq '') {
    local $! = 0;
    open $output, '>', $opts{output}
        or die "cannot open output file: $opts{output}: $!";
  }
  else {
    Carp::croak('cannot use output of type ' . ref($opts{output}));
  }

  my $self = {
      output       => $output,
      omit_css     => $opts{omit_css} // 0,
      embed_css    => $opts{embed_css} // 1,
      ext_css_name => $opts{ext_css_name},

      in_dl        => 0,
      in_dd        => 0,
      in_table     => 0,
      tree         => undef,
      source       => undef
  };
  $self->{ext_css_name} //= $self->{omit_css} ? undef : 'mana_doc.css';

  bless $self, __PACKAGE__;
  return $self;
}

sub parse :prototype($$) {
  my ($self, $src) = @_;
  my $pod = Pod::Simple::SimpleTree->new;
  $pod->complain_stderr(1);
  $pod->nbsp_for_S(1);
  $pod->accept_directive_as_processed('table');
  $pod->accept_directive_as_processed('row');
  $pod->accept_targets(qw/html mana_html/);
  $pod->accept_codes(qw/H T/);

  if (ref($src) eq 'SCALAR') {
    $self->{source} = 'in-memory';
    $self->{tree} = $pod->parse_string_document($$src)->root;

  }
  elsif (ref($src) eq 'ARRAY') {
    $self->{source} = 'array of lines';
    $self->{tree} = $pod->parse_lines(@$src)->root;

  }
  elsif (ref($src) eq 'GLOB') {
    $self->{source} = "filehandle: $src";
    $self->{tree} = $pod->parse_file($src)->root;

  }
  elsif (ref($src) eq '') {
    $self->{source} = "file: $src";
    $self->{tree} = $pod->parse_file($src)->root;

  }
  else {
    $self->{source} = undef;
    Carp::croak('cannot parse input of type ' . ref($src));
  }
}

sub source :prototype($) {
  my ($self) = @_;
  return $self->{source};
}

sub run :prototype($) {
  my ($self) = @_;
  if (!$self->{omit_css} && !$self->{embed_css}) {
    open my $css, '>', $self->{css_file}
        or die "cannot open css file: $self->{css_file}: $!";
    print $css $css_text;
  }
  $self->_transform($self->{tree});
}

sub _strip_formats_and_join :prototype(@);
sub _strip_formats_and_join :prototype(@) {
  my (@elements) = @_;
  my $str = '';

  for my $elem (@elements) {
    if (ref($elem) eq '') {
      $str .= $elem;
    }
    elsif (ref($elem) eq 'ARRAY') {
      $str .= _strip_formats_and_join($elem->@[2 .. $#$elem]);
    }
  }

  return $str;
}

sub _anchorize :prototype($) {
  local ($_) = (shift);
  s/(\W)/ord $1/eg;
  return $_;
}

sub _output :prototype($$;$) {
  my ($self, $text, $where) = @_;
  $where //= $self->{output};

  if (!defined $where) {
    print STDOUT $text;
  }
  elsif (ref($where) eq 'SCALAR') {
    $$where .= $text;
  }
  elsif (ref($where) eq 'ARRAY') {
    local $_ = '';
    push @$where, $_ for split /^/, $text;
  }
  else {
    print $where $text;
  }
}

sub _start_dd :prototype($) {
  my ($self) = @_;
  if ($self->{in_dl}) {
    $self->_output(q{<dd class="pod_list_body pod_list pod_content">});
  }
}

sub _end_dd :prototype($) {
  my ($self) = @_;
  if ($self->{in_dl}) {
    $self->_output(q{</dd>});
  }
}

sub _transform :prototype($_);

sub _transform_Document :prototype($$@) {
  state $html_start = <<'HTML_EOF';
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Mana::Doc Documentation</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Serif:ital@0;1&display=swap" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital@0;1&display=swap" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:ital@0;1&display=swap" rel="stylesheet">
  <link rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.0.1/styles/hybrid.min.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.0.1/highlight.min.js"></script>
  <script>hljs.highlightAll();</script>
HTML_EOF
  state $html_end = <<'HTML_EOF';
</body>
</html>
HTML_EOF

  my ($self, undef, @children) = @_;
  # Title fix
  if (eval {$children[0]->[2] =~ /\ANAME\z/i}) {
    $self->_output($html_start =~ s/Mana::Doc Documentation/$children[1]->[2]/r);
  }
  else {
    $self->_output($html_start);
  }

  # CSS
  if (!$self->{omit_css}) {
    if ($self->{embed_css}) {
      $self->_output(qq{<style>\n$css_text\n</style>});
    }
    else {
      Carp::croak 'ext_css_name needs to be defined if omit_css is unset'
          if !defined($self->{ext_css_name});

      local $! = 0;
      open my $css, '>', $self->{ext_css_name}
          or die "cannot open to-be-generated external CSS file: $self->{ext_css_name}: $!";
      $self->_output(qq{<link rel="stylesheet" type="text/css" href="$self->{ext_css_name}">\n});
      print $css $css_text;
    }
  }
  elsif ($self->{omit_css}) {
    if (defined $self->{ext_css_name}) {
      $self->_output(qq{<link rel="stylesheet" type="text/css" href="$self->{ext_css_name}">\n});
    }
  }

  $self->_output(qq{</head>\n<body>\n});
  $self->_transform($_) for @children;
  $self->_output($html_end);
}

sub _transform_head_n :prototype($$$@) {
  my ($lvl, $self, undef, @children) = @_;

  Carp::croak("head$lvl element must have a name: children: @_")
      if @children < 1;

  my $head_start;
  my $head_end;

  if ($lvl <= 3) {
    my $name = _anchorize(_strip_formats_and_join(@children));

    $head_start = <<"HEAD_EOF";
<h$lvl class="pod_header_$lvl pod_header pod_content">
  <a name="$name"></a>
  <a href="#$name">
HEAD_EOF
    $head_end = <<"HEAD_EOF";
</a></h$lvl>
HEAD_EOF
  }
  else {
    $head_start = <<"HEAD_EOF";
<h$lvl class="pod_header_$lvl pod_header pod_content">
HEAD_EOF
    $head_end = <<"HEAD_EOF";
</h$lvl>
HEAD_EOF
  }

  $self->_output($head_start);
  $self->_transform($_) for @children;
  $self->_output($head_end);
}

sub _transform_head1 :prototype($$@) { unshift @_, 1; goto &_transform_head_n; }
sub _transform_head2 :prototype($$@) { unshift @_, 2; goto &_transform_head_n; }
sub _transform_head3 :prototype($$@) { unshift @_, 3; goto &_transform_head_n; }
sub _transform_head4 :prototype($$@) { unshift @_, 4; goto &_transform_head_n; }
sub _transform_head5 :prototype($$@) { unshift @_, 5; goto &_transform_head_n; }
sub _transform_head6 :prototype($$@) { unshift @_, 6; goto &_transform_head_n; }

sub _transform_Para :prototype($$@) {
  state $p_start = <<'P_EOF';
<p class="pod_paragraph pod_content">
P_EOF
  state $p_end = <<'P_EOF';
</p>
P_EOF

  my ($self, undef, @children) = @_;
  $self->_start_dd;
  $self->_output($p_start);
  $self->_transform($_) for @children;
  $self->_output($p_end);
  $self->_end_dd;
}

sub _transform_Verbatim :prototype($$@) {
  state $pre_start = # can't use heredoc for empty line creeps in
      '<pre class="pod_verbatim pod_content"><code class="pod_code pre_content">';
  state $pre_end = <<'PRE_EOF';
</code></pre>
PRE_EOF

  my ($self, undef, @children) = @_;
  $self->_start_dd;
  $self->_output($pre_start);
  $self->_transform($_) for @children;
  $self->_output($pre_end);

}

sub _transform_fmt :prototype($$$@) {
  my ($fmt, $self, undef, @children) = @_;

  my $fmt_start = qq{<span class="pod_format_$fmt pod_format">};
  state $fmt_end = qq{</span>};

  $self->_output($fmt_start);
  $self->_transform($_) for @children;
  $self->_output($fmt_end);
}
sub _transform_B :prototype($$@) {
  unshift @_, 'B';
  goto &_transform_fmt;
}
sub _transform_C :prototype($$@) {
  unshift @_, 'C';
  goto &_transform_fmt;
}
sub _transform_H :prototype($$@) {
  unshift @_, 'H';
  goto &_transform_fmt;
}
sub _transform_I :prototype($$@) {
  unshift @_, 'I';
  goto &_transform_fmt;
}
sub _transform_F :prototype($$@) {
  unshift @_, 'F';
  goto &_transform_fmt;
}

sub _transform_T :prototype($$@) {
  warn "T<> formatting code used outside of =table or =row";
}

sub _transform_X :prototype($$@) {
  my ($self, undef, @children) = @_;
  local $" = ' ';
  $self->_output(qq{<a name="@children"></a>});
}
sub _transform_L :prototype($$@) {
  my ($self, $opts, @children) = @_;

  if ($opts->{type} eq 'man') {
    $opts->{to} =~ /(.+)\(([^)]+)\)/;
    $self->_output(qq{<a href="https://man.openbsd.org/$1.$2">});
    $self->_transform($_) for @children;
    $self->_output(qq{</a>});

  }
  elsif ($opts->{type} eq 'url') {
    $self->_output(qq{<a href="$opts->{to}">});
    $self->_transform($_) for @children;
    $self->_output(qq{</a>});

  }
  elsif ($opts->{type} eq 'pod') {
    my $external_pod = defined $opts->{to};
    my $url = $external_pod ? 'https://perldoc.perl.org/' : '';
    my $frag = '#' . _anchorize($opts->{section});
    $self->_output(qq{<a href="$url$frag">});
    $self->_transform($_) for @children;
    $self->_output(qq{</a>});
  }
}

sub _transform_list_item :prototype($$@) {
  state $li_start = <<'LI_EOF';
<li class="pod_list_body pod_content">
LI_EOF
  state $li_end = <<'LI_EOF';
</li>
LI_EOF

  my ($self, undef, @children) = @_;
  $self->_output($li_start);
  $self->_transform($_) for @children;
  $self->_output($li_end);
}

sub _transform_item_bullet :prototype($$@) {goto &_transform_list_item;}
sub _transform_item_number :prototype($$@) {goto &_transform_list_item;}
sub _transform_item_text :prototype($$@) {
  # sanity check: this should only happen if inside over-text block
  my ($self, undef, @children) = @_;
  die "insanity: item-text outside over-text"
      unless $self->{in_dl};
  my $frag = _anchorize(_strip_formats_and_join(@children));

  my $dt_start = <<"DT_EOF";
<dt class="pod_list_header pod_list pod_content">
  <a name="$frag"></a>
  <a href="#$frag"><p class="pod_paragraph pod_content">
DT_EOF
  state $dt_end = <<'DT_EOF';
</p></a>
</dt>
DT_EOF

  $self->_output($dt_start);
  $self->_transform($_) for @children;
  $self->_output($dt_end);
}

# sub _transform_over_empty : prototype($$@); -> do not implement for it does nothing

sub _transform_over_block :prototype($$@) {
  state $div_start = <<'DIV_EOF';
<div class="pod_block_list pod_list_container pod_content">
DIV_EOF
  state $div_end = <<'DIV_EOF';
</div>
DIV_EOF

  my ($self, undef, @children) = @_;
  $self->_start_dd;
  $self->_output($div_start);
  $self->_transform($_) for @children;
  $self->_output($div_end);
  $self->_end_dd;
}

sub _transform_over_number :prototype($$@) {
  state $ol_start = <<'OL_EOF';
<ol class="pod_number_list pod_list_container pod_content">
OL_EOF
  state $ol_end = <<'OL_EOF';
</ol>
OL_EOF

  my ($self, undef, @children) = @_;
  $self->_start_dd;
  $self->_output($ol_start);
  $self->_transform($_) for @children;
  $self->_output($ol_end);
  $self->_end_dd;
}

sub _transform_over_bullet :prototype($$@) {
  state $ul_start = <<'UL_EOF';
<ul class="pod_number_list pod_list_container pod_content">
UL_EOF
  state $ul_end = <<'UL_EOF';
</ul>
UL_EOF

  my ($self, undef, @children) = @_;
  $self->_start_dd;
  $self->_output($ul_start);
  $self->_transform($_) for @children;
  $self->_output($ul_end);
  $self->_end_dd;
}

sub _transform_over_text :prototype($$@) {
  state $dl_start = <<'DL_EOF';
<dl class="pod_text_list pod_list_container pod_content">
DL_EOF
  state $dl_end = <<'DL_EOF';
</dl>
DL_EOF

  my ($self, undef, @children) = @_;
  $self->_start_dd;
  $self->_output($dl_start);
  $self->{in_dl} = 1;
  $self->_transform($_) for @children;
  $self->{in_dl} = 0;
  $self->_output($dl_end);
  $self->_end_dd;
}

sub _transform_for :prototype($$@) {
  my ($self, undef, @children) = @_;

  $self->_transform($_) for @children;
}

sub _transform_Data :prototype($$$) {
  state $div_start = <<'DIV_EOF';
<div class="pod_data pod_content">
DIV_EOF
  state $div_end = <<'DIV_EOF';
</div>
DIV_EOF

  my ($self, undef, $content) = @_;
  $self->_output($div_start);
  $self->_output($content);
  $self->_output($div_end);
}

sub _transform_table :prototype($$@) {
  state $table_start = <<'TABLE_EOF';
<table class="mana_table pod_table pod_content">
TABLE_EOF

  my ($self, undef, @children) = @_;
  push @children, ['T'] unless
      ref($children[-1]) eq 'ARRAY' && $children[-1]->[0] eq 'T';

  $self->_start_dd;
  $self->_output($table_start);

  $self->{in_table} = 1;
  my $need_th = 1;
  for (@children) {
    if ($need_th) {
      $self->_output(q{<th class="pod_table_head pod_table_cell pod_content">});
      $need_th = 0;
    }
    if (ref($_) eq 'ARRAY' && $_->[0] eq 'T') {
      $self->_output(q{<hr class="_pod_table_head_bar"></th>});
      $need_th = 1;
      next;
    }

    $self->_transform($_);
  }
}

sub _transform_row :prototype($$@) {
  state $row_start = <<'DIV_EOF';
<tr class="pod_table_row pod_content">
DIV_EOF
  state $row_end = <<'DIV_EOF';
</tr>
DIV_EOF

  my ($self, undef, @children) = @_;
  die "insanity: =row must follow a =table directive (or another =row)"
      unless $self->{in_table};

  push @children, [ 'T' ] unless
      ref($children[-1]) eq 'ARRAY' && $children[-1]->[0] eq 'T';
  $self->_output($row_start);
  my $need_td = 1;
  for (@children) {
    if ($need_td) {
      $self->_output(q{<td class="pod_table_data pod_table_cell pod_content">});
      $need_td = 0;
    }
    if (ref($_) eq 'ARRAY' && $_->[0] eq 'T') {
      $self->_output(q{</td>});
      $need_td = 1;
      next;
    }

    $self->_transform($_);
  }
  $self->_output($row_end);
}

sub _transform :prototype($_) {
  my ($self, $pod_structure) = @_;

  if (ref($pod_structure) eq '') {
    $self->_output(escape_html($pod_structure));
    return;
  }

  ## <table> ending
  my $type = $pod_structure->[0];
  $type =~ s/\W/_/g;
  my $func = "_transform_$type";
  if ($self->{in_table}
      && !($self->{in_table} = $type =~ /\Atable|row|[BCHIFXL]\z/)) {
    $self->_output(qq{</table>});
    $self->_end_dd;
  }

  no strict 'refs';
  if ($self->can($func)) {
    $self->$func($pod_structure->@[1 .. $#$pod_structure]);
  }
  use strict 'refs';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mana::Doc::HTML - The HTML backend for Mana::Doc

=head1 DESCRIPTION

This module provides the HTML backend for rendering Mana::Doc documents.

=head2 Construction

When construction the following options can be provided to Mana::Doc::new to
pass through to Mana::Doc::HTML.


=over 2

=item I<output> // undef

Is used to specify the output file to generate. Different types can be used

=over 2

=item SCALAR-ref

The produced content will be appended to the string of the reference.

=item ARRAY-ref

Pieces of content will be pushed to the array of the reference.

=item GLOB-ref

Or a filehandle in general. Output will be written to the specified file which
should be opened for writing. If not behavior is undefined.

=item SCALAR

The string value of the variable will be opened as a file for writing and the
generated content will be written there.

=item C<undef>

If the value is not defined output is written to C<STDOUT>.

=back

=item I<omit_css> // 0

If this option is enabled, no CSS will be generated for use by the HTML output.
This is useful if you want to supply your own CSS files, and therefore have no
need for the Mana::Doc defaults.

This option always overrides all other CSS related options; if it is enabled
all others will be ignored.

=item I<embed_css> // 1

When using the default Mana::Doc CSS, this option can be set (as is by default)
to embed it into the HTML file. This is useful if you'd otherwise have only one
file with all your documentation but the external CSS would be another one to
handle.

As of now, you cannot specify external files to get embedded, only the Mana::Doc
CSS can be embedded this way (or by Mana::Doc::HTML in general).

=item I<ext_css_name> // (I<omit_css> ? C<undef> : C<mana_doc.css>)

If I<embed_css> is set this option is ignored.

If I<omit_css> is set, and this is C<undef> the HTML will be generated completely
without CSS and it won't link to anything.

If I<omit_css> is set, but this is defined, the generated HTML file will link
to an external CSS of the name specified in this option.

If I<omit_css> is not set, the default Mana::Doc CSS file will be written to
the filename specified here and the HTML file will link to it as an external
file.

=back

=head1 SEE ALSO

L<Mana::Doc> - For the Mana::Doc format documentation.

L<manadoc> - For the command line tool for using Mana::Doc.

=head1 AUTHOR

András Bodor E<lt>bodand@pm.meE<gt>

=head1 COPYRIGHT

Copyright (c) 2021- András Bodor

=head1 LICENSE

This library is actually free software; you can use, modify, sell, and/or
redistribute it in whole or in parts under the BSD 3-Clause license.

=cut
