#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use Modern::Perl '2012';
use utf8;

use ProductOpener::Config qw/:all/;
use ProductOpener::Store qw/:all/;
use ProductOpener::Index qw/:all/;
use ProductOpener::Display qw/:all/;
use ProductOpener::Tags qw/:all/;
use ProductOpener::Users qw/:all/;
use ProductOpener::Images qw/:all/;
use ProductOpener::Lang qw/:all/;
use ProductOpener::Mail qw/:all/;
use ProductOpener::Products qw/:all/;
use ProductOpener::Food qw/:all/;
use ProductOpener::Ingredients qw/:all/;
use ProductOpener::Images qw/:all/;


use CGI qw/:cgi :form escapeHTML/;
use URI::Escape::XS;
use Storable qw/dclone/;
use Encode;
use JSON;


# Get a list of all products

my $total = 0;

foreach my $l (values %lang_lc) {

	$lc = $l;
	$lang = $l;


my $cursor = $products_collection->query({ lc => $lc })->fields({ id=>1, code => 1, empty => 1 });;
my $count = $cursor->count();
my $removed = 0;
my $notfound = 0;
	
	print STDERR "$count products to check\n";
	
	while (my $product_ref = $cursor->next) {
        
		
		my $code = $product_ref->{code};
		my $id = $product_ref->{id};
		my $path = product_path($code);
		
		#print STDERR "updating product $code\n";
		
		$product_ref = retrieve_product($code);
		
		if ((defined $product_ref) and ($code ne '')) {
				
			$lc = $product_ref->{lc};
			$lang = $lc;
			
			if (($product_ref->{empty} == 1) and (time() > $product_ref->{last_modified_t} + 86400)) {
				$product_ref->{deleted} = 'on';
				my $comment = "automatic removal of product without information or images";

				# print STDERR "removing product code $code\n";
				$removed++;
				if ($lc eq 'vi') {
					# store_product($product_ref, $comment);
				}
			}
		}
		else {
			print "product code $code - id $id : file not found\n";
			$notfound++;
			
			# try to add 0
			$product_ref = retrieve_product($id);

			if (defined $product_ref) {
				print STDERR "found id: $id - code: $product_ref->{code}\n";
				$product_ref->{code} = $product_ref->{code} . '';
				my $code = $product_ref->{code};
				my $path = product_path($code);
				if (1) {
					if ($product_ref->{deleted}) {
						$products_collection->remove({"_id" => $product_ref->{_id}});
					}
					else {
						$products_collection->save($product_ref);
					}
					store("$data_root/products/$path/product.sto", $product_ref);
				}
			}
		}

	}
	
print STDERR "$lc - notfound $notfound products\n";
$total += $removed;
}

print STDERR "total - removed $total products\n";


exit(0);

