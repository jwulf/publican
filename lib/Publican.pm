package Publican;

use utf8;
use warnings;
use strict;
use Carp;
use Config::Simple '-strict';
use XML::TreeBuilder 5.4;
use I18N::LangTags::List;
use Term::ANSIColor qw(:constants uncolor);
use File::Find::Rule;
use XML::LibXSLT;
use XML::LibXML;
use Publican::Localise;
use Publican::ConfigData;
use Encode;
use Cwd qw(abs_path);
use Data::Dumper;
use File::Copy::Recursive;
use Encode qw(is_utf8 decode_utf8 encode_utf8);
use Sort::Versions;
use version;

use vars
    qw(@ISA $VERSION @EXPORT @EXPORT_OK $SINGLETON $LOCALISE $SPEC_VERSION %PARAMS);

$File::Copy::Recursive::KeepMode = 0;

$VERSION = version->declare('v4.3.2');
@ISA     = qw(Exporter);

@EXPORT
    = qw(dir_list debug_msg get_all_langs logger help_config maketext new_tree dtd_string rcopy dircopy fcopy rcopy_glob fmove dirmove params_as_docbook);

# Track when the SPEC file generation is incompatible.
$SPEC_VERSION = '4.1';

my $DEFAULT_CONFIG_FILE = 'publican.cfg';
my $DEBUG               = undef;
my $NOCOLOURS           = undef;
my $QUIET               = undef;

my %PARAM_OLD = (
    ARCH                       => 'arch',
    BOOKS                      => 'books',
    BRAND                      => 'brand',
    BREW_DIST                  => 'brew_dist',
    CHUNK_FIRST                => 'chunk_first',
    CHUNK_SECTION_DEPTH        => 'chunk_section_depth',
    CLASSPATH                  => 'classpath',
    COMMON_CONFIG              => '',
    COMMON_CONTENT             => '',
    CONDITION                  => 'condition',
    CONFIDENTIAL               => 'confidential',
    DEFAULT_LANGS              => '',
    DOCNAME                    => '',
    DOC_TYPE                   => 'type',
    DOC_URL                    => 'doc_url',
    DTD_VER                    => 'dtdver',
    DT_OBSOLETES               => 'dt_obsoletes',
    GENERATE_SECTION_TOC_LEVEL => 'generate_section_toc_level',
    IGNORED_TRANSLATIONS       => 'ignored_translations',
    LICENSE                    => 'license',
    OS_VER                     => 'os_ver',
    PRODUCT                    => '',
    PROD_URL                   => 'prod_url',
    PROD_VERSION               => '',
    PROGNAME                   => '',                             # l10n
    SET_REPO                   => 'repo',
    SET_REPO_TYPE              => 'scm',
    SHOW_REMARKS               => 'show_remarks',
    SOURCE                     => '',                             # l10n
    SRC_URL                    => 'src_url',
    TRANSLATIONS               => '',
    TOC_SECTION_DEPTH          => 'toc_section_depth',
    WEB_BREW_DIST              => 'web_brew_dist',
    WEB_OBSOLETES              => 'web_obsoletes',
    XMLFILE                    => '',
    XML_LANG                   => 'xml_lang',
);

# All the valid fields in the publican.cfg file
# constraint: a regex to validate the content
%PARAMS = (

    arch => {
        descr => maketext('Arch to filter output on.'),

    },
    audience => {
        descr => maketext('audience to filter output on.'),

    },
    books => {
        descr => maketext(
            'A space-separated list of books used in this remote set.'),

    },
    banned_attrs => {
        descr => maketext(
            'A comma-separated list of XML attributes that are not permitted in the source.'
        ),
        limit_to => 'brand',
    },
    banned_tags => {
        descr => maketext(
            'A comma-separated list of XML tags that are not permitted in the source.'
        ),
        limit_to => 'brand',
    },
    base_brand => {
        descr    => maketext('The base brand to use for this brand.'),
        default  => 'common',
        limit_to => 'brand',
    },
    brand => {
        descr   => maketext('The brand to use when building this package.'),
        default => 'common',

    },
    brew_dist => {
        descr => maketext(
            'The brew dist to use for building the standalone desktop rpm.'),
        default => 'docs-5E',
        alert   => maketext(
            'This field is deprecated and will be removed from Publican in the future.'
        ),
    },
    bridgehead_in_toc => {
        descr   => maketext('Display bridge head elements in the TOCs?'),
        default => 0,
    },
    chunk_first => {
        descr => maketext(
            'For HTML, should the first section be on the same page as its parent?'
        ),
        default => 0,

    },
    chunk_section_depth => {
        descr => maketext(
            'For HTML, what is the deepest level of nesting at which a section should be split onto its own page?'
        ),
        default => 4,
    },
    classpath => {
        descr => maketext('Path to jar files for FOP.'),
        default =>
            '/usr/share/java/ant/ant-trax-1.7.0.jar:/usr/share/java/xmlgraphics-commons.jar:/usr/share/java/batik-all.jar:/usr/share/java/xml-commons-apis.jar:/usr/share/java/xml-commons-apis-ext.jar',
    },
    common_config => {
        descr   => maketext('Path to publican content.'),
        default => Publican::ConfigData->config('datadir'),
    },
    common_content => {
        descr   => maketext('Path to publican common content.'),
        default => Publican::ConfigData->config('datadir')
            . '/Common_Content',
    },
    condition => {
        descr => maketext(
            'Conditions on which to prune XML before transformation.'),
    },
    confidential => {
        descr   => maketext('Is the content confidential?'),
        default => 0,
    },
    confidential_text => {
        descr =>
            maketext('The text used to indicate content is confidential.'),
        default => maketext('CONFIDENTIAL'),
    },
    conformance => {
        descr => maketext('conformance to filter output on.'),

    },
    debug => {
        descr   => maketext('Print out extra messages?'),
        default => 0,

    },
    docname => {
        descr => maketext(
            'Name of this document. Fetched from title tag in xml_lang/TYPE_Info.xml if not set in cfg file.'
        ),
        constraint => '^[0-9a-zA-Z_\-\.\+]+$',
        not_for    => 'brand',
    },
    doc_url => {
        descr => maketext(
            'URL for the documentation team for this package. Used for top right URL on HTML.'
        ),
        default => 'https://fedorahosted.org/publican',

    },
    dtd_type => {
        descr =>
            maketext('Override Type for DocType. Must be a complete string.'),
        limit_to => 'brand',
    },
    dtd_uri => {
        descr =>
            maketext('Override URI for DocType. Must be a complete string.'),
        limit_to => 'brand',
    },
## BUGBUG this should be ripped from file header
    dtdver => {
        descr => maketext(
            'Version of the DocBook DTD on which this project is based.'),
        default => '4.5',
    },
    dt_format => {
        descr   => maketext('The format to use for the desktop output.'),
        default => 'html-desktop',
    },
    dt_obsoletes => {
        descr => maketext(
            'Space-separated list of packages the desktop RPM obsoletes.'
        ),

    },
    dt_requires => {
        descr => maketext(
            'Space-separated list of packages the desktop RPM requires.'),

    },
    'ec_id' => {
        descr =>
            maketext('Eclipse plugin ID. Defaults to "$product.$docname"'),
    },
    'ec_name' => {
        descr =>
            maketext('Eclipse plugin name. Defaults to "$product $docname"'),
    },
    'ec_provider' => {
        descr => maketext(
            'Eclipse plugin provider. Defaults to "Publican-[_1]"', $VERSION
        ),
    },
    extras_dir => {
        descr   => maketext('Directory where images are located.'),
        default => 'extras',
    },
    generate_section_toc_level => {
        descr => maketext(
            'Generate table of contents down to the given section depth.'),
        default => 0,

    },
    ignored_translations => {
        descr => maketext(
            'Languages to replace with xml_lang regardless of translation status.'
        ),

    },
    img_dir => {
        descr   => maketext('Directory where images are located.'),
        default => 'images',
    },
    info_file => { descr => maketext('Override the default Info file.'), },
    lang      => {
        descr => maketext('lang to filter output on.'),

    },
    license => {
        descr   => maketext('License this package uses.'),
        default => 'GFDL',

    },
    mainfile => {
        descr => maketext(
            'The name of the main xml and ent files for this book, sans file extension and language. Fetched from docname if not set.'
        ),
    },
    menu_category => {
        descr => maketext(
            'Semicolon-separated list of menu categories for the desktop package.'
        ),
    },
    no_embedtoc => {
        descr => maketext(
            'Brand option to disable embedding the navigational toc in web packages'
        ),
        limit_to => 'brand',
    },
    os => {
        descr => maketext('os to filter output on.'),

    },
    os_ver => { descr => maketext('The OS for which to build packages.'), },
    pdf_body_font => {
        descr   => maketext('The font to use for body text in PDFs.'),
        default => 'Liberation Sans',
    },
    pdf_mono_font => {
        descr   => maketext('The font to use for mono text in PDFs.'),
        default => 'Liberation Mono',
    },
    product => {
        descr => maketext(
            'Product this package covers. Fetched from productname tag in xml_lang/TYPE_Info.xml'
        ),
        constraint => '^[0-9a-zA-Z_\-\.\+]+$',
        not_for    => 'brand',
    },
    prod_url => {
        descr =>
            maketext('URL for the product. Used in top left URL in HTML.'),
        default => 'https://fedorahosted.org/publican',

    },
    repo => {
        descr => maketext('Repository from which to fetch remote set books.'),
    },
    scm => {
        descr => maketext(
            'Type of repository in which books that form part of a remote set are stored. Supported types: SVN, GIT.'
        ),
    },
    rev_dir => {
        descr => maketext(
            q|By default Revision History is sorted in descending order. Set this to 'asc' or 'ascending' to reverse the sort.|
        ),
    },
    rev_file =>
        { descr => maketext('Override the default Revision History file.'), },
    revision => {
        descr => maketext('revision to filter output on.'),

    },
    revisionflag => {
        descr => maketext('revisionflag to filter output on.'),

    },
    role => {
        descr => maketext('role to filter output on.'),

    },
    security => {
        descr => maketext('security to filter output on.'),

    },
    show_remarks => {
        descr   => maketext('Display remarks in transformed output.'),
        default => 0,

    },
    sort_order => {
        descr =>
            maketext('Override the default sort weighting. Defaults to 50.'),
    },
    src_url => {
        descr => maketext(
            'URL to find tar of source files. Used in RPM Spec files.'),
    },
    status => {
        descr => maketext('status to filter output on.'),

    },
    tmp_dir => {
        descr   => maketext('Directory to use for building.'),
        default => 'tmp',

    },
    toc_section_depth => {
        descr => maketext(
            'Depth of sections to include in the main table of contents.'),
        default => 2,

    },
    type => {
        descr => maketext(
            'Type of content this package contains. Supported: set, book, article, brand'
        ),
        default => 'Book',

    },
    txt_formater => {
        descr =>
            maketext('Choose the formatter to use when creating txt output.'),
        constraint => '^(links{1}|tables{1}|default)$',
        default    => 'default',
    },
    userlevel => {
        descr => maketext('userlevel to filter output on.'),

    },
    vendor => {
        descr => maketext('vendor to filter output on.'),

    },
    version => {
        descr => maketext(
            'Version of this package. Fetched from productnumber tag in xml_lang/TYPE_Info.xml'
        ),
        constraint => '^[0-9][^\p{IsSpace}]*$',
    },
    web_brew_dist => {
        descr   => maketext('The brew dist to use for building the web rpm.'),
        default => 'docs-5E',
    },
    web_formats => {
        descr => maketext(
            'A comma-separated list of the formats to use for the web packages.'
        ),
        default => 'html,html-single,pdf,epub',
    },
    web_home => {
        descr => maketext(
            'This is a home page for a Publican-generated website, not a standard book.'
        ),
        alert =>
            'web_home is deprecated and will be removed from Publican in the future. Use "web_type: home" instead.',
    },
    web_type => {
        descr => maketext(
            'This is a special page for a Publican-generated website, not a standard book. Valid types are home, product, and version.'
        ),
        constraint => '^(home|product|version)$',
    },
    web_host => {
        descr => maketext(
            'This is a host name for a Publican-generated website, used for searches and the Sitemap. Be sure to include the full path to your document tree. E.g. if your documents are in the docs directory: http://www.example.com/docs'
        ),
        alert =>
            'web_host is deprecated and will be removed from Publican in the future. Use "host" in the web site configuration file instead.',
    },
    web_obsoletes =>
        { descr => maketext('Packages to obsolete in web RPM.'), },
    web_search => {
        descr => maketext(
            'Override the default search form for a Publican website. By default this will use Google search and do a site search if web_host is set.'
        ),
        alert =>
            'web_search is deprecated and will be removed from Publican in the future. Use "search" in the web site configuration file instead.',
    },
    web_name_label => {
        descr => maketext(
            'Override the book name, bottom level, menu label on a Publican website.'
        ),
    },
    web_product_label => {
        descr => maketext(
            'Override the product, top level, menu label on a Publican website.'
        ),
    },
    web_version_label => {
        descr => maketext(
            'Override the version, middle level, menu label on a Publican website. To hide this menu item set this to: UNUSED'
        ),
    },
    web_cfg => {
        descr => maketext(
            'Full path for the publican site configuration file for non standard RPM websites.'
        ),
        limit_to => 'brand',
    },
    web_dir => {
        descr    => maketext('Install path for non standard RPM websites.'),
        limit_to => 'brand',
    },
    web_req => {
        descr => maketext(
            'Name of site package for non standard RPM websites. Required to ensure the site is installed.'
        ),
        limit_to => 'brand',
    },
    wkhtmltopdf_opts => {
        descr => maketext(
            'Extra options to pass to wkhtmltopdf. e.g. wkhtmltopdf_opts: "-O landscape -s A3"'
        ),
    },
    wordsize => {
        descr => maketext('wordsize to filter output on.'),

    },
    xml_lang => {
        descr   => maketext('Language in which XML is authored.'),
        default => 'en-US',
    },
    drupal_author => {
        descr => maketext(
            'The author name to be shown in drupal book page. It must be a valid drupal username.'
        ),
        default => 'Publican',
    },
    drupal_menu_title => {
        descr => maketext(
            'Override the bookname that will be shown in the drupal menu.'),
    },
    drupal_menu_block => {
        descr   => maketext('The menu where we can find the book.'),
        default => 'user-guide',
    },
    drupal_image_path => {
        descr => maketext(
            'The directory where the image should be stored in drupal server.'
        ),
        default => '/sites/default/files/documentation/',
    },

);

# Setup localisation ASAP
BEGIN {
    if ( !$LOCALISE ) {
        $LOCALISE = Publican::Localise->get_handle()
            || croak("Could not create a Publican::Localise object");
        $LOCALISE->encoding("UTF-8");
        $LOCALISE->textdomain("publican");
    }
}

=head1 NAME

Publican - Used to control settings for sub modules.


=head1 VERSION

This document describes Publican version $VERSION


=head1 SYNOPSIS

    use Publican;

    my $publican = Publican->new({DEBUG => 1});

=head1 DESCRIPTION

Handles general configuration of all sub modules.

=head1 INTERFACE 

=cut

# Module implementation here

=head2 _load_config

Private method for loading a config file

=cut

sub _load_config {
    my ( $self, $args ) = @_;

    my $configfile = ( delete( $args->{configfile} )
            || croak( maketext("configfile is a mandatory argument") ) );
    my $common_config  = delete( $args->{common_config} );
    my $common_content = delete( $args->{common_content} );
    my $brand_dir      = delete( $args->{brand_dir} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }
    if ( not -f $configfile ) {

        croak( maketext( "Config file not found: [_1].", $configfile ) );
    }

    my $real_config = new Config::Simple();
    $real_config->syntax('http');
    $real_config->read($configfile)
        || croak(
        maketext( "Failed to load config file: [_1]", $configfile ) );

    my %Config = $real_config->vars();

    my $config = new Config::Simple();
    $config->syntax('http');
    foreach my $key ( keys(%Config) ) {
        unless ( defined $PARAMS{$key} ) {
            logger(
                maketext(
                    "WARNING: Unknown config key [_1], ignoring.\n", $key
                ),
                RED
            );
            next;
        }
    }

    foreach my $key ( keys(%PARAMS) ) {
        if (   defined $Config{$key}
            && defined $PARAMS{$key}->{limit_to}
            && (lc( ( $Config{'type'} || 'book' ) ) ne
                lc( $PARAMS{$key}->{limit_to} ) )

            )
        {
            logger(
                maketext(
                    "WARNING: config key [_1] is not valid for this type of object, ignoring.\n",
                    $key
                ),
                RED
            );
            next;
        }

        # Output alerts about a parameter
        if ( defined $Config{$key} && defined $PARAMS{$key}->{alert} ) {
            _alert( $PARAMS{$key}->{alert} . "\n" );
        }

        # skip any bogus or empty fields
        my $tmp = $Config{$key};
        if ( defined $tmp ) {
            if ( ref $tmp eq "ARRAY" ) {
                if ( $#{$tmp} >= 0 ) {
                    $config->param( $key,
                        decode_utf8( join( ',', @{ $Config{$key} } ) ) );
                }
            }
            elsif ( $tmp ne "" ) {
                $config->param( $key, decode_utf8($tmp) );
            }
        }
        elsif ( defined $PARAMS{$key}->{default} ) {
            $config->param( $key, $PARAMS{$key}->{default} );
        }
    }

    $config->param( 'common_config',  $common_config )  if $common_config;
    $config->param( 'common_content', $common_content ) if $common_content;
    $config->param( 'brand_dir',
        decode_utf8( abs_path( encode_utf8($brand_dir) ) ) )
        if $brand_dir;

    $self->{configfile} = $configfile;
    $self->{config}     = $config;

    my $type     = $config->param('type');
    my $xml_lang = $config->param('xml_lang');
    my $brand    = $config->param('brand');

    # don't try and load version info for brand files
    if ( $type ne 'brand' ) {
        my $info_file = "$xml_lang/$type" . '_Info.xml';
        $info_file = "$xml_lang/" . $config->param('info_file')
            if ( $config->param('info_file') );

        croak( maketext( "Can't locate required file: [_1]", $info_file ) )
            if ( !-f $info_file );

## BUGBUG DocBook specific stuff should be moved to the DocBook sub classes

        my $xml_doc = XML::TreeBuilder->new();
        eval { $xml_doc->parse_file($info_file); };

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
                croak(
                    maketext( "FATAL ERROR: [_1]: [_2]", $info_file, $@ ) );
            }
        }

        my $docname = $config->param('docname');

        eval {
            $docname
                = $xml_doc->root()->look_down( "_tag", "title" )->as_text();
        }
            unless defined($docname);
        if ($@) {
            croak maketext("title not found in Info file");
        }
        $docname =~ s/\s/_/g;

        my $product = $config->param('product');

        eval {
            $product
                = $xml_doc->root()->look_down( "_tag", "productname" )
                ->as_text();
        }
            unless defined($product);
        if ($@) {
            croak maketext("productname not found in Info file");
        }
        $product =~ s/\s/_/g;

        my $version = $config->param('version');
        eval {
            $version
                = $xml_doc->root()->look_down( "_tag", "productnumber" )
                ->as_text();
        }
            unless defined($version);
        if ($@) {
            croak maketext("productnumber not found in Info file");
        }

        my ( $edition, $release )
            = $self->get_ed_rev( { lang => $xml_lang } );

        if ( not defined( $self->{config}->param('mainfile') ) ) {
            $self->{config}->param( 'mainfile', $docname );
        }

        $self->{config}->param( 'docname', $docname );
        $self->{config}->param( 'product', $product );
        $self->{config}->param( 'version', $version );
        $self->{config}->param( 'release', $release );
        $self->{config}->param( 'edition', $edition );

        my $brand_path = $self->{config}->param('brand_dir')
            || $self->{config}->param('common_content') . "/$brand";
        $brand_path =~ s/\"//g;

        # Override publican defaults with brand defaults
        if ( -f "$brand_path/defaults.cfg"
            && ( !-z "$brand_path/defaults.cfg" ) )
        {
            my $tmp_cfg = new Config::Simple("$brand_path/defaults.cfg")
                || croak(
                maketext("Failed to load brand defaults.cfg file") );
            my %Config = $tmp_cfg->vars();
            foreach my $cfg ( keys(%Config) ) {

          # If a book key is unset or equals the publican default, Override it
                if (   ( !$self->{config}->param($cfg) )
                    or ( !defined( $PARAMS{$cfg}->{default} ) )
                    or ( $self->{config}->param($cfg) eq
                        $PARAMS{$cfg}->{default} )
                    )
                {
                    $self->{config}->param( $cfg, $Config{$cfg} );
                }
            }
        }

        # Enforce Brand Overrides
        if ( -f "$brand_path/overrides.cfg"
            && ( !-z "$brand_path/overrides.cfg" ) )
        {
            my $tmp_cfg = new Config::Simple("$brand_path/overrides.cfg")
                || croak(
                maketext("Failed to load brand overrides.cfg file") );
            my %Config = $tmp_cfg->vars();
            foreach my $cfg ( keys(%Config) ) {
                $config->param( $cfg, $Config{$cfg} );
            }
        }

        # Brand Settings
        my $brand_cfg = new Config::Simple("$brand_path/publican.cfg")
            || croak(
            maketext(
                "Failed to load brand file: [_1]",
                "$brand_path/publican.cfg"
            )
            );

        $self->{brand_config} = $brand_cfg;

        $config->param( 'ec_name', "$product $docname" )
            unless defined $config->param('ec_name');
        $config->param( 'ec_id', "org.$product.$docname" )
            unless defined $config->param('ec_id');
        $config->param( 'ec_provider', "Publican-$VERSION" )
            unless defined $config->param('ec_provider');
    }
    $DEBUG = $self->{config}->param('debug') if ( !$DEBUG );

    return;
}

=head2 _validate_config

Private method for validating configuration

=cut

sub _validate_config {
    my ( $self, $args ) = @_;

    foreach my $key ( keys(%PARAMS) ) {
        my $value = $self->{config}->param($key);

        if (( defined( $PARAMS{$key}->{not_for} ) )
            && (lc( $PARAMS{$key}->{not_for} ) eq
                lc( $self->{config}->param('type') ) )
            )
        {
            if ( defined($value) ) {
                croak(
                    maketext(
                        "Parameter [_1] is not permitted in a [_2].", $key,
                        $self->{config}->param('type')
                    )
                );
            }
            else {
                next;
            }
        }

        if ( defined $PARAMS{$key}->{constraint} ) {
            my $constraint = $PARAMS{$key}->{constraint};
            if ( defined($value) && ( $value !~ /$constraint/ ) ) {
                croak(
                    maketext(
                        "Invalid format for [_1]. Value ([_2]) does not conform to constraint ([_3])",
                        $key, $value, $constraint
                    )
                );
            }
        }
    }

    return;
}

=head2  new

Create a Publican object.

my $publican = Publican->new({debug => 1});

=head3 Parameters:

   configfile       Override Configuration file to use.
   debug            Use debug mode for messages.
   common_config    Override path to coomo configuration files.
   common_content   Override path to common content files.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;

    my $self;
    if ($SINGLETON) {
        $self = $SINGLETON;
    }
    else {
        my $configfile
            = ( delete( $args->{configfile} ) || $DEFAULT_CONFIG_FILE );
        $DEBUG = ( delete( $args->{debug} ) || $DEBUG );
        my $common_config  = delete( $args->{common_config} );
        my $common_content = delete( $args->{common_content} );
        $QUIET     = delete( $args->{QUIET} );
        $NOCOLOURS = delete( $args->{NOCOLOURS} );
        my $brand_dir = delete( $args->{brand_dir} );
        my $allow_network =  delete( $args->{allow_network} );
        my $no_clean =  delete( $args->{no_clean} );

        if ( %{$args} ) {
            croak(
                maketext(
                    "unknown arguments: [_1]",
                    join( ", ", keys %{$args} )
                )
            );
        }

        $self = bless {}, $class;
        $SINGLETON = $self;

        $self->{allow_network} = $allow_network;
        $self->{no_clean} = $no_clean;

        # BUGBUG this should be replaced by Publican::Config
        if ( $^O eq 'MSWin32' ) {
            eval { require Win32::TieRegistry; };
            croak(
                maketext(
                    "Failed to load Win32::TieRegistry module. Error: [_1]",
                    $@
                )
            ) if ($@);

            $ENV{ANSI_COLORS_DISABLED} = 1;

            my $key = new Win32::TieRegistry( "LMachine\\Software\\Publican",
                { Delimiter => "\\" } );

            if ( $key and $key->GetValue("") ) {
                if ( !$common_config ) {
                    $common_config = $key->GetValue("");
                    $common_config =~ s/\\/\//g;
                }
                $common_content = "$common_config/Common_Content"
                    if ( !$common_content );
            }

            $common_config  = qq{"$common_config"}  if ($common_config);
            $common_content = qq{"$common_content"} if ($common_content);
        }
        elsif ( $^O eq 'darwin' ) {
            if ( !$common_config ) {
                $common_config = '/opt/local/share/publican';
            }
            if ( !$common_content ) {
                $common_content = "$common_config/Common_Content";
            }
        }

        $self->_load_config(
            {   configfile     => $configfile,
                common_config  => $common_config,
                common_content => $common_content,
                brand_dir      => $brand_dir,
            }
        );

        debug_msg( maketext("config loaded") . "\n" );

        $self->_validate_config();
    }

    return $self;
}

=head2  debug_msg

Print out debugging information.

=cut

sub debug_msg {
    my ($arg) = @_;
    my ( $caller, $func, $line, @rest ) = caller(1);    # caller(0) eg
                                                        # Complete, caller(1)
                                                        # eg readline

    # bail ASAP if not debugging
    if ( !$DEBUG ) {
        return;
    }

    ($caller) = caller(0);

    #    $caller =~ s/.*:://;

    $arg  = "" unless defined $arg;
    $func = "" unless defined $func;
    $line = "" unless defined $line;

    my $rest = join "|", map { defined $_ ? $_ : "UNDEF" } @rest;

    logger( "\nDEBUG: ", RED );
    if ( 0 and $arg and ref $arg ) {
        eval { require Data::Dumper };
        if ($@) {
            logger( $arg->as_string, RED );
        }
        else {
            logger( Data::Dumper::Dumper($arg), RED );
        }
    }
    else {

##        logger( "$caller: $func, $line\n\t$arg\n", RED );
        logger( "$caller: $arg", RED );
    }

    return;
}

sub _alert {
    my ($msg) = @_;
    logger( $msg, RED );

    return;
}

=head2 param

Return the current value of a configuration parameter

$publican->param('debug');

=cut

sub param {
    my ( $self, $name ) = @_;

    return $self->{config}->param($name)
        if defined( $self->{config}->param($name) );

    return $PARAMS{$name}->{default} if defined $PARAMS{$name}->{default};

    return;
}

=head2 help_config

Display a list of config file parameters and a short description of them.

=cut

sub help_config {
    my ( $self, $name ) = @_;
    logger( maketext("Parameters used in the config file:") . "\n" );

    foreach my $param ( sort( keys(%PARAMS) ) ) {
        logger( "\t$param:\n\t\t" . $PARAMS{$param}->{descr} . "\n" );
        logger(   "\t\t"
                . maketext( "Default: [_1]", $PARAMS{$param}->{default} )
                . "\n" )
            if ( defined( $PARAMS{$param}->{default} ) );
        logger( "\t\t"
                . maketext( "Constraint: [_1]",
                $PARAMS{$param}->{constraint} )
                . "\n" )
            if ( defined( $PARAMS{$param}->{constraint} ) );

        logger("\n");
    }

    return;
}

=head2 dir_list

list all the files in a directory, and its sub-directories, matching the supplied regex.

=cut

sub dir_list {
    my ( $dir, $regex, $clean_images ) = @_;
    croak( maketext("dir is a required argument") ) unless ($dir);

    unless ( -d $dir ) {
        logger( maketext( "skipping non existent directory: [_1]", $dir ) );
        return;
    }

    croak( maketext("regex is a required argument") )
        if ( !$regex || $regex eq "" );

    my @filelist;
    my $rule = File::Find::Rule->new;

    if ( $regex =~ m/[|()]/ ) {
        $rule->file->name(qr/$regex/);
    }
    else {
        $rule->file->name($regex);
    }

    $rule->start($dir);

    my $extras = $SINGLETON->param('extras_dir');
    my $images = $SINGLETON->param('img_dir');

    while ( my $file = $rule->match ) {
        utf8::decode($file);    ## BUGBUG blowing up Archive::Tar.
        push( @filelist, $file )
            unless ( $clean_images
            and $file =~ m{(/$extras/|/icons/|$images/icon.svg)} );
    }

    return @filelist;
}

=head2 get_all_langs

Get all valid language directories.

=cut

sub get_all_langs {
    my $no_src_lang = shift;

    my ( $handle, %filelist, @langs );
    my $tmp_dir  = $SINGLETON->param('tmp_dir');
    my $xml_lang = $SINGLETON->param('xml_lang');

    opendir( $handle, '.' )
        || croak( maketext( "Can't open directory: [_1]", $@ ) );
    my @dirs = sort( readdir($handle) );
    closedir($handle);

    foreach my $dir (@dirs) {
        if ( -d $dir ) {
            next
                if ( $dir
                =~ /^(\.|\.\.|pot|$tmp_dir|xsl|\..*|CVS|publish|book_templates|trans_drop|rpm_templates)$/
                );

            if ( valid_lang($dir) ) {
                push( @langs, $dir )
                    unless ( $no_src_lang && ( $dir eq $xml_lang ) );
            }
            else {
                logger( maketext( "Skipping unknown language: [_1]", $dir )
                        . "\n" );
            }
        }
    }

    return ( join( ',', @langs ) );
}

=head2 logger

Log something, currently emits to STDOUT

TODO: consider using Log::Dispatch or similar

=cut

sub logger {
    my ( $msg, $colour ) = @_;

    return if ($QUIET);

    if ( $colour && !$NOCOLOURS ) {
        print( STDOUT $colour, $msg, RESET );
    }
    else {
        print( STDOUT $msg );
    }

    return;
}

=head2 valid_lang

Is the requested language valid according to I18N::LangTags::List

=cut

sub valid_lang {
    my $lang = shift;
    my $name = ( I18N::LangTags::List::name($lang) || '' );

    return ( I18N::LangTags::List::is_decent($lang) && ( $name ne '' ) );
}

=head2 maketext

Get localised strings

=cut

sub maketext {
    my $string = shift();
    my @params = @_;

    if ($LOCALISE) {
        return ( decode_utf8( $LOCALISE->maketext( $string, @params ) ) );
    }
    else {
        carp( RED, "Warning localisation not enabled!\n", RESET );
    }

    return ($string);
}

=head2 run_xslt

Apply the supplied xslt file to the supplied XML and return a string of the output.

=cut

sub run_xslt {
    my ( $self, $args ) = @_;
    my $xml_file = delete( $args->{xml_file} )
        || croak( maketext("xml_file is a mandatory argument") );
    my $xsl_file = delete( $args->{xsl_file} )
        || croak( maketext("xsl_file is a mandatory argument") );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $parser = XML::LibXML->new(no_network => !$self->{allow_network});
    my $xslt   = XML::LibXSLT->new();
    $parser->expand_entities(1);
    
    my $source;
    eval { $source = $parser->parse_file($xml_file); };

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
            croak( maketext( "FATAL ERROR: [_1]: [_2]", $xml_file, $@ ) );
        }
    }

    my $style_doc;
    eval { $style_doc = $parser->parse_file($xsl_file); };

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
            croak( maketext( "FATAL ERROR: [_1]: [_2]", $xsl_file, $@ ) );
        }
    }

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

        my $new_href = 'file:///D:/Data/temp/Publican/docbook-xsl-1.75.2';
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
    my $results    = $stylesheet->transform($source);
    my $value;
    eval { $value = $stylesheet->output_string($results) };

    return ($value);
}

=head2 new_tree

Create a new XML::TreeBuilder object with the required attributes for DocBook.

TODO: Make XmlClean use this.

=cut

sub new_tree {

    my $store_comments = ( shift() || 0 );
    my $noexpand = shift();

    my $xml_doc = XML::TreeBuilder->new(
        { 'NoExpand' => !$noexpand, 'ErrorContext' => "2" } );
    $xml_doc->store_pis(1);
    $xml_doc->store_cdata(1);

    my $empty_element_map = $xml_doc->_empty_element_map;
    $empty_element_map->{'xref'}       = 1;
    $empty_element_map->{'index'}      = 1;
    $empty_element_map->{'imagedata'}  = 1;
    $empty_element_map->{'area'}       = 1;
    $empty_element_map->{'ulink'}      = 1;
    $empty_element_map->{'xi:include'} = 1;

    $xml_doc->store_comments(1) if ($store_comments);

    return ($xml_doc);
}

=head2 dtd_string

Returns a valid DTD for the DocBook tag supplied.

Parameters:
	tag	 The root tag for this file
	dtdver	 The DTD version
	ent_file An entity file to include (optional)

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub dtd_string {
    my ($args) = @_;
    my $tag = delete( $args->{tag} )
        || croak( maketext("tag is a mandatory argument") );
    my $dtdver = delete( $args->{dtdver} )
        || croak( maketext("dtdver is a mandatory argument") );
    my $ent_file = delete( $args->{ent_file} );
    my $cleaning = delete( $args->{cleaning} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $uri = qq|http://www.oasis-open.org/docbook/xml/$dtdver/docbookx.dtd|;
    my $dtd_type = qq|-//OASIS//DTD DocBook XML V$dtdver//EN|;

    # TODO Maynot be necessary
    if ( $^O eq 'MSWin32' ) {
        eval { require Win32::TieRegistry; };
        croak(
            maketext(
                "Failed to load Win32::TieRegistry module. Error: [_1]", $@
            )
        ) if ($@);

        my $key = new Win32::TieRegistry( "LMachine\\Software\\Publican",
            { Delimiter => "\\" } );

        $uri = 'file:///C:/publican/DTD/docbookx.dtd';

        if ( $key and $key->GetValue("dtd_path") ) {
            $uri = 'file:///' . $key->GetValue("dtd_path") . '/docbookx.dtd';
        }

        $uri =~ s/ /%20/g;
        $uri =~ s/\\/\//g;
    }

    $dtd_type = $SINGLETON->param('dtd_type')
        if ( $SINGLETON && $SINGLETON->param('dtd_type') );
    $uri = $SINGLETON->param('dtd_uri')
        if ( $SINGLETON && $SINGLETON->param('dtd_uri') );

    my $dtd = <<DTDHEAD;
<?xml version='1.0' encoding='utf-8' ?>
<!DOCTYPE $tag PUBLIC "$dtd_type" "$uri" [
DTDHEAD

    if ( $dtdver =~ m/^5/ ) {
        # make sure docbook4 entities still work
        $dtd = <<DTDHEAD;
<?xml version='1.0' encoding='utf-8' ?>
<!DOCTYPE $tag [
DTDHEAD
    }

    # BUGBUG if we put the DB ENT first it breaks the builds ...
    my $before = 0;

    if ( $before == 1 &&  $dtdver =~ m/^5/ ) {
        # make sure docbook4 entities still work
        $dtd .= <<DTDHEAD;
<!ENTITY % sgml.features "IGNORE">
<!ENTITY % xml.features "INCLUDE">
<!ENTITY % DOCBOOK_ENTS PUBLIC "-//OASIS//ENTITIES DocBook Character Entities V4.5//EN" "http://www.oasis-open.org/docbook/xml/4.5/dbcentx.mod">
%DOCBOOK_ENTS;
DTDHEAD
    }


    # handle entity file
    if ($ent_file) {
        $dtd .= <<ENT;
<!ENTITY % BOOK_ENTITIES SYSTEM "$ent_file">
%BOOK_ENTITIES;
ENT
    }

    if ( $before == 0 &&  $dtdver =~ m/^5/ ) {
        # make sure docbook4 entities still work
        $dtd .= <<DTDHEAD;
<!ENTITY % sgml.features "IGNORE">
<!ENTITY % xml.features "INCLUDE">
<!ENTITY % DOCBOOK_ENTS PUBLIC "-//OASIS//ENTITIES DocBook Character Entities V4.5//EN" "http://www.oasis-open.org/docbook/xml/4.5/dbcentx.mod">
%DOCBOOK_ENTS;
DTDHEAD
    }


    $dtd .= <<DTDTAIL;
]>
DTDTAIL

    return ($dtd);
}

=head2  print_banned_tags

Print a list of tags that are not supported.

=cut

sub print_banned_tags {
    my $self = shift();
    print "\n"
        . maketext(
        "NOTE: These lists of tags and attributes are brand specific and are not part of Publican itself."
        ) . "\n\n";

    print "\n" . maketext("Banned tags:") . "\n";
    foreach my $key (
        sort( split( /,/, ( $self->param('banned_tags') || "" ) ) ) )
    {
        print("\t$key\n");
    }

    print "\n" . maketext("Banned attributes:") . "\n";
    foreach my $attr (
        sort( split( /,/, ( $self->param('banned_attrs') || "" ) ) ) )
    {
        print("\t$attr\n");
    }
    print "\n";

    return;
}

=head2 add_revision

Add a full entry in to the revision history.

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub add_revision {
    my ( $self, $args ) = @_;
    my $members = delete( $args->{members} )
        || croak(
        maketext( "[_1] is a required option for add_revision", 'members' ) );

    my $revnumber = delete( $args->{revnumber} );
    my $date      = delete( $args->{date} );
    my $firstname = delete( $args->{firstname} )
        || croak(
        maketext( "[_1] is a required option for add_revision", 'firstname' )
        );
    my $surname = delete( $args->{surname} )
        || croak(
        maketext( "[_1] is a required option for add_revision", 'surname' ) );
    my $email = delete( $args->{email} )
        || croak(
        maketext( "[_1] is a required option for add_revision", 'email' ) );
    my $lang = delete( $args->{lang} )
        || croak(
        maketext( "[_1] is a required option for add_revision", 'lang' ) );

    unless ($revnumber) {
        my ( $edition, $release )
            = $self->get_ed_rev( { lang => $lang, bump => 1 } );
        $revnumber = "$edition-$release";
    }

    unless ($date) {
        $date = DateTime->now()->strftime("%a %b %e %Y");
    }

    my $lc_lang = $lang;
    $lc_lang =~ s/-/_/g;
    my $locale = Publican::Localise->get_handle($lc_lang)
        || croak(
        "Could not create a Publican::Localise object for language: [_1]",
        $lang );
    $locale->encoding("UTF-8");
    $locale->textdomain("publican");

    my $revision = XML::Element->new_from_lol(
        [   'revision',
            [ 'revnumber', $revnumber ],
            [ 'date',      $date ],
            [   'author',
                [ 'firstname', $firstname ],
                [ 'surname',   $surname ],
                [ 'email',     $email ],
            ],
            [ 'revdescription', ['simplelist'], ],
        ],
    );

    my $list = $revision->root()->look_down( "_tag", 'simplelist' );
    foreach my $member ( @{$members} ) {
        my $mem = XML::TreeBuilder->new(
            {   'NoExpand'     => "1",
                'ErrorContext' => "2"
            }
        );
        $mem->parse("<member>$member</member>");
        $list->push_content($mem);
    }

    my $dtdver    = $self->param('dtdver');
    my $ent_file  = undef;
    my $main_file = $self->param('mainfile');
    if ( -e "$lang/$main_file.ent" ) {
        $ent_file = "$lang/$main_file.ent";
    }

    my $rev_file = "$lang/Revision_History.xml";
    $rev_file = "$lang/" . $self->param('rev_file')
        if ( $self->param('rev_file') );

    my $node;
    my $rev_doc = new_tree();

    if ( -f $rev_file ) {
        eval { $rev_doc->parse_file($rev_file); };

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
                croak( maketext( "FATAL ERROR: [_1]: [_2]", $rev_file, $@ ) );
            }
        }
    }
    else {
        $rev_doc->root()->tag('appendix');
        my $rev_hist = XML::Element->new_from_lol(
            [ 'title', decode_utf8( $locale->maketext('Revision History') ) ],
        );

        $rev_doc->root()->push_content($rev_hist);

        $rev_hist
            = XML::Element->new_from_lol( [ 'simpara', ['revhistory'], ], );

        $rev_doc->root()->push_content($rev_hist);
    }

    eval { $node = $rev_doc->root()->look_down( "_tag", "revhistory" ); };
    if ($@) {
        croak( maketext( "revhistory not found in [_1]", $rev_file ) );
    }

    if ( $self->param('rev_dir') && $self->param('rev_dir') =~ /^asc/i ) {
        $node->push_content($revision);
    }
    else {
        $node->unshift_content($revision);
    }

    my $OUTDOC;
    open( $OUTDOC, ">:encoding(UTF-8)", "$rev_file" )
        || croak( maketext( "Could not open [_1] for output!", $rev_file ) );
    print( $OUTDOC dtd_string(
            {   tag      => 'appendix',
                dtdver   => $dtdver,
                ent_file => $ent_file,
                cleaning => 1
            }
        )
    );
    print( $OUTDOC $rev_doc->root()->as_XML() );
    close($OUTDOC);
    $rev_doc->root()->delete();

    my $cleaner = Publican::XmlClean->new( { exclude_ent => 1 } );
    $cleaner->process_file( { file => $rev_file, out_file => $rev_file } );

    return;
}

=head2 get_ed_rev

Get the current edition (version) and release from the Revision History file.

Parameters: language, bump.

If bump is set the returned revision will increment before it's returned.

## BUGBUG this should be moved to the DocBook sub classes

=cut

sub get_ed_rev {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("'lang' is a required option for get_ed_rev") );
    my $bump = delete( $args->{bump} );

    my $rev_file = "$lang/Revision_History.xml";
    $rev_file = "$lang/" . $self->param('rev_file')
        if ( $self->param('rev_file') );

    croak( maketext( "Can't locate required file: [_1]", $rev_file ) )
        if ( !-f $rev_file );

    my $rev_doc = XML::TreeBuilder->new();
    eval { $rev_doc->parse_file($rev_file); };

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
            croak( maketext( "FATAL ERROR: [_1]: [_2]", $rev_file, $@ ) );
        }
    }

    my @revs = map { $_->as_text() }
        sort { versioncmp( $b->as_text(), $a->as_text() ) }
        ( $rev_doc->root()->look_down( "_tag", "revnumber" ) );

    my $VR = shift(@revs);

    croak(
        maketext(
            "FATAL ERROR: revnumber missing or empty, it must match the required format of '[_1]'",
            '^([0-9.]*)-([0-9.]*)$/'
        )
    ) if ( !$VR || $VR eq '' );

    $VR =~ /^([0-9.]*)-([0-9.]*)$/ || croak(
        maketext(
            "FATAL ERROR: revnumber ([_1]) does not match the required format of '[_2]'",
            $VR,
            '^([0-9.]*)-([0-9.]*)$/'
        )
    );

    my $edition = $1;
    my $release = $2;
    $release =~ s/(\d+)$/(1+$1)/e if ($bump);

    return ( ( $edition, $release ) );
}

=head2 fcopy

UTF8 escape calls to File::Copy::Recursive

=cut

sub fcopy {
    my ( $from, $to ) = @_;

    File::Copy::Recursive::fcopy( encode_utf8($from), encode_utf8($to) )
        || croak(
        maketext(
            "Can not copy file [_1] to [_2] due to error: [_3]",
            $from, $to, $@
        )
        );

    return;
}

=head2 fmove

UTF8 escape calls to File::Copy::Recursive

=cut

sub fmove {
    my ( $from, $to ) = @_;

    File::Copy::Recursive::fmove( encode_utf8($from), encode_utf8($to) )
        || croak(
        maketext(
            "Can not move file [_1] to [_2] due to error: [_3]",
            $from, $to, $@
        )
        );

    return;
}

=head2 rcopy

UTF8 escape calls to File::Copy::Recursive

=cut

sub rcopy {
    my ( $from, $to ) = @_;

    File::Copy::Recursive::rcopy( encode_utf8($from), encode_utf8($to) )
        || croak(
        maketext(
            "Can not copy files [_1] to [_2] due to error: [_3]",
            $from, $to, $@
        )
        );

    return;
}

=head2 rcopy_glob

UTF8 escape calls to File::Copy::Recursive

=cut

sub rcopy_glob {
    my ( $from, $to ) = @_;

    my @files
        = File::Copy::Recursive::rcopy_glob( encode_utf8($from),
        encode_utf8($to) )
        || croak(
        maketext(
            "Can not copy files [_1] to [_2] due to error: [_3]",
            $from, $to, $@
        )
        );

    return (@files);
}

=head2 dircopy

UTF8 escape calls to File::Copy::Recursive

=cut

sub dircopy {
    my ( $from, $to ) = @_;

    File::Copy::Recursive::dircopy( encode_utf8($from), encode_utf8($to) )
        || croak(
        maketext(
            "Can not copy directory [_1] to [_2] due to error: [_3]",
            $from, $to, $@
        )
        );

    return;
}

=head2 dirmove

UTF8 escape calls to File::Copy::Recursive

=cut

sub dirmove {
    my ( $from, $to ) = @_;

    File::Copy::Recursive::dirmove( encode_utf8($from), encode_utf8($to) )
        || croak(
        maketext(
            "Can not move directory [_1] to [_2] due to error: [_3]",
            $from, $to, $@
        )
        );

    return;
}

=head2 params_as_docbook

Returns DocBook chunks describing all the configuration options. Used to generate autodocs.

=cut

sub params_as_docbook {
    my ( $gen_list, $brand_list, $web_list ) = @_;

    foreach my $key ( sort( keys(%PARAMS) ) ) {
        my $entry = XML::Element->new_from_lol(
            [ 'varlistentry', {id => $key},[ 'term', "$key" ] ] );

        if ( defined( $PARAMS{$key}->{limit_to} )
            && $PARAMS{$key}->{limit_to} eq 'brand' )
        {
            $brand_list->push_content($entry);
        }
        elsif ( defined( $PARAMS{$key}->{limit_to} )
            && $PARAMS{$key}->{limit_to} eq 'site' )
        {
            $web_list->push_content($entry);
        }
        else {
            $gen_list->push_content($entry);
        }
        my $item = XML::Element->new_from_lol(
            [ 'listitem', [ 'para', $PARAMS{$key}->{descr} ] ] );

        $entry->push_content($item);

        if ( defined( $PARAMS{$key}->{default} ) ) {
            my $def = XML::Element->new_from_lol(
                [   'para',
                    maketext(
                        "The default value for this parameter is: [_1]",
                        $PARAMS{$key}->{default}
                    )
                ]
            );

            $item->push_content($def);
        }

        if ( defined( $PARAMS{$key}->{constraint} ) ) {
            my $constraint = XML::Element->new_from_lol(
                [   'para',
                    maketext(
                        "This parameter is constrained with the following regular expression: [_1]",
                        $PARAMS{$key}->{constraint}
                    )
                ]
            );

            $item->push_content($constraint);
        }

        if ( defined( $PARAMS{$key}->{not_for} ) ) {
            my $info = XML::Element->new_from_lol(
                [   'tip',
                    [   'para',
                        maketext(
                            "This field is not supported for: [_1].",
                            $PARAMS{$key}->{not_for}
                        )
                    ]
                ]
            );

            $item->push_content($info);
        }

        if ( defined( $PARAMS{$key}->{alert} ) ) {
            my $warn = XML::Element->new_from_lol(
                [ 'warning', [ 'para', $PARAMS{$key}->{alert} ] ] );

            $item->push_content($warn);
        }
    }

}

1;    # Magic true value required at end of module
__END__

=head1 DIAGNOSTICS

=over

=item C<< unknown args %s >>

All subs with named parameters will return this error when unexpected named arguments are provided.

=item C<< %s is a required argument >>

Any sub with a mandatory parameter will return this error if the parameter is undef.

=item C<< Config file not found: %s >>

publican can not find the named configuration file.

=item C<< Failed to load config file: %s >>

The named configuration file could not be loaded.

=item C<< Can't locate required file: %s >>

A file required for processing could not be found.

=item C<< title not found in Info file >>

The <type>_Info.xml file does not contain a title tag.

=item C<< productname not found in Info file >>

The <type>_Info.xml file does not contain a productname tag.

=item C<< productnumber not found in Info file >>

The <type>_Info.xml file does not contain a productnumber tag.

=item C<< pubsnumber not found in Info file >>

The <type>_Info.xml file does not contain a pubsnumber tag.

=item C<< Failed to load brand default config file >>

A detected defaults.cfg for the current brand could not be loaded.

=item C<< Failed to load brand overrides config file >>

A detected overrides.cfg for the current brand could not be loaded.

=item C<< Could not create a Publican::Localise object >>

Could not create a Publican::Localise object

=item C<< Can't open directory >>

=back


=head1 CONFIGURATION AND ENVIRONMENT

Publican requires no configuration files or environment variables.

=head1 DEPENDENCIES

Carp
version
Config::Simple
XML::TreeBuilder
I18N::LangTags::List
Term::ANSIColor
File::Find::Rule;
Publican::Localise;


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<publican-list@redhat.com>, or through the web interface at
L<https://bugzilla.redhat.com/bugzilla/enter_bug.cgi?product=Publican&amp;component=publican>.

=head1 AUTHOR

Jeff Fearn  C<< <jfearn@redhat.com> >>
