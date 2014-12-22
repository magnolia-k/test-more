use strict;
use warnings;

# this test is very similar to what is generated by Dist::Zilla::Plugin::Test::CheckBreaks

use Test::More;
use CPAN::Meta;
use CPAN::Meta::Requirements;
use Module::Metadata;

my $breaks = CPAN::Meta->load_file('MYMETA.json')->custom('x_breaks');
my $reqs = CPAN::Meta::Requirements->new;
$reqs->add_string_requirement($_, $breaks->{$_}) foreach keys %$breaks;

my $result = check_breaks($reqs);
if (my @breaks = grep { defined $result->{$_} } keys %$result)
{
    diag 'You have the following modules installed, which are not compatible with the latest Test::More:';
    diag "$result->{$_}" for sort @breaks;
    diag "\n", 'You should now update these modules!';
}

pass 'conflicting modules checked';

# this is an inlined simplification of CPAN::Meta::Check.
sub check_breaks {
    my $reqs = shift;
    return +{
        map { $_ => _check_break($reqs, $_) } $reqs->required_modules,
    };
}

sub _check_break {
    my ($reqs, $module) = @_;
    my $metadata = Module::Metadata->new_from_module($module);
    return if not defined $metadata;
    my $version = eval { $metadata->version };
    return "Missing version info for module '$module'" if not $version;
    return sprintf 'Installed version (%s) of %s is in range \'%s\'', $version, $module, $reqs->requirements_for_module($module) if $reqs->accepts_module($module, $version);
    return;
}

done_testing;
