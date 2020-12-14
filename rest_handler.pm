use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use utf8;
use Encode;
use DBI;
use DBD::MariaDB;
use Config::IniFiles;
use 5.026;

my ($config, $db_handle, $env, $debug);
$env = q{development};

sub read_config {
    my $db_config = Config::IniFiles->new(
        -file => q{./config/db.ini},
    );

    return $db_config;
}

sub db_connect {
    if (!$config) {
        $config = read_config();
    };

    my $dsn = sprintf(
        q{dbi:%s:database=%s;host=%s;port=%s},
        $config->val($env, q{driver}),
        $config->val($env, q{database}),
        $config->val($env, q{host}),
        $config->val($env, q{port}),
    );

    if (!DBI->parse_dsn($dsn)) {
        croak qq{Can't parse DSN '$dsn'.};
    }

    my $handle = DBI->connect(
        $dsn, $config->val($env, q{user}), $config->val($env, q{password}),
        {
            RaiseError => 1,
            PrintError => 0
        }
    ) or croak $DBI::errstr;

    return $handle;
}

$db_handle = db_connect();

sub _get_param {
    my $params  = shift;
    my $key     = shift || return undef;
    my $filter  = shift;

    return undef if !defined $params->{$key};
    say "$key found!";

    my $value = $params->{$key};

    say Data::Dumper->Dump( [ $value ], [qw( found_value_for_$key )] );

    if ($value !~ $filter) {
        say Data::Dumper->Dump( [ q{data not valid}, $filter, $value, $key ], [qw( msg filter value key )] );
        return undef;
    }

    return $value;
}

sub get_param {
    return _get_param(@_);
}

sub get_param_id {
    my ($params) = shift;
    return _get_param($params, q{id}, qr{^\d+$}xms);
}

sub get_param_bool {
    my ($params, $key) = @_;
    my $bool = _get_param($params, $key, qr{^(1|0|true|false)$}xms);
    return undef if not defined $bool;
    return 0 if ( $bool =~ qr{^(0|false)$});
    return 1 if ( $bool =~ qr{^(1|true)$});
}

sub get_param_ts {
    my ($params, $key) = @_;
    return _get_param($params, $key, qr{^\d+$}xms);
}

get q{/version} => sub {
    return { version => q{0.0.1} };
};

get q{/cities} => sub {
    my $cities = $db_handle->selectall_arrayref(
        "SELECT id, name FROM cities ORDER BY id",
        { Slice => {} }
    );

    return $cities;
};

get q{/collection/types} => sub {
    my $collection_types = $db_handle->selectall_arrayref(
        q{SELECT * FROM collections ORDER BY id},
        { Slice => {} }
    );

    return $collection_types
};

get q{/city/by/id} => sub {
    my $request_params = shift;

    # id is mandatory
    my $city_id  = get_param_id($request_params);
    if (not defined $city_id) {
        return {
            error => q{Param 'id' is not valid.},
            dump => Dumper($request_params->{id}),
        };
    }

    if (defined $city_id) {
        my $cities = $db_handle->selectrow_hashref(
            "SELECT id AS 'id', 'name' AS 'name' FROM cities WHERE id = '$city_id' ORDER BY id",
            { Slice => {} }
        );

        if ($cities) {
            return $cities;
        }
    }

    return {};
};

get q{/streets/by/city/id} => sub {
    my $request_params = shift;

    # id is mandatory
    my $city_id  = get_param_id($request_params);
    if (not defined $city_id) {
        return {
            error => q{Param 'id' is not valid.},
            dump => Dumper($request_params->{id}),
        };
    }

    if (defined $city_id) {
        my $streets = $db_handle->selectall_arrayref(
            qq{SELECT * FROM streets ORDER BY id ASC},
            { Slice => {} }
        );

        if ($streets) {
            return $streets;
        }
    }

    return {};
};

get q{/appointments/by/street/id} => sub {
    my $request_params      = shift;
    my ($time_start, $time_end, $next_seconds, $verbose, $verbose_streets, $verbose_collection, $collection_id);
    my ($sql_period_particles, $sql_verbose_particles, @conditions, @verbose_conditions, @select_fields);

    # check params
    # id (street_id) is mandatory
    my $street_id  = get_param_id($request_params);
    if (not defined $street_id) {
        return {
            error => q{Param 'id' is not valid.},
            dump => Dumper($request_params->{id}),
        };
    }

    if (defined $request_params->{collection_id}) {
        $collection_id = get_param($request_params, q{collection_id}, qr{^\d+$});
        if (not defined $collection_id) {
            return {
                error => q{Parameter 'collection_id' is not valid.},
                dump  => Dumper($request_params->{$collection_id}),
            };
        }

        push @conditions, qq{app.collection_id = $collection_id};
    }

    if (defined $request_params->{verbose_collection}) {
        $verbose_collection = get_param_bool($request_params, q{verbose_collection});
        if (not defined $verbose_collection) {
            return {
                error => q{Param 'verbose_collection' is not valid.},
                dump => Dumper($request_params->{verbose_collection}),
            };
        }
    }

    if (defined $request_params->{verbose_streets}) {
        $verbose_streets = get_param_bool($request_params, q{verbose_streets});
        if (not defined $verbose_streets) {
            return {
                error => q{Param 'verbose_streets' is not valid.},
                dump => Dumper($request_params->{verbose_streets}),
            };
        }
    }

    if (defined $request_params->{verbose}) {
        $verbose = get_param_bool($request_params, q{verbose});
        if (not defined $verbose) {
            return {
                error => q{Param 'verbose' is not valid.},
                dump => Dumper($request_params->{verbose}),
            };
        }
    }

    if (defined $request_params->{start}) {
        $time_start = get_param_ts($request_params, q{start});
        if (not defined $time_start) {
            return {
                error => q{Param 'start' is not valid.},
                dump => Dumper($request_params->{start}),
            };
        }
    }

    if (defined $request_params->{end}) {
        $time_end = get_param_ts($request_params, q{end});
        if (not defined $time_end) {
            return {
                error => q{Param 'end' is not valid.},
                dump => Dumper($request_params->{end}),
            };
        }
    }

    if (defined $request_params->{next}) {
        $next_seconds = get_param_ts($request_params, q{next});
        if (not defined $next_seconds) {
            return {
                error => q{Param 'next' is not valid.},
                dump => Dumper($request_params->{next}),
            };
        }
    }

    # check request integrity
    if ($next_seconds && ($time_start || $time_end)) {
        return { error => q{Requesting a coming time window and start and or end time is not supported!}};
    }

    # default select fields
    push @select_fields, (
        q{app.uuid AS uuid},
        q{app.`datetime` AS datetime},
        q{app.street_id AS street},
        q{UNIX_TIMESTAMP(app.datetime) AS timestamp},
    );

    # default condition
    push @conditions, (
        qq{app.street_id = $street_id},
    );

    # add constraint for date begin
    push @conditions, qq{ app.`datetime` >= FROM_UNIXTIME($time_start) }
        if $time_start;

    # add constraint for date end
    push @conditions, qq{ app.`datetime` <= FROM_UNIXTIME($time_start) }
        if $time_end;

    if ($next_seconds) {
        push @conditions, (
            qq{app.`datetime` > NOW()},
            qq{app.`datetime` < DATE_ADD(NOW(), INTERVAL $next_seconds SECOND)},
        );
    }

    if ($verbose || $verbose_collection) {
        push @verbose_conditions, q{JOIN collections AS coll ON app.collection_id = coll.id};
        push @select_fields, ( q{coll.name AS collection_type} );
    };

    if ($verbose || $verbose_streets) {
        push @verbose_conditions, q{JOIN streets AS street ON app.street_id = street.id};
        push @select_fields, ( q{street.name AS street} );
    }

    my $sql_cond_particle       = join q{ AND }, @conditions;
    my $sql_verbose_particle    = join q{ }, @verbose_conditions;
    my $sql_select_particle     = join q{, }, @select_fields;

    if (defined $street_id) {
         my $sql = qq{SELECT $sql_select_particle FROM appointments AS app $sql_verbose_particle WHERE $sql_cond_particle ORDER BY `datetime` ASC};

        $debug && return {
            cond_sql        => $sql_cond_particle,
            period_sql      => $sql_period_particles,
            verbose_sql     => $sql_verbose_particles,
            generated_sql   => $sql,
        } ;

        my $appointments = $db_handle->selectall_arrayref($sql, { Slice => {} });
        return $appointments if ($appointments);
    }

    return {};
};

1;