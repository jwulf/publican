package Publican::Builder::DocBook;

use utf8;
use strict;
use warnings;
use 5.008;

use base 'Publican::Builder';
use Publican::Builder;

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
use Publican::ConfigData;
use Sort::Versions;
use Template;
use Encode qw(is_utf8 decode_utf8 encode_utf8);
use Data::Dumper;
use HTML::WikiConverter;
use File::Slurp;

use vars qw(@ISA @EXPORT @EXPORT_OK);

@ISA = qw(Publican::Builder);

%HTML::Element::optionalEndTag = ();

=head1 NAME

Publican::Builder::DocBook - A module to Convert XML to various output formats

=head1 SYNOPSIS

    use Publican::Builder::DocBook;
    my $builder = Publican::Builder::DocBook->new();
    $builder->clean_ids();

=head1 DESCRIPTION

Manipulate DocBook XML and convert to other formats.

=head1 INTERFACE 

=cut

=head2  new

Create a new Publican::Builder::DocBook object.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;
    my $self = $class->SUPER::new($args);

    bless $self, $class;

    return $self;
}

=head2  build

Transform the source in to another format.

=cut

sub build {
    my ( $self, $args ) = @_;

    my $langs = delete( $args->{langs} )
        || croak( maketext("langs is a mandatory argument") );
    my $formats = delete( $args->{formats} )
        || croak( maketext("formats is a mandatory argument") );
    my $publish         = delete( $args->{publish} )         || undef;
    my $embedtoc        = delete( $args->{embedtoc} )        || undef;
    my $distributed_set = delete( $args->{distributed_set} ) || 0;
    my $pdftool         = delete( $args->{pdftool} )         || undef;
    my $pub_dir         = delete( $args->{pub_dir} )
        || croak( maketext("pub_dir is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $product = $self->{publican}->param('product');
    my $version = $self->{publican}->param('version');
    my $docname = $self->{publican}->param('docname');
    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $type    = $self->{publican}->param('type');
    my $brand   = $self->{publican}->param('brand');

    if ( ( $type eq 'Set' ) && ( $self->{publican}->{config}->param('scm') ) )
    {
        $self->get_books();
        $self->build_set_books( { langs => $langs } );
    }

    if ( $langs =~ /^all$/i ) {
        $langs = get_all_langs();
    }

    my $drupal = 0;
    if ( $formats =~ /drupal-book/ ) {
        $drupal = 1;
    }

    $self->setup_xml(
        {   langs           => $langs,
            exlude_common   => ( $type eq 'brand' ),
            distributed_set => $distributed_set,
            drupal          => $drupal
        }
    );

    foreach my $lang ( sort( split( /,/, $langs ) ) ) {
        logger( maketext( "Beginning work on [_1]", $lang ) . "\n" );

        # hmmm can't validate brand XML as it's incomplete
        if (    ( $type ne 'brand' )
            and $self->{validate}
            and ( $self->validate_xml( { lang => $lang } ) == $INVALID ) )
        {
            logger(
                maketext(
                    "All build formats will be skipped for language: [_1]",
                    $lang )
                    . "\n",
                RED
            );
            next;
        }

        # catch txt not being rebuilt BZ #802576
        my $rebuild = 1;

        foreach my $format ( split( /,/, $formats ) ) {
            logger( "\t" . maketext( "Starting [_1]", $format ) . "\n" );
            if ( $format eq 'test' ) {
                logger( "\t" . maketext( "Finished [_1]", $format ) . "\n" );
                next;
            }

            $self->transform(
                {   format   => $format,
                    lang     => $lang,
                    embedtoc => $embedtoc,
                    rebuild  => $rebuild,
                    pdftool  => $pdftool,

                }
            ) unless ( $format eq 'xml' );

            $rebuild = 0
                if ( $format eq 'txt' || $format eq 'html-single-plain' );

            if ($publish) {
                if ( $type eq 'brand' ) {
                    my $path = "$pub_dir/$brand/$lang";
                    mkpath($path);
                    rcopy( "$tmp_dir/$lang/$format/*", "$path/." )
                        if ( -d "$tmp_dir/$lang/$format" );
                }
                else {
                    my $path
                        = "$pub_dir/$lang/$product/$version/$format/$docname";

                    # The basic layout is for the web system
                    # but these formats are used differently
                    if ( $self->{publican}->param('web_home') ) {
                        $path = "$pub_dir/home/$lang";
                    }
                    elsif ( $self->{publican}->param('web_type') ) {
                        my $web_type = $self->{publican}->param('web_type');
                        if ( $web_type =~ m/^home$/i ) {
                            $path = "$pub_dir/home/$lang";
                            fcopy( 'site_overrides.css',
                                "$pub_dir/home/site_overrides.css" )
                                if ( -f 'site_overrides.css' );

                            # Build ADs
                            if ( -f "$tmp_dir/$lang/xml/Ads.xml" ) {
                                mkpath($path);
                                my $common_config = $self->{publican}
                                    ->param('common_config');

                                my $xsl_file
                                    = $common_config . "/xsl/carousel.xsl";

                                # required for Windows
                                $xsl_file =~ s/"//g;
                                my $parser = XML::LibXML->new();
                                my $xslt   = XML::LibXSLT->new();
                                my $source;
                                eval {
                                    $source
                                        = $parser->parse_file(
                                        "$tmp_dir/$lang/xml/Ads.xml");
                                };
                                if ($@) {

                                    if ( ref($@) ) {

                       # handle a structured error (XML::LibXML::Error object)
                                        croak(
                                            maketext(
                                                "FATAL ERROR 1: [_1]:[_2] in [_3] on line [_4]: [_5]",
                                                $@->domain(),
                                                $@->code(),
                                                $@->file(),
                                                $@->line(),
                                                $@->message(),
                                            )
                                        );
                                    }
                                    else {
                                        croak(
                                            maketext(
                                                "FATAL ERROR 2: [_1]", $@
                                            )
                                        );
                                    }
                                }

                                my $style_doc
                                    = $parser->parse_file($xsl_file);
                                my $stylesheet
                                    = $xslt->parse_stylesheet($style_doc);
                                my $results = $stylesheet->transform($source);
                                my $outfile;
                                my $ad_file = "$path/carousel.html";

                                open( $outfile, ">:encoding(UTF-8)",
                                    "$ad_file" )
                                    || croak(
                                    maketext(
                                        "Can't open ad file: [_1]", $@
                                    )
                                    );
                                print( $outfile $stylesheet->output_string(
                                        $results) );
                                close($outfile);
                                unlink("$tmp_dir/$lang/xml/Ads.xml");
                            }
                        }
                        elsif ( $web_type =~ m/^product$/i ) {
                            $path = "$pub_dir/home/$lang/$product";

                            my $tmpl_dir = "$pub_dir/datadir/$lang/$product";

                            # Copy External Links
                            if ( -f "$tmp_dir/$lang/xml/External_Links.xml" )
                            {
                                mkpath($tmpl_dir);
                                fcopy(
                                    "$tmp_dir/$lang/xml/External_Links.xml",
                                    "$tmpl_dir/External_Links.xml"
                                );
                                unlink(
                                    "$tmp_dir/$lang/xml/External_Links.xml");
                            }

                            if ( -f "$tmp_dir/$lang/xml/Groups.xml" ) {
                                mkpath($tmpl_dir);
                                my $xml_doc = XML::TreeBuilder->new(
                                    {   'NoExpand'     => "0",
                                        'ErrorContext' => "2"
                                    }
                                );
                                eval {
                                    $xml_doc->parse_file(
                                        "$tmp_dir/$lang/xml/Groups.xml");
                                };
                                if ($@) {
                                    croak(
                                        maketext( "FATAL ERROR 3: [_1]", $@ )
                                    );
                                }

                                foreach my $node (
                                    $xml_doc->look_down(
                                        '_tag', 'varlistentry'
                                    )
                                    )
                                {
                                    my $sort = $node->attr('role');
                                    croak(
                                        maketext(
                                            "varlistentry must have it's attribute 'role' set to an integer"
                                        )
                                        )
                                        if ( !defined($sort)
                                        || $sort !~ /^\d+$/ );

                                    my $subtitles = 0;
                                    my $annot = $node->attr('annotations');
                                    $subtitles = 1
                                        if ( $annot && lc($annot) eq 'yes' );

                                    my $term
                                        = $node->look_down( '_tag', 'term' )
                                        ->as_trimmed_text();

                                    my $text = $node->look_down( '_tag',
                                        'listitem' )->as_trimmed_text();
                                    my $OUT;
                                    open( $OUT, ">:encoding(UTF-8)",
                                        "$tmpl_dir/$sort.tmpl" )
                                        || croak( maketext("BURP") );
                                    print( $OUT <<EOL);

[% label = "$term" %]
[% description = "$text" %]
[% subtitles = $subtitles %]
EOL

=head1
#BUGBUG fix templates
                                   print( $OUT <<EOL
\t\t\t\t\t\t<div class="group" id="[% prod %]-[% ver.replace('\\.', '-')%]-$sort">
\t\t\t\t\t\t\t<span>$term</span>
EOL
                                    );

                                    print( $OUT <<EOL
\t\t\t\t\t\t\t<span>$text</span>
EOL
                                    ) if ( $text && $text ne "" );

                                    print( $OUT <<EOL
\t\t\t\t\t\t</div>
EOL
                                    );
=cut

                                    close($OUT);
                                }

                                unlink("$tmp_dir/$lang/xml/Groups.xml");
                            }
                        }
                        elsif ( $web_type =~ m/^version$/i ) {
                            $path = "$pub_dir/home/$lang/$product/$version";
                        }
                    }
                    elsif ( $format eq 'html-desktop' ) {
                        $path = "$pub_dir/desktop/$lang";
                    }
                    elsif ( $format eq 'xml' ) {
                        $path = "$pub_dir/xml/$lang";
                    }
                    elsif ( $format eq 'eclipse' ) {
                        $path = "$pub_dir/eclipse/$lang";
                    }

                    mkpath($path);
                    if ( $format eq 'epub' ) {
                        fcopy( "$tmp_dir/$lang/" . $self->{epub_name},
                            "$path/." );
                    }
                    else {
                        rcopy( "$tmp_dir/$lang/$format/*", "$path/." )
                            if ( -d "$tmp_dir/$lang/$format" );

             # for splash pages, we need to rename them if using a web style 2
                        if ($self->{publican}->param('web_type')
##                            && $self->{publican}->param('web_style') == 2
                            )
                        {
                            fmove( "$path/index.html", "$path/splash.html" );
                        }
                    }
                }
            }
            logger( "\t" . maketext( "Finished [_1]", $format ) . "\n" );
        }
    }

    if ($publish) {
        if ( $type eq 'brand' ) {
            if ( -d 'xsl' ) {
                my $path = "$pub_dir/$brand/xsl";
                mkpath($path);
                rcopy( "xsl", "$path/." );
            }
            if ( -d 'book_templates' ) {
                my $path = "$pub_dir/$brand/book_templates";
                mkpath($path);
                rcopy( "book_templates", "$path/." );
            }
            if ( -d 'templates' ) {
                my $path = "$pub_dir/$brand/templates";
                mkpath($path);
                rcopy( "templates", "$path/." );
            }
        }
    }
    debug_msg("end of build\n");
    return;
}

=head2 transform

Run XSLT over XML

=cut

sub transform {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );
    my $format = delete( $args->{format} )
        || croak( maketext("format is a mandatory argument") );
    my $embedtoc = delete( $args->{embedtoc} ) || 0;
    my $rebuild  = delete( $args->{rebuild} )  || 0;
    my $pdftool  = delete( $args->{pdftool} )  || undef;

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    if ( defined($pdftool) && ( $pdftool !~ /^(?:fop|wkhtmltopdf)$/ ) ) {
        croak(
            maketext(
                "pdftool only supports fop or wkhtmltopdf, not: [_1]",
                $pdftool
            )
        );
    }

    my $dir;
    my $lc_lang = $lang;
    $lc_lang =~ s/-/_/g;
    my $locale = Publican::Localise->get_handle($lc_lang)
        || croak(
        "Could not create a Publican::Localise object for language: [_1]",
        $lang );
    $locale->encoding("UTF-8");
    $locale->textdomain("publican");

## BUGBUG test an alternative to fop!
    my $wkhtmltopdf_cmd = which('wkhtmltopdf');
    my $diefopdie = ( $wkhtmltopdf_cmd && $wkhtmltopdf_cmd ne '' );
    $diefopdie = 0 if ( $pdftool && $pdftool eq 'fop' );

    my $tmp_dir           = $self->{publican}->param('tmp_dir');
    my $docname           = $self->{publican}->param('docname');
    my $common_config     = $self->{publican}->param('common_config');
    my $common_content    = $self->{publican}->param('common_content');
    my $brand             = $self->{publican}->param('brand');
    my $toc_section_depth = $self->{publican}->param('toc_section_depth');
    my $confidential      = $self->{publican}->param('confidential');
    my $confidential_text = $self->{publican}->param('confidential_text');
    my $show_remarks      = $self->{publican}->param('show_remarks');
    my $generate_section_toc_level
        = $self->{publican}->param('generate_section_toc_level');
    my $chunk_section_depth = $self->{publican}->param('chunk_section_depth');
    my $doc_url             = $self->{publican}->param('doc_url');
    my $prod_url            = $self->{publican}->param('prod_url');
    my $chunk_first         = $self->{publican}->param('chunk_first');
    my $xml_lang            = $self->{publican}->param('xml_lang');
    my $classpath           = $self->{publican}->param('classpath');
    my $type                = lc( $self->{publican}->param('type') );
    my $ec_name             = $self->{publican}->param('ec_name');
    my $ec_id               = $self->{publican}->param('ec_id');
    my $ec_provider         = $self->{publican}->param('ec_provider');
    my $product             = $self->{publican}->param('product');
    my $bridgehead_in_toc   = $self->{publican}->param('bridgehead_in_toc');
    my $main_file           = $self->{publican}->param('mainfile');
    my $brand_path          = $self->{publican}->param('brand_dir')
        || $common_content . "/$brand";
    my $web_type = $self->{publican}->param('web_type') || '';

    my $TAR_NAME
        = $self->{publican}->param('product') . '-'
        . $self->{publican}->param('docname') . '-'
        . $self->{publican}->param('version');
    my $RPM_VERSION = $self->{publican}->param('edition');

    my $RPM_RELEASE = $self->{publican}->param('release');

    my $pdf_name
        = $self->{publican}->param('product') . '-'
        . $self->{publican}->param('version') . '-'
        . $self->{publican}->param('docname') . '-'
        . "$lang.pdf";

    my $sub_format = 0;

    $sub_format = 1 if ( $format eq 'txt' );
    foreach my $dialect ( HTML::WikiConverter->available_dialects ) {
        if ( $dialect eq $format ) {
            $sub_format = 1;
            last;
        }
    }

    if ($sub_format) {
        if ( !-e "$tmp_dir/$lang/html-single-plain" || $rebuild ) {
            $self->transform(
                { lang => $lang, format => 'html-single-plain' } );
        }

        $dir = pushd("$tmp_dir/$lang");
        mkdir $format;
        my $TXT_FILE;
        my $fh;
        open( $fh, "<:encoding(UTF-8)", "html-single-plain/index.html" )
            || croak( maketext("Can't open file for html input!") );

        if ( $format eq 'txt' ) {
            open( $TXT_FILE, ">:encoding(UTF-8)", "$format/$docname.txt" )
                || croak( maketext("Can't open file for text output!") );

            my $tree = HTML::TreeBuilder->new();
            eval { $tree->parse_file($fh); };

            if ($@) {
                croak( maketext( "FATAL ERROR 4: [_1]", $@ ) );
            }
## BZ #697363
            my $formatter = $self->{publican}->param('txt_formater') || '';

            if ( $formatter eq 'links' ) {
                my $f = HTML::FormatText::WithLinks->new();
                print( $TXT_FILE $f->parse( $tree->as_HTML() ) );

            }
            elsif ( $formatter eq 'tables' ) {
                print( $TXT_FILE HTML::FormatText::WithLinks::AndTables
                        ->convert(
                        $tree->as_HTML,
                        {   leftmargin   => 0,
                            rightmargin  => 72,
                            anchor_links => 0,
                            before_link  => ' [%n] '
                        }
                        )
                );
            }
            else {
                my $f = HTML::FormatText->new(
                    leftmargin  => 0,
                    rightmargin => 72
                );
                print( $TXT_FILE $f->format($tree) );
            }

        }
        else {
            # must be a wiki format
            open( $TXT_FILE, ">:encoding(UTF-8)", "$format/$docname.txt" )
                || croak( maketext("Can't open file for text output!") );

            my $tree = HTML::TreeBuilder->new();
            eval { $tree->parse_file($fh); };

            if ($@) {
                croak( maketext( "FATAL ERROR 4: [_1]", $@ ) );
            }

            # remove broken empty anchors
            foreach my $node ( $tree->root()->look_down( '_tag', 'a' ) ) {
                if ( $node->is_empty() && $node->id() ) {
                    $node->parent()->id( $node->id() );
                    $node->delete();
                }
            }

            # remove extra code tags anchors
            foreach my $node ( $tree->root()
                ->look_down( _tag => 'code', class => qr/email|uri/ ) )
            {
                $node->replace_with_content();
            }
            my %opts;

            if ( $format eq 'Markdown' ) {
                $opts{link_style}         = 'inline';
                $opts{ordered_list_style} = 'one-dot';
                $opts{md_extra}           = 1;
            }

            my $wc   = new HTML::WikiConverter( dialect => $format, %opts );
            my $html = encode_utf8( $tree->as_XML() );
            my $txt  = $wc->html2wiki($html);
            print( $TXT_FILE decode_utf8($txt) );
        }
        close($TXT_FILE);
        $dir = undef;
        return;
    }

    my ( $web_product_label, $web_version_label, $web_name_label )
        = $self->web_labels( { lang => $lang, xml_lang => $xml_lang } );

    if ( $format eq 'pdf' && $diefopdie ) {
        if ( -d "$tmp_dir/$lang/html-pdf" ) {
            rmtree("$tmp_dir/$lang/html-pdf");
        }

        $self->transform( { lang => $lang, format => 'html-pdf' } );

        mkdir "$tmp_dir/$lang/pdf";

        my $tmpl_path = Publican::ConfigData->config('book_templates');

        my $header = "$tmp_dir/$lang/html-pdf/header.html";
        my $footer = "$tmp_dir/$lang/html-pdf/footer.html";

        my @wkhtmltopdf_args = (
            $wkhtmltopdf_cmd,        '--disable-smart-shrinking',
            '--javascript-delay',    0,
            '--header-spacing',      6,
            '--footer-spacing',      6,
            '--margin-top',          '14mm',
            '--margin-bottom',       '14mm',
            '--margin-left',         '15mm',
            '--margin-right',        '15mm',
            '--header-html',         $header,
            '--footer-html',         $footer,
            '--load-error-handling', 'ignore'
        );

        if ( $self->{publican}->param('wkhtmltopdf_opts') ) {
            push( @wkhtmltopdf_args,
                split( /\s+/, $self->{publican}->param('wkhtmltopdf_opts') )
            );
        }

        rcopy_glob( "$tmpl_path/*.css", "$tmp_dir/$lang/html-pdf/" );

        if ( -d "$brand_path/book_templates" ) {
            rcopy_glob(
                "$brand_path/book_templates/*.css",
                "$tmp_dir/$lang/html-pdf/"
            ) if ( glob("$brand_path/book_templates/*.css") );
            $tmpl_path = "$brand_path/book_templates:$tmpl_path";
        }

        my $tconf = { INCLUDE_PATH => $tmpl_path, };
        my $template = Template->new($tconf)
            or croak( Template->error() );

        my $subtitle = $self->get_subtitle( { lang => $lang } );
        $subtitle =~ s/"/\\"/g;
        $subtitle =~ s/\p{Z}+/ /g;
        chomp($subtitle);

        my $prod
            = $web_product_label
            ? $web_product_label
            : $self->{publican}->param('product');
        $prod =~ s/_/ /g;

        my $ver
            = $web_version_label
            ? $web_version_label
            : $self->{publican}->param('version');
        $ver =~ s/_/ /g;

        my $name
            = $web_name_label
            ? $web_name_label
            : $self->{publican}->param('docname');
        $name =~ s/_/ /g;

        my @authors = $self->get_author_list( { lang => $lang } );
        my $contributors = $self->get_contributors( { lang => $lang } );
        my $legalnotice = $self->get_legalnotice( { lang => $lang } );
        my $abstract
            = $self->get_abstract( { lang => $lang, format => 'xml' } );
        $abstract =~ s/\p{Z}+/ /g;

        my @keywords = $self->get_keywords( { lang => $lang } );
        my $draft = $self->get_draft( { lang => $lang } );

        my $xml_file = "$tmp_dir/$lang/xml/" . ucfirst($type) . '_Info.xml';
        $xml_file
            = "$tmp_dir/$lang/xml/" . $self->{publican}->param('info_file')
            if ( $self->{publican}->param('info_file') );
        croak( maketext( "Can't locate required file: [_1]", $xml_file ) )
            if ( !-f $xml_file );

        my $xml_doc = XML::TreeBuilder->new();
        eval { $xml_doc->parse_file($xml_file); };
        if ($@) {
            croak( maketext( "FATAL ERROR 5: [_1]", $@ ) );
        }

        my $logo = eval {
            $xml_doc->root()->look_down( "_tag", "corpauthor" )
                ->look_down( "_tag", "imagedata" )->attr('fileref');
        };

        my $edition = eval {
            $xml_doc->root()->look_down( "_tag", "edition" )->as_text();
        };
        my $releaseinfo = eval {
            $xml_doc->root()->look_down( "_tag", "releaseinfo" )->as_text();
        };

        my $bodyfont = $self->{publican}->param('pdf_body_font');
        my $monofont = $self->{publican}->param('pdf_mono_font');

        my $vars = {
            draft   => $draft,
            product => decode_utf8( encode_utf8($prod) ),
            docname => decode_utf8( encode_utf8($name) ),
            version => decode_utf8( encode_utf8($ver) ),
            release => decode_utf8(
                encode_utf8( $self->{publican}->param('release') )
            ),
            subtitle     => decode_utf8( encode_utf8($subtitle) ),
            authors      => \@authors,
            editorlabel  => decode_utf8( $locale->maketext("Edited by") ),
            contributors => $contributors,
            contriblabel =>
                decode_utf8( $locale->maketext("With contributions from") ),
            legalnotice   => $legalnotice,
            legaltitle    => decode_utf8( $locale->maketext("Legal Notice") ),
            abstract      => $abstract,
            abstracttitle => decode_utf8( $locale->maketext("Abstract") ),
            keywordtitle  => decode_utf8( $locale->maketext("Keywords") ),
            toctitle => decode_utf8( $locale->maketext("Table of Contents") ),
            logo     => ( $logo || 'Common_Content/images/title_logo.svg' ),
            buildpath           => abs_path("$tmp_dir/$lang/html-pdf"),
            chunk_section_depth => $chunk_section_depth,
            bodyfont            => $bodyfont,
            bodyface =>
                ( -f "$tmp_dir/$lang/html-pdf/$bodyfont-font-faces.css" ),
            monofont => $monofont,
            monoface =>
                ( -f "$tmp_dir/$lang/html-pdf/$monofont-font-faces.css" ),
            overrides_css => ( -f "$tmp_dir/$lang/html-pdf/overrides.css" ),
            lang_css      => ( -f "$tmp_dir/$lang/html-pdf/lang.css" ),
        };

        if (@keywords) {
            $vars->{keywords} = \@keywords;
        }

        if ($edition) {
            $vars->{edition} = decode_utf8(
                $locale->maketext( 'Edition [_1]', $edition ) );
        }
        if ($releaseinfo) {
            $vars->{releaseinfo} = decode_utf8($releaseinfo);
        }

        $template->process(
            'cover.tmpl', $vars,
            "$tmp_dir/$lang/html-pdf/cover.html",
            binmode => ':encoding(UTF-8)'
        ) or croak( $template->error() );

        push( @wkhtmltopdf_args,
            'cover', "$tmp_dir/$lang/html-pdf/cover.html" );

        my $toc_xsl = "$tmp_dir/$lang/html-pdf/toc.xsl";

        $template->process( 'toc-xsl.tmpl', $vars, $toc_xsl,
            binmode => ':encoding(UTF-8)' )
            or croak( $template->error() );

        my $out_file = "$tmp_dir/$lang/html-pdf/header.html";

        $template->process( 'header.tmpl', $vars, $out_file,
            binmode => ':encoding(UTF-8)' )
            or croak( $template->error() );

        $out_file = "$tmp_dir/$lang/html-pdf/footer.html";

        $template->process( 'footer.tmpl', $vars, $out_file,
            binmode => ':encoding(UTF-8)' )
            or croak( $template->error() );

        $out_file = "$tmp_dir/$lang/html-pdf/pdfmain.css";

        $template->process( 'pdfmain-css.tmpl', $vars, $out_file,
            binmode => ':encoding(UTF-8)' )
            or croak( $template->error() );

        push(
            @wkhtmltopdf_args,
            'toc',
            '--xsl-style-sheet',
            $toc_xsl,
##            '--toc-header-text',
##            decode_utf8( $locale->maketext("Table of Contents") ),
            "$tmp_dir/$lang/html-pdf/index.html",
            "$tmp_dir/$lang/pdf/$pdf_name"
        );

        logger( "Running: " . join( " ", @wkhtmltopdf_args ) . "\n" );
        my $result = system(@wkhtmltopdf_args);
        if ($result) {
            croak(
                "\n",
                maketext(
                    'wkhtmltopdf died, PDF generation failed. Check log for details.'
                ),
                "\n"
            );
        }
        return;
    }

    my $xsl_file = $common_config . "/xsl/$format.xsl";
    $xsl_file = "$brand_path/xsl/$format.xsl"
        if ( -f "$brand_path/xsl/$format.xsl" );

    # required for Windows
    $xsl_file =~ s/"//g;

    my %xslt_opts = (
        'toc.section.depth'          => $toc_section_depth,
        'confidential'               => $confidential,
        'confidential.text'          => "'$confidential_text'",
        'profile.lang'               => "'$lang'",
        'l10n.gentext.language'      => "'$lang'",
        'show.comments'              => $show_remarks,
        'generate.section.toc.level' => $generate_section_toc_level,
        'use.extensions'             => 1,
        'tablecolumns.extensions'    => 1,
        'publican.version'           => "'$Publican::VERSION'",
        'bridgehead.in.toc'          => $bridgehead_in_toc,
        'body.only'                  => 0,
        'brand'                      => "'$brand'",
        'langpath'                   => "'$lang'",
        'book.type'                  => "'$type'",
        'web.type'                   => "'$web_type'",
##        '' => ,
    );

    mkdir "$tmp_dir/$lang/$format";

    my $pop_prod = $self->{publican}->param('product');
    my $pop_ver  = $self->{publican}->param('version');
    my $pop_name = $self->{publican}->param('docname');

    my $toc_path = '../../../..';
    $toc_path = '.' if ( $self->{publican}->param('web_home') );

    if ( $self->{publican}->param('web_type') ) {
        if ( $web_type =~ m/^home$/i ) {
            $toc_path = '.';
            $pop_prod = undef;
            $pop_ver  = undef;
            $pop_name = undef;
        }
        elsif ( $web_type =~ m/^product$/i ) {
            $toc_path = '..';
            $pop_ver  = undef;
            $pop_name = undef;
        }
        elsif ( $web_type =~ m/^version$/i ) {
            $toc_path = '../..';
            $pop_name = undef;
        }
    }

    $xslt_opts{clean_title}
        = $web_name_label
        ? $web_name_label
        : $pop_name;

    $xslt_opts{clean_title} = $self->{publican}->param('docname')
        unless ( $xslt_opts{clean_title} );
    $xslt_opts{clean_title} = '"' . $xslt_opts{clean_title} . '"';
    $xslt_opts{clean_title} =~ s/_/ /g;

    if ( $format eq 'html-single' ) {

        $dir = pushd("$tmp_dir/$lang/$format");

        $xslt_opts{'doc.url'}  = "'$doc_url'";
        $xslt_opts{'prod.url'} = "'$prod_url'";
        $xslt_opts{'package'} = "'$TAR_NAME-$lang-$RPM_VERSION-$RPM_RELEASE'";
        $xslt_opts{'embedtoc'} = $embedtoc;
        $xslt_opts{'tocpath'}  = "'$toc_path'";
        $xslt_opts{'pop_prod'} = "'$pop_prod'" if ($pop_prod);
        $xslt_opts{'pop_ver'}  = "'$pop_ver'" if ($pop_ver);
        $xslt_opts{'pop_name'} = "'$pop_name'" if ($pop_name);
    }
    elsif ( $format eq 'html-single-plain' ) {

        $dir = pushd("$tmp_dir/$lang/$format");
    }
    elsif ( $format eq 'html-pdf' ) {
        $dir = pushd("$tmp_dir/$lang/$format");
        my $title;

        $title
            = $web_product_label
            ? $web_product_label
            : $self->{publican}->param('product');
        $title .= ' ';
        $title .=
              $web_version_label
            ? $web_version_label
            : $self->{publican}->param('version');
        $title .= ' ';

        $title =~ s/_/ /g;

        $xslt_opts{'product'}    = "'$title'";
        $xslt_opts{'svg.object'} = "0";
        $xslt_opts{'doc.url'}    = "'$doc_url'";
        $xslt_opts{'prod.url'}   = "'$prod_url'";
        $xslt_opts{'package'} = "'$TAR_NAME-$lang-$RPM_VERSION-$RPM_RELEASE'";
        $xslt_opts{'tocpath'} = "'$toc_path'";
        $xslt_opts{'pop_prod'} = "'$pop_prod'" if ($pop_prod);
        $xslt_opts{'pop_ver'}  = "'$pop_ver'" if ($pop_ver);
        $xslt_opts{'pop_name'} = "'$pop_name'" if ($pop_name);
    }
    elsif ( $format eq 'html-desktop' ) {
        $xsl_file = $common_config . "/xsl/html-single.xsl";
        $xsl_file = "$brand_path/xsl/html-single.xsl"
            if ( -e "$brand_path/xsl/html-single.xsl" );
        $dir = pushd("$tmp_dir/$lang/$format");

        $xslt_opts{'doc.url'}  = "'$doc_url'";
        $xslt_opts{'prod.url'} = "'$prod_url'";
        $xslt_opts{'package'} = "'$TAR_NAME-$lang-$RPM_VERSION-$RPM_RELEASE'";
        $xslt_opts{'desktop'} = 1;

    }
    elsif ( $format eq 'html' ) {
        $dir = pushd("$tmp_dir/$lang/$format");

        $xslt_opts{'doc.url'}  = "'$doc_url'";
        $xslt_opts{'prod.url'} = "'$prod_url'";
        $xslt_opts{'package'} = "'$TAR_NAME-$lang-$RPM_VERSION-$RPM_RELEASE'";
        $xslt_opts{'embedtoc'}             = $embedtoc;
        $xslt_opts{'tocpath'}              = "'$toc_path'";
        $xslt_opts{'chunk.first.sections'} = $chunk_first;
        $xslt_opts{'chunk.section.depth'}  = $chunk_section_depth;
        $xslt_opts{'pop_prod'}             = "'$pop_prod'" if ($pop_prod);
        $xslt_opts{'pop_ver'}              = "'$pop_ver'" if ($pop_ver);
        $xslt_opts{'pop_name'}             = "'$pop_name'" if ($pop_name);
    }
    elsif ( $format eq 'drupal-book' ) {
        $dir                               = pushd("$tmp_dir/$lang/$format");
        $xslt_opts{'chunk.first.sections'} = $chunk_first;
        $xslt_opts{'chunk.section.depth'}  = $chunk_section_depth;
        $xslt_opts{'doc.url'}              = "'$doc_url'";
        $xslt_opts{'prod.url'}             = "'$prod_url'";
    }
    elsif ( ( $format =~ /^pdf/ ) and ( -f $xsl_file ) ) {
        $dir = pushd("$tmp_dir/$lang/xml");
    }
    elsif ( $format eq 'epub' ) {
        $dir = pushd("$tmp_dir/$lang/$format");
    }
    elsif ( $format eq 'eclipse' ) {
        $xslt_opts{'eclipse.plugin.name'}     = "'$ec_name'";
        $xslt_opts{'eclipse.plugin.id'}       = "'$ec_id'";
        $xslt_opts{'eclipse.plugin.provider'} = "'$ec_provider'";
        $dir = pushd("$tmp_dir/$lang/$format");
    }
    elsif ( $format eq 'man' ) {
        $dir = pushd("$tmp_dir/$lang/$format");
    }
    else {
        croak( maketext( "Unknown format: [_1]", $format ) );
    }

    # required for Windows
    $xsl_file =~ s/"//g;

    logger(
        "\t" . maketext( "Using XML::LibXSLT on [_1]", $xsl_file ) . "\n" );
    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();
    XML::LibXSLT->register_function( 'urn:perl', 'adjustColumnWidths',
        \&adjustColumnWidths );
    XML::LibXSLT->register_function( 'urn:perl', 'highlight', \&highlight );
    XML::LibXSLT->register_function( 'urn:perl', 'insertCallouts',
        \&insertCallouts );
    XML::LibXSLT->register_function( 'urn:perl', 'numberLines',
        \&numberLines );
    XML::LibXSLT->max_depth(10000);

    my $security = XML::LibXSLT::Security->new();
    $security->register_callback( create_dir => sub { 1; } );

    #    $security->register_callback(read_net => sub { 0; });
    $xslt->security_callbacks($security);

    $parser->expand_xinclude(1);
    $parser->expand_entities(1);

    my $source;
    eval { $source = $parser->parse_file("../xml/$main_file.xml"); };

    if ($@) {
        if ( ref($@) ) {

            # handle a structured error (XML::LibXML::Error object)
            croak(
                maketext(
                    "FATAL ERROR 6: [_1]:[_2] in [_3] on line [_4]: [_5]",
                    $@->domain(),
                    $@->code(),
                    $@->file(),
                    $@->line(),
                    $@->message(),
                )
            );
        }
        else {
            croak( maketext( "FATAL ERROR 7: [_1]", $@ ) );
        }
    }

    my $style_doc = $parser->parse_file($xsl_file);

## BUGBUG get Win32 working with Publican::ConfigData
## BUGBUG also get catalog working!
    if ( $^O eq 'MSWin32' ) {
        eval { require Win32::TieRegistry; };
        croak(
            maketext(
                "Failed to load Win32::TieRegistry module. Error: [_1]", $@
            )
        ) if ($@);

        my $defualt_href
            = 'http://docbook.sourceforge.net/release/xsl/current';
        my $key = new Win32::TieRegistry( "LMachine\\Software\\Publican",
            { Delimiter => "\\" } );

        my $new_href = 'file:///C:/publican/docbook-xsl-1.76.1';
        if ( $key and $key->GetValue("xsl_path") ) {
            $new_href = 'file:///' . $key->GetValue("xsl_path");
            $new_href =~ s/ /%20/g;
            $new_href =~ s/\\/\//g;
        }

        my @nodelist = $style_doc->getElementsByTagName('xsl:import');
        foreach my $node (@nodelist) {
            my $href = $node->getAttribute('href');
            debug_msg("changing $defualt_href to $new_href\n");
            $href =~ s|$defualt_href|$new_href|;
            $node->setAttribute( 'href', $href );
        }
    }

    my $stylesheet = $xslt->parse_stylesheet($style_doc);
    my $results = $stylesheet->transform( $source, %xslt_opts );

    if ( $format =~ /^pdf/ ) {
        eval { $stylesheet->output_file( $results, "$docname.fo" ) };
    }
    elsif ( $format =~ /^html-/ ) {    # html-single and html-desktop html-pdf
        eval { $stylesheet->output_file( $results, "index.html" ) };
    }
    else {                             # html
        eval { $stylesheet->output_string($results) };
    }

    croak( maketext( "Transformation error '[_1]' : [_2]", $!, $@ ) ) if $@;

    if ( $format =~ /^pdf/ ) {
        my $fop_command
            = qq|CLASSPATH="$classpath" fop -q -c $common_config/fop/fop.xconf -fo $docname.fo -pdf ../pdf/$pdf_name|;

## TODO find out if we need to set classpath on windows and how
        if ( $^O eq 'MSWin32' ) {
            $fop_command
                = qq|fop -q -c $common_config/fop/fop.xconf -fo $docname.fo -pdf ../pdf/$pdf_name|;
        }

        if ( system($fop_command) != 0 ) {
            croak(
                "\n",
                maketext(
                    "FOP error, PDF generation failed. Check log for details."
                ),
                "\n"
            );
        }

        $dir = undef;
    }
    elsif ( $format eq 'epub' ) {
        $dir = undef;
        my $images = $self->{publican}->param('img_dir');
        dircopy( "$tmp_dir/$lang/xml/$images",
            "$tmp_dir/$lang/$format/OEBPS/$images" )
            if ( -d "$tmp_dir/$lang/xml/$images" );
        dircopy(
            "$tmp_dir/$lang/xml/Common_Content",
            "$tmp_dir/$lang/$format/OEBPS/Common_Content"
        );

        unlink("$tmp_dir/$lang/$format/OEBPS/$images/icon.svg");
        unlink("$tmp_dir/$lang/$format/OEBPS/Common_Content/css/brand.css");
        unlink("$tmp_dir/$lang/$format/OEBPS/Common_Content/css/common.css");
        unlink("$tmp_dir/$lang/$format/OEBPS/Common_Content/css/default.css");
        unlink(
            "$tmp_dir/$lang/$format/OEBPS/Common_Content/css/overrides.css");
        unlink("$tmp_dir/$lang/$format/OEBPS/Common_Content/css/pdf.css");

        unless (
            -f "$tmp_dir/$lang/$format/OEBPS/Common_Content/css/lang.css" )
        {
            my $OUTDOC;
            open( $OUTDOC, ">:encoding(UTF-8)",
                "$tmp_dir/$lang/$format/OEBPS/Common_Content/css/lang.css" )
                || croak(
                maketext(
                    "Could not open [_1] for output!",
                    "\$tmp_dir/\$lang/\$format/OEBPS/Common_Content/css/lang.css"
                )
                );
            close($OUTDOC);
        }

        # remove any RCS from the output
        finddepth( \&del_unwanted_dirs, "$tmp_dir/$lang/$format" );

        # remove any XML files from common
        finddepth( \&del_unwanted_xml,
            "$tmp_dir/$lang/$format/OEBPS/Common_Content" );

        my @files        = dir_list( "$tmp_dir/$lang/$format/OEBPS", '*' );
        my $content_file = "$tmp_dir/$lang/$format/OEBPS/content.opf";
        my $tree         = XML::TreeBuilder->new(
            { 'NoExpand' => "1", 'ErrorContext' => "2" } );
        $tree->parse_file("$content_file");
        my $node;
        eval { $node = $tree->look_down( '_tag', "manifest" ); };
        if ( $@ or !$node ) {
            croak( maketext("manifest not found") );
        }

        foreach my $file (@files) {
            $file =~ s/^.*OEBPS\///g;
            $file =~ /(...)$/;
            my $ext = $1;
            my $id  = $file;
            $id =~ s/\//-/g;

            my $exists;
            eval { $exists = $tree->root()->look_down( 'href', "$file" ); };

            if ( !defined($exists) ) {
                $node->push_content(
                    [   'item',
                        {   href         => "$file",
                            'media-type' => "image/$ext",
                            id           => $id
                        }
                    ]
                );
            }
        }

        my $OUTDOC;
        open( $OUTDOC, ">:encoding(UTF-8)", "$content_file" )
            || croak(
            maketext( "Could not open [_1] for output!", $content_file ) );
        my $text = $tree->as_XML();
        $text =~ s/&#34;/"/g;
        $text =~ s/&#39;/'/g;
        $text =~ s/&quot;/"/g;
        $text =~ s/&apos;/'/g;
        print( $OUTDOC $text );
        close($OUTDOC);

        my $MIME;
        open( $MIME, ">", "$tmp_dir/$lang/$format/mimetype" )
            || croak( maketext("Can't open mimetype file: ") );
        print( $MIME 'application/epub+zip' );
        close($MIME);

        $dir = pushd("$tmp_dir/$lang/$format");

        my $zip = Archive::Zip->new();

        my $mimetype = $zip->addFile("mimetype");
        $mimetype->desiredCompressionMethod(COMPRESSION_STORED);

        my $member = $zip->addDirectory("OEBPS/");
        $member = $zip->addDirectory("META-INF/");

        my @filelist = File::Find::Rule->file->not_name('mimetype')->in(".");
        foreach my $file (@filelist) {
            $member = $zip->addFile($file);
        }

        my $epub_name
            = $self->{publican}->param('product') . '-'
            . $self->{publican}->param('version') . '-'
            . $self->{publican}->param('docname') . '-'
            . "$lang.epub";
        $self->{epub_name} = $epub_name;
        $zip->writeToFileNamed("../$epub_name") == AZ_OK
            || croak( maketext("epub creation failed.") );
        logger(
            maketext( "Wrote epub archive: [_1]",
                "$tmp_dir/$lang/$epub_name" )
                . "\n"
        );
        $dir = undef;
    }
    elsif ( $format eq 'man' ) {

        # NO-OP?
    }
    elsif ( $format eq 'drupal-book' ) {
        $dir = undef;

        my $title = $xslt_opts{clean_title};
        $title =~ s/^"//;
        $title =~ s/"$//;

        my $docname = $self->{publican}->param('docname');
        my $product = $self->{publican}->param('product');
        my $version = $self->{publican}->param('version');
        my $edition = $self->{publican}->param('edition');
        my $release = $self->{publican}->param('release');

        my $filename
            = "$product-$version-$docname-$lang-$edition-$release.tar.gz";
        my $content_dir
            = "$product-$version-$docname-$lang-$edition-$release";

        $self->drupal_transform(
            { lang => $lang, filename => $filename, title => $title } );
        my $images = $self->{publican}->param('img_dir');

        dircopy( "$tmp_dir/$lang/xml/$images",
            "$tmp_dir/$lang/$format/$content_dir/$images" )
            if ( -d "$tmp_dir/$lang/xml/$images" );

        dircopy( "$xml_lang/files",
            "$tmp_dir/$lang/$format/$content_dir/files" )
            if ( -e "$xml_lang/files" );
        dircopy( "$lang/files", "$tmp_dir/$lang/$format/$content_dir/files" )
            if ( -e "$lang/files" );

        # remove any RCS from the output
        finddepth( \&del_unwanted_dirs, "$tmp_dir/$lang/$format" );

        $dir = pushd("$tmp_dir/$lang/$format");

        # remove all html files
        my @htmls = glob "*.html";
        foreach (@htmls) {
            unlink($_);
        }

        my $tar      = Archive::Tar->new();
        my @filelist = File::Find::Rule->file->in($content_dir);
        $tar->add_files(@filelist);
        $tar->write( $filename, COMPRESS_GZIP );
        $dir = undef;
        logger(
            maketext( "Wrote tar archive: [_1]",
                "$tmp_dir/$lang/$format/$filename" )
                . "\n"
        );
    }
    else {
        my $images = $self->{publican}->param('img_dir');
        $dir = undef;
        dircopy( "$tmp_dir/$lang/xml/$images",
            "$tmp_dir/$lang/$format/$images" )
            if ( -d "$tmp_dir/$lang/xml/$images" );
        dircopy(
            "$tmp_dir/$lang/xml/Common_Content",
            "$tmp_dir/$lang/$format/Common_Content"
            )
            if ( $embedtoc == 0
            || $format eq 'html-desktop'
            || $format eq 'html-pdf' );
        dircopy( "$xml_lang/files", "$tmp_dir/$lang/$format/files" )
            if ( -e "$xml_lang/files" );
        dircopy( "$lang/files", "$tmp_dir/$lang/$format/files" )
            if ( -e "$lang/files" );

        # remove any RCS from the output
        finddepth( \&del_unwanted_dirs, "$tmp_dir/$lang/$format" );

        # remove any XML files from common
        finddepth( \&del_unwanted_xml,
            "$tmp_dir/$lang/$format/Common_Content" )
            if ( $embedtoc == 0
            || $format eq 'html-desktop'
            || $format eq 'html-pdf' );
    }

    $xslt       = undef;
    $source     = undef;
    $style_doc  = undef;
    $stylesheet = undef;
    $parser     = undef;

## TODO BUGBUG freeing $results goes BOOM on windows
## TODO requires testing since the other crashbug is resolved
    $results = undef;

    return;
}

=head2 drupal_transform

Write csv file for drupal node import

=cut

sub drupal_transform {
    my ( $self, $args ) = @_;

    my $lang = delete $args->{lang}
        || croak maketext(
        "[_1] is a mandatory argument for drupal_transform", 'lang' );
    my $filename = delete $args->{filename}
        || croak maketext(
        "[_1] is a mandatory argument for drupal_transform", 'filename' );
    my $title = delete $args->{title}
        || croak maketext(
        "[_1] is a mandatory argument for drupal_transform", 'title' );

    my $tmp_dir    = $self->{publican}->param('tmp_dir');
    my $main_file  = $self->{publican}->param('mainfile');
    my $docname    = $self->{publican}->param('docname');
    my $product    = $self->{publican}->param('product');
    my $version    = $self->{publican}->param('version');
    my $edition    = $self->{publican}->param('edition');
    my $release    = $self->{publican}->param('release');
    my $xml_lang   = $self->{publican}->param('xml_lang');
    my $drupal_dir = "$tmp_dir/$lang/drupal-book";
    my $subtitle   = $self->get_subtitle( { lang => $lang } );
    my $abstract   = $self->get_abstract( { lang => $lang } );
    my $keywords   = join( ',', $self->get_keywords( { lang => $lang } ) );

    my $parser = XML::LibXML->new();
    $parser->expand_xinclude(1);
    $parser->expand_entities(1);

    my $source;
    eval {
        $source = $parser->parse_file("$tmp_dir/$lang/xml/$main_file.xml");
    };

    my %all_nodes;
    my %section_maps;
    my $nodes_order = $self->get_nodes_order(
        {   source       => $source,
            section_maps => \%section_maps,
            all_nodes    => \%all_nodes
        }
    );

    my $outputs = $self->build_drupal_book(
        {   lang         => $lang,
            nodes_order  => $nodes_order,
            section_maps => \%section_maps,
            all_nodes    => \%all_nodes
        }
    );

    $self->{dbh}->disconnect()
        if ( defined $self->{dbh} );

    my $out_file
        = "$drupal_dir/$product-$version-$docname-$lang-$edition-$release.xml";
    my $fh;

    open( $fh, ">:encoding(UTF-8)", $out_file )
        || croak(
        maketext( "Could not open [_1] for output: [_2]", $out_file, $@ ) );

    $fh->print(<<EOH);
<?xml version="1.0" encoding="UTF-8"?>
<document>
  <name>$product $version $title</name>
  <title>$title</title>
  <subtitle>$subtitle</subtitle>
  <lang>$lang</lang>
  <images>$filename</images>
  <product>$product</product>
  <version>$version</version>
  <edition>$edition</edition>
  <release>$release</release>
  <abstract>$abstract</abstract>
  <keywords>$keywords</keywords>
EOH

    foreach my $row ( @{$outputs} ) {
        $fh->print(<<EOR);
  <page>
    <title>$row->[0]</title>
    <url>$row->[10]</url>
    <parent>$row->[2]</parent>
    <weight>$row->[3]</weight>
    <menu>$row->[4]</menu>
    <body>$row->[6]</body>
  </page>
EOR
    }

    $fh->print("</document>\n");

    return;
}

=head2 get_nodes_order

Get all nodes with id from xml files in order

=cut

sub get_nodes_order {
    my ( $self, $args ) = @_;

    my $source = delete( $args->{source} )
        || croak( maketext("source is a mandatory argument") );

    my $node         = delete( $args->{node} )         || undef;
    my $section_maps = delete( $args->{section_maps} ) || {};
    my $all_nodes    = delete( $args->{all_nodes} )    || {};
    my $check_dups   = delete( $args->{check_dups} )   || {};

    my %order;
    my @node_list;

    if ( !$node ) {
        @node_list
            = $source->getElementsByTagName('book')->[0]->childNodes();
    }
    else {
        @node_list = $node->childNodes();
    }

    my $count = 0;
    foreach my $cnode (@node_list) {
        if ( $cnode->nodeName() eq 'index' ) {
            $order{ ++$count }{'id'} = "ix01";
            $order{$count}{'type'} = "index";
        }

    # $cnode->attributes will return namespace too, so we need to skip it here
        next if ( !$cnode->hasAttributes() );

        my $unique_id = undef;
        foreach my $cnode_attr ( $cnode->attributes() ) {
            if ( $cnode_attr->name() eq "conformance" ) {
                $unique_id = $cnode_attr->getValue();

                #print "$unique_id\n";
            }

            if ( $cnode_attr && $cnode_attr->name() eq "id" ) {
                my $value = $cnode_attr->getValue();
                $order{ ++$count }{'id'} = $value;
                $order{$count}{'type'} = $cnode->nodeName();
                $section_maps->{$value} = $unique_id || $value;

                if ( defined $unique_id ) {

                    croak(
                        maketext(
                            "Duplicate conformance value in section $value which value = $unique_id."
                        )
                    ) if ( defined $check_dups->{$unique_id} );

                    $check_dups->{$unique_id} = 1;
                }

#|| croak ( maketext("missing 'conformance' attribute in $order{$count}{type} where id is $value") );
                $all_nodes->{$value} = 1;
                my $child_nodes = $self->get_nodes_order(
                    {   source       => $source,
                        node         => $cnode,
                        section_maps => $section_maps,
                        all_nodes    => $all_nodes,
                        check_dups   => $check_dups,
                    }
                );
                $order{$count}{'childs'} = $child_nodes
                    if ( %{$child_nodes} );
            }
        }
    }
    return \%order;
}

=head2 build_drupal_book

Convert each html file into csv a row for drupal.

=cut

sub build_drupal_book {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak(
        maketext("lang is a mandatory argument for build_drupal_book") );

    my $nodes_order = delete( $args->{nodes_order} )
        || croak(
        maketext("nodes_order is a mandatory argument for build_drupal_book")
        );

    my $section_maps = delete $args->{section_maps} || {};
    my $all_nodes    = delete $args->{all_nodes}    || {};

    my $parent       = delete $args->{parent}       || "";
    my $parent_alias = delete $args->{parent_alias} || "";

    my $tmp_dir    = $self->{publican}->param('tmp_dir');
    my $docname    = $self->{publican}->param('docname');
    my $product    = $self->{publican}->param('product');
    my $version    = $self->{publican}->param('version');
    my $author     = $self->{publican}->param('drupal_author');
    my $book_title = $self->{publican}->param('drupal_menu_title');
    my $menu_block = $self->{publican}->param('drupal_menu_block');
    my $img_path   = $self->{publican}->param('drupal_image_path');

    $menu_block = ($menu_block) ? "menu-$menu_block" : "";

    my $bookname     = "$product-$version-$docname-$lang";
    my $drupal_dir   = "$tmp_dir/$lang/drupal-book";
    my $resource_dir = "$lang/$product/$version/$docname";

    my @outputs;
    my $weight        = -16;
    my $previous_type = "";
    foreach my $order_num ( sort { $a <=> $b } keys %{$nodes_order} ) {

        my $page
            = ( $nodes_order->{$order_num}{'id'} =~ /^book\-/ )
            ? 'index'
            : $nodes_order->{$order_num}{'id'};
        my $file_name = "$drupal_dir/$page.html";

        if ( -e $file_name ) {
            my @csv_row;
            my $tree = HTML::TreeBuilder->new();

            open my $html_file, "<:encoding(utf8)", $file_name
                or croak "$file_name: $!";

            eval { $tree->parse_file($html_file); };
            if ($@) {
                croak( maketext( "FATAL ERROR 8: [_1]", $@ ) );
            }

            $html_file->close();

            my $title_element = $tree->look_down( '_tag', 'title' );
            my $title = $title_element->as_trimmed_text;

            #delete html head
            my $head_element = $tree->look_down( '_tag', 'head' );
            $head_element->delete();

            my $delete_first_header = 1;
            my %header_tags = ( h1 => 1, h2 => 1, h3 => 1, h4 => 1, h5 => 1 );

            $tree->traverse(
                [    # Callbacks;
                        # pre-order callback:
                    sub {
                        my $node = $_[0];
                        my $tag  = $node->{'_tag'};

              # only delete the first header tag because it is already showing
              # in the drupal title
                        if ( defined $header_tags{$tag}
                            && $delete_first_header == 1 )
                        {
                            $node->delete();
                            $delete_first_header = 0;
                        }

                        if (   defined $node->attr('id')
                            && defined $section_maps->{ $node->attr('id') } )
                        {
                            my $id = $node->attr('id');
                            $node->attr( 'id', $section_maps->{$id} );
                        }

                        if ( $tag eq 'img' && defined $node->attr('src') ) {
                            my $old_value = $node->attr('src');
                            $node->attr( 'src',
                                "$img_path$resource_dir/" . $old_value )
                                if ($old_value);
                        }

                        if (   $tag eq 'object'
                            && defined $node->attr('type')
                            && $node->attr('type') eq 'image/svg+xml' )
                        {
                            my $old_value = $node->attr('data') || undef;
                            $node->attr( 'data',
                                "$img_path$resource_dir/" . $old_value )
                                if ($old_value);
                        }

                        if ( $tag eq 'a' && defined $node->attr('href') ) {
                            my $old_value = $node->attr('href');
                            if ($old_value) {
                                my @links;
                                my $update_link = 0;
                                @links = split( '#', $old_value );

                                for ( my $i = 0; $i < @links; $i++ ) {
                                    next if ( !$links[$i] );
                                    $links[$i] =~ s/\.html$//;
                                    if (defined $section_maps->{ $links[$i] }
                                        )
                                    {
                                        $links[$i]
                                            = $section_maps->{ $links[$i] };
                                        $update_link = 1;
                                    }

                                    unless ($update_link) {

                                        # check if it is internal page
                                        if (defined $all_nodes->{ $links[$i] }
                                            )
                                        {
                                            $update_link = 1;
                                        }
                                    }

                                    if ( $links[$i] eq 'ix01' ) {
                                        $links[$i] = 'index';
                                        $update_link = 1;
                                    }
                                }

                                if ($update_link) {
                                    $old_value = join( '#', @links );
                                    $node->attr( 'href',
                                        "$bookname-" . $old_value );
                                    $update_link = 0;
                                }

                                #else {
                                #print ">>$old_value>> not found\n";
                                #}
                            }
                        }

                        return HTML::Element::OK;    # keep traversing
                    },

                    # post-order callback:
                    undef
                ],
                1,    # don't call the callbacks for text nodes
            );

            my $alias = "$bookname-$page";
            my $section_weight
                = { preface => 1, chapter => 2, appendix => 3 };

            #if ($previous_type ne $nodes_order->{$order_num}{'type'}) {
            if ( $weight < 30 ) {
                $weight++;
            }
            else {
                logger(
                    maketext(
                        "Reached the maximum page ordering weight(30) that drupal can support. The rest of the pages will be ordered in alphabetical order\n"
                    ),
                    RED
                );
            }

            #}

            my $menu_link  = "";
            my $menu_title = "";
            my $book
                = ($book_title)
                ? $book_title
                : "$product $version $docname";
            if ( $page eq 'index' ) {
                $alias      = $bookname;
                $title      = $book;
                $menu_title = $book;
                $menu_link  = $menu_block;
                $book       = "";
            }
            elsif ( $page eq 'ix01' ) {
                $alias = "$bookname-index";
            }
            else {
                $alias = "$bookname-$section_maps->{$page}"
                    || croak( maketext("Fail to get the mapping for $page") );
            }

            $title =~ s/\s+/ /g;
            my $html_string = $tree->as_HTML( '<>&', "", {} );
            $html_string =~ s{^<!DOCTYPE [^>]*>\n*}{};
            $html_string =~ s{<html.*>\s*<body[^>]*>}{};
            $html_string =~ s{</body>}{};
            $html_string =~ s{</html>}{};
##            $html_string =~ s{&ldquo;}{"};
##            $html_string =~ s{&rdquo;}{"};
##            $html_string =~ s{&nbsp;}{ };

            push @csv_row, $title;
            push @csv_row, $book;
            push @csv_row, $parent;
            push @csv_row, $weight;
            push @csv_row, $menu_title;
            push @csv_row, $menu_link;
            push @csv_row, $html_string;
            push @csv_row, 2;
            push @csv_row, $author;
            push @csv_row, 'TRUE';
            push @csv_row, $alias;

            push @outputs, \@csv_row;

            if ( defined $nodes_order->{$order_num}{'childs'} ) {
                my $child_outputs = $self->build_drupal_book(
                    {   lang         => $lang,
                        nodes_order  => $nodes_order->{$order_num}{'childs'},
                        section_maps => $section_maps,
                        parent       => $title,
                        parent_alias => $alias,
                    }
                );
                push @outputs, @{$child_outputs};
            }

            $previous_type = $nodes_order->{$order_num}{'type'};
        }
    }

    return \@outputs;
}

=head2  adjustColumnWidths

Adjust column widths for XML Tables. Converts hard coded to px and relative withs to %.

FO input:

"<?xml version=\"1.0\"?>\n<fo:table-column xmlns:fo=\"http://www.w3.org/1999/XSL/Format\" column-number=\"1\" column-width=\"1*\"/>\n<fo:table-column xmlns:fo=\"http://www.w3.org/1999/XSL/Format\" column-number=\"2\" column-width=\"2*\"/>\n<fo:table-column xmlns:fo=\"http://www.w3.org/1999/XSL/Format\" column-number=\"3\" column-width=\"1*\"/>\n<fo:table-column xmlns:fo=\"http://www.w3.org/1999/XSL/Format\" column-number=\"4\" column-width=\"3*\"/>\n"


HTML input:

"<?xml version=\"1.0\"?>\n<colgroup xmlns=\"http://www.w3.org/1999/xhtml\"><col width=\"1*\"/><col width=\"2*\"/><col width=\"1*\"/><col width=\"3*\"/></colgroup>\n"

Returns: modified input tree which is XHTML or XML:FO

=cut

sub adjustColumnWidths {

    my $width   = shift();
    my $content = shift();

    my $table_width = $width->string_value();

    my %px_ratios = (
        in => 96.0000000000011,
        cm => 37.795275591,
        mm => 3.779527559,
        pc => 16,
        pt => 1.333333333,
        px => 1,
    );

    # XML::LibXML::Document
    my $doc       = $content->get_node(1);
    my $childnode = $doc->firstChild;

    # HTML
    my $tagname        = 'col';
    my $width_tag      = 'width';
    my $perc_remaining = 100;

    # FO
    if ( $childnode->nodeName() eq 'fo:table-column' ) {
        $tagname   = 'fo:table-column';
        $width_tag = 'column-width';
    }

    my @widths = ();
    my ( $prop, $perc, $exact, $total_prop ) = ( 0, 0, 0, 0 );
    my $set_width = undef;

    # $node is XML::LibXML::Element
    foreach my $node ( $doc->getElementsByTagName($tagname) ) {

        # $width is XML::LibXML::Attr
        my $width = $node->getAttribute($width_tag);
        if ($width) {
            $set_width = 1;
        }
        else {
            $width = '1*';
        }
        if ( $width =~ m/^(\d+)\*$/ ) {
            $prop++;
            $total_prop += $1;
        }
        elsif ( $width =~ m/^(\d+)\%$/ ) {
            $perc++;
            $perc_remaining -= $1;
        }
        elsif ( $width =~ m/^([0-9]*\.?[0-9]+)(cm|mm|in|pc|pt|px)$/ ) {
            $exact++;
            $width = sprintf( "%dpx", $1 * $px_ratios{$2} );
        }
        else {
            logger(
                maketext( "Unknown width format will be ignored: [_1]",
                    $width )
                    . "\n",
                RED
            );
            $width = '1*';
            $prop++;
            $total_prop += 1;
        }

        push( @widths, "$width" );
    }

    for ( my $i = 0; $i < @widths; $i++ ) {
        my $width = $widths[$i];

        if ( $width =~ m/^(\d+)\*$/ ) {
            $width
                = floor(
                ( ( $1 / $total_prop ) * ( $perc_remaining / 100 ) * 100 )
                + 0.5 )
                . '%';

        }

        $widths[$i] = $width;
    }

    my $i = 0;
    if ($set_width) {
        foreach my $node ( $doc->getElementsByTagName($tagname) ) {
            $node->setAttribute( $width_tag, $widths[$i] );
            $i++;
        }
    }
    return ($content);
}

=head2  highlight

perl_highlight syntax highlighting

Edit highlight_color template in pdf.xsl and .perl_XXX in CSS to change highlight colours

Returns: Modified input tree, which is DocBook XML.

=cut

sub highlight {
    my $lang    = shift();
    my $content = shift();

    my $language = $lang->string_value();

    my $hl = new Syntax::Highlight::Engine::Kate(
        substitutions => {
            "<" => "&lt;",
            ">" => "&gt;",
            "&" => "&amp;",
        },
        format_table => {
            Alert        => [ "<span class='perl_Alert'>",        "</span>" ],
            BaseN        => [ "<span class='perl_BaseN'>",        "</span>" ],
            BString      => [ "<span class='perl_BString'>",      "</span>" ],
            Char         => [ "<span class='perl_Char'>",         "</span>" ],
            Comment      => [ "<span class='perl_Comment'>",      "</span>" ],
            DataType     => [ "<span class='perl_DataType'>",     "</span>" ],
            DecVal       => [ "<span class='perl_DecVal'>",       "</span>" ],
            Error        => [ "<span class='perl_Error'>",        "</span>" ],
            Float        => [ "<span class='perl_Float'>",        "</span>" ],
            Function     => [ "<span class='perl_Function'>",     "</span>" ],
            IString      => [ "<span class='perl_IString'>",      "</span>" ],
            Keyword      => [ "<span class='perl_Keyword'>",      "</span>" ],
            Normal       => [ "",                                 "" ],
            Operator     => [ "<span class='perl_Operator'>",     "</span>" ],
            Others       => [ "<span class='perl_Others'>",       "</span>" ],
            RegionMarker => [ "<span class='perl_RegionMarker'>", "</span>" ],
            Reserved     => [ "<span class='perl_Reserved'>",     "</span>" ],
            String       => [ "<span class='perl_String'>",       "</span>" ],
            Variable     => [ "<span class='perl_Variable'>",     "</span>" ],
            Warning      => [ "<span class='perl_Warning'>",      "</span>" ],
        },
    );

    my $lang_module = $hl->languagePlug( $language, 1 ) || croak(
        "\n\t"
            . maketext( "'[_1]' is not a valid language for highlighting.",
            $language )
            . "\n"
    );

    my $modname = "Syntax::Highlight::Engine::Kate::$lang_module";
    my $plug;
    ## This has to be a string to stop use being run in BEGIN
    # BUGBUG why doesn't this use require?
    ## no critic
    eval "use $modname; \$plug = new $modname(engine => \$hl);";
    ## use critic

    if ( defined($plug) ) {
        $language = $plug->language();
    }
    else {
        croak(
            maketext(
                "Cannot create plugin for language '[_1]': [_2]",
                $language, $@
            )
        );
    }

    $hl->language($language);

    my $parser = XML::LibXML->new();

## BUGBUG testing https://bugzilla.redhat.com/show_bug.cgi?id=604255
##    my $test = $content->get_node(1);
##    my $in_string = $test->toString();
##    $in_string =~ s/^<\?xml version="1.0"\?>\n//gm;
##debug_msg("Highlighting: " . $in_string . "\n") if $language eq 'C++';

    $parser->expand_entities(0);
    my $out_string = '';    #$hl->highlightText( $content->string_value() );

    foreach my $line ( split /^/, $content->string_value() ) {
        my $chomped = chomp($line);
        $out_string .= '<span class="line">&#8203;</span>'
            . $hl->highlightText($line);
        if($chomped) {
            # reset stack
            $hl->highlightText("\n");
            $out_string .= "\n";
        }
    }
##debug_msg("Highlighting: $out_string\n");

    # this gives an XML::LibXML::DocumentFragment
    my $list = $parser->parse_balanced_chunk($out_string);

    # remove the input node
    $content->shift;

    # append the marked-up nodes
    foreach my $node ( $list->childNodes() ) {
        $content->push($node);
    }

    return ($content);
}

=head2 insertCallouts

XSLT callout function for inserting Callout markup in to verbatim text.

Parameters:
	areaspec: the DocBook areaspec node set
	verbatim: the XHTML/XML:FO tree to place gfx in

Returns: modified $verbatim

BUGBUG: BZ #561618
BUGBUG: The approach taken here does not work for tagged content in the verbatim.
BUGBUG: Need to walk the node tree in childnode instead of using it as a string.
BUGBUG: make sure class is being set

=cut

sub insertCallouts {
    my $areaspec = shift();
    my $verbatim = shift();
    my $mode     = ( shift() || 'gfx' );

    my $embedded = 0;
    if ( $mode eq 'embedtoc' ) {
        $mode     = 'gfx';
        $embedded = 1;
    }

    # XML::LibXML::Document
    my $doc       = $areaspec->get_node(1);
    my $verb      = $verbatim->get_node(1);
    my $childnode = $verb->firstChild;

    my $format = 'HTML';
    my $tag    = $childnode->nodeName();

    # PDF
    if ( $tag eq 'fo:block' ) {
        $format = 'PDF';
    }

# This is a hash of arrays, key is line number, array contains indexes on that line.
    my %callout;

    my $index = 0;

    # $node is XML::LibXML::Element
    foreach my $node ( $doc->childNodes() ) {
        if ( $node->nodeName() eq 'areaset' ) {
            $index++;
            foreach my $child ( $node->childNodes() ) {
                if ( $child->nodeName() eq 'area' ) {
                    my $pos = 0;
                    my $col = $child->getAttribute('coords')
                        || carp(
                        maketext("'area' requires a 'coords' attribute.") );
                    if ( $col =~ m/^(\d+)\s+(\d+)$/ ) {
                        $col = $1;
                        $pos = $2;
                    }

                    push( @{ $callout{$col}{lines} }, $index );
                    $callout{$col}{'pos'} = $pos;
                }
            }
        }
        elsif ( $node->nodeName() eq 'area' ) {
            $index++;
            my $pos = 0;
            my $col = $node->getAttribute('coords')
                || carp( maketext("'area' requires a 'coords' attribute.") );

            if ( $col =~ m/^(\d+)\s+(\d+)$/ ) {
                $col = $1;
                $pos = $2;
            }

            push( @{ $callout{$col}{lines} }, $index );
            $callout{$col}{'pos'} = $pos;
        }
    }

    my $in_string = $childnode->string_value();
    my $out_node  = XML::LibXML::Element->new( $childnode->nodeName() );

    my $out_string = '';
    my $count      = 0;
    my $position   = 40;

    my $parser = XML::LibXML->new();
    $parser->expand_entities(0);

    my $test       = $verb->toString();
    my $line_count = 0;

    # calculate numer of lines
    my $io = IO::String->new($test);
    while (<$io>) {
        $line_count++;
    }

    # calculate longest line
    $io    = IO::String->new($test);
    $count = -1;
    while (<$io>) {
        $count++;
        my $line = $_;
        chomp($line);

        # skip first line, which has xml decl
        if ( $count == 0 ) { next; }

        # skip last line, which is close tag
        if ( $count == $line_count - 1 ) { next; }

        my $fline = "";

        if ( $line !~ /^$/ ) {

            # for first node add close tag
## BUGBUG this will break if there are nested block tags
            my $node;
            if ( $count == 1 ) {
                $node = $parser->parse_xml_chunk( $line . "</$tag>" );
            }
            else {

                # FO needs a wrapper to set the namespace
                if ( $format eq 'PDF' ) {
                    $node
                        = $parser->parse_xml_chunk(
                        qq|<$tag xmlns:fo="http://www.w3.org/1999/XSL/Format">|
                            . $line
                            . "</$tag>" );
                }
                else {
                    $node = $parser->parse_xml_chunk($line);
                }
            }

            # calculate unformated line length
            $fline = $node->string_value();
        }

        $position = max( $position, length($fline) + 4 );
        if ( defined( $callout{$count} ) ) {
            $callout{$count}{'length'} = length($fline);
        }
    }

    # add callout numbers
    $io    = IO::String->new($test);
    $count = -1;
    while (<$io>) {
        my $line = $_;
        $count++;

        # skip first line, which has xml decl
        if ( $count == 0 ) { next; }
        $out_string .= $line;

        if ( defined( $callout{$count} ) ) {
            chomp($out_string);

            # if the position requested is less than the line length,
            # use the calculated position instead
            my $pos = $callout{$count}{'pos'};
            $pos = $position if ( $pos < $callout{$count}{'length'} );

            my $padding = $pos - ( $callout{$count}{'length'} || 0 );
            $out_string .= " " x $padding;

            foreach my $index (
                sort( { $a <=> $b } @{ $callout{$count}{lines} } ) )
            {
                if ( $mode eq 'gfx' ) {
                    my $gfx_node;

                    my $common_path = '"Common_Content';

                    $common_path = '../../../..' if ($embedded);
                    if ( $format eq 'HTML' ) {
                        $gfx_node = XML::LibXML::Element->new('img');
                        $gfx_node->setAttribute( 'class', 'callout' );
                        $gfx_node->setAttribute( 'alt',   $index );
                        $gfx_node->setAttribute( 'src',
                            "$common_path/images/$index.png" );
                    }
                    elsif ( $format eq 'PDF' ) {
                        $gfx_node = XML::LibXML::Element->new(
                            'fo:external-graphic');
                        $gfx_node->setAttribute( 'src',
                            "url(Common_Content/images/$index.svg)" );
                        $gfx_node->setAttribute( 'content-width',  '10pt' );
                        $gfx_node->setAttribute( 'content-height', '10pt' );
                        $gfx_node->setAttribute( 'content-type',
                            'content-type:image/svg+xml' );
                        $gfx_node->setNamespace(
                            'http://www.w3.org/1999/XSL/Format', 'fo' );
                    }
                    $out_string .= $gfx_node->toString();
                }
                elsif ( $mode eq 'css' ) {
                    $out_string
                        .= qq{<span class='inlinecallout'>$index</span> };
                }
                else {    # numeric
                    $out_string .= "$index ";
                }
            }
            $out_string .= "\n";
        }

    }

    $childnode->replaceNode( $parser->parse_xml_chunk($out_string) );
    return ($verbatim);
}

=head2  numberLines

perl_numberLines XSL function for numbering lines.

Returns: Modified input tree, which is DocBook XML.

=cut

sub numberLines {

    # BUGBUG testing BZ #653432
    my $count   = shift()->string_value();
    my $content = shift();

    my $parser = XML::LibXML->new();
    $parser->expand_entities(0);

    my $text      = $content->string_value();
    my $num_lines = () = ( $text =~ /^/mg );
    my $format    = '%' . length("$num_lines") . 's:' . chr(160);

    my $out_string = $text;
    $out_string =~ s/^/sprintf("$format",$count++)/egm;

    # this gives an XML::LibXML::DocumentFragment
    # BUGBUG testing BZ #653432
    # my $list = $parser->parse_balanced_chunk($out_string);
    my $list = XML::LibXML::Text->new($out_string);

    # remove the input node
    $content->shift;

    # BUGBUG testing BZ #653432
    $content->push($list);

    # append the marked-up nodes
    #    foreach my $node ( $list->childNodes() ) {
    #        $content->push($node);
    #    }

    return ($content);
}

=head2 web_labels

Determine if the labels use in the web navigation are different from the names used for packaging.

=cut

sub web_labels {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );
    my $xml_lang = delete( $args->{xml_lang} )
        || croak( maketext("xml_lang is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $type    = $self->{publican}->param('type');
    my $docname = $self->{publican}->param('docname');
    my $product = $self->{publican}->param('product');
    my $version = $self->{publican}->param('version');

    my $web_product_label = $self->{publican}->param('web_product_label')
        || undef;
    my $web_version_label = $self->{publican}->param('web_version_label')
        || undef;
    my $web_name_label = $self->{publican}->param('web_name_label') || undef;

    #    if ( $lang ne $xml_lang ) {
    my $xml_file = "$tmp_dir/$lang/xml/$type" . '_Info.xml';
    $xml_file = "$tmp_dir/$lang/xml/" . $self->{publican}->param('info_file')
        if ( $self->{publican}->param('info_file') );
    croak( maketext( "Can't locate required file: [_1]", $xml_file ) )
        if ( !-f $xml_file );

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );
    eval { $xml_doc->parse_file($xml_file); };
    if ($@) {
        croak(
            maketext(
                "FATAL ERROR 9: opening file [_1]:\n\t[_2]", $xml_file,
                $@
            )
        );
    }

    # BUGBUG can't translate overridden labels :(
    unless ($web_product_label) {
        $web_product_label = eval {
            $xml_doc->root()->look_down( "_tag", "productname" )->as_text();
        };
        if ($@) {

            #            croak maketext("productname not found in Info file");
        }
        else {
            $web_product_label =~ s/\s/_/g;
        }
    }

    unless ($web_name_label) {
        $web_name_label = eval {
            $xml_doc->root()->look_down( "_tag", "title" )->as_text();
        };
        if ($@) {

            #           croak maketext("title not found in Info file");
        }
        else {
            $web_name_label =~ s/\s/_/g;
        }
    }

    #    }

    $web_product_label =~ s/"/\\"/g if ($web_product_label);
    $web_name_label =~ s/"/\\"/g    if ($web_name_label);
    $web_version_label =~ s/"/\\"/g if ($web_version_label);

    if ( $web_name_label && $web_name_label eq $docname ) {
        $web_name_label = undef;
    }

    if ( $web_version_label && $web_version_label eq $version ) {
        $web_version_label = undef;
    }

    if ( $web_product_label && $web_product_label eq $product ) {
        $web_product_label = undef;
    }

    return ( $web_product_label, $web_version_label, $web_name_label );
}

=head2 change_log

Generate an RPM style change log from $xml_lang/Revision_History.xml

=cut

sub change_log {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak("lang is a mandatory argument");

    if ( %{$args} ) {
        croak "unknown args: " . join( ", ", keys %{$args} );
    }

    my $log     = "";
    my $tmp_dir = $self->{publican}->param('tmp_dir');

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );

    my $rev_file = "Revision_History.xml";
    $rev_file = $self->{publican}->param('rev_file')
        if ( $self->{publican}->param('rev_file') );

    my $path = "$tmp_dir/$lang/xml/$rev_file";
    $path = "$lang/$rev_file"
        if ( $self->{publican}->param('web_home')
        || $self->{publican}->param('web_type') );

    eval { $xml_doc->parse_file("$path"); };
    if ($@) {
        croak( maketext( "FATAL ERROR 10: [_1]", $@ ) );
    }

    $xml_doc->root()->look_down( "_tag", "revision" )
        || croak(
        maketext(
            "Missing mandatory field '[_1]' in revision history.", 'revision'
        )
        );

    foreach my $revision ( $xml_doc->root()->look_down( "_tag", "revision" ) )
    {

        my $node = $revision->look_down( '_tag', 'date' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.", 'date'
            )
            );
        my $in_date = $node->as_trimmed_text();
        my $dt      = DateTime::Format::DateParse->parse_datetime($in_date)
            || croak(
            maketext( "Invalid date: '[_1]' in revision history.", $in_date )
            );
        my $date = $dt->strftime("%a %b %e %Y");

        $node = $revision->look_down( '_tag', 'firstname' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.",
                'firstname'
            )
            );
        my $firstname = $node->as_trimmed_text();

        $node = $revision->look_down( '_tag', 'surname' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.",
                'surname'
            )
            );
        my $surname = $node->as_trimmed_text();

        $node = $revision->look_down( '_tag', 'email' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.",
                'email'
            )
            );
        my $email = $node->as_trimmed_text();

        $node = $revision->look_down( '_tag', 'revnumber' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision history.",
                'revnumber'
            )
            );

        my $revnumber = $node->as_trimmed_text();

        unless ( $revnumber =~ m/\d[0-9.]*-\d[0-9.]*/ ) {
            croak(
                maketext(
                    "ERROR: revnumber '[_1]' does not match required format [_2]. e.g. '1-1'.\n",
                    $revnumber,
                    q|\d[0-9.]*-\d[0-9.]*|
                )
            );
        }

        $log .= sprintf( "* %s %s %s <%s> - %s\n",
            $date, $firstname, $surname, $email, $revnumber );

        $revision->look_down( '_tag', 'member' )
            || croak(
            maketext(
                "Missing mandatory field '[_1]' in revision.", 'member'
            )
            );
        foreach my $member ( $revision->look_down( '_tag', 'member' ) ) {
            $log .= sprintf( "- %s \n", $member->as_trimmed_text() );
        }

        $log .= "\n";
    }

    return ($log);
}

=head2 get_abstract

Return the abstract for the supplied language with all white space truncated.

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub get_abstract {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );
    my $format = delete( $args->{format} ) || 'text';

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $info_file
        = "$tmp_dir/$lang/xml/"
        . $self->{publican}->param('type')
        . '_Info.xml';
    $info_file = "$tmp_dir/$lang/xml/" . $self->{publican}->param('info_file')
        if ( $self->{publican}->param('info_file') );

    croak( maketext("abstract can not be calculated before building.") )
        unless ( -f $info_file );

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );
    eval { $xml_doc->parse_file($info_file); };
    if ($@) {
        croak( maketext( "FATAL ERROR 11: [_1]", $@ ) );
    }

    my $abs = $xml_doc->look_down( '_tag', 'abstract' )
        || croak(
        maketext(
            "Can not locate '[_1]' tag in file '[_2]'", 'abstract',
            $info_file
        )
        );

    my $abstract = '';

    if ( $format eq 'html' ) {
        $abstract = $abs->as_HTML();
    }
    elsif ( $format eq 'xml' ) {
        $abstract = $abs->as_XML();
    }
    else {
        $abstract = $abs->as_text();
    }

    # tidy up white space
    $abstract =~ s/^[ \t]*//gm;
    $abstract =~ s/^\n\n+//;
    $abstract =~ s/\n\n+$//;
    $abstract =~ s/\n\n\n/\n\n/g;
    $abstract =~ s/[ \t][ \t]+/ /gm;

    # RPM doesn't like non-breaking-space
    $abstract =~ s/\x{A0}/ /gm;
    return ($abstract);
}

=head2 get_subtitle

Return the subtitle for the supplied language with white space truncated.

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub get_subtitle {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );

    my $use_source = delete( $args->{use_source} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }
    my $info_file;

    if ($use_source) {
        $info_file
            = "$lang/" . $self->{publican}->param('type') . '_Info.xml';

        $info_file = "$lang/" . $self->{publican}->param('info_file')
            if ( $self->{publican}->param('info_file') );

    }
    else {
        my $tmp_dir = $self->{publican}->param('tmp_dir');
        $info_file
            = "$tmp_dir/$lang/xml/"
            . $self->{publican}->param('type')
            . '_Info.xml';
        $info_file
            = "$tmp_dir/$lang/xml/" . $self->{publican}->param('info_file')
            if ( $self->{publican}->param('info_file') );
    }

    croak( maketext( "Info file missing: [_1]", $info_file ) )
        unless ( -f $info_file );

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );
    eval { $xml_doc->parse_file($info_file); };
    if ($@) {
        croak( maketext( "FATAL ERROR 12: [_1]", $@ ) );
    }

    my $st = $xml_doc->look_down( '_tag', 'subtitle' )
        || croak(
        maketext(
            "Can not locate '[_1]' tag in file '[_2]'", 'subtitle',
            $info_file
        )
        );

    my $subtitle = $st->as_text();

    # tidy up white space
    $subtitle =~ s/^\s*//gm;

    # RPM doesn't like non-breaking-space
    $subtitle =~ s/\x{A0}/ /gm;
    $subtitle =~ s/\s+/ /;
    $subtitle =~ s/\s*$//gm;

    return ($subtitle);
}

=head2 get_author_list

Return the author list for the supplied language.

=cut

sub get_author_list {
    my ( $self, $args ) = @_;
    logger( "get_author_list should be sub-classed!" . "\n", RED );

    return;
}

=head2 get_contributors

Return the contributor hash for the supplied language.

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub get_contributors {
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

    my %contributors;

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $file    = "$tmp_dir/$lang/xml/Author_Group.xml";

    croak(
        maketext("contributor list can not be calculated before building.") )
        unless ( -f $file );

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );
    eval { $xml_doc->parse_file($file); };
    if ($@) {
        croak( maketext( "FATAL ERROR 13: [_1]", $@ ) );
    }

    foreach my $node (
        $xml_doc->root()->look_down(
            "_tag", qr/^(?:author|editor|othercredit|corpauthor|orgname)$/
        )
        )
    {
        my %person;
        if ( $node->attr('class') ) {
            my $role = $node->attr('class');
            if ( $role eq "copyeditor" ) {
                $person{role} = maketext("Copy Editor");
            }
            elsif ( $role eq "graphicdesigner" ) {
                $person{role} = maketext("Graphic Designer");
            }
            elsif ( $role eq "productioneditor" ) {
                $person{role} = maketext("Production Editor");
            }
            elsif ( $role eq "technicaleditor" ) {
                $person{role} = maketext("Technical Editor");
            }
            elsif ( $role eq "translator" ) {
                $person{role} = maketext("Translator");
            }
        }

        my @fields
            = qw/firstname surname email contrib orgname orgdiv corpauthor/;
        foreach my $field (@fields) {
            my $field_node = $node->look_down( "_tag", $field );
            if ($field_node) {
                $person{$field} = $field_node->as_text();
            }
        }

        push( @{ $contributors{ $node->tag() } }, \%person );
    }

    return ( \%contributors );
}

=head2 get_keywords

Return the contributor hash for the supplied language.

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub get_keywords {
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

    my @keywords;

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $info    = ( $self->{publican}->param('info_file')
            || $self->{publican}->param('type') . '_Info.xml' );
    my $file = "$tmp_dir/$lang/xml/$info";

    croak( maketext("keyword list can not be calculated before building.") )
        unless ( -f $file );

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );
    eval { $xml_doc->parse_file($file); };
    if ($@) {
        croak( maketext( "FATAL ERROR 14: [_1]", $@ ) );
    }

    foreach my $node ( $xml_doc->root()->look_down( "_tag", 'keyword' ) ) {
        push( @keywords, $node->as_text() );
    }

    return (@keywords);
}

=head2 get_legalnotice

Return the legal notice for the supplied language.

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub get_legalnotice {
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

    my @keywords;

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $file    = "$tmp_dir/$lang/xml/Common_Content/Legal_Notice.xml";

    croak( maketext("Legal notice can not be calculated before building.") )
        unless ( -f $file );

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );
    eval { $xml_doc->parse_file($file); };
    if ($@) {
        croak( maketext( "FATAL ERROR 15: [_1]", $@ ) );
    }

    my $ln = $xml_doc->root()->look_down( "_tag", 'legalnotice' );
    $ln->detach();
    my $html = $self->to_html( { xml_doc => $ln } );
    return ($html);
}

=head2 get_draft

Is the book in draft mode?.

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub get_draft {
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

    my $main_file = $self->{publican}->param('mainfile');
    my $draft     = 0;

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $file    = "$tmp_dir/$lang/xml/$main_file.xml";

    croak(
        maketext(
            "Main XML file ([_1]) can not be calculated before building.",
            "$main_file.xml"
        )
    ) unless ( -f $file );

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => "0", 'ErrorContext' => "2" } );
    eval { $xml_doc->parse_file($file); };
    if ($@) {
        croak( maketext( "FATAL ERROR 16: [_1]", $@ ) );
    }

    $draft = ( $xml_doc->root()->attr('status')
            && $xml_doc->root()->attr('status') eq 'draft' );
    return ($draft);
}

=head2 to_html

Convert an XML::Element node containing DocBook XML directly to HTML text.

=cut

sub to_html {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("xml_doc is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }
    my $text;

    my %titles;

    my %MAP_OUT = (
## structural
        article => { tag => 'section' },
        book    => { tag => 'section' },
        part    => { tag => 'section' },
        set     => { tag => 'section' },
##sections
        appendix   => { tag => 'section' },
        chapter    => { tag => 'section' },
        refsect1   => { tag => 'section' },
        refsect2   => { tag => 'section' },
        refsect3   => { tag => 'section' },
        refsection => { tag => 'section' },
        sect1      => { tag => 'section' },
        sect2      => { tag => 'section' },
        sect3      => { tag => 'section' },
        sect4      => { tag => 'section' },
        sect5      => { tag => 'section' },
        section    => { tag => 'section' },
        toc        => { tag => 'section' },

## blocks
        abstract         => { tag => 'div' },
        acknowledgements => { tag => 'div' },
        address          => { tag => 'address' },
        annotation       => { tag => 'div' },
        answer           => { tag => 'div' },
        bibliodiv        => { tag => 'div' },
        biblioentry      => { tag => 'div' },
        bibliography     => { tag => 'div' },
        bibliolist       => { tag => 'div' },
        bibliomixed      => { tag => 'div' },
        bibliomset       => { tag => 'div' },
        biblioset        => { tag => 'div' },
        blockquote       => { tag => 'blockquote' },
        bridgehead       => { tag => 'div' },
        callout          => { tag => 'div' },
        calloutlist      => { tag => 'div' },
        caption          => { tag => 'div' },
        caution          => { tag => 'div' },
        colophon         => { tag => 'div' },
        constraintdef    => { tag => 'div' },
        corpauthor       => { tag => 'div' },
        cover            => { tag => 'div' },
        epigraph         => { tag => 'div' },
        equation         => { tag => 'div' },
        example          => { tag => 'div' },
        figure           => { tag => 'figure' },
        formalpara       => { tag => 'div' },
        glossary         => { tag => 'div' },
        glossdef         => { tag => 'div' },
        glossdiv         => { tag => 'div' },
        glossentry       => { tag => 'div' },
        glosslist        => { tag => 'div' },
        glosssee         => { tag => 'div' },
        glossseealso     => { tag => 'div' },
        imageobjectco    => { tag => 'div' },
        important        => { tag => 'section' },
        index            => { tag => 'div' },
        indexdiv         => { tag => 'div' },
        indexentry       => { tag => 'div' },
        informalequation => { tag => 'div' },
        informalexample  => { tag => 'div' },
        informalfigure   => { tag => 'div' },
        informaltable    => { tag => 'div' },
        itemizedlist     => { tag => 'ul' },
        legalnotice      => { tag => 'div' },
        listitem => { tags => { default => 'li', varlistentry => 'dd' } },
        literallayout     => { tag => 'div' },
        mediaobject       => { tag => 'div' },
        member            => { tag => 'li' },
        msg               => { tag => 'div' },
        msgentry          => { tag => 'div' },
        msgexplan         => { tag => 'div' },
        msgmain           => { tag => 'div' },
        msgset            => { tag => 'div' },
        note              => { tag => 'section' },
        orderedlist       => { tag => 'ol' },
        para              => { tag => 'div' },
        partintro         => { tag => 'div' },
        personblurb       => { tag => 'div' },
        preface           => { tag => 'section' },
        primaryie         => { tag => 'div' },
        printhistory      => { tag => 'div' },
        procedure         => { tag => 'ol' },
        productionset     => { tag => 'div' },
        programlisting    => { tag => 'pre' },
        programlistingco  => { tag => 'div' },
        qandadiv          => { tag => 'div' },
        qandaentry        => { tag => 'li' },
        qandaset          => { tag => 'ol' },
        refentry          => { tag => 'div' },
        refentrytitle     => { tag => 'div' },
        reference         => { tag => 'div' },
        refnamediv        => { tag => 'div' },
        refsynopsisdiv    => { tag => 'div' },
        revhistory        => { tag => 'div' },
        revision          => { tag => 'div' },
        screen            => { tag => 'pre' },
        screenco          => { tag => 'div' },
        screenshot        => { tag => 'div' },
        secondaryie       => { tag => 'div' },
        seealsoie         => { tag => 'div' },
        seeie             => { tag => 'div' },
        setindex          => { tag => 'div' },
        sidebar           => { tag => 'aside' },
        simpara           => { tag => 'p' },
        simplelist        => { tag => 'ul' },
        simplemsgentry    => { tag => 'div' },
        simplesect        => { tag => 'div' },
        step              => { tag => 'li' },
        stepalternatives  => { tag => 'li' },
        substeps          => { tag => 'ol' },
        subtitle          => { tag => 'h2' },
        synopfragment     => { tag => 'div' },
        synopfragmentref  => { tag => 'div' },
        task              => { tag => 'div' },
        taskprerequisites => { tag => 'div' },
        taskrelated       => { tag => 'div' },
        tasksummary       => { tag => 'div' },
        term              => { tag => 'dt' },
        tertiaryie        => { tag => 'div' },
        tip               => { tag => 'section' },
        title             => { tag => 'h1' },
        tocdiv            => { tag => 'div' },
        tocentry          => { tag => 'div' },
        variablelist      => { tag => 'dl' },
        varlistentry      => { tag => 'RWC' },
        warning           => { tag => 'section' },

## inline
        abbrev            => { tag => 'abbr' },
        accel             => { tag => 'span' },
        acronym           => { tag => 'span' },
        anchor            => { tag => 'span' },
        application       => { tag => 'span' },
        artpagenums       => { tag => 'span' },
        authorinitials    => { tag => 'span' },
        bibliocoverage    => { tag => 'span' },
        biblioid          => { tag => 'span' },
        bibliomisc        => { tag => 'span' },
        biblioref         => { tag => 'span' },
        bibliorelation    => { tag => 'span' },
        bibliosource      => { tag => 'span' },
        citation          => { tag => 'span' },
        citebiblioid      => { tag => 'span' },
        citerefentry      => { tag => 'span' },
        citetitle         => { tag => 'span' },
        city              => { tag => 'span' },
        classname         => { tag => 'span' },
        co                => { tag => 'span' },
        code              => { tag => 'span' },
        command           => { tag => 'span' },
        computeroutput    => { tag => 'samp' },
        constant          => { tag => 'span' },
        coref             => { tag => 'span' },
        country           => { tag => 'span' },
        database          => { tag => 'span' },
        date              => { tag => 'span' },
        email             => { tag => 'a' },
        emphasis          => { tag => 'span' },
        envar             => { tag => 'span' },
        errorcode         => { tag => 'span' },
        errorname         => { tag => 'span' },
        errortext         => { tag => 'span' },
        errortype         => { tag => 'span' },
        exceptionname     => { tag => 'span' },
        fax               => { tag => 'span' },
        filename          => { tag => 'span' },
        firstname         => { tag => 'span' },
        firstterm         => { tag => 'span' },
        foreignphrase     => { tag => 'span' },
        funcdef           => { tag => 'span' },
        funcparams        => { tag => 'span' },
        function          => { tag => 'span' },
        glossterm         => { tag => 'span' },
        group             => { tag => 'span' },
        guibutton         => { tag => 'span' },
        guiicon           => { tag => 'span' },
        guilabel          => { tag => 'span' },
        guimenu           => { tag => 'span' },
        guimenuitem       => { tag => 'span' },
        guisubmenu        => { tag => 'span' },
        hardware          => { tag => 'span' },
        holder            => { tag => 'span' },
        honorific         => { tag => 'span' },
        initializer       => { tag => 'span' },
        inlineequation    => { tag => 'span' },
        inlinemediaobject => { tag => 'div' },
        interfacename     => { tag => 'span' },
        keycap            => { tag => 'span' },
        keycode           => { tag => 'span' },
        keycombo          => { tag => 'span' },
        keysym            => { tag => 'span' },
        lhs               => { tag => 'span' },
        lineage           => { tag => 'span' },
        lineannotation    => { tag => 'span' },
        link              => { tag => 'span' },
        literal           => { tag => 'span' },
        manvolnum         => { tag => 'span' },
        markup            => { tag => 'span' },
        mathphrase        => { tag => 'span' },
        menuchoice        => { tag => 'span' },
        methodname        => { tag => 'span' },
        methodparam       => { tag => 'span' },
        modifier          => { tag => 'span' },
        mousebutton       => { tag => 'span' },
        nonterminal       => { tag => 'span' },
        olink             => { tag => 'span' },
        ooclass           => { tag => 'span' },
        ooexception       => { tag => 'span' },
        oointerface       => { tag => 'span' },
        option            => { tag => 'span' },
        optional          => { tag => 'span' },
        orgdiv            => { tag => 'span' },
        orgname           => { tag => 'span' },
        otheraddr         => { tag => 'span' },
        othername         => { tag => 'span' },
        package           => { tag => 'span' },
        pagenums          => { tag => 'span' },
        paramdef          => { tag => 'span' },
        parameter         => { tag => 'span' },
        phone             => { tag => 'span' },
        phrase            => { tag => 'span' },
        pob               => { tag => 'span' },
        postcode          => { tag => 'span' },
        productname       => { tag => 'span' },
        productnumber     => { tag => 'span' },
        prompt            => { tag => 'span' },
        property          => { tag => 'span' },
        pubdate           => { tag => 'span' },
        quote             => { tag => 'span' },
        refpurpose        => { tag => 'span' },
        replaceable       => { tag => 'span' },
        returnvalue       => { tag => 'span' },
        revnumber         => { tag => 'span' },
        rhs               => { tag => 'span' },
        sbr               => { tag => 'span' },
        seriesvolnums     => { tag => 'span' },
        shortcut          => { tag => 'span' },
        state             => { tag => 'span' },
        street            => { tag => 'span' },
        subscript         => { tag => 'span' },
        superscript       => { tag => 'span' },
        surname           => { tag => 'span' },
        symbol            => { tag => 'span' },
        systemitem        => { tag => 'span' },
        tag               => { tag => 'span' },
        termdef           => { tag => 'span' },
        varname           => { tag => 'span' },
        void              => { tag => 'span' },
        volumenum         => { tag => 'span' },
        wordasword        => { tag => 'span' },
        xref              => { tag => 'a', attrs => { linkend => 'href' } },
        year              => { tag => 'span' },

        # © ®
## inline or block
        affiliation    => { tag => 'div' },
        alt            => { tag => 'div' },
        arg            => { tag => 'div' },
        attribution    => { tag => 'div' },
        author         => { tag => 'div' },
        authorgroup    => { tag => 'div' },
        collab         => { tag => 'div' },
        imageobject    => { tag => 'div' },
        issuenum       => { tag => 'div' },
        jobtitle       => { tag => 'div' },
        msgaud         => { tag => 'div' },
        msginfo        => { tag => 'div' },
        msglevel       => { tag => 'div' },
        msgorig        => { tag => 'div' },
        msgrel         => { tag => 'div' },
        msgsub         => { tag => 'div' },
        msgtext        => { tag => 'div' },
        org            => { tag => 'div' },
        othercredit    => { tag => 'div' },
        person         => { tag => 'div' },
        personname     => { tag => 'div' },
        publisher      => { tag => 'div' },
        publishername  => { tag => 'div' },
        refclass       => { tag => 'div' },
        refdescriptor  => { tag => 'div' },
        refmiscinfo    => { tag => 'div' },
        refname        => { tag => 'div' },
        releaseinfo    => { tag => 'div' },
        remark         => { tag => 'div' },
        revdescription => { tag => 'div' },
        revremark      => { tag => 'div' },
        shortaffil     => { tag => 'div' },
        subject        => { tag => 'div' },
        subjectset     => { tag => 'div' },
        subjectterm    => { tag => 'div' },
        textdata       => { tag => 'div' },
        textobject     => { tag => 'div' },
        titleabbrev    => { tag => 'div' },
        token          => { tag => 'div' },
        trademark      => { tag => 'span', content => ' ®' },
        type           => { tag => 'div' },
        uri            => { tag => 'div' },
        userinput      => { tag => 'span' },
        varargs        => { tag => 'div' },
        videodata      => { tag => 'div' },
        videoobject    => { tag => 'div' },

## Complex
        classsynopsisinfo   => { tag  => 'div' },
        funcsynopsisinfo    => { tag  => 'div' },
        synopsis            => { tag  => 'div' },
        arc                 => { tag  => 'div' },
        area                => { tag  => 'div' },
        areaset             => { tag  => 'div' },
        areaspec            => { tag  => 'div' },
        audiodata           => { tag  => 'div' },
        audioobject         => { tag  => 'div' },
        classsynopsis       => { tag  => 'div' },
        cmdsynopsis         => { tag  => 'div' },
        col                 => { tag  => 'col' },
        colgroup            => { tag  => 'colgroup' },
        colspec             => { tag  => 'col' },
        confdates           => { tag  => 'div' },
        confgroup           => { tag  => 'div' },
        confnum             => { tag  => 'div' },
        confsponsor         => { tag  => 'div' },
        conftitle           => { tag  => 'div' },
        constraint          => { tag  => 'div' },
        constructorsynopsis => { tag  => 'div' },
        contractnum         => { tag  => 'div' },
        contractsponsor     => { tag  => 'div' },
        contrib             => { tag  => 'div' },
        copyright           => { tag  => 'span', content => ' ©' },
        dedication          => { tag  => 'div' },
        destructorsynopsis  => { tag  => 'div' },
        edition             => { tag  => 'div' },
        editor              => { tag  => 'div' },
        entry               => { tags => { default => 'td', thead => 'th' } },
        entrytbl            => { tag  => 'table' },
        extendedlink        => { tag  => 'div' },
        fieldsynopsis       => { tag  => 'div' },
        footnote            => { tag  => 'div' },
        footnoteref         => { tag  => 'div' },
        funcprototype       => { tag  => 'div' },
        funcsynopsis        => { tag  => 'div' },
        imagedata       => { tag => 'img', attrs => { fileref => 'src' } },
        indexterm       => { tag => 'div' },
        info            => { tag => 'div' },
        itermset        => { tag => 'div' },
        keyword         => { tag => 'div' },
        keywordset      => { tag => 'div' },
        label           => { tag => 'div' },
        locator         => { tag => 'div' },
        methodsynopsis  => { tag => 'div' },
        primary         => { tag => 'div' },
        production      => { tag => 'div' },
        productionrecap => { tag => 'div' },
        question        => { tag => 'div' },
        refmeta         => { tag => 'div' },
        row             => { tag => 'tr' },
        secondary       => { tag => 'div' },
        see             => { tag => 'div' },
        seealso         => { tag => 'div' },
        seg             => { tag => 'div' },
        seglistitem     => { tag => 'div' },
        segmentedlist   => { tag => 'div' },
        segtitle        => { tag => 'div' },
        spanspec        => { tag => 'div' },
        table           => { tag => 'table' },
        tbody           => { tag => 'tbody' },
        td              => { tag => 'td' },
        tertiary        => { tag => 'div' },
        tfoot           => { tag => 'tfoot' },
        tgroup          => { tag => 'colgroup' },
        th              => { tag => 'th' },
        thead           => { tag => 'thead' },
        tr              => { tag => 'tr' },
        mml             => { tag => 'div' },
        svg             => { tag => 'div' },

## db4 ... if we feel like it?
        bookinfo => { tag => 'div' },
        ulink    => { tag => 'a', attrs => { url => 'href' } },
        sgmltag  => { tag => 'span' },
    );

    my $empty_element_map = $xml_doc->_empty_element_map;
    $empty_element_map->{img} = 1;
    $empty_element_map->{col} = 1;

## Loop through all tags and change them
## 'tag' means there is only one choice
## 'tags' means the new class depends on parent or grand parent
    foreach my $node ( $xml_doc->root()->look_down( '_tag', qr/.*/ ) ) {
        my $tag = $node->tag();
        my $newtag;
        my $content = undef;
        if ( defined( $MAP_OUT{$tag}->{'tags'} ) ) {
            my $par_tag   = $node->parent->tag();
            my $par_class = ( $node->parent->attr('class') || '' );
            my $gp_tag    = $node->parent->parent->tag();
            if ( defined( $MAP_OUT{$tag}->{'tags'}->{$par_tag} ) ) {
                $newtag = $MAP_OUT{$tag}->{'tags'}->{$par_tag};
            }
            elsif ( defined( $MAP_OUT{$tag}->{'tags'}->{$par_class} ) ) {
                $newtag = $MAP_OUT{$tag}->{'tags'}->{$par_class};
            }
            elsif ( defined( $MAP_OUT{$tag}->{'tags'}->{$gp_tag} ) ) {
                $newtag = $MAP_OUT{$tag}->{'tags'}->{$gp_tag};
            }
            else {
                $newtag = $MAP_OUT{$tag}->{'tags'}->{'default'};
            }
        }
        elsif ( defined( $MAP_OUT{$tag}->{'tag'} ) ) {
            $newtag = $MAP_OUT{$tag}->{'tag'};
        }
        else {
            logger( maketext( "Unknow tag: [_1]", $tag ) . "\n", RED );
            next;
        }

        $node->tag($newtag);
        my $class = $tag;

        # status becomes class
        if ( $node->attr('status') ) {
            $class .= " " . $node->attr('status');
            $node->attr( 'status', undef );
        }

        # role becomes class
        if ( $node->attr('role') ) {
            $class .= " " . $node->attr('role');
            $node->attr( 'role', undef );
        }

        # extra admonition class for styling
        $class .= ' admonition'
            if ( $tag =~ /(?:note|warning|tip|important|caution)/ );

        $node->attr( 'class', $class ) unless ( $node->attr('class') );

    # get rid of some unused attributes
    # BUGBUG some of these may need to be acted on
    # BUGBUG some of these are used for profiling and _do_ need to be acted on
        $node->attr( 'conformance', undef );
        $node->attr( 'format',      undef );
        $node->attr( 'remap',       undef );
        $node->attr( 'scheme',      undef );
        $node->attr( 'spacing',     undef );
        $node->attr( 'frame',       undef );
        $node->attr( 'xml:base',    undef );
        $node->attr( 'scalefit',    undef );
        $node->attr( 'colsep',      undef );
        $node->attr( 'rowsep',      undef );
        $node->attr( 'align',       undef );
        $node->attr( 'colname',     undef );
        $node->attr( 'cols',        undef );
        $node->attr( 'colnum',      undef );
        $node->attr( 'colwidth',    undef );

        # Some attributes map directly
        if ( defined( $MAP_OUT{$tag}->{'attrs'} ) ) {
            foreach my $attr ( keys( %{ $MAP_OUT{$tag}->{'attrs'} } ) ) {
                if ( $node->attr($attr) ) {
                    $node->attr( $MAP_OUT{$tag}->{'attrs'}->{$attr},
                        $node->attr($attr) );
                    $node->attr( $attr, undef );
                }
            }
        }

        if ( $tag eq 'email' ) {
            $node->attr( 'href', 'mailto:' . $node->as_text() );
        }

        if ( $MAP_OUT{$tag}->{content} ) {
            if (   ( $tag eq 'trademark' )
                && ( $node->attr('class') eq 'copyright' ) )
            {
                $node->push_content( $MAP_OUT{copyright}->{content} );
            }
            else {
                $node->push_content( $MAP_OUT{$tag}->{content} );
            }
        }

    }

    # Some tags are supurflous and can be removed
    foreach my $node ( $xml_doc->root()->look_down( '_tag', 'RWC' ) ) {
        $node->replace_with_content();
    }

    # table tweaks
    foreach my $node ( $xml_doc->root()->look_down( '_tag', 'table' ) ) {

        # move thead and tbody out of tgroup
        if ( my $colgroup = $node->look_down( '_tag', 'colgroup' ) ) {
            if ( my $tbody = $colgroup->look_down( '_tag', 'tbody' ) ) {
                $colgroup->postinsert($tbody);
            }
            if ( my $thead = $colgroup->look_down( '_tag', 'thead' ) ) {
                $colgroup->postinsert($thead);
            }
        }
    }

##BUGBUG image alt text if it exists
    foreach my $node ( $xml_doc->root()->look_down( '_tag', 'img' ) ) {
        $node->attr( 'alt', 'FIXME' );
    }

    # remove p tag in revhistory
    foreach
        my $node ( $xml_doc->root()->look_down( 'class', qr/revhistory/ ) )
    {
        if ( $node->parent && $node->parent->tag() eq 'p' ) {
            $node->parent->replace_with_content();
        }
    }

    my @headings = ( 'div', { class => 'toc' } );

##$self->headings({xml_doc => $xml_doc, headings => \@headings});
    $self->links( { xml_doc => $xml_doc } );
##$self->footnotes({xml_doc => $xml_doc});
    $self->highlight2( { xml_doc => $xml_doc } );
    $self->number_lines( { xml_doc => $xml_doc } );
##$self->toc({xml_doc => $xml_doc, headings => \@headings});

## BUGBUG no header/footer yet
    #print <<EOL;
    #<!DOCTYPE HTML>
    #<html>
    #<head>
    #	<title>TEST</title>
    #	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    #	<link rel="stylesheet" href="test.css" type="text/css">
    #</head>
    #<body>
    #EOL
    $text = $xml_doc->root()->as_XML();

    #print $xml_doc->root()->as_XML(), "\n</body>\n</html>";

    return ($text);
}

=head2 headings

Create an array of all headings in DocBook XML.

=cut

sub headings {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("xml_doc is a mandatory argument") );
    my $headings = delete( $args->{headings} )
        || croak( maketext("headings is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    # move some titles outside the thing they mark.
    # Add label texts
    my $chapter    = 0;
    my @section    = ( 0, 0, 0, 0, 0 );
    my $sect_depth = 0;
    my $table      = 0;
    my $proc       = 0;
    my $example    = 0;
    my $appendix   = 0;
    my $number;
    my $ina = undef;

    foreach my $node ( $xml_doc->root()->look_down( '_tag', 'h1' ) ) {
        my $pclass = $node->parent->attr('class');

        if ( $node->parent && $node->parent->tag() =~ /(?:table|ol)/ ) {

            # move this after list
            $node->parent->preinsert($node);
        }

        if ( $pclass =~ m/(^chapter| chapter)/ ) {
            $ina = 'chapter';
            $node->tag('h1');
            $chapter++;
            @section = ( 0, 0, 0, 0, 0 );
            $number  = $chapter;
            $table   = 0;
            $proc    = 0;
            $example = 0;
            my $text = "$number. " . $node->as_text();
            $node->delete_content();
            $node->push_content( ucfirst($pclass) . " $text" );
            push(
                @{$headings},
                [   'div',
                    [ 'a', { href => '#' . $node->parent->id() }, $text ]
                ]
            );
        }
        elsif ( $pclass =~ m/(^appendix| appendix)/ ) {
            $ina = 'appendix';
            $node->tag('h1');
            $appendix++;
            @section = ( 0, 0, 0, 0, 0 );
            $number  = chr( 64 + $appendix );
            $table   = 0;
            $proc    = 0;
            $example = 0;

            my $text = "$number. " . $node->as_text();
            $node->delete_content();
            $node->push_content("Appendix $text");
            push(
                @{$headings},
                [   'div',
                    [ 'a', { href => '#' . $node->parent->id() }, $text ]
                ]
            );
        }
        elsif ( $pclass =~ m/(^preface| preface)/ ) {
            $ina = 'preface';
            my $text = $node->as_text();
            push(
                @{$headings},
                [   'div',
                    [ 'a', { href => '#' . $node->parent->id() }, $text ]
                ]
            );
        }
        elsif ( $pclass =~ m/(^section| section)/ ) {
            my $cont = $chapter;

            $cont = chr( 64 + $appendix ) if ( $ina eq 'appendix' );

            my @ans = $node->look_up( 'class', qr/^section| section/ );
            my $depth = $#ans;
            $section[$depth]++;
            $sect_depth = $depth;
            for ( my $i = $depth + 1; $i <= $#section; $i++ ) {
                $section[$i] = 0;
            }
            if ( $ina eq 'preface' ) {
                $number
                    = join( '.', map { Roman($_) } @section[ 0 .. $depth ] );
            }
            else {
                $number = "$cont." . join( '.', @section[ 0 .. $depth ] );
            }

            $node->tag( 'h' . ( $depth + 2 ) );
            my $text = "$number. " . $node->as_text();
            if ( $ina ne 'preface' ) {
                $node->delete_content();
                $node->push_content( ucfirst($pclass) . " $text" );
            }
            else {
                my $txt
                    = '<tmp>'
                    . ucfirst($pclass)
                    . " <span class='roman'>$number.</span> "
                    . $node->as_text()
                    . '</tmp>';
                $node->delete_content();
                $node->push_content(
                    XML::TreeBuilder->new()->parse($txt)->detach_content() );
            }
            push(
                @{$headings},
                [   'div',
                    { class => $node->tag() },
                    [ 'a', { href => '#' . $node->parent->id() }, $text ]
                ]
            );

        }
        elsif ( $pclass =~ m/(^table| table)/ ) {
            my $text = "Table $chapter.$table. " . $node->as_text();
            $node->delete_content();
            $node->push_content($text);
            $node->attr( 'class', $node->attr('class') . ' table formal' );
            $table++;
        }
        elsif ( $pclass =~ m/(^procedure| procedure)/ ) {
            my $text = "Procedure $chapter.$proc. " . $node->as_text();
            $node->delete_content();
            $node->push_content($text);
            $node->attr( 'class',
                $node->attr('class') . ' procedure formal' );
            $proc++;
        }
        elsif ( $pclass =~ m/(^example| example)/ ) {
            my $text = "Example $chapter.$example. " . $node->as_text();
            $node->delete_content();
            $node->push_content($text);
            $node->attr( 'class', $node->attr('class') . ' formal example' );
            $example++;
        }
    }

    return;
}

=head2 links 

Convert DocBook links in to HTML5 anchors.

=cut

sub links {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("xml_doc is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    # BUGBUG xref/link for internal links needs proper text
    foreach my $node ( $xml_doc->root()->look_down( '_tag', 'a' ) ) {
        if ( $node->is_empty() ) {
            my $text = $node->attr('href');

            if ( $node->attr('class') =~ /xref/ ) {
                my $title;
                my $target = $xml_doc->root()
                    ->look_down( 'id', $node->attr('href') );
                if (   $target
                    && ( $title = $target->look_down( 'class', qr/title/ ) )
                    && $title->parent->same_as($target) )
                {
                    $text = $title->as_text();
                }
                else {
                    print STDERR "No title for " . $node->attr('href') . "\n";
                }
                $node->attr( 'href', '#' . $node->attr('href') );
            }
            $node->push_content($text);
        }
    }

    return;
}

=head2 footnotes

Convert DocBook footnotes in to HTML5 footnotes.

=cut

sub footnotes {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("xml_doc is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }
    my $footers = 0;

    # BUGBUG xref/link for internal links needs proper text
    foreach my $node ( $xml_doc->root()->look_down( 'class', qr/footnote/ ) )
    {
        $footers++;

        my @content = $node->detach_content();
        my $footer  = XML::TreeBuilder->new(
            { 'NoExpand' => "1", 'ErrorContext' => "2" } );
        $footer->parse(
            qq|<div class="footnote"><a id="footer.$footers" href="#ref.$footers">$footers</a></div>|
        );
        $footer->push_content(@content);

        my $block = $node->look_up( 'class', qr/section|chapter|appendix/ );
        $block->push_content($footer);

        my $anchor = XML::TreeBuilder->new(
            { 'NoExpand' => "1", 'ErrorContext' => "2" } );
        $anchor->parse(
            qq|<tmp><sup>[<a id="ref.$footers" href="#footer.$footers">$footers</a>]</sup></tmp>|
        );
        $node->replace_with( $anchor->detach_content() )->delete();
    }

    return;
}

=head2 highlight2

Highlight code blocks in HTML5.

TODO replace with highlight.js??

=cut

sub highlight2 {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("xml_doc is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }
    my $hl = new Syntax::Highlight::Engine::Kate(
        substitutions => {
            "<" => "&lt;",
            ">" => "&gt;",
            "&" => "&amp;",
        },
        format_table => {
            Alert        => [ "<span class='Alert'>",        "</span>" ],
            BaseN        => [ "<span class='BaseN'>",        "</span>" ],
            BString      => [ "<span class='BString'>",      "</span>" ],
            Char         => [ "<span class='Char'>",         "</span>" ],
            Comment      => [ "<span class='Comment'>",      "</span>" ],
            DataType     => [ "<span class='DataType'>",     "</span>" ],
            DecVal       => [ "<span class='DecVal'>",       "</span>" ],
            Error        => [ "<span class='Error'>",        "</span>" ],
            Float        => [ "<span class='Float'>",        "</span>" ],
            Function     => [ "<span class='Function'>",     "</span>" ],
            IString      => [ "<span class='IString'>",      "</span>" ],
            Keyword      => [ "<span class='Keyword'>",      "</span>" ],
            Normal       => [ "",                            "" ],
            Operator     => [ "<span class='Operator'>",     "</span>" ],
            Others       => [ "<span class='Others'>",       "</span>" ],
            RegionMarker => [ "<span class='RegionMarker'>", "</span>" ],
            Reserved     => [ "<span class='Reserved'>",     "</span>" ],
            String       => [ "<span class='String'>",       "</span>" ],
            Variable     => [ "<span class='Variable'>",     "</span>" ],
            Warning      => [ "<span class='Warning'>",      "</span>" ],
        },
    );

    foreach my $node ( $xml_doc->root()
        ->look_down( 'class', qr/programlisting/, 'language', qr/.+/ ) )
    {
        my $language = $node->attr('language');
        my $lang_module = $hl->languagePlug( $language, 1 ) || croak(
            "\n\t"
                . maketext(
                "'[_1]' is not a valid language for highlighting. Language names are case sensitive.",
                $language
                )
                . "\n"
        );

        my $modname = "Syntax::Highlight::Engine::Kate::$lang_module";
        my $plug;
        ## This has to be a string to stop use being run in BEGIN
        ## no critic
        eval "use $modname; \$plug = new $modname(engine => \$hl);";
		## use critic
		
        if ( defined($plug) ) {
            $language = $plug->language();
        }
        else {
            croak(
                maketext(
                    "Cannot create plugin for language '[_1]': [_2]",
                    $language, $@
                )
            );
        }

        $hl->language($language);

        my $text = $hl->highlightText( $node->as_text() );
        $node->delete_content();
        my $txt = XML::TreeBuilder->new(
            { 'NoExpand' => "1", 'ErrorContext' => "2" } );
        $txt->parse(qq|<pre class="programlisting">$text</pre>|);
        $node->push_content( $txt->root()->detach_content() );
        $node->attr( 'language', undef );
    }

    return;
}

=head2 number_lines

Number lines in HTML5 code blocks.

=cut

sub number_lines {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("xml_doc is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }
    foreach my $node (
        $xml_doc->root()->look_down(
            'class', qr/programlisting/, 'linenumbering', 'numbered'
        )
        )
    {
        my $count     = ( $node->attr('startinglinenumber') || 1 );
        my $text      = $node->as_XML();
        my $num_lines = () = ( $text =~ /^/mg );
        my $format    = '%' . length("$num_lines") . 's:' . chr(160);
        $text =~ s/^/sprintf("$format",$count++)/egm;
        $text =~ s/^(\d*[^<]*)(<[^>]*>)/$2$1/;
        $node->delete_content();
        my $txt = XML::TreeBuilder->new(
            { 'NoExpand' => "1", 'ErrorContext' => "2" } );
        $txt->parse(qq|$text|);
        $node->push_content( $txt->root()->detach_content() );
    }

    return;
}

=head2 toc

Create an HTML5 TOC.

=cut

sub toc {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("xml_doc is a mandatory argument") );
    my $headings = delete( $args->{headings} )
        || croak( maketext("headings is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }
    my $toc = XML::Element->new_from_lol($headings);
    my $node = $xml_doc->root()->look_down( 'class', qr/info/ );

    $node->postinsert($toc);
    return;

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

