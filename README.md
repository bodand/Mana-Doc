# NAME

Mana::Doc - A slightly modified POD parser that generates the Mage project docs

# SYNOPSIS

    use Mana::Doc;
    $doc = Mana::Doc->new(target => 'HTML',
                          output => 'my_doc.html');
    $doc->parse('my_doc.manad');
    $doc->run;

# DESCRIPTION

A pod-ish formatter used by the Mage project to generate the ManaVM, Mage, and
Chalk documentation pages which are written in pod syntax but support extra
features as described in ["Mana::Doc Extensions"](#mana-doc-extensions).

# TARGETS

Since Mana::Doc contains extraneous syntactical elements compared to normal POD
documents, other POD formatters are likely to choke on it. (Some, [Pod::Simple](https://metacpan.org/pod/Pod%3A%3ASimple)
for example whose parser this module uses internally, can be made to work
slightly by making it ignore POD syntax errors, but the formatting will be
faulty anyways.) For this reason Mana::Doc provi- \*_khmm_\* will provide
different backends to allow generating different output formats. The list of
currently supported target markup languages are listed below:

- HTML

    This backend generates modern-ish HTML5 code that relies on CSS features to make
    it look acceptable. JavaScript is scarcely used to allow faster load times, and
    because it sucks, but code-block coloring is fancy.

## Mana::Doc Extensions

Mana::Doc extends the pod specification with according to the followings listed.

- The `H<>` format

    The `H<>` format code which, by default, transforms into slightly
    less visible text(?) used in ManaVM's documentation to represent leading
    namespaces in a type or function name.

    In custom CSS you can refer to it as the class `.pod_format_H`.

- The `=table` and `=row` directives

    Since tables are rather useful in documentation and constructing them from
    verbatim blocks manually is not really a good experience Mana::Doc supports
    extra directives to create simple tables. Note that as of now complex things
    like joining cells are not supported.

    The syntax is as follows:

        =table Title#1 | Title#2 | Title#3

        =row Row 1 Elem#1 | Elem#2 | Elem#3

        =row Row 2 Elem#1 | Elem#2 | Elem#3

    A =table directive followed by one ore more =row directives define a table. For
    multiple tables after one-another, just start a new =table directive. The
    first element that is not a =row directive finishes the table.

    If there is a table like thing following this paragraph in whatever format you
    are reading this, it is a bare example of what this could look like without the
    default Mana::Doc style applied (if applicable in target format).


        | Title#1      | Title#2 | Title#3 |
        |:-------------|:--------|:--------|
        | Row 1 Elem#1 | Elem#2  | Elem#3  |
        | Row 2 Elem#1 | Elem#2  | Elem#3  |

    <div>

            <table>
              <tr>
                <th>Title#1</th>
                <th>Title#2</th>
                <th>Title#3</th>
              </tr>
              <tr>
                <td>Row 1 Elem#1</td>
                <td>Elem#2</td>
                <td>Elem#3</td>
              </tr>
              <tr>
                <td>Row 2 Elem#1</td>
                <td>Elem#2</td>
                <td>Elem#3</td>
              </tr>
            </table>
    </div>

    The pipes are used to separate the columns in the table.

# AUTHOR

András Bodor <bodand@pm.me>

# COPYRIGHT

Copyright (c) 2021- András Bodor

# LICENSE

This library is actually free software; you can use, modify, sell, and/or
redistribute it in whole or in parts under the BSD 3-Clause license.

# SEE ALSO

[perlpod](https://metacpan.org/pod/perlpod), [perlpodspec](https://metacpan.org/pod/perlpodspec) - For the standard POD format used and supported by Perl

[Pod::Simple](https://metacpan.org/pod/Pod%3A%3ASimple), [Pod::Simple::HTML](https://metacpan.org/pod/Pod%3A%3ASimple%3A%3AHTML), [Pod::Simple::SimpleTree](https://metacpan.org/pod/Pod%3A%3ASimple%3A%3ASimpleTree) - For the modules
used by Mana::Doc to provide the basic POD parsing support. Note that this may
change in the future but will be considered a breaking change if that happens.
