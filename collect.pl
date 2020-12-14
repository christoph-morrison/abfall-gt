#! /usr/bin/env perl
#
######################################################################  Pragmas
use strict;
use warnings FATAL => 'all';
use feature 'unicode_strings';
use utf8;
use 5.026;

#
###################################################################### Built-in libraries
use Carp;
use Encode qw( decode_utf8 encode_utf8 );

#
###################################################################### Libraries
use Readonly;
use HTTP::Tiny;
use Data::Dumper;
use URL::Encode;
use DBI;
use DBD::MariaDB;
use iCal::Parser;
use Config::IniFiles;


Readonly my $base_uri           => q();
Readonly my $id_street_re       => qr{ <option\svalue="(?<id>[^"]+)[^>]*>(?<street>[^<]+)<\/option> }xs;
Readonly my $year_re            => qr{ <option\s>(?<year>20\d{2})</option> }xs;
Readonly my $env                => q{development};
Readonly my $skip_ical_fetch    => 1;
Readonly my $verbose            => 1;

my ($db_handle, $html, %streets, @available_years, $config, $db_config);

#
###################################################################### Main
get_calendar_data();

#
###################################################################### Functions
sub translate_summary_2_collection_id {
    my $summary     = shift // return q{unknown};
    my $re_index    = undef;
    my $collection_id = undef;

    $summary = decode_utf8($summary);

    my %collection_id_re = (
        1 => qr{^Restmüll\s*14-tgl.$},
        2 => qr{^Restmüll\s*4-wö.$},
        3 => qr{^Kompost$},
        4 => qr{^Altpapier$},
        5 => qr{^Gelber Sack$},
        6 => qr{^Saisonkompost$},
    );

    for  $re_index (sort keys %collection_id_re) {
        my $re = $collection_id_re{$re_index};
        $collection_id =  $re_index if ($summary =~ $re);
        last if $collection_id;
    }

    return $collection_id;
}

sub get_street_listing {
    my $base_uri = $config->val($env, q{base_uri});

    my $response = HTTP::Tiny->new->get($base_uri);

    if ($response->{success}) {
        $html = $response->{content};
    }

    croak qq{Request to $base_uri failed: $response->{content} ($response->{reason})} unless $response->{success};
}

sub get_available_streets {
    if (!$html) {
        get_street_listing();
    }

    while ( $html =~ /$id_street_re/g ) {
        $streets{$+{id}} = _fix_street_name($+{street});
    }
}

sub get_available_years {
    if (!$html) {
        get_street_listing();
    }

    while ( $html =~ /$year_re/g ) {
        push @available_years, $+{year};
    }
}

sub get_calendar_data {
    if (!$db_handle) {
        $db_handle = db_connect();
    }

    if (!%streets) {
        get_available_streets();
    }

    if (!@available_years) {
        get_available_years()
    }

    my $temp_dir = $config->val($env, q{temp_dir});

    for my $street_id (sort keys %streets) {
        _insert_street($street_id, $streets{$street_id});
        for my $year (@available_years) {
            my  $outfile = qq{$temp_dir/$street_id-$year.ics};
            _fetch_ical_file($street_id, $year, $outfile, [0..5]) if (not defined $skip_ical_fetch);
            if (! -s $outfile) {
                say STDERR qq{$outfile does not exist for $street_id};
                next;
            }
            _parse_ical_data($outfile, $street_id)
        }
    }
}

sub read_config {
    $db_config = Config::IniFiles->new(
        -file       => q{./config/db.ini},
        -default    => q{general}
    );

    $config = Config::IniFiles->new(
        -file       => q{./config/collect.ini},
        -default    => q{general}
    );

    return $db_config;
}

sub db_connect {
    if (!$config || !$db_config) {
        read_config();
    };

    my $dsn = sprintf(
        q{dbi:%s:database=%s;host=%s;port=%s},
        $db_config->val($env, q{driver}),
        $db_config->val($env, q{database}),
        $db_config->val($env, q{host}),
        $db_config->val($env, q{port}),
    );

    if (!DBI->parse_dsn($dsn)) {
        croak qq{Can't parse DSN '$dsn'.};
    }

    my $handle = DBI->connect(
        $dsn, $db_config->val($env, q{user}), $db_config->val($env, q{password}),
        {
            RaiseError => 1,
            PrintError => 0
        }
    ) or croak $DBI::errstr;

    return $handle;
}

#
###################################################################### Helper function
sub _fix_street_name {
    my $street_name = decode_utf8 shift;

    # ucfirst word by word
    $street_name =~ s/(\w+)/ucfirst lc $1/eg;

    # expand [Ss]tr.
    $street_name =~ s/([Ss])tr\./$1traße/g;

    # reset -Von- to -von-
    $street_name =~ s/-Von-/-von-/g;

    # lowercase Dem/Den/Der, Ab, Ohne, Nur, Bis, Grossen
    $street_name =~ s/\b(De[mnr]|Ab|Ohne|Nur|Bis|Grossen)\b/lc $1/eg;

    return $street_name;
}

sub _insert_street {
    my ($street_id, $street_name) = @_;

    $verbose && say Data::Dumper->Dump(
        [ $street_id, $street_name ],
        [qw( street_id street_name )]
    );

    $db_handle->do(
        q{REPLACE INTO `streets` VALUES(?, ?)},
        undef,
        $street_id,
        $street_name,
    );

    if ($db_handle->err()) {
        die q{Insert failed: }, $db_handle->errstr();
    }
}

sub _parse_ical_data {
    my $file        = shift;
    my $street_id   = shift;
    my $ics_parser  = iCal::Parser->new();
    my $hash        = $ics_parser->parse($file);

    for my $event ($hash->{events}) {
        # say Data::Dumper->Dump( [ $event ], [qw( event )] );
        for my $year (sort keys %{$event} ) {
            say "+ Found year $year";

            for my $month (sort keys %{$event->{$year}} ) {
                say " +- Found month $month";

                for my $day (sort keys %{$event->{$year}->{$month}} ) {
                    say "  +- Found day $day";

                    for my $uuid (sort keys %{$event->{$year}->{$month}->{$day}} ) {
                        my $event_details = $event->{$year}->{$month}->{$day}->{$uuid};

                        my $translated_collection_id = translate_summary_2_collection_id($event_details->{SUMMARY});

                        if (!$translated_collection_id) {
                            say qq($event_details->{SUMMARY} can't be translated ($uuid));
                            sleep 5000;
                            next;
                        }

                        say Data::Dumper->Dump(
                            [ $uuid, $event_details->{SUMMARY}, $event_details->{DTSTART}->stringify(), $translated_collection_id, $street_id ],
                            [qw( UUID Summary Start Collection_ID Street_ID )] );

                        $db_handle->do(
                            q{REPLACE INTO `appointments` VALUES(?, ?, ?, ?)},
                            undef,
                            $uuid,
                            $event_details->{DTSTART},
                            $street_id,
                            $translated_collection_id,
                        );

                        if ($db_handle->err()) {
                            say q{Insert failed: }, $db_handle->errstr();
                        }
                    }
                }
            }
        }
    }
}

sub _fetch_ical_file {
    my ($street_id, $year, $outfile, $collection_ids) = @_;

    my  $url     =
        sprintf q(%s/downloadfile.jsp;jsessionid=123foobar--jK.srv31452?format=%s&strasse=%d&ort=%s&jahr=%d&%s),
            $base_uri,                                                  # basis adresse
            q(ics),                                                     # format
            $street_id,                                                 # strasse
            URL::Encode::url_encode_utf8(q(Gütersloh)),                 # ort
            $year,                                                      # jahr
            join q(&), map { qq{fraktion=$_} } @{$collection_ids}       # fraktionen
        ;

    my $http_ics_request = HTTP::Tiny->new;
    $http_ics_request->mirror($url, $outfile);
}

