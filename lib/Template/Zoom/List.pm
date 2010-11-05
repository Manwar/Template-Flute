# Template::Zoom::List - Zoom list class
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

package Template::Zoom::List;

use strict;
use warnings;

# Constructor
sub new {
	my ($class, $sob, $static, $spec, $name) = @_;
	my ($self);
	
	$class = shift;
	$static ||= [];
	
	$self = {sob => $sob, static => $static, valid_input => undef};

	bless $self;
	
	if ($spec && $name) {
		$self->inputs_add($spec->list_inputs($name));
		$self->sorts_add($spec->list_sorts($name));
		$self->paging_add($spec->list_paging($name));
	}
	
	return $self;
}

sub params_add {
	my ($self, $params) = @_;

	$self->{params} = $params;
}

sub inputs_add {
	my ($self, $inputs) = @_;

	if (ref($inputs) eq 'HASH') {
		$self->{inputs} = $inputs;
		$self->{valid_input} = 0;
	}
}

sub sorts_add {
	my ($self, $sort) = @_;

	$self->{sorts} = $sort;
}

sub paging_add {
	my ($self, $paging) = @_;

	$self->{paging} = $paging;
}

# name method - returns name of the list
sub name {
	my ($self) = @_;

	return $self->{sob}->{name};
}

# iterator method - returns iterator for the list
sub iterator {
	my ($self) = @_;

	return $self->{iterator};
}

# set_iterator method - sets iterator for the list
sub set_iterator {
	my ($self, $iterator) = @_;
	
	$self->{iterator} = $iterator;
}

# set_static_class - set static class
sub set_static_class {
	my ($self, $class) = @_;

	push(@{$self->{static}}, $class);
}

# apply_static_class - apply static class to element
sub static_class {
	my ($self, $row_pos) = @_;
	my ($idx);

	if (@{$self->{static}}) {
		$idx = $row_pos % scalar(@{$self->{static}});
		
		return $self->{static}->[$idx];
	}
}
		
# elt (element) method - returns corresponding template element of the list
sub elt {
	my ($self) = @_;

	return $self->{sob}->{elts}->[0];
}

# params method - returns list parameter
sub params {
	my ($self) = @_;

	return $self->{params};
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

sub query {
	my ($self) = @_;
	my (%query, $found, $name, %cols);

	%query = (tables => [], columns => {}, query => []);
	
	if ($self->{sob}->{table}) {
		push @{$query{tables}}, $self->{sob}->{table};
		$found = 1;
	}

	for (@{$self->{params}}) {
		if (exists $_->{field}) {
			$name = $_->{field};
		}
		else {
			$name = $_->{name};
		}
		
		push @{$query{columns}->{$self->{sob}->{table}}}, $name;
		$cols{$name} = 1;
		$found = 1;
	}

	# qualifier based on the input
	for (values %{$self->{inputs}}) {
		if (exists $_->{field}) {
			$name = $_->{field};
		}
		else {
			$name = $_->{name};
		}
			
		push @{$query{query}}, $name => $_->{value};

		# qualifiers need to be present in column specification
		unless (exists $cols{$name}) {
			push @{$query{columns}->{$self->{sob}->{table}}}, $name;
		}
	}

	# sorting
	if (exists $self->{sorts}->{default}) {
		my @sort;

		for my $op (@{$self->{sorts}->{default}->{ops}}) {
			if ($op->{direction}) {
				push (@sort, "$op->{name} $op->{direction}");
			}
			else {
				push (@sort, $op->{name});
			}
		}

		$query{sort_by} = join(',', @sort);
	}
	
	if ($found) {
		return \%query;
	}
}

1;
