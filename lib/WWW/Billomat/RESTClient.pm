package WWW::Billomat::RESTClient;

use 5.010;

use strict;
use warnings;

use base 'REST::Client';

=head1 NAME

WWW::Billomat::RESTClient - REST client for WWW::Billomat

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Used by L<WWW::Billomat> internally.

=head1 METHODS

=head2 request

Overridden from L<REST::Client/request>. Sleeps and retries if the quota on the
number of API calls per time window is exceeded (see
http://www.billomat.com/en/api/basics/rate-limiting).

=cut

sub request {
    my $self = shift;

    {
        my $res = $self->next::method(@_);

        if ($res->responseCode == 429) {
            if ( !$res->responseHeader('X-Rate-Limit-Remaining') ) {
                my $time_until_reset
                    = $res->responseHeader('X-Rate-Limit-Reset') // time;

                my $time_to_sleep = $time_until_reset - time;
                $time_to_sleep = 10 if $time_to_sleep < 0;

                warn "The quota on the number of API calls per time window is "
                    . "exceeded (see "
                    . "http://www.billomat.com/en/api/basics/rate-limiting). "
                    . "Sleeping $time_to_sleep seconds before retrying.\n";

                sleep $time_to_sleep;

                redo;
            }
        }

        return $res;
    }
}


1; # End of WWW::Billomat::RESTClient
