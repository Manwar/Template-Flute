# Template::Zoom::PDF::Import - Zoom PDF import class
#
# Copyright (C) 2010 Stefan Hornburg (Racke) <racke@linuxia.de>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

package Template::Zoom::PDF::Import;

use strict;
use warnings;

use PDF::API2;
use POSIX qw/floor/;

sub new {
	my ($proto, @args) = @_;
	my ($class, $self);

	$class = ref($proto) || $proto;
	$self = {@args};

	bless ($self, $class);
}

sub import {
	my ($self, %parms) = @_;
	my ($pdf_import, $pages, $page_in, $page_out, $scale, @mbox, $gfx, $txt, $xo);

	unless ($parms{pdf}) {
		return;
	}
	
	unless ($parms{file}) {
		return;
	}

	if ($parms{scale}) {
		$scale = $parms{scale};
	}
	else {
		$scale = 1;
	}
	
	eval {
		$pdf_import = PDF::API2->open($parms{file});
	};

	if ($@) {
		warn "Failed to open PDF file $parms{file}: $@\n";
		return;
	}

	$pages = 0;
	
	# Start and end page
	$parms{start} ||= 1;
	$parms{end} ||= $pdf_import->pages();

	for (my $i = $parms{start}; $i <= $parms{end}; $i++) {
		my (@mbox, $new_left, $new_bottom, $left_edge, $bottom, $right_edge, $top);
			
		$page_out = $parms{pdf}->page(0);
		$page_in = $pdf_import->openpage($i);

		# get original page size
		@mbox = $page_in->get_mediabox;
		($left_edge, $bottom, $right_edge, $top) = @mbox;

		# copy page as a form
		$gfx = $page_out->gfx;
		$xo = $parms{pdf}->importPageIntoForm($pdf_import, $i);

		$new_left = $left_edge;
		$new_bottom = floor ((1 + $top - $bottom) * (1-$scale));
		
		$gfx->formimage($xo,
						$new_left, $new_bottom, # x y
						$scale);
		
		$pages++;
	}

	return {pages => $pdf_import->pages(), cur_page => $page_out};
}

1;

