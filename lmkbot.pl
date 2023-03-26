#!/usr/local/bin/perl5.36 -CSDA

use strict;

use warnings;

use LWP::UserAgent;

use HTTP::Request;

use HTTP::Response;

use HTTP::Headers;

use Mojo::DOM;

use URI;

# ================================================================ #
# ======================  Declare/Define  ======================== #
# ================================================================ #

# Keep track of what we need to visit
our @url_to_visit = ('https://ast.ru/series/luchshaya-mirovaya-klassika-1241886/');



# Keep track of what we have already seen
our %seen_url_before;



our $scheme = URI->new( $url_to_visit[0] )->scheme;
our $host = URI->new( $url_to_visit[0] )->host;

# ================================================================ #
# ============================= Main ============================= #
# ================================================================ #

{
    my $url = URI->new($url_to_visit[0]);

    # Links
    my @extracted_links;


    my $headers = HTTP::Headers->new();
    $headers->header(content_type => 'text/html');


    my $ua = LWP::UserAgent->new();

    $ua->agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36');
    $ua->default_headers($headers);


    while (@url_to_visit) {
        my $url = shift @url_to_visit;

        # Make a request
        my $response = make_request($ua, $url);

        next unless $response;

        # Parse HTML
        my $dom = Mojo::DOM->new($response->decoded_content);

        if ($url =~ /\/series\//i) {
            push @url_to_visit, map {+ $scheme . '://' . $host . $_} $dom->find("a[href^=\"/book/\"]")->map(attr => 'href')->each;

            push @url_to_visit, map {+ $scheme . '://' . $host . $_} $dom->find("a[class=\"pagination__link\"]")->map(attr => 'href')->each;
        }
        elsif ($url =~ /\/book\//i) {
            my $title = $dom->at("h2[class^=\"book-detail__title\"]")->text;
            my $author = $dom->at("div[class=\"book-detail__authors-list bd__wrap--m hide-desktop-tablet\"]")->all_text;


            # Trimming (e.g, removing whitespaces)
            $title =~ s/^\s+|\s+$//g;
            $author =~ s/^\s+|\s+$//g;

            print $title, ' - ', $author, "\n";
        }
    }
}

# ================================================================ #
# ===========================  Subs  ============================= #
# ================================================================ #

sub make_request {
    my ($agent, $url) = @_;

    my $request_get = HTTP::Request->new(
        GET => $url,
    );


    if (!$seen_url_before{$url}) {
        # Making a request
        my $response = $agent->request($request_get);

        if ($response->is_success) {
            $seen_url_before{$url} = 1;

            return $response;
        }
        else {
            print STDERR "Can't GET the url: ", $url, " ", $response->status_line, "\n";
        }
    }


    return undef;
}