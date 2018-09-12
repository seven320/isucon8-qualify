package ISUCON8::Portal::Model::Team;

use strict;
use warnings;
use feature 'state';
use parent 'ISUCON8::Portal::Model';

use ISUCON8::Portal::Exception;
use ISUCON8::Portal::Constants::Common;

use Mouse;

__PACKAGE__->meta->make_immutable;

no Mouse;

sub find_team {
    my ($self, $params) = @_;
    my $id       = $params->{id};
    my $password = $params->{password};

    my $team;
    eval {
        $self->db->run(sub {
            my $dbh = shift;
            my ($stmt, @bind) = $self->sql->select(
                'teams',
                ['*'],
                {
                    id       => $id,
                    password => $password, # TODO: password hash
                },
            );
            $team = $dbh->selectrow_hashref($stmt, undef, @bind);
        });
    };
    if (my $e = $@) {
        $e->rethrow if ref $e eq 'ISUCON8::Portal::Exception';
        ISUCON8::Portal::Exception->throw(
            code    => ERROR_INTERNAL_ERROR,
            message => "$e",
            logger  => sub { $self->log->critf(@_) },
        );
    }

    return $team;
}

sub get_team {
    my ($self, $params) = @_;
    my $id = $params->{id};

    my $team;
    eval {
        $self->db->run(sub {
            my $dbh = shift;
            my ($stmt, @bind) = $self->sql->select(
                'teams',
                ['*'],
                {
                    id => $id,
                },
            );
            $team = $dbh->selectrow_hashref($stmt, undef, @bind);
        });
    };
    if (my $e = $@) {
        $e->rethrow if ref $e eq 'ISUCON8::Portal::Exception';
        ISUCON8::Portal::Exception->throw(
            code    => ERROR_INTERNAL_ERROR,
            message => "$e",
            logger  => sub { $self->log->critf(@_) },
        );
    }

    return $team;
}

sub get_servers {
    my ($self, $params) = @_;
    my $group_id = $params->{group_id};

    my $servers = [];
    eval {
        $self->db->run(sub {
            my $dbh = shift;
            my ($stmt, @bind) = $self->sql->select(
                'servers',
                ['*'],
                {
                    group_id => $group_id,
                },
                {
                    order_by => { -asc => 'global_ip' },
                },
            );
            $servers = $dbh->selectall_arrayref($stmt, { Slice => {} }, @bind);
        });
    };
    if (my $e = $@) {
        $e->rethrow if ref $e eq 'ISUCON8::Portal::Exception';
        ISUCON8::Portal::Exception->throw(
            code    => ERROR_INTERNAL_ERROR,
            message => "$e",
            logger  => sub { $self->log->critf(@_) },
        );
    }

    return $servers;
}

sub get_latest_score {
    my ($self, $params) = @_;
    my $team_id = $params->{team_id};

    my $score;
    eval {
        $self->db->run(sub {
            my $dbh = shift;
            my ($stmt, @bind) = $self->sql->select(
                'team_scores',
                ['*'],
                {
                    team_id => $team_id,
                },
            );
            $score = $dbh->selectrow_hashref($stmt, undef, @bind);
        });
    };
    if (my $e = $@) {
        $e->rethrow if ref $e eq 'ISUCON8::Portal::Exception';
        ISUCON8::Portal::Exception->throw(
            code    => ERROR_INTERNAL_ERROR,
            message => "$e",
            logger  => sub { $self->log->critf(@_) },
        );
    }

    return $score;
}

sub get_team_scores {
    my ($self, $params) = @_;
    my $limit = $params->{limit};

    my $scores = [];
    eval {
        $self->db->run(sub {
            my $dbh = shift;
            my ($stmt, @bind) = $self->sql->select(
                { teams => 't' },
                [
                    's.team_id', 's.latest_score', 's.best_score', 's.updated_at',
                    's.latest_status', 't.name', 't.category',
                ],
                {},
                {
                    join => {
                        type      => 'LEFT',
                        table     => { team_scores => 's' },
                        condition => { 't.id' => 's.team_id' },
                    },
                    order_by => [
                        { -desc => 's.latest_score' },
                        { -asc  => 't.id' },
                    ],
                    $limit ? { limit => $limit } : (),
                },
            );
            $scores = $dbh->selectall_arrayref($stmt, { Slice => {} }, @bind);
        });
    };
    if (my $e = $@) {
        $e->rethrow if ref $e eq 'ISUCON8::Portal::Exception';
        ISUCON8::Portal::Exception->throw(
            code    => ERROR_INTERNAL_ERROR,
            message => "$e",
            logger  => sub { $self->log->critf(@_) },
        );
    }

    return $scores;
}

sub get_tema_jobs {
    my ($self, $params) = @_;
    my $team_id = $params->{team_id};
    my $limit   = $params->{limit};

    my $jobs = [];
    eval {
        $self->db->run(sub {
            my $dbh = shift;
            my ($stmt, @bind) = $self->sql->select(
                'bench_queues',
                [qw/id team_id state result_status result_score updated_at/],
                {
                    team_id => $team_id,
                },
                {
                    order_by => { -desc => 'updated_at' },
                    $limit ? { limit => $limit } : (),
                },
            );
            $jobs = $dbh->selectall_arrayref($stmt, { Slice => {} }, @bind);
        });
    };
    if (my $e = $@) {
        $e->rethrow if ref $e eq 'ISUCON8::Portal::Exception';
        ISUCON8::Portal::Exception->throw(
            code    => ERROR_INTERNAL_ERROR,
            message => "$e",
            logger  => sub { $self->log->critf(@_) },
        );
    }

    return $jobs;
}

1;
