package Publican::Builder;

use utf8;
use strict;
use warnings;
use 5.008;
use Carp;
use Config::Simple '-strict';
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
## BUGBUG test for BZ #697363
## BUGBUG HTML::FormatText::WithLinks::AndTables requires patches from
# https://rt.cpan.org/Public/Bug/Display.html?id=63555
# https://rt.cpan.org/Public/Bug/Display.html?id=55919
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
our ( $INVALID, %LANG_MAP );
@EXPORT = qw($INVALID %LANG_MAP del_unwanted_dirs del_unwanted_xml);
@ISA    = qw(Exporter);

$INVALID = 1;

my $DEFAULT_WRAP = 82;
$columns = $DEFAULT_WRAP;

%LANG_MAP = (
    ar => 'ar-SA',
    as => 'as-IN',
    bg => 'bg-BG',
    bn => 'bn-IN',
    bs => 'bs-BA',
    ca => 'ca-ES',
    cs => 'cs-CZ',
    da => 'da-DK',
    de => 'de-DE',
    el => 'el-GR',
    en => 'en-US',
    es => 'es-ES',
    fa => 'fa-IR',
    fi => 'fi-FI',
    fr => 'fr-FR',
    gu => 'gu-IN',
    he => 'he-IL',
    hi => 'hi-IN',
    hr => 'hr-HR',
    hu => 'hu-HU',
    id => 'id-ID',
    is => 'is-IS',
    it => 'it-IT',
    ja => 'ja-JP',
    kn => 'kn-IN',
    ko => 'ko-KR',
    lv => 'lv-LV',
    ml => 'ml-IN',
    mr => 'mr-IN',
    ms => 'ms-MY',
    nb => 'nb-NO',
    nl => 'nl-NL',
    or => 'or-IN',
    pa => 'pa-IN',
    pl => 'pl-PL',
    pt => 'pt-PT',
    ru => 'ru-RU',
    si => 'si-LK',
    sk => 'sk-SK',
    sr => 'sr-Latn-RS',
    sv => 'sv-SE',
    ta => 'ta-IN',
    te => 'te-IN',
    th => 'th-TH',
    tr => 'tr-TR',
    uk => 'uk-UA',
);

=head1 NAME

Publican::Builder - A module to Convert XML to various output formats

=head1 SYNOPSIS

    use Publican::Builder;
    my $builder = Publican::Builder->new();
    $builder->clean_ids();

=head1 DESCRIPTION

Manipulate XML and convert to other formats.

=head1 INTERFACE 

=cut

=head2  new

Create a new Publican::Builder object.

=cut

sub new {
    my ( $this, $args ) = @_;
    my $class = ref($this) || $this;

    my $novalid = delete( $args->{novalid} ) || 0;

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $self = bless {}, $class;

    $self->{publican}   = Publican->new();
    $self->{translator} = Publican::Translate->new();
    $self->{validate}   = !$novalid;
    my $common_content = $self->{publican}->param('common_content');
    my $common_config  = $self->{publican}->param('common_config');
    my $brand          = $self->{publican}->param('brand');
    my $brand_path     = $self->{publican}->param('brand_dir')
        || $common_content . "/$brand";


    my $tmpl_path = Publican::ConfigData->config('rpm_templates');
    $tmpl_path = "$brand_path/rpm_templates:$tmpl_path"
        if ( -d "$brand_path/rpm_templates" );

    my $conf = { INCLUDE_PATH => $tmpl_path, };

    #    $conf->{DEBUG} = Template::Constants::DEBUG_ALL;# if ($debug);
    # create Template object
    $self->{template} = Template->new($conf) or croak( Template->error() );

    return $self;
}

=head2  build

Transform the source in to another format.

Valid formats: eclipse epub html html-single html-desktop man pdf txt

=cut

sub build {
    my ( $self, $args ) = @_;
    logger( "build should be sub-classed!" . "\n", RED );

    return;
}

=head2 del_unwanted_dirs

Callback that deletes all unwanted directories from the given directory tree. Used to delete CVS and SVN files from the working directories.

=cut

sub del_unwanted_dirs {
    my $dir      = $_;
    my @unwanted = qw(  );

    if ( $dir =~ /^(CVS|\.svn|\.git|.*\.swp|.*\.xml~|.directory)$/ ) {
        rmtree($_)
            || croak(
            maketext(
                "couldn't remove unwanted dir '[_1]', error: [_2]",
                $_, $@
            )
            );
        return;
    }
    return;
}

=head2 del_unwanted_xml

Callback that deletes all unwanted xml from the given directory tree.

=cut

sub del_unwanted_xml {
    if ( $_ =~ /\.xml$/ ) {
        unlink($_)
            || croak(
            maketext(
                "couldn't unlink xml file '[_1]', error: [_2]", $_, $@
            )
            );
        return;
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
    logger( "validate_xml should be sub-classed!" . "\n", RED );
    return;
}

=head2 package_brand

Create the structure for the distributed files and save it as a tar.gz file

=cut

sub package_brand {
    my ( $self, $args ) = @_;
    my $binary = delete( $args->{binary} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $name    = lc( $self->{publican}->param('brand') );
    my $version = $self->{publican}->param('version');
    my $release = $self->{publican}->param('release');

    my $tardir = "publican-$name-$version";
    mkpath("$tmp_dir/tar/$tardir");
    mkpath("$tmp_dir/rpm");

    my $langs     = get_all_langs();
    my @file_list = (
        'publican.cfg', "publican-$name.spec",
        'README',       'COPYING',
        'defaults.cfg', 'overrides.cfg'
    );

    foreach my $file (@file_list) {
        rcopy( $file, "$tmp_dir/tar/$tardir/." ) if ( -f $file );
    }

    foreach my $dir ( split( /,/, $langs ),
        'pot', 'xsl', 'book_templates', 'rpm_templates' )
    {
        dircopy( "$dir", "$tmp_dir/tar/$tardir/$dir" ) if ( -d $dir );
    }

    my $dir = pushd("$tmp_dir/tar");
    finddepth( \&del_unwanted_dirs, $tardir );
    my @files = dir_list( $tardir, '*' );
    Archive::Tar->create_archive( "$tardir.tgz", 9, @files );
    $dir = undef;

    fmove( "$tmp_dir/tar/$tardir.tgz", "$tmp_dir/rpm/." );

    $self->build_rpm( { spec => "publican-$name.spec", binary => $binary } );

    return;
}

=head2 package_home

Package a book for use as a Publican Website home page.

=cut

sub package_home {
    my ( $self, $args ) = @_;

    my $binary = delete( $args->{binary} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $tmp_dir    = $self->{publican}->param('tmp_dir');
    my $product    = $self->{publican}->param('product');
    my $version    = $self->{publican}->param('version');
    my $docname    = $self->{publican}->param('docname');
    my $edition    = $self->{publican}->param('edition');
    my $configfile = $self->{publican}->param('configfile');
    my $release    = $self->{publican}->param('release');
    my $xml_lang   = $self->{publican}->param('xml_lang');
    my $type       = $self->{publican}->param('type');
    my $web_type   = $self->{publican}->param('web_type') || 'home';
    my $web_dir    = $self->{publican}->param('web_dir')
        || '%{_localstatedir}/www/html/docs';
    my $name_start = "$docname";
    $name_start = "$product-$docname"          if ( $web_type eq 'product' );
    $name_start = "$product-$docname-$version" if ( $web_type eq 'version' );

    my $tardir = "$name_start-web-$web_type-$edition";

    mkpath("$tmp_dir/tar/$tardir");
    mkpath("$tmp_dir/rpm");

    my $langs     = get_all_langs();
    my @file_list = qw(publican.cfg site_overrides.css);

    foreach my $file (@file_list) {
        rcopy( $file, "$tmp_dir/tar/$tardir/." ) if ( -f $file );
    }

    foreach my $dir ( split( /,/, $langs ), 'pot' ) {
        dircopy( "$dir", "$tmp_dir/tar/$tardir/$dir" ) if ( -d $dir );
    }

    my $dir = pushd("$tmp_dir/tar");
    finddepth( \&del_unwanted_dirs, $tardir );
    my @files = dir_list( $tardir, '*' );
    Archive::Tar->create_archive( "$tardir-$release.tgz", 9, @files );
    $dir = undef;

    fmove( "$tmp_dir/tar/$tardir-$release.tgz", "$tmp_dir/rpm/." );

    my $common_config = $self->{publican}->param('common_config');
    my $xsl_file      = $common_config . "/xsl/web-home-spec.xsl";
    $xsl_file =~ s/"//g;    # windows

    my $license = $self->{publican}->param('license');
    my $brand   = 'publican-' . lc( $self->{publican}->param('brand') );
    my $doc_url = $self->{publican}->param('doc_url');
    my $src_url = $self->{publican}->param('src_url');
## BUGBUG for home pages we need to use $xml_lang/Rev... NOT $tmp/$lang/...
    my $log = $self->change_log( { lang => $xml_lang } );
    my $embedtoc = '--embedtoc';

    $embedtoc = "" if ( $self->{publican}->param('no_embedtoc') );

    my %xslt_opts = (
        'book-title' => $name_start,
        'brand'      => $brand,
        'prod'       => $product,
        'prodver'    => $version,
        'rpmver'     => $edition,
        'rpmrel'     => $release,
        'docname'    => $docname,
        'license'    => $license,
        'url'        => $doc_url,
        'src_url'    => $src_url,
        'log'        => $log,
        tmpdir       => $tmp_dir,
        web_dir      => $web_dir,
        web_type     => $web_type,
        spec_version => $Publican::SPEC_VERSION,
        embedtoc     => $embedtoc,
    );

    logger(
        "\t" . maketext( "Using XML::LibXSLT on [_1]", $xsl_file ) . "\n" );

    my $parser    = XML::LibXML->new();
    my $xslt      = XML::LibXSLT->new();
    my $info_file = "$xml_lang/$type" . '_Info.xml';
    $info_file = "$xml_lang/" . $self->{publican}->param('info_file')
        if ( $self->{publican}->param('info_file') );

    my $source    = $parser->parse_file($info_file);
    my $style_doc = $parser->parse_file($xsl_file);

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    my $results = $stylesheet->transform( $source,
        XML::LibXSLT::xpath_to_string(%xslt_opts) );

    my $outfile;
    my $spec_name = "$tmp_dir/rpm/$name_start-web-$web_type.spec";

    open( $outfile, ">:encoding(UTF-8)", "$spec_name" )
        || croak( maketext( "Can't open spec file: [_1]", $@ ) );
    print( $outfile $stylesheet->output_string($results) );
    close($outfile);

    $self->build_rpm(
        {   spec   => "$tmp_dir/rpm/$name_start-web-$web_type.spec",
            binary => $binary
        }
    );

    return;
}

=head2 build_rpm

Build an srpm for books and brands.

=cut

sub build_rpm {
    my ( $self, $args ) = @_;

    my $spec = delete( $args->{spec} )
        || croak( maketext("spec is a mandatory argument") );
    my $binary = delete( $args->{binary} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    my $tmp_dir = $self->{publican}->param('tmp_dir');
    my $os_ver  = $self->{publican}->param('os_ver');

    my $dir = abs_path("$tmp_dir/rpm");

    # From cspanspec and Fedora Makefile.common
    my $rpmbuild
        = ( -x "/usr/bin/rpmbuild" ? "/usr/bin/rpmbuild" : "/bin/rpm" );

    unless ( -x $rpmbuild ) {
        logger( maketext("rpmbuild not found, rpm creation aborted.") . "\n",
            RED );
        return;
    }

    debug_msg(
        maketext( "Building rpms from [_1] using [_2] in [_3]",
            $spec, $rpmbuild, $dir )
            . "\n"
    );

    my @rpm_args = (
        "--define", "_sourcedir $dir", "--define", "_builddir $dir",
        "--define", "_srcrpmdir $dir", "--define", "_rpmdir $dir"
    );

    if ($binary) {
        push( @rpm_args, "-ba" );
    }
    else {
        push( @rpm_args, "-bs", "--nodeps" );
    }

    if ($os_ver) {
        $os_ver = ".$os_ver" unless ( $os_ver =~ m/^\./ );
        push( @rpm_args, "--define", "dist $os_ver" );
    }

    push( @rpm_args, $spec );

    if ( system( $rpmbuild, @rpm_args ) != 0 ) {
        if ( $? == -1 ) {
            croak maketext( "Failed to execute [_1], error number: [_2]",
                $rpmbuild, $! )
                . "\n";
        }
        elsif ( WIFSIGNALED($?) ) {
            croak maketext( "[_1] died with signal [_2]",
                $rpmbuild, WTERMSIG($?) )
                . "\n";
        }
        else {
            croak maketext( "[_1] exited with value [_2]",
                $rpmbuild, WEXITSTATUS($?) )
                . "\n";
        }
    }

    return;
}

=head2 package

Create the structure for the distributed files and save it as a tar.gz file

Creates RPM Specfile and build SRPM.

TODO: Consider handling other package formats, deb etc.

=cut

sub package {
    my ( $self, $args ) = @_;

    my $lang = delete( $args->{lang} )
        || croak( maketext("lang is a mandatory argument") );
    my $desktop       = delete( $args->{desktop} )       || 0;
    my $short_sighted = delete( $args->{short_sighted} ) || 0;
    my $binary        = delete( $args->{binary} );

    if ( %{$args} ) {
        croak(
            maketext(
                "unknown arguments: [_1]", join( ", ", keys %{$args} )
            )
        );
    }

    croak(
        maketext(
            "Short-sighted packages can only be used to make desktop rpms. Add --desktop to your argument list."
        )
    ) if ( $short_sighted and not $desktop );

    my $tmp_dir           = $self->{publican}->param('tmp_dir');
    my $product           = $self->{publican}->param('product');
    my $version           = $self->{publican}->param('version');
    my $docname           = $self->{publican}->param('docname');
    my $edition           = $self->{publican}->param('edition');
    my $configfile        = $self->{publican}->param('configfile');
    my $release           = $self->{publican}->param('release');
    my $xml_lang          = $self->{publican}->param('xml_lang');
    my $type              = $self->{publican}->param('type');
    my $web_formats_comma = $self->{publican}->param('web_formats');
    my $web_formats       = $web_formats_comma;
    my $embedtoc          = '--embedtoc';

    $embedtoc = "" if ( $self->{publican}->param('no_embedtoc') );

    $web_formats =~ s/,/ /g;
    my $book_src_lang = undef;

    if ( $lang ne $xml_lang ) {
	$book_src_lang = $xml_lang;

        $release = undef;
## BUGBUG this should be moved to the DocBook sub classes
        my $rev_file = "$lang/Revision_History.xml";
        $rev_file = "$lang/" . $self->{publican}->param('rev_file')
            if ( $self->{publican}->param('rev_file') );

        croak( maketext( "Can't locate required file: [_1]", $rev_file ) )
            if ( !-f $rev_file );

        my $rev_doc = XML::TreeBuilder->new(
            { 'NoExpand' => "1", 'ErrorContext' => "2" } );
        $rev_doc->parse_file($rev_file);
        my $VR = eval {
            $rev_doc->root()->look_down( "_tag", "revnumber" )->as_text();
        };
        if ($@) {
            croak( maketext( "revnumber not found in [_1]", $rev_file ) );
        }

        $VR =~ /^([0-9.]*)-([0-9.]*)$/ || croak(
            maketext(
                "revnumber ([_1]) does not match the required format of '[_2]'",
                $VR,
                '^([0-9.]*)-([0-9.]*)$/'
            )
        );

        $edition = $1;
        $release = $2;
    }

    my $name_start = "$product-$docname-$version";
    $name_start = "$product-$docname" if ($short_sighted);

    my $tardir = "$name_start-web-$lang-$edition";
    $tardir = "$name_start-$lang-$edition" if ($desktop);
    $tardir = "$name_start-$lang-$edition" if ($short_sighted);

    # distributed sets need to be collected before packaging
    if ( ( $type eq 'Set' ) && ( $self->{publican}->{config}->param('scm') ) )
    {
        $self->get_books();
        $self->build_set_books( { langs => $lang } );
    }

    $self->setup_xml( { langs => $lang, cleaning => 1 } );

    mkpath("$tmp_dir/tar/$tardir");
    dircopy( "$tmp_dir/$lang/xml", "$tmp_dir/tar/$tardir/$lang" );
    rmtree("$tmp_dir/tar/$tardir/$lang/Common_Content");
    mkpath("$tmp_dir/rpm");

    dircopy( "$xml_lang/icons", "$tmp_dir/tar/$tardir/$lang/icons" )
        if ( -e "$xml_lang/icons" );
    dircopy( "$lang/icons", "$tmp_dir/tar/$tardir/$lang/icons" )
        if ( -e "$lang/icons" );
    finddepth( \&del_unwanted_dirs, "$tmp_dir/tar/$tardir/$lang/icons" )
        if ( -e "$tmp_dir/tar/$tardir/$lang/icons" );

    dircopy( "$xml_lang/files", "$tmp_dir/tar/$tardir/$lang/files" )
        if ( -e "$xml_lang/files" );
    dircopy( "$lang/files", "$tmp_dir/tar/$tardir/$lang/files" )
        if ( -e "$lang/files" );
    finddepth( \&del_unwanted_dirs, "$tmp_dir/tar/$tardir/$lang/files" )
        if ( -e "$tmp_dir/tar/$tardir/files" );

    $self->{publican}->{config}->param( 'xml_lang', $lang );

    # Need to remove scm from packaged set to avoid fetching from repo
    my $tmp_scm = undef;

    if ( $type eq 'Set' && $self->{publican}->{config}->param('scm') ) {
        $tmp_scm = $self->{publican}->{config}->param('scm');
        $self->{publican}->{config}->delete('scm');
    }

    my $common_config = $self->{publican}->param('common_config');
    my $xsl_file      = $common_config . "/xsl/web-spec.xsl";
    $xsl_file = $common_config . "/xsl/dt_htmlsingle_spec.xsl" if ($desktop);
    $xsl_file =~ s/"//g;    # windows
    my $license       = $self->{publican}->param('license');
    my $brand         = lc( $self->{publican}->param('brand') );
    my $doc_url       = $self->{publican}->param('doc_url');
    my $src_url       = $self->{publican}->param('src_url') || "";
    my $dt_obsoletes  = $self->{publican}->param('dt_obsoletes') || "";
    my $dt_requires   = $self->{publican}->param('dt_requires') || "";
    my $web_obsoletes = $self->{publican}->param('web_obsoletes') || "";
    my $translation   = ( $lang ne $xml_lang );
    my $language      = code2language( substr( $lang, 0, 2 ) );

    my ( $web_product_label, $web_version_label, $web_name_label )
        = $self->web_labels( { lang => $lang, xml_lang => $xml_lang } );

    my $web_dir = $self->{publican}->param('web_dir')
        || '%{_localstatedir}/www/html/docs';
    my $web_cfg = $self->{publican}->param('web_cfg')
        || Publican::ConfigData->config('etc') . '/publican-website.cfg';
    my $web_req    = $self->{publican}->param('web_req')    || '';
    my $sort_order = $self->{publican}->param('sort_order') || '';

    my $menu_category = $self->{publican}->param('menu_category')
        || "X-Red-Hat-Base;";
    $menu_category =~ s/__LANG__/$lang/g;
    $menu_category .= ';' if ( $menu_category !~ /;\s*$/ );

    # store lables for rebuilding translated content
    $self->{publican}->{config}
        ->param( 'web_product_label', $web_product_label )
        if ($web_product_label);
    $self->{publican}->{config}
        ->param( 'web_version_label', $web_version_label )
        if ($web_version_label);
    $self->{publican}->{config}->param( 'web_name_label', $web_name_label )
        if ($web_name_label);

    $self->{publican}->{config}->param( 'release', $release );

    # don't override these
    $self->{publican}->{config}->delete('common_config');
    my $common_content = $self->{publican}->param('common_content');
    $self->{publican}->{config}->delete('common_content');
    $self->{publican}->{config}->delete('release');
    $self->{publican}->{config}->delete('edition');
    $self->{publican}->{config}->delete('brand_dir');
    $self->{publican}->{config}->delete('cover_image');

    $self->{publican}->{config}->write("$tmp_dir/tar/$tardir/publican.cfg");

    $self->{publican}->{config}->param( 'common_config',  $common_config );
    $self->{publican}->{config}->param( 'common_content', $common_content );
    $self->{publican}->{config}->param( 'xml_lang',       $xml_lang );
    $self->{publican}->{config}->param( 'scm',     $tmp_scm ) if ($tmp_scm);
    $self->{publican}->{config}->param( 'release', $release );
    $self->{publican}->{config}->param( 'edition', $edition );


    my $dir = pushd("$tmp_dir/tar");
    my @files = dir_list( $tardir, '*' );
    Archive::Tar->create_archive( "../rpm/$tardir-$release.tgz", 9, @files );

    $dir = undef;

    my $log = $self->change_log( { lang => $lang } );

## BUGBUG this should be moved to the DocBook sub classes
    my $full_abstract = $self->get_abstract( { lang => $lang } );
    $full_abstract =~ s/\p{Z}+/ /g;

    # Wrap description for RPM style requirements
    $columns = 68;
    my $abstract = fill( "", "", $full_abstract );
    $columns = $DEFAULT_WRAP;

    # Escape single quotes to prevent bash breaking
    $full_abstract =~ s/"/\\"/g;

## BUGBUG this should be moved to the DocBook sub classes
    my $full_subtitle = $self->get_subtitle( { lang => $lang } );
    $full_subtitle =~ s/"/\\"/g;
    $full_subtitle =~ s/\p{Z}+/ /g;
    chomp($full_subtitle);

    my %vars = (
        book_title        => $name_start,
        lang              => $lang,
        prod              => $product,
        prodver           => $version,
        rpmver            => $edition,
        rpmrel            => $release,
        docname           => $docname,
        license           => $license,
        brand             => "publican-$brand",
        url               => $doc_url,
        src_url           => $src_url,
        'log'             => $log,
        dt_obsoletes      => $dt_obsoletes,
        dt_requires       => $dt_requires,
        web_obsoletes     => $web_obsoletes,
        translation       => $translation,
        language          => $language,
        abstract          => $abstract,
        tmpdir            => $tmp_dir,
        ICONS             => ( -e "$xml_lang/icons" ? 1 : 0 ),
        product_label     => $web_product_label,
        version_label     => $web_version_label,
        name_label        => $web_name_label,
        web_dir           => $web_dir,
        web_cfg           => $web_cfg,
        web_req           => $web_req,
        full_abstract     => $full_abstract,
        full_subtitle     => $full_subtitle,
        web_formats       => $web_formats,
        web_formats_comma => $web_formats_comma,
        menu_category     => $menu_category,
        spec_version      => $Publican::SPEC_VERSION,
        embedtoc          => $embedtoc,
        sort_order        => $sort_order,
	book_version      => "$edition-$release",
	book_src_lang     => $book_src_lang,
        img_dir           => $self->{publican}->param('img_dir'),
    );

    # \p{Z} is unicode white space, which is a super set of ascii white space.
    if ( $full_abstract !~ /[^\p{Z}]/ ) {
        logger(
            maketext(
                "WARNING: You can not create RPM packages with a blank abstract. Skipping RPM creation.\n"
            ),
            RED
        );
        return;
    }

    if ( $full_subtitle !~ /[^\p{Z}]/ ) {
        logger(
            maketext(
                "WARNING: You can not create RPM packages with a blank subtitle. Skipping RPM creation.\n"
            ),
            RED
        );
        return;
    }

    my $spec_name = "$tmp_dir/rpm/$name_start-web-$lang.spec";
    $spec_name = "$tmp_dir/rpm/$name_start-$lang.spec"
        if ( $desktop or $short_sighted );
   
    $self->{template}->process(
        'spec.tmpl', \%vars,
        $spec_name,
        binmode => ':encoding(UTF-8)'
    ) or croak( $self->{template}->error() );

    $self->build_rpm( { spec => $spec_name, binary => $binary } );

    return;
}

=head2 web_labels

Determine if the labels use in the web navigation are different from the names used for packaging.

This should be sub-classed.

=cut

sub web_labels {
    my ( $self, $args ) = @_;
    logger( "web_labels should be sub-classed!\n", RED );
    return;
}

=head2 setup_xml

Create the proper directory structure for the XML, including copying in Brand files.

This should be sub-classed.

=cut

sub setup_xml {
    my ( $self, $args ) = @_;
    logger( "setup_xml should be sub-classed!" . "\n", RED );
    return;
}

=head2 clean_ids

Travers over the source XML and update the id's to match the standard format.

Updates all existing PO files with the new xref links.

This should be sub-classed.

=cut

sub clean_ids {
    my ( $self, $args ) = @_;
    logger( "clean_ids should be sub-classed!" . "\n", RED );
    return;
}

=head2 change_log

Generate an RPM style change log from $xml_lang/Revision_History.xml

This should be sub-classed.

=cut

sub change_log {
    my ( $self, $args ) = @_;
    logger( "change_log should be sub-classed!" . "\n", RED );

    return;
}

=head2 get_books

Fetch all the books for a set from a repo.

Supported Repos: SVN

=cut

sub get_books {
    my ( $self, $args ) = @_;

    my $scm = ( lc( $self->{publican}->param('scm') ) || "" );

    unless ($scm) {
        logger(
            maketext(
                "Config parameter 'scm' not found; treating set as standalone."
                )
                . "\n",
            RED
        );
        return;
    }

    croak( maketext( "Unknown set SCM: [_1]", $scm ) )
        unless ( $scm =~ /^(svn|svn)$/ );

    my $books = $self->{publican}->param('books')
        || croak(
        maketext(
            "'books' is a required configuration parameter for a remote set")
            . "\n"
        );
    my $repo = $self->{publican}->param('repo')
        || croak(
        maketext(
            "'repo' is a required configuration parameter for a remote set")
            . "\n"
        );

    foreach my $book ( split( " ", $books ) ) {
        if ( !-d $book ) {
            logger( maketext( "Fetching [_1] from scm", $book ) . "\n" );
            if ( $scm eq 'svn' ) {
                debug_msg(
                    "TODO: should be using Alien::SVN or similar to access SVN!\n"
                );
                if ( system("svn export --quiet $repo/$book $book") != 0 ) {
                    croak(
                        maketext(
                            "Fatal Error: SVN export failed. Book: [_1]. Error Number: [_2]",
                            $book,
                            $?
                        )
                    );
                }
            }
        }
    }

    return;
}

=head2 build_set_books

Prepare XML from sub books for Remote Sets

=cut

sub build_set_books {
    my ( $self, $args ) = @_;

    my $langs = delete( $args->{langs} )
        || croak( maketext("langs is a mandatory argument") );

    if ( %{$args} ) {
        croak( maketext( "unknown args: " . join( ", ", keys %{$args} ) ) );
    }

    my $books = $self->{publican}->param('books')
        || croak(
        maketext(
            "'books' is a required configuration parameter for a remote set")
        );
    my $tmp_dir = $self->{publican}->param('tmp_dir');

    foreach my $book ( split( " ", $books ) ) {
        logger( maketext( "Start building [_1]", $book ) . "\n" );
        my $dir = pushd($book);

        logger(
            maketext("Running clean_ids to prevent inter-book ID clashes.")
                . "\n" );

        if ( system("publican clean_ids") != 0 ) {
            croak(
                maketext(
                    "Fatal error: Book failed to run clean_ids! Book: [_1]. Error Number: [_2]",
                    $book,
                    $?
                )
            );
        }

        if (system(
                "publican build --formats=xml --langs=$langs --distributed_set"
            ) != 0
            )
        {

            # build failed
            croak(
                maketext(
                    "Fatal error: Book failed to build! Book: [_1]. Error Number: [_2]",
                    $book,
                    $?
                )
            );
        }

        $dir = undef;

        foreach my $lang ( split( /,/, $langs ) ) {
            dirmove(
                "$book/$tmp_dir/$lang/xml/images",
                "$tmp_dir/$lang/xml/images/$book/images"
            );
            dircopy( "$book/$tmp_dir/$lang/xml", "$tmp_dir/$lang/xml/$book" );
        }
        logger( maketext( "Finish building [_1]", $book ) . "\n" );
    }

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
Config::Simple
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
