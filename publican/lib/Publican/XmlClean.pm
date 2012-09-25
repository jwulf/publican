package Publican::XmlClean;

use strict;
use warnings;
use 5.008;
use Carp;
use XML::TreeBuilder;
use Config::Simple '-strict';
use Publican;
use File::Path;
use Term::ANSIColor qw(:constants);
use Publican::Builder;
use File::Inplace;
use DBI;

## Testing collation
my $test_collate = 1;
if ($test_collate) {
    use Unicode::Collate;
}

use vars qw( $VERSION );

$VERSION = '0.2';

=head1 NAME

Publican::XmlClean - A module to reformat XML to Publican standards

=head1 VERSION

This document describes Publican::XmlClean version $VERSION

=head1 SYNOPSIS

    use Publican::XmlClean;

    my $cleaner = Publican::XmlClean->new( { clean_id => 1 } );

    foreach my $xml_file ( sort(@xml_files) ) {
        $cleaner->process_file( { file => $xml_file, out_file => $xml_file } );
    }

  
=head1 DESCRIPTION

Publican::XmlClean tidies XML formatting and filters structure based on input rules.

=head1 INTERFACE 

=cut

my %UPDATED_IDS;
my %UNIQUE_IDS;
my %MAX_CONFORMANCE;

my %MAP_OUT = (
    section    => { block => 1, newline_after => 1 },
    refsection => { block => 1, newline_after => 1, no_id => 1 },
    chapter       => { block         => 1 },
    preface       => { block         => 1 },
    bibliography  => { block         => 1 },
    bibliodiv     => { block         => 1 },
    biblioentry   => { block         => 1 },
    othercredit   => { block         => 1 },
    legalnotice   => { block         => 1 },
    address       => { block         => 1, verbatim => 1 },
    book          => { block         => 1 },
    article       => { block         => 1 },
    part          => { block         => 1 },
    partintro     => { block         => 1 },
    para          => { block         => 1 },
    formalpara    => { block         => 1 },
    simpara       => { block         => 1 },
    itemizedlist  => { block         => 1 },
    orderedlist   => { block         => 1 },
    variablelist  => { block         => 1 },
    seglistitem   => { block         => 1 },
    segtitle      => { newline_after => 1 },
    seg           => { newline_after => 1 },
    segmentedlist => { block         => 1 },
    simplelist    => { block         => 1 },
    qandaset      => { block         => 1 },
    qandaentry    => { block         => 1 },
    question      => { block         => 1 },
    answer        => { block         => 1 },
    member        => { newline_after => 1 },
    remark        => { newline_after => 1 },
    userinput => {},
    listitem  => { block => 1, keep_id => 1 },
    title         => { newline_after => 1 },
    refentrytitle => { newline_after => 1 },
    refpurpose    => { newline_after => 1 },
    refname       => { newline_after => 1 },
    refnamediv    => { block         => 1, id_node => 'refname' },
    manvolnum     => { newline_after => 1 },
    street           => {},
    city             => {},
    state            => {},
    postcode         => {},
    country          => {},
    phone            => {},
    fax              => {},
    pob              => {},
    subtitle         => { newline_after => 1 },
    screen           => { block => 1, verbatim => 1 },
    programlisting   => { block => 1, verbatim => 1 },
    programlistingco => { block => 1, newline_after => 1 },
    xref        => { force_empty => 1 },
    footnoteref => { force_empty => 1 },
    important   => { block       => 1, no_id => 1 },
    note        => { block       => 1, no_id => 1 },
    warning     => { block       => 1, no_id => 1 },
    figure      => { block       => 1 },
    mediaobject => { block       => 1 },
    imageobject => { block       => 1 },
    imagedata     => {},
    'xi:include'  => { newline_after => 1 },
    'xi:fallback' => { newline_after => 1 },

    #    glossary          => { block         => 1 },
    #    glossentry        => { block         => 1, id_node => 'glossterm' },
    #    glossdiv          => { block         => 1 },
    #    glossdef          => { block         => 1 },
    #    glossterm         => { newline_after => 1 },
    #    glosssee          => { newline_after => 1 },
    #    glossseealso      => { newline_after => 1 },
    table             => { block         => 1 },
    informaltable     => { block         => 1 },
    thead             => { block         => 1 },
    tgroup            => { block         => 1 },
    tbody             => { block         => 1 },
    tr                => { block         => 1 },
    td                => { block         => 1 },
    row               => { block         => 1 },
    entry             => { block         => 1 },
    refentry          => { block         => 1 },
    refmeta           => { block         => 1 },
    refentryinfo      => { block         => 1, no_id => 1 },
    reference         => { block         => 1 },
    indexterm         => { block         => 1, mixed_mode => 1 },
    primary           => { newline_after => 1, mixed_mode => 1 },
    secondary         => { newline_after => 1, mixed_mode => 1 },
    tertiary          => { newline_after => 1, mixed_mode => 1 },
    bookinfo          => { block         => 1 },
    articleinfo       => { block         => 1 },
    abstract          => { block         => 1 },
    inlinemediaobject => { block         => 1 },
    publisher         => { block         => 1 },
    copyright         => { block         => 1 },
    authorgroup       => { block         => 1 },
    author            => { block         => 1 },
    editor            => { block         => 1 },
    corpauthor        => { block         => 1 },
    revision          => { block         => 1 },
    revhistory        => { block         => 1 },
    revdescription    => { block         => 1 },
    publishername     => { block         => 1 },
    affiliation       => { block         => 1 },
    year              => { newline_after => 1 },
    holder            => { newline_after => 1 },
    revnumber         => { newline_after => 1 },
    date              => { newline_after => 1 },
    honorific         => { newline_after => 1 },
    firstname         => { newline_after => 1 },
    surname           => { newline_after => 1 },
    email             => { newline_after => 1, mixed_mode => 1 },
    isbn              => { newline_after => 1 },
    issuenum          => { newline_after => 1 },
    edition           => { newline_after => 1 },
    pubdate           => { newline_after => 1 },
    productname       => { mixed_mode    => 1, newline_after => 1 },
    productnumber     => { newline_after => 1 },
    pubsnumber        => { newline_after => 1 },
    contrib           => { newline_after => 1 },
    shortaffil        => { newline_after => 1 },
    jobtitle          => { newline_after => 1 },
    orgname           => { newline_after => 1 },
    orgdiv            => { newline_after => 1 },
    citetitle      => {},
    trademark      => {},
    ulink          => {},
    firstterm      => {},
    menuchoice     => {},
    acronym        => {},
    abbrev         => {},
    command        => {},
    filename       => {},
    'index'        => {},
    application    => {},
    'package'      => {},
    guimenu        => {},
    sgmltag        => {},
    guilabel       => {},
    guibutton      => {},
    emphasis       => {},
    phrase         => {},
    replaceable    => {},
    computeroutput => {},
    guimenuitem    => {},
    textobject     => { block => 1 },
    varlistentry   => { block => 1 },
    term           => { newline_after => 1 },
    colspec        => { newline_after => 1 },
    areaspec       => { block => 1 },
    areaset        => { block => 1, keep_id => 1 },
    area           => { newline_after => 1, keep_id => 1 },
    calloutlist  => { block => 1 },
    callout      => { block => 1 },
    procedure    => { block => 1, newline_after => 1 },
    appendix     => { block => 1 },
    appendixinfo => { block => 1 },
    cmdsynopsis  => { block => 1 },
    arg          => { block => 1 },
    group        => { block => 1 },
    accel         => {},
    blockquote    => { block => 1 },
    classname     => {},
    code          => {},
    colophon      => { block => 1 },
    envar         => {},
    example       => { block => 1 },
    footnote      => { keep_id => 1 },
    guisubmenu    => {},
    interface     => {},
    keycap        => {},
    keycombo      => {},
    literal       => {},
    literallayout => { block => 1, verbatim => 1 },
    option        => {},
    parameter     => {},
    prompt        => {},
    property      => {},
    see              => { newline_after => 1, },
    seealso          => { newline_after => 1, },
    step             => { block         => 1, keep_id => 1 },
    substeps         => { block         => 1 },
    stepalternatives => { block         => 1 },
    systemitem    => {},
    wordasword    => {},
    citerefentry  => {},
    manvolnum     => {},
    function      => {},
    uri           => {},
    mousebutton   => {},
    hardware      => {},
    type          => {},
    methodname    => {},
    exceptionname => {},
    varname       => {},
    interfacename => {},
    othername     => { newline_after => 1 },
    '~comment'    => {},
    foreignphrase => {},
    chapterinfo   => { block => 1 },
    keywordset    => { block => 1 },
    keyword       => { newline_after => 1 },
    subjectset    => { block => 1 },
    subject       => { block => 1 },
    subjectterm   => { newline_after => 1 },
    superscript   => {},
);

=head2 new

Create a new Publican::XmlClean object.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;

    my $config = new Config::Simple();
    $config->syntax('simple');

    $config->param( 'lang', delete( $args->{lang} ) ) if ( $args->{lang} );
    $config->param( 'update_includes', delete( $args->{update_includes} ) )
        if ( $args->{update_includes} );
    $config->param( 'clean_id', ( delete( $args->{clean_id} ) ) || 0 );
    $config->param( 'show_unknown', delete( $args->{show_unknown} ) )
        if ( $args->{show_unknown} );
    $config->param( 'donotset_lang',   ( delete( $args->{donotset_lang} ) )   || 1 );
    $config->param( 'distributed_set', ( delete( $args->{distributed_set} ) ) || 0 );
    $config->param( 'exclude_ent',     ( delete( $args->{exclude_ent} ) )     || 0 );

    if ( %{$args} ) {
        croak( maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }

    my $self = bless {}, $class;
    $self->{config} = $config;

    my $publican = Publican->new();
    $self->{publican} = $publican;


    $self->{banned_tags} = {};
    foreach my $btag ( split( /,/, ( $self->{publican}->param('banned_tags') || "" ) ) ) {
        $self->{banned_tags}{$btag} = 1;
    }

    $self->{banned_attrs} = {};
    foreach my $battr ( split( /,/, ( $self->{publican}->param('banned_attrs') || "" ) ) ) {
        $self->{banned_attrs}{$battr} = 1;
    }

    my $clean_id        = $self->{config}->param('clean_id');
    my $xml_lang        = $self->{publican}->param('xml_lang');

    if ( $clean_id ) {
        # create database to track section id changes
        my $db_file = "$xml_lang/clean_id_tracker.db";  
        $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", { RaiseError => 1 }) 
          || croak( maketext($DBI::errstr) );
        $self->{dbh}->{AutoCommit} = 0;
        $self->create_db();

        my $sql = "select original, max(conformance) as max_count from clean_id_tracker group by original";
        my $results = $self->{dbh}->selectall_hashref($sql, 'original');

        foreach my $id (keys %{$results}) {
            $UNIQUE_IDS{$id} = $results->{$id}{max_count};
        }
    }

    return $self;
}

=head2  print_known_tags

Print a list of tags that have had their output QA'd.

=cut

sub print_known_tags {
    my $self = shift();
    foreach my $key ( sort( keys(%MAP_OUT) ) ) {
        print("$key\n");
    }

    return;
}

=head2 prune_xml($node)

Remove unwanted nodes.

If $lang is set then delete all nodes that have lang set and do not contain $lang

If $arch is set then delete all nodes that have arch set and do not contain $arch

If $condition is set then delete all nodes that have condition set and do not contain $condition 

=cut

sub prune_xml {
    my ( $self, $xml_doc ) = @_;

    my $original_tag = $xml_doc->root()->{'_tag'};

    if ($xml_doc) {
        if ( $self->{config}->param('lang') ) {
            $xml_doc->pos( $xml_doc->root() );
            while (
                my $node = $xml_doc->look_down(
                    sub {
                        $_[0]->attr('lang')
                            && $_[0]->attr('lang') !~ ( $self->{config}->param('lang') );
                    }
                )
                )
            {
                croak(
                    maketext(
                        "FATAL ERROR: language profiling would prune root node. Do NOT set lang in a root node."
                    )
                ) if ( $node->same_as( $xml_doc->root() ) );
                $node->delete();
            }
        }
        if ( $self->{publican}->param('arch') ) {
            $xml_doc->pos( $xml_doc->root() );
            while (
                my $node = $xml_doc->look_down(
                    sub {
                        $_[0]->attr('arch')
                            && $_[0]->attr('arch') !~ ( $self->{publican}->param('arch') );
                    }
                )
                )
            {
                croak(
                    maketext(
                        "FATAL ERROR: arch profiling would prune root node. Do NOT set arch in a root node."
                    )
                ) if ( $node->same_as( $xml_doc->root() ) );
                $node->delete();
            }
        }

        if ( $self->{publican}->param('condition') ) {
            $xml_doc->pos( $xml_doc->root() );
            while (
                my $node = $xml_doc->look_down(
                    sub {
                        $_[0]->attr('condition')
                            && $_[0]->attr('condition')
                            !~ ( $self->{publican}->param('condition') );
                    }
                )
                )
            {
                croak(
                    maketext(
                        "FATAL ERROR: condition profiling would prune root node. Do NOT set condition in a root node."
                    )
                ) if ( $node->same_as( $xml_doc->root() ) );
                $node->delete();
            }
        }
    }

    return;
}

=head2 Clean_ID

Rename ID's and update xrefs.

If this node has a title as a child set it's ID else remove the ID

=cut

sub Clean_ID {
    my ( $self, $node ) = @_;
    my $my_id   = "";
    my $par_title  = "";
    my $sect_title = "";
    my $docname  = $self->{publican}->param('docname');
    my $product  = $self->{publican}->param('product');
    my $track_id = $self->{config}->param('track_id');

    if ($node) {
        my $tag = $node->{'_tag'};

        # keep_id means keep the current ID without modification.
        if ( $MAP_OUT{$tag}->{keep_id} ) {
            $my_id = $node->id() || "";
        }
        elsif ( !$MAP_OUT{$tag}->{no_id} ) {
            foreach my $child ( $node->content_refs_list() ) {
                if ( ref $$child
                    && $$child->{'_tag'} eq ( $MAP_OUT{$tag}->{id_node} || 'title' ) )
                {
                    $sect_title = $$child->as_text;

                    $my_id = $$child->as_text;
                    $my_id =~ s/[- ]/_/g;
                    $my_id =~ s/[^a-zA-Z0-9\._]//g;
                    $my_id =~ s/_+/_/g;

                    # Must start with a letter!
                    if ( $my_id =~ /^\d/ ) {
                        $my_id = 'a' . $my_id;
                    }

                    if ( $node->parent() ) {
                        my $par_title = $node->parent()->look_up( sub { $_[0]->attr('id'); } );
                        if ( $my_id ne "" && $par_title ) {
                            my $my_p_id = $par_title->attr('id');

                            $my_p_id =~ s/^.*-//;
                            $my_id = "$my_p_id-$my_id";
                        }
                    }
                    last;
                }
            }
        }

        my $tmp_id = "";
        # prepend product & book name (to avoid problems in sets)
        # prepend tag type for translations BZ #427312
        if ( $my_id ne "" ) {
            $my_id = "$product-$docname-$my_id";
            $my_id = substr( $tag, 0, 4 ) . "-$my_id";

            if ( $node->attr( 'conformance') && 
                 $node->attr( 'conformance') > 1 
            ) {
                $tmp_id = join('_', $my_id, $node->attr( 'conformance'));
            }
            else {
                $tmp_id = $my_id;
            }
        }

        if ( $node->id() && $node->id() ne $tmp_id ) {

            my $conformance = 1;
            if ( defined $UNIQUE_IDS{$my_id}  ) {
                $conformance = $UNIQUE_IDS{$my_id} + 1;  
            }

            $UNIQUE_IDS{$my_id} = $conformance;
            $node->attr( 'conformance', $conformance);
            $tmp_id = ($conformance > 1) ? join('_', $my_id, $conformance) : $my_id;

            $UPDATED_IDS{ $node->id() } = $tmp_id;

            #print "change from " . $node->id() . " to $tmp_id\n";

            $self->track_id( { old_id      => $node->id(), 
                               new_id      => $tmp_id, 
                               conformance => $conformance,
            } )
        }

        if ( $my_id eq "" ) {
            $my_id = undef;
        }

        $node->attr( 'id', $tmp_id );
    }

    return;
}

sub track_id {
    my ( $self, $args ) = @_;

    my $old_id      = delete $args->{old_id} ||
      croak ( maketext( "old_id is the mandatory argument for track_id" ) );

    my $new_id      = delete $args->{new_id}      || return;
    my $conformance = delete $args->{conformance} || 0;
   
    return if ( $new_id eq $old_id );

    my $docname = $self->{publican}->param('docname')
      || croak( maketext( "clean_id failed to get the docname" ) );

    my $product = $self->{publican}->param('product')
      || croak( maketext( "clean_id failed to get the product name" ) );

    my $version = $self->{publican}->param('version')
      || croak( maketext( "clean_id failed to get the version number" ) );

    my $current_file = $self->{current_file}
      || croak( maketext( "clean_id failed to get the xml filename" ) );

    $current_file =~ s/^\s+|\s+$//;

    my $original = $new_id;
    if ($conformance > 1) {
        $original =~ s/\_\d+$//;
    }
 
    eval {      
        my $sql = <<SQL; 
          SELECT map_to, section_id 
            FROM clean_id_tracker 
           WHERE
             product    = ? AND
             docname    = ? AND
             version    = ? AND
             xml_file   = ? AND
             section_id = ?
SQL

        my $sth = $self->{dbh}->prepare($sql);
        $sth->execute($product, $docname, $version, $current_file, $old_id);
        my $result = $sth->fetchrow_hashref();

        my $map_to = "";
        if ( defined $result && %{$result} ) {
            $map_to = $result->{map_to};

            my $update_sql = <<SQL; 
              UPDATE clean_id_tracker 
                SET section_id  = ?,
                    conformance = ?,
                    original    = ?
                WHERE
                  product     = ? AND
                  docname     = ? AND
                  version     = ? AND
                  xml_file    = ? AND
                  section_id  = ? AND
                  map_to      = ?
SQL
            my $update_sth = $self->{dbh}->prepare($update_sql);
            $update_sth->execute($new_id, $conformance, $original, $product, $docname, $version, $current_file, $old_id, $map_to);
            $update_sth->finish();           
        }
        else {
            $map_to = $old_id;

            # store the latest section id of this title
            my $insert_sql = <<SQL; 
              INSERT INTO clean_id_tracker 
                (product, docname, version, xml_file, conformance, section_id, map_to, original) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
SQL
            my $insert_sth = $self->{dbh}->prepare($insert_sql);
            $insert_sth->execute($product, $docname, $version, $current_file, $conformance, $new_id, $map_to, $original);
            $insert_sth->finish();         
        }

        $sth->finish();
    };

    if ($@) {
        $self->{dbh}->rollback();
        croak ( maketext("Error tracking id for '$new_id' in '$current_file': $@") );
    }

    return;
}

=head2 print_xml

Print out utf8 XML files

Have to output xml/DTD header

=cut

sub print_xml {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("xml_doc is a mandatory argument") );
    my $out_file = delete( $args->{out_file} )
        || croak( maketext("out_file is a mandatory argument") );

    if ( %{$args} ) {
        croak( maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }

    my $lvl       = 0;
    my $dtdver    = $self->{publican}->param('dtdver');
    my $docname   = $self->{publican}->param('docname');
    my $lang      = $self->{config}->param('lang');
    my $main_file = $self->{publican}->param('mainfile');

    if ($xml_doc) {
        my $file = $out_file;
        my $path = '';

        # handle nested directories
        if ( $file =~ m|^(.*/xml)/(.*\/)[^\/]*\.xml| ) {
            $path = $2;
            mkpath("$1/$path") if ( !-d $path );
            $path =~ s|[^/]*/|\.\./|g;
        }

        $xml_doc->pos( $xml_doc->root() );
        if (   !$self->{config}->param('clean_id')
            && !$self->{config}->param('update_includes')
            && !$self->{config}->param('donotset_lang') )
        {
            if ( $dtdver !~ m/^5/ ) {
                $xml_doc->attr( 'lang', $lang );
            }
        }

        if ( $dtdver =~ m/^5/ ) {
            $xml_doc->attr( 'xml:lang', $lang );
        }

        my $type = $xml_doc->attr("_tag");
        $file =~ m|^(.*/xml/)|;
        my $text = $self->my_as_XML( { xml_doc => $xml_doc, path => ( $1 || './' ) } );
## BUGBUG revert to upstream as_XML?
##        my $text = $xml_doc->as_XML();
        $text =~ s/&#34;/"/g;
        $text =~ s/&#39;/'/g;
        $text =~ s/&quot;/"/g;
        $text =~ s/&apos;/'/g;

        $xml_doc->root()->delete();

        my $OUTDOC;
        open( $OUTDOC, ">:encoding(UTF-8)", "$out_file" )
            || croak( maketext( "Could not open [_1] for output!", $out_file ) );

        my $ent_file = undef;

        # Will be unset when processing common files outside books
        if ( $docname && !$self->{config}->param('exclude_ent') ) {
            my $xml_lang = $self->{publican}->param('xml_lang');
            if ( -e "$xml_lang/$main_file.ent" ) {
                $ent_file = "$path$main_file.ent";
            }
        }

        print( $OUTDOC Publican::dtd_string(
                { tag => $type, dtdver => $dtdver, ent_file => $ent_file }
            )
        );

        #debug_msg("is utf8: " . utf8::is_utf8($text) . "\n");
        print( $OUTDOC $text );
        close($OUTDOC);
    }

    return;
}

sub validate_tags {
    my ( $self, $node, $tag ) = @_;

    my $show_unknown = $self->{publican}->param('show_unknown');

    return if (!$node && !$tag );

    if ( $self->{banned_tags}{$tag} ) {
        croak(
            maketext(
                "ERROR: Banned tag ([_1]) detected. Discuss this with your brands owners if you think this is in error.",
                $tag
                )
                . "\n"
        );
    }

    foreach my $attr ( keys(%{$self->{banned_attrs}}) ) {
        if ( $node->attr($attr) ) {
            croak(
                maketext(
                    "ERROR: Banned attribute ([_1]) detected. Discuss this with your brands owners if you think this is in error.",
                    $attr
                    )
                    . "\n\n"
            );
        }
    }

    if ( $show_unknown && !$MAP_OUT{$tag} ) {
        logger(
            maketext(
                "*WARNING: Unvalidated tag: '[_1]'. This tag may not be displayed correctly, may generate invalid xhtml, or may breach Section 508 Accessibility standards.",
                $tag
                )
                . "\n",
                RED
        );
    }

    return;
}


=head2 my_as_XML

Traverse tree and output xml as text. Overrides traverse ... evil stuff.

=cut

sub my_as_XML {
    my ( $self, $args ) = @_;

    my $xml_doc = delete( $args->{xml_doc} )
        || croak( maketext("'xml_doc' is a mandatory argument") );
    my $path = delete( $args->{path} )
        || croak( maketext("'path' is a mandatory argument") );

    # based on as_HTML
    my $tree              = $xml_doc->root();
    my @xml               = ();
    my $empty_element_map = $tree->_empty_element_map;

    my $clean_id     = $self->{config}->param('clean_id');
    my $lang         = $self->{config}->param('lang');

    # This flags tags that use  /> instead of end tags IF they are empty.
    $empty_element_map->{xref}         = 1;
    $empty_element_map->{footnoteref}  = 1;
    $empty_element_map->{'index'}      = 1;
    $empty_element_map->{'xi:include'} = 1;
    $empty_element_map->{ulink}        = 1;
    $empty_element_map->{imagedata}    = 1;
    $empty_element_map->{area}         = 1;

    my $depth  = 0;
    my $indent = "\t";

    my ( $tag, $node, $start );    # per-iteration scratch

    # $_[0] = node
    # $_[1] = startflag
    # $_[2] = depth
    # $_[3] = parent
    # $_[4] = text node index

    $tree->traverse(
        sub {
            ( $node, $start ) = @_;
            if ( ref $node ) {     # it's an element
                                   # delete internal attrs
                $node->attr( 'depth', undef );
                $node->attr( 'name',  undef );

                $tag = $node->{'_tag'};

                if ($start) {      # on the way in

                    $self->validate_tags($node, $tag);
                    
                    if ($clean_id) {
                        $self->Clean_ID($node);
                    }

                    if (( $MAP_OUT{$tag}->{'newline'} )
                        && (   ( not defined $MAP_OUT{$tag}->{mixed_mode} )
                            || ( not $MAP_OUT{$tag}->{mixed_mode} )
                            || ( not $node->look_up( '_tag', 'para' ) ) )
                        )
                    {
                        push( @xml, "\n", $indent x $depth );
                    }

                    if ( $MAP_OUT{$tag}->{verbatim} ) {
                        push( @xml, "\n" );
                    }
                    elsif ( $MAP_OUT{$tag}->{block} ) {

                        # Check to make sure the block is starting on it's own line
                        # If not add a new line and indent
                        if (( $xml[$#xml] && $xml[$#xml] =~ /\S/ )
                            && (   ( not defined $MAP_OUT{$tag}->{mixed_mode} )
                                || ( not $MAP_OUT{$tag}->{mixed_mode} )
                                || ( not $node->look_up( '_tag', 'para' ) ) )
                            )
                        {
                            push( @xml, "\n", $indent x $depth );
                        }
                        $depth++;
                    }

                    if ( $tag eq 'imagedata' || $tag eq 'graphic' ) {
                        $node->attr('fileref') =~ m/(...)$/;
                        my $format = uc($1);
                        if ( !$node->attr('format') && $format ) {
                            $node->attr( 'format', $format );
                        }

                        my $img_file = "$path" . $node->attr('fileref');
                        $img_file = $self->{publican}->param('xml_lang') . "/" . $img_file
                            if ($clean_id);
                        if ( -f $img_file ) {

                            #nop
                        }
                        elsif ( $img_file !~ /Common_Content/ ) {
                            logger(
                                "\t"
                                    . maketext( "WARNING: Image missing: [_1]", $img_file )
                                    . "\n",
                                RED
                            );
                        }

                        # when building distrubuted sets, we need to prepend the
                        # books name to the image path to prevent image name clashes
                        my $preptxt = 'images/' . $self->{publican}->param('docname');

                        if (   $self->{config}->param('distributed_set')
                            && $node->attr('fileref') !~ /^$preptxt/ )
                        {
                            $node->attr( 'fileref', "$preptxt/" . $node->attr('fileref') );
                        }
                    }

                    if ( $empty_element_map->{$tag}
                        and !@{ $node->content_array_ref() } )
                    {
                        push( @xml, $node->starttag_XML( undef, 1 ) );
                        if ($MAP_OUT{$tag}->{newline_after}
                            && (   ( not defined $MAP_OUT{$tag}->{mixed_mode} )
                                || ( not $MAP_OUT{$tag}->{mixed_mode} )
                                || ( not $node->look_up( '_tag', 'para' ) ) )
                            )
                        {
                            push( @xml, "\n", $indent x $depth );
                        }
                    }
                    else {
                        push( @xml, $node->starttag_XML(undef) );
                    }

                    if ( $MAP_OUT{$tag}->{block} ) {
                        if (   $node->parent()
                            && $MAP_OUT{ $node->parent()->{'_tag'} }->{'line_wrap'} )
                        {
                            push( @xml, "\n" );
                        }
                        elsif (
                            ( not $MAP_OUT{$tag}->{verbatim} )
                            && (   ( not defined $MAP_OUT{$tag}->{mixed_mode} )
                                || ( not $MAP_OUT{$tag}->{mixed_mode} )
                                || ( not $node->look_up( '_tag', 'para' ) ) )
                            )
                        {
                            push( @xml, "\n", $indent x $depth );
                        }
                    }
                }
                else {    # on the way out
                    if ( $MAP_OUT{$tag}->{block} ) {

                        # remove empty lines
                        if ( $xml[$#xml] =~ /^[\t ]*$/s ) {
                            pop(@xml);
                            if ( $xml[$#xml] =~ /^[\t ]*$/s ) {
                                pop(@xml);
                            }
                        }

                        # remove trailing space
                        if ( $xml[$#xml] =~ /[\t ]*$/ )    # ||
                        {
                            $xml[$#xml] =~ s/[\t ]*$//;
                        }

                        if ( $MAP_OUT{$tag}->{block} ) {
                            if ( $MAP_OUT{$tag}->{verbatim} ) {
## BZ #604465 don't add trailing newline.
##                                push( @xml, "\n" );
                            }
                            elsif (( defined $MAP_OUT{$tag}->{mixed_mode} )
                                && ( $MAP_OUT{$tag}->{mixed_mode} )
                                && ( $node->look_up( '_tag', 'para' ) ) )
                            {
                                $depth--;
                            }
                            elsif ($node->parent()
                                && $MAP_OUT{ $node->parent()->{'_tag'} }->{'line_wrap'} )
                            {
                                $depth--;
                                push( @xml, "\n" );
                            }
                            else {
                                $depth--;
                                push( @xml, "\n", $indent x $depth );
                            }
                        }
                    }

                    unless ( $empty_element_map->{$tag}
                        and !@{ $node->content_array_ref() } )
                    {
                        push( @xml, $node->endtag_XML() );
                    }    # otherwise it will have been an <... /> tag.

                    if (( $MAP_OUT{$tag}->{newline_after} )
                        && (   ( not defined $MAP_OUT{$tag}->{mixed_mode} )
                            || ( not $MAP_OUT{$tag}->{mixed_mode} )
                            || ( not $node->look_up( '_tag', 'para' ) ) )
                        )
                    {
                        push( @xml, "\n", $indent x $depth );
                    }

                    if (( $MAP_OUT{$tag}->{block} )
                        && (   ( not defined $MAP_OUT{$tag}->{mixed_mode} )
                            || ( not $MAP_OUT{$tag}->{mixed_mode} )
                            || ( not $node->look_up( '_tag', 'para' ) ) )
                        )
                    {
                        push( @xml, "\n", $indent x $depth );
                    }
                }
            }
            else {    # it's just text
                my $parent = $_[3];

                # Remove extra space from non-verbatim tags
                if ( $parent
                    && !( $MAP_OUT{ $parent->{'_tag'} }->{verbatim} ) )
                {

                    # Don't out put empty tags
                    # BZ #453067 but spaces between inline tags should be output
                    if ( $node !~ /^[\t ]*$/ || $node !~ /\n/ ) {

                        # Truncate leading space
                        $node =~ s/[\n\r\f\t ]+/ /g;

                        if ( $MAP_OUT{ $parent->{'_tag'} }->{block} ) {

                            # for the first child, remove leading space and indent it
                            if ( $_[4] == 0 ) {
                                $node =~ s/^ //g;
                            }
                        }

                        $tree->_xml_escape($node);

                        # zero width space to allow Chinese to wrap
##                        if ( $lang
##                            && ( $lang eq 'zh-CN' || $lang eq 'zh-TW' ) )
##                        {
##                            $node =~ s/([\x{2000}-\x{AFFF}])/$1\&\#x200B\;/g;
##                        }

                        push( @xml, $node );
                    }
                }
                else {    # Verbatim
                    $tree->_xml_escape($node);
                    push( @xml, $node );
                }
            }
            1;            # keep traversing
        }
    );

    return ( join( '', @xml, "\n" ) );
}

=head2 validate_tables

Ensure Tables comply to requirements not enforceable in XML validation.

1. tgroup attribute cols must match the number of entries in every row.

=cut

sub validate_tables {
    my ( $self, $xml_doc ) = @_;

    if ($xml_doc) {
        $xml_doc->pos( $xml_doc->root() );

        foreach my $node ( $xml_doc->look_down( "_tag", "tgroup" ) ) {

            # TODO this should report the line number
            # until then it try's to determine the Tables title or id
            my $table = $node->look_up( "_tag", qr/table|informaltable/ );
            if ( !$table ) {
                logger(
                    maketext(
                        "WARNING: table validation failed. Could not determine table for tgroup, column numbers cannot be validated"
                    )
                );
                next;
            }
            my $title = $table->look_down( "_tag", "title" );
            if ($title) {
                $title = $title->as_text();
            }
            else {
                $title = ( $table->attr('id') || "Can't identify table" );
            }
            my $cols = $node->attr('cols')
                || croak maketext(
                "*ERROR: Fatal Table Error* Table ([_1]) contains invalid data\nAttribute cols is mandatory for tgroup",
                $title
                ) . "\n";

            foreach my $row ( $node->look_down( "_tag", "row" ) ) {
                my @entries = $row->look_down( "_tag", "entry" );
                if ( @entries > $cols ) {
                    croak maketext(
                        "*ERROR: Fatal Table Error* Table ([_1]) contains invalid data\nAttribute cols ([_2]) does not match number of entry elements ([_3])",
                        $title, $cols, @entries )
                        . "\n";
                }
            }
        }
    }

    return;
}

=head2 sort_glossaries

Sort glosslists

=cut

sub sort_glossaries {
    my ( $self, $xml_doc ) = @_;

    return unless ($test_collate);

    my $Collator = Unicode::Collate->new();

    if ($xml_doc) {
        foreach my $glosslist ( $xml_doc->root->look_down( "_tag", "glosslist" ) ) {
            my @glossentries = sort( {
                    $Collator->cmp(
                        $a->look_down( "_tag", "glossterm" )->as_text(),
                        $b->look_down( "_tag", "glossterm" )->as_text()
                    )
            } $glosslist->look_down( "_tag", "glossentry" ) );

            foreach my $glossentry (@glossentries) {
                $glossentry->detach();
                $glosslist->push_content($glossentry);
            }
        }
    }

    return;
}

=head2 process_file

Create XML::TreeBuilder object and perform operations.

=cut

sub process_file {
    my ( $self, $args ) = @_;

    my $file = delete( $args->{file} )
        || croak( maketext("file is a mandatory argument") );
    my $out_file = delete( $args->{out_file} ) || undef;

    # set the the current processing filename
    $self->{current_file} = $file;

    if ( %{$args} ) {
        croak( maketext( "unknown arguments: [_1]", join( ", ", keys %{$args} ) ) );
    }

    logger( "\t" . maketext( "Processing file [_1] -> [_2]", $file, $out_file ) . "\n" );

    my $clean_id        = $self->{config}->param('clean_id');
    my $update_includes = $self->{config}->param('update_includes');
    my $xml_lang        = $self->{publican}->param('xml_lang');

    my $xml_doc = XML::TreeBuilder->new( { 'NoExpand' => "1", 'ErrorContext' => "2" } );
    $xml_doc->store_comments(1);
    $xml_doc->store_pis(1);
##debug_msg("here 1");

    $xml_doc->parse_file($file)
        || croak( maketext( "Can't open file '[_1]' [_2]", $file, $@ ) );
##debug_msg("here 2");

    $self->validate_tables($xml_doc);
    $self->sort_glossaries($xml_doc);

    if ($update_includes) {
        $self->update_include($xml_doc);
    }
    elsif ( !$clean_id ) {
        $self->prune_xml($xml_doc);
    }

    $self->print_xml( { xml_doc => $xml_doc, out_file => $out_file } );

    if ($clean_id) {

        # Update links in xml
        foreach my $xml_file ( dir_list( $xml_lang, '*.xml' ) ) {
            my $editor = new File::Inplace( file => $xml_file );
            while ( my ($line) = $editor->next_line ) {
                foreach my $key ( keys(%UPDATED_IDS) ) {
                    $line =~ s/linkend="$key"/linkend="$UPDATED_IDS{$key}"/g;
                }
                $editor->replace_line($line);
            }

            $editor->commit;
        }

        # update links in PO files
        foreach my $dir ( split( /,/, get_all_langs() ) ) {
            next if ( $dir eq $xml_lang );
            foreach my $po_file ( dir_list( $dir, '*.po' ) ) {
                my $editor = new File::Inplace( file => $po_file );
                while ( my ($line) = $editor->next_line ) {
                    foreach my $key ( keys(%UPDATED_IDS) ) {

                        # all of string on one line
                        $line =~ s/=\\"$key\\"/=\\"$UPDATED_IDS{$key}\\"/g;

                        # tail of string line wrapped
                        $line =~ s/=\\"$key"/=\\"$UPDATED_IDS{$key}"/g;

                        # string line wrapped after '='
                        $line =~ s/\\"$key\\"/\\"$UPDATED_IDS{$key}\\"/g;
                    }
                    $editor->replace_line($line);
                }

                $editor->commit;
            }
        }

        # clear out changes ... might be better to save them up and do a single pass...
        %UPDATED_IDS = ();
    }

    return;
}

sub create_db {
    my $self = shift;
    my $sql;

    eval {
        my $check_table_sql =<<SQL;
          SELECT name 
            FROM sqlite_master 
           WHERE name='clean_id_tracker'
SQL

        my $create_table_sql = <<SQL;
          CREATE TABLE clean_id_tracker (
            id             INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            product        TEXT NOT NULL,
            version        TEXT NOT NULL,
            docname        TEXT NOT NULL,
            xml_file       TEXT NOT NULL,
            original       TEXT NOL NULL,
            conformance    INT NOT NULL DEFAULT 0,
            section_id     TEXT NOT NULL,
            map_to         TEXT NOT NULL
        )
SQL

        my $table = $self->{dbh}->selectrow_hashref($check_table_sql);

        return if ( defined $table->{name} );

        $self->{dbh}->do($create_table_sql);

    };

    if ($@) {
        $self->{dbh}->rollback();
        croak ( maketext("Failed to create table: $@") );
    }

    return;
}

sub DESTROY {
    my $self = shift;

    if ( defined $self->{dbh} ) {
        eval {
            $self->{dbh}->commit();
        };

        if ($@) {
            $self->rollback();
            croak ( maketext("$@") );
        }
        
        $self->{dbh}->disconnect();
    }
}

1;    # Magic true value required at end of module

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected named arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandatory parameter will return this error if the parameter is undef.

=item C<< Could not open %s for output! >>

The named file could not be opened.

=item C<< Can't calculate image size of %s >>

Images are automatically scaled if thy are to wide, this check could not be
performed due to either access permissions or file weirdness.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Publican::XmlClean requires no configuration files or environment variables.


=head1 DEPENDENCIES

Carp
version
XML::TreeBuilder
Text::Wrap
Config::Simple
Publican
File::Path
Term::ANSIColor
Cwd

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Publican&component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
