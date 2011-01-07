# Template::Zoom::Form - Zoom form class
#
# Copyright (C) 2010-2011 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package Template::Zoom::Form;

use strict;
use warnings;

# Constructor
sub new {
	my ($class, $sob, $static) = @_;
	my ($self);
	
	$class = shift;
	$self = {sob => $sob, static => $static, valid_input => undef};

	bless $self;
}

sub params_add {
	my ($self, $params) = @_;

	$self->{params} = $params || [];
}

sub fields_add {
	my ($self, $fields) = @_;

	$self->{fields} = $fields || [];
}

sub inputs_add {
	my ($self, $inputs) = @_;

	if (ref($inputs) eq 'HASH') {
		$self->{inputs} = $inputs;
		$self->{valid_input} = 0;
	}
}

# name method - returns name of the form
sub name {
	my ($self) = @_;

	return $self->{sob}->{name};
}

# elt (element) method - returns corresponding template element of the form
sub elt {
	my ($self) = @_;

	return $self->{sob}->{elts}->[0];
}

# fields method - returns defined form fields
sub fields {
	my ($self) = @_;

	return $self->{fields};
}

# params method - returns form parameter
sub params {
	my ($self) = @_;

	return $self->{params};
}

# inputs method - returns form inputs
sub inputs {
	my ($self) = @_;

	return $self->{inputs};
}

# input method - verifies that input parameters are sufficient
sub input {
	my ($self, $params) = @_;
	my ($error_count);

	if (! $params && $self->{valid_input} == 1) {
		return 1;
	}
	
	$error_count = 0;
	$params ||= {};
	
	for my $input (values %{$self->{inputs}}) {
		if ($input->{required} && ! $params->{$input->{name}}) {
			warn "Missing input for $input->{name}.\n";
			$error_count++;
		}
		else {
			$input->{value} = $params->{$input->{name}};
		}
	}

	if ($error_count) {
		return 0;
	}

	$self->{valid_input} = 1;
	return 1;
}

# action method - returns form action
sub action {
	my ($self) = @_;

	return $self->{action};
}

# set_action method - changes form action
sub set_action {
	my ($self, $action) = @_;

	$self->{sob}->{elts}->[0]->set_att('action', $action);
	$self->{action} = $action;
}

# set_method method - changes form method
sub set_method {
	my ($self, $method) = @_;

	$self->{sob}->{elts}->[0]->set_att('method', $method);
	$self->{method} = $method;
}

# fill - fills form fields
sub fill {
	my ($self, $href) = @_;
	my ($f, @elts, $zref);

	for my $f (@{$self->fields()}) {
		@elts = @{$f->{elts}};

		if (@elts == 1) {
			$zref = $elts[0]->{"zoom_$f->{name}"};
			
			if ($zref->{rep_sub}) {
				# call subroutine to handle this element
				$zref->{rep_sub}->($elts[0], $href->{$f->{name}});
			}
			elsif ($elts[0]->gi() eq 'textarea') {
				$elts[0]->set_text($href->{$f->{name}});
			}
			else {
				$elts[0]->set_att('value', $href->{$f->{name}});
			}
		}
	}
}

# finalize - adds action and other stuff to form
sub finalize {
	my ($self, $elt) = @_;

	for (qw/action method/) {
		if (exists $self->{$_} && $self->{$_}) {
			$elt->set_att($_, $self->{$_});
		}
	}

	return;
}

sub query {
	my ($self) = @_;
	my (%query, $found, %cols);

	%query = (tables => [], columns => {}, query => []);
	
	if ($self->{sob}->{table}) {
		push @{$query{tables}}, $self->{sob}->{table};
		$found = 1;
	}

	for (@{$self->{params}}) {
		push @{$query{columns}->{$self->{sob}->{table}}}, $_->{name};
		$cols{$_->{name}} = 1;
		$found = 1;
	}

	# qualifier based on the input
	for (values %{$self->{inputs}}) {
		if ($_->{value}) {
			push @{$query{query}}, $_->{name} => $_->{value};

			# qualifiers need to be present in column specification
			unless (exists $cols{$_->{name}}) {
				push @{$query{columns}->{$self->{sob}->{table}}}, $_->{name};
			}
		}
	}
	
	if ($found) {
		return \%query;
	}
}

1;
