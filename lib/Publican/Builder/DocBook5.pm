package Publican::Builder::DocBook5;

use utf8;
use strict;
use warnings;
use 5.008;

use base 'Publican::Builder::DocBook';
use Publican::Builder;
use Publican::Builder::DocBook;

use Carp;
use Publican;
use Publican::XmlClean;
use Publican::Translate;
use File::Path;
use File::pushd;
use File::Find;
use XML::LibXSLT;
use XML::LibXML;
use Cwd qw(abs_path);
use Archive::Tar;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use DateTime;
use DateTime::Format::DateParse;
use Syntax::Highlight::Engine::Kate;
use HTML::TreeBuilder;
use HTML::FormatText;
use HTML::FormatText::WithLinks::AndTables;
use HTML::FormatText::WithLinks;
use Term::ANSIColor qw(:constants);
use POSIX qw(floor :sys_wait_h);
use Locale::Language;
use List::Util qw(max);
use Text::Wrap qw(fill $columns);
use IO::String;
use File::Which;
use Text::CSV_XS;
use Publican::ConfigData;
use Sort::Versions;
use Template;
use Encode qw(is_utf8 decode_utf8 encode_utf8);

use vars qw(@ISA @EXPORT @EXPORT_OK);

@ISA = qw(Publican::Builder::DocBook);

=head1 NAME

Publican::Builder::DocBook5 - A module to Convert XML to various output formats

=head1 SYNOPSIS

    use Publican::Builder::DocBook5;
    my $builder = Publican::Builder::DocBook5->new();
    $builder->clean_ids();

=head1 DESCRIPTION

Manipulate DocBook 4 XML and convert to other formats.

=head1 INTERFACE 

=cut

=head2  new

Create a new Publican::Builder::DocBook5 object.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;
    my $self = $class->SUPER::new($args);

    bless $self, $class;

    return $self;
}

=head2 setup_xml

Create the proper directory structure for the XML, including copying in Brand files.

=cut

sub setup_xml {
    my ( $self, $args ) = @_;
    my $xml_lang = $self->{publican}->param('xml_lang');
    my $tmp_dir  = $self->{publican}->param('tmp_dir');
    my $type     = $self->{publican}->param('type');

    my $exlude_common = delete( $args->{'exlude_common'} ) || undef;
    my $langs = delete( $args->{langs} )
        || croak( maketext("langs is a mandatory argument") );
    my $distributed_set = delete( $args->{distributed_set} ) || 0;
    my $drupal          = delete( $args->{drupal} )          || 0;
    my $cleaning        = delete( $args->{cleaning} )        || 0;

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $extras = $self->{publican}->param('extras_dir');

    foreach my $lang ( split( /,/, $langs ) ) {
        logger( maketext( "Setting up [_1]", $lang ) . "\n" );

        croak(
            maketext(
                "Invalid build request: language directory [_1] does not exist.",
                $lang
            )
        ) if ( !-d $lang );

        mkpath("$tmp_dir/$lang/xml");

        my $lc_lang = $lang;
        $lc_lang =~ s/-/_/g;
        my $locale = Publican::Localise->get_handle($lc_lang)
            || croak(
            "Could not create a Publican::Localise object for language: [_1]",
            $lang
            );
        $locale->encoding("UTF-8");
        $locale->textdomain("publican");

        if ( $lang eq $xml_lang ) {

            if ($drupal) {

                # preprocess. set the unique id for every sections
                my $set_ids = Publican::XmlClean->new();

                logger( maketext("Preprocessing xml files...\n") );
                $set_ids->set_unique_ids();
                logger( maketext("Finish preprocess\n") );
            }

            dircopy( $lang, "$tmp_dir/$lang/xml_tmp" );
        }
        elsif ( ( $self->{publican}->param('ignored_translations') )
            && ($self->{publican}->param('ignored_translations') =~ m/$lang/ )
            )
        {
            logger(
                "\t"
                    . maketext( "Bypassing translation for [_1]", $lang )
                    . "\n",
                GREEN
            );
            dircopy( $self->{publican}->param('xml_lang'),
                "$tmp_dir/$lang/xml_tmp" );
        }
        else {
            my @po_files = dir_list( $lang, '*.po' );
            croak(
                maketext(
                    "Invalid build request: no PO files exist for language [_1]",
                    $lang
                )
            ) unless (@po_files);

            mkpath("$tmp_dir/$lang/xml_tmp");

            my $source_dir = $self->{publican}->param('xml_lang');
            $source_dir = 'trans_drop' if ( -d 'trans_drop' );
            my $extras = $self->{publican}->param('extras_dir');

            my @xml_files = dir_list( $source_dir, '*.xml' );

            foreach my $xml_file ( sort(@xml_files) ) {
                next if ( $xml_file =~ m|$source_dir/$extras/| );
                my $po_file = $xml_file;
                $po_file =~ s/\.xml/\.po/;
                $po_file =~ s/$source_dir/$lang/;

                my $out_file = $xml_file;
                $out_file =~ s/$source_dir//;

                $out_file =~ m|^(.*)/[^/]+$|;
                my $path = ( $1 || undef );
                mkpath("$tmp_dir/$lang/xml_tmp/$path")
                    if ( $path && !-d $path );

                if ( !-f $po_file ) {
                    logger(
                        "\t"
                            . maketext(
                            "PO file '[_1]' not found! Using base XML!",
                            $po_file )
                            . "\n",
                        CYAN
                    );
                    rcopy( $xml_file, "$tmp_dir/$lang/xml_tmp/$out_file" );
                }
                else {
                    $self->{translator}->po2xml(
                        {   xml_file => $xml_file,
                            po_file  => $po_file,
                            out_file => "$tmp_dir/$lang/xml_tmp/$out_file"
                        }
                    );
                }
            }

            my $rev_file = "Revision_History.xml";
            $rev_file = $self->{publican}->param('rev_file')
                if ( $self->{publican}->param('rev_file') );

            if ( -f "$lang/$rev_file" ) {
                my $rev_tree       = $self->{publican}->new_tree();
                my $trans_rev_tree = $self->{publican}->new_tree();

                $rev_tree->parse_file("$tmp_dir/$lang/xml_tmp/$rev_file");
                $trans_rev_tree->parse_file("$lang/$rev_file");

                my $id = undef;

                my $anode = $rev_tree->look_down( '_tag', "appendix" );
                $id = $anode->id() if ( $anode && $anode->id() );
                my $merged_rev_tree = XML::Element->new_from_lol(
                    [   'appendix',
                        { id => $id },
                        [   'title',
                            decode_utf8(
                                $locale->maketext('Revision History')
                            )
                        ],
                        [ 'simpara', ['revhistory'], ],
                    ],
                );

                my $node
                    = $merged_rev_tree->look_down( '_tag', "revhistory" );

                my @revisions = sort {
                    versioncmp(
                        $b->look_down( '_tag', "revnumber" )->as_text(),
                        $a->look_down( '_tag', "revnumber" )->as_text()
                        )
                    } (
                    $rev_tree->look_down( '_tag', "revision" ),
                    $trans_rev_tree->look_down( '_tag', "revision" )
                    );

                if (   $self->{publican}->param('rev_dir')
                    && $self->{publican}->param('rev_dir') =~ /^asc/i )
                {
                    @revisions = reverse(@revisions);
                }

                $node->push_content(@revisions);
                my $OUTDOC;
                open( $OUTDOC, ">:encoding(UTF-8)",
                    "$tmp_dir/$lang/xml_tmp/$rev_file" )
                    || croak(
                    maketext(
                        "Could not open [_1] for output!",
                        "$tmp_dir/$lang/xml_tmp/$rev_file",
                        $@
                    )
                    );

                print( $OUTDOC dtd_string(
                        {   tag      => 'appendix',
                            dtdver   => $self->{publican}->param('dtdver'),
                            cleaning => 1
                        }
                    )
                );

                print( $OUTDOC $merged_rev_tree->as_XML() );
                close($OUTDOC);
            }

            my $trans_file = "$lang/Author_Group.xml";
            if ( -f $trans_file ) {
                my $auth_file = "$tmp_dir/$lang/xml_tmp/Author_Group.xml";

                my $auth_doc = XML::TreeBuilder->new(
                    { 'NoExpand' => "1", 'ErrorContext' => "2" } );
                $auth_doc->parse_file($auth_file);
                my $auth_node = eval {
                    $auth_doc->root()->look_down( "_tag", "authorgroup" );
                };
                if ($@) {
                    croak(
                        maketext(
                            "authorgroup not found in [_1]", $auth_file
                        )
                    );
                }
                my $trans_doc = XML::TreeBuilder->new(
                    { 'NoExpand' => "1", 'ErrorContext' => "2" } );
                $trans_doc->parse_file($trans_file);
                my $trans_node = eval {
                    $trans_doc->root()->look_down( "_tag", "authorgroup" );
                };
                if ($@) {
                    croak(
                        maketext(
                            "authorgroup not found in [_1]", $trans_file
                        )
                    );
                }

                $auth_doc->push_content( $trans_doc->detach_content() );
                my $text = $auth_doc->as_XML();

                my $OUTDOC;
                open( $OUTDOC, ">:encoding(UTF-8)", $auth_file )
                    || croak(
                    maketext( "Could not open [_1] for output!", $auth_file )
                    );
                print( $OUTDOC $text );
                close($OUTDOC);
                $auth_doc->root()->delete();
                $trans_node->root()->delete();
            }

        }

        # clean XML
        my $cleaner = Publican::XmlClean->new(
            {   lang            => $lang,
                donotset_lang   => $exlude_common,
                distributed_set => $distributed_set,
                cleaning        => $cleaning,
            }
        );

        my @xml_files = dir_list( "$tmp_dir/$lang/xml_tmp", '*.xml' );

        # copy css for brand and default images for non-brand
        if ( $type eq 'brand' ) {
            dircopy( "$lang/css", "$tmp_dir/$lang/xml/css" )
                if ( -d "$lang/css" );

            dircopy( "$lang/scripts", "$tmp_dir/$lang/xml/scripts" )
                if ( -d "$lang/scripts" );
        }

        my $images = $self->{publican}->param('img_dir');

        if ( $type ne 'brand' ) {
            dircopy( "$xml_lang/$images", "$tmp_dir/$lang/xml/$images" )
                if ( -d "$xml_lang/$images" );
        }

        dircopy( "$lang/$images", "$tmp_dir/$lang/xml/$images" )
            if ( -d "$lang/$images" );

        unless ($exlude_common) {
            mkpath("$tmp_dir/$lang/xml/Common_Content");

            # copy common files
            my $common_content = $self->{publican}->param('common_content');
            my $brand          = $self->{publican}->param('brand');
            my $base_brand
                = ( $self->{publican}->{brand_config}->param('base_brand')
                    || 'common' );

            if ( $common_content =~ m/\"/ & $common_content !~ m/\s/ ) {
                $common_content =~ s/\"//g;
            }

            my $brand_path = $self->{publican}->param('brand_dir')
                || $common_content . "/$brand";

            rcopy_glob(
                $common_content . "/$base_brand/en-US/*",
                "$tmp_dir/$lang/xml/Common_Content"
            );

            if ( $lang ne 'en-US' ) {
                if ( -d $common_content . "/$base_brand/$lang" ) {
                    rcopy_glob(
                        $common_content . "/$base_brand/$lang/*",
                        "$tmp_dir/$lang/xml/Common_Content"
                    );
                }
                elsif (
                    defined( $LANG_MAP{$lang} )
                    && (  -d $common_content
                        . "/$base_brand/"
                        . $LANG_MAP{$lang} )
                    )
                {
                    rcopy_glob(
                        $common_content
                            . "/$base_brand/"
                            . $LANG_MAP{$lang} . "/*",
                        "$tmp_dir/$lang/xml/Common_Content"
                    );

                }

            }
            if (   ( $brand ne $base_brand )
                || ( $brand_path ne $common_content . "/$brand" ) )
            {
                my $brand_lang
                    = $self->{publican}->{brand_config}->param('xml_lang');

                my @files = rcopy_glob(
                    $brand_path . "/$brand_lang/*",
                    "$tmp_dir/$lang/xml/Common_Content"
                );

                croak(
                    maketext(
                        "Brand '[_1]' had no content to copy.", $brand
                    )
                ) if ( scalar(@files) == 0 );

                if ( $lang ne $brand_lang ) {
                    if ( -d $brand_path . "/$lang" ) {
                        rcopy_glob( "$brand_path/$lang/*",
                            "$tmp_dir/$lang/xml/Common_Content" );
                    }
                    elsif ( defined( $LANG_MAP{$lang} )
                        && ( -d $brand_path . "/" . $LANG_MAP{$lang} ) )
                    {
                        rcopy_glob(
                            "$brand_path/" . $LANG_MAP{$lang} . "/*",
                            "$tmp_dir/$lang/xml/Common_Content"
                        );
                    }
                }
            }

            my $main_file = $self->{publican}->param('mainfile');

            my $ent_file = "$xml_lang/$main_file.ent";
            rcopy( $ent_file, "$tmp_dir/$lang/xml/." ) if ( -e $ent_file );

            $ent_file = "$lang/$main_file.ent";
            rcopy( $ent_file, "$tmp_dir/$lang/xml/." ) if ( -e $ent_file );

            dircopy( "$xml_lang/$extras", "$tmp_dir/$lang/xml/$extras" )
                if ( -d "$xml_lang/$extras" );
            dircopy( "$lang/$extras", "$tmp_dir/$lang/xml/$extras" )
                if ( -d "$lang/$extras" );

            my @com_xml_files
                = dir_list( "$tmp_dir/$lang/xml/Common_Content", '*.xml' );

            $cleaner->{config}->param( 'common', 1 );
            foreach my $xml_file ( sort(@com_xml_files) ) {
                my $out_file = $xml_file;
                chmod( 0664, $out_file );
                $cleaner->process_file(
                    { file => $xml_file, out_file => $out_file } );
            }
        }

        if (    $type eq 'Set'
            and !defined( $self->{publican}->{config}->param('scm') )
            and defined( $self->{publican}->{config}->param('books') ) )
        {
            foreach my $xml_file ( sort(@xml_files) ) {
                my $out_file = $xml_file;
                $out_file =~ s/xml_tmp/xml/;
                rcopy( $xml_file, $out_file );
            }
            my @ent_files = dir_list( $lang, '*.ent' );
            foreach my $ent_file ( sort(@ent_files) ) {
                my $out_file = $ent_file;
                $out_file =~ s/$lang/$tmp_dir\/$lang\/xml/;
                rcopy( $ent_file, $out_file );
            }

        }
        else {
            foreach my $xml_file ( sort(@xml_files) ) {
                next if ( $xml_file =~ m{/$extras/} );
                my $out_file = $xml_file;
                $out_file =~ s/xml_tmp/xml/;

                $cleaner->process_file(
                    { file => $xml_file, out_file => $out_file } );
            }
        }
        finddepth( \&del_unwanted_dirs, $tmp_dir );
    }

    return;

}

=head2 clean_ids

Travers over the source XML and update the id's to match the standard format.

Updates all existing PO files with the new xref links.

=cut

sub clean_ids {
    my ( $self, $args ) = @_;

    #    if ( %{$args} ) {
    #        croak "unknown args: " . join( ", ", keys %{$args} );
    #    }

    my @xml_files = dir_list( $self->{publican}->param('xml_lang'), '*.xml' );
    my $cleaner
        = Publican::XmlClean->new( { clean_id => 1, id_attr => 'xml:id' } );
    my $extras = $self->{publican}->param('extras_dir');

    foreach my $xml_file ( sort(@xml_files) ) {
        next if ( $xml_file =~ m{/$extras/} );
        $cleaner->process_file(
            { file => $xml_file, out_file => $xml_file } );
    }

    return;
}

=head2 validate_xml

Ensure the XML validates against the DTD.

To debug the XML catalogs

export XML_DEBUG_CATALOG=1

test...

unset XML_DEBUG_CATALOG

=cut

sub validate_xml {
    my ( $self, $args ) = @_;
    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $docname   = $self->{publican}->param('docname');
    my $dtdver    = $self->{publican}->param('dtdver');
    my $main_file = $self->{publican}->param('mainfile');

    if (   ( $self->{publican}->param('ignored_translations') )
        && ( $self->{publican}->param('ignored_translations') =~ m/$lang/ ) )
    {
        logger(
            maketext( "Bypassing test for language: [_1]", $lang ) . "\n" );
        return (0);
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');

    my $dir = pushd("$tmp_dir/$lang/xml");

    my $parser = XML::LibXML->new(
        {   pedantic_parser   => 1,
            suppress_errors   => 0,
            suppress_warnings => 1,
            line_numbers      => 1,
            expand_xinclude   => 1
        }
    );

    croak(
        maketext( "Cannot locate main XML file: '[_1]'", "$main_file.xml" ) )
        unless ( -f "$main_file.xml" );

    my $source;
    eval { $source = $parser->parse_file("$main_file.xml"); };

    if ($@) {
        if ( ref($@) ) {

            # handle a structured error (XML::LibXML::Error object)
            croak(
                maketext(
                    "FATAL ERROR: [_1]:[_2] in [_3] on line [_4]: [_5]",
                    $@->domain(),
                    $@->code(),
                    $@->file(),
                    $@->line(),
                    $@->message(),
                )
            );
        }
        else {
            croak( maketext( "FATAL ERROR: [_1]", $@ ) );
        }
    }

## BUGBUG how does this get localised?
# e.g. even though /usr/share/xml/docbook5/schema/rng/5.0/catalog.xml contains a local link
# setting location = http://docbook.org/xml/5.0/rng/docbook.rng still does a web look up :(
## BUGBUG also need to change header ... entities?
# http://www.docbook.org/xml/5.1b2/rng/docbook.rng
# http://www.docbook.org/xml/5.0/rng/docbook.rng
# wget http://docbook.org/xml/5.1b2/tools/db4-upgrade.xsl
# for file in `ls *.xml`; do echo "$file"; xsltproc ../../db4-upgrade-publican.xsl $file > $file.tmp;mv $file.tmp $file; echo; done
    my $rngschema = XML::LibXML::RelaxNG->new(
        location => "http://docbook.org/xml/$dtdver/rng/docbook.rng" );
    eval { $rngschema->validate($source); };
    if ($@) {
        logger(
            maketext("RelaxNG Validation failed for '$dir/$main_file.xml': ")
                . "\nIGNORING: Validation is broken, see BZ #1097495\n",
            RED
        );
##        croak("$@\n$!\n");
    }
    logger("RelaxNG Validation OK\n");

    $dir = undef;

    return (0);
}

=head2 get_author_list

Return the author list for the supplied language.

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub get_author_list {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my @authors;

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $file    = "$tmp_dir/$lang/xml/Author_Group.xml";

    croak( maketext("ERROR: Cannot find Author file Author_Group.xml.") )
        unless ( -f $file );

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );
    $xml_doc->parse_file($file);

    foreach my $author (
        $xml_doc->root()->look_down( "_tag", qr/^(?:author|orgname)$/ ) )
    {
        if ( $author->tag() =~ /^(?:orgname)$/ ) {
            my $name;

            eval { $name = $author->as_text; };
            if ($@) {
                croak(
                    maketext(
                        "corpauthor can not be converted to text as expected."
                    )
                );
            }
            push( @authors, "$name" );
        }
        else {
            my ( $fn, $sn );
            eval { $fn = $author->look_down( "_tag", 'firstname' )->as_text; };
            if ($@) {
                croak(
                    maketext(
                        "Author’s firstname not found in Author_Group.xml as expected."
                    )
                );
            }

            eval { $sn = $author->look_down( "_tag", 'surname' )->as_text; };
            if ($@) {
                croak(
                    maketext(
                        "Author’s surname not found in Author_Group.xml as expected."
                    )
                );
            }

            push( @authors, "$fn $sn" );
        }
    }

    return (@authors);
}

1;    # Magic true value required at end of module
__END__

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected named arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandatory parameter will return this error if the parameter is undef.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Publican requires no configuration files or environment variables.


=head1 DEPENDENCIES

Carp
version
Publican
Publican::XmlClean
Publican::Translate
File::Path
File::pushd
File::Find
XML::LibXSLT
XML::LibXML
Cwd
Archive::Tar
DateTime
DateTime::Format::DateParse
Syntax::Highlight::Engine::Kate
HTML::TreeBuilder
HTML::FormatText
Term::ANSIColor
POSIX

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Publican&component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
