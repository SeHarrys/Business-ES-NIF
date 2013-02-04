package Business::ES::NIF;

=head1 NAME                                                                                                                                                                                                                     
 
 Business::ES::NIF - Check is valid Spanish NIF

=cut

our $VERSION = '0.03';

use strict;
use warnings FATAL => 'all';

=head1 SYNOPSIS                                                                                                                                                                                                                 

    use Business::ES::NIF;
                                                                                                                                                                                                          
    my $NIF = Business::ES::NIF->new( '01234567L' );

    $NIF->NIF('B01234567');

    unless ( $NIF->{status} ) {
     say "Invalid NIF";
     exit;
    }

    say $NIF->{type};

=head1 DESCRIPTION

Validate a Spanish NIF / CIF / NIE

Save a reference with the status 0 or 1 , in the case of staus is false return the nif validate in 'nif_check'

Referencias: http://es.wikipedia.org/wiki/Numero_de_identificacion_fiscal  

=head1 EXPORT                                                                                                                                                                                                                   

=head1 SUBROUTINES/METHODS                                                                                                                                                                                                      

=cut 

my $Types = {
 NIF => {
     re => '^[0-9]{8}[A-Za-z]',
     val => sub {
	 my $dni = shift;
	 my $ret = shift || 0;

	 $dni =~ /^([0-9]{8})([A-Za-z])/x;
	 my ($NIF,$DC) = ($1,$2);
	 my $L = substr( 'TRWAGMYFPDXBNJZSQVHLCKE', $NIF % 23, 1);
	 
	 return $NIF.$L if $ret;

	 return 1 if $L eq $DC;
	 return 0;
     },
     extra => sub { return 'NIF'; }
 },
 CIF => { 
     re => '^[ABCDEFGHJPQRUVNW][0-9]{8}$',
     val => sub {
         my $cif = shift;
         
	 $cif =~ /^([ABCDEFGHJPQRUVNW])([0-9]{7})([0-9])$/x; 
	 my ($sociedad, $inscripcion, $control) = ($1,$2,$3);
	 
	 my @n = split //, $inscripcion;
	 my $pares = $n[1] + $n[3] + $n[5];          
	 my $nones;                                  
	 for (0, 2, 4, 6) {
	     my $d   = $n[$_] * 2;                   
	     $nones += $d < 10 ? $d : $d - 9;        
	 }
	 my $c = (10 - substr($pares + $nones, -1)) % 10; 
	 my $l = substr('JABCDEFGHI', $c, 1);       
	 
         for ($sociedad) {
             if (/[KPQS]/i) {
                 return 0 if $l ne uc($control);
             }elsif (/[ABEH]/i) {
                 return 0 if $c != $control;
             }else {
                 return 0 if $c != $control  and  $l ne uc($control);
             }
         }
	 
	 return 1;
     },
     extra => sub {
         my $cif = shift;

         my $Tipos = {
             'A' => 'Sociedad Anonima - S.A',
             'B' => 'Sociedad Limitada - S.L',
             'C' => 'Sociedad Colectiva - S.C',
             'D' => 'Sociedades comanditarias',
             'E' => 'Comunidad de bienes y herencias',
             'F' => 'Sociedades cooperativas',
             'G' => 'Asociaciones',
             'H' => 'Comunidaddes de propietarios',
             'J' => 'Sociedades civiles',
             'P' => 'Corporaciones locales',
             'Q' => 'Organismos publicos',
             'N' => 'Entidades extranjeras',
             'R' => 'Congregaciones e instituciones religiosas',
             'S' => 'Organos de administracion del estado',
             'U' => 'Uniones temporales de epresas',
             'V' => 'Otros tipos de sociedades',
             'W' => 'Establecimientos permanentes de entidades no residentes en España',
         };
         $cif =~ /^([ABCDEFGHJPQRUVNW])[0-9]{7}[0-9]$/x;

         return $Tipos->{$1};
     }
 },
 NIE => {
     re => '^[XY][0-9]{7}[A-Z]$',
     val => sub {
	 my $dni = shift;
	 $dni =~ /^([XY])([0-9]{7})([A-Z])$/x;
	 
	 my ($NIE,$NIF,$DC) = ($1,$2,$3);
	 
         for ($NIE) {
             $NIF = '0'.$NIF if /X/;
             $NIF = '1'.$NIF if /Y/;
             $NIF = '2'.$NIF if /Z/;
         }

         my $L = substr( 'TRWAGMYFPDXBNJZSQVHLCKE', $NIF % 23, 1);
	 
         return 1 if $L eq $DC;
         return 0;
     },
     extra => sub { return 'NIE';  }     
 }
};

=head2 new
    
=cut
sub new {
    my ( $class, $nif ) = @_;

    my $self = {};

    $self = bless $self, $class;

    return $self unless $nif;

    $self->{nif} = standard($nif);

    $self->check();

    return $self;
}

=head2 NIF

=cut
sub NIF {
    my $self = shift;

    $self->{nif} = standard(shift);

    $self->check();
}

=head2 standard

=cut
sub standard {
    my $NIF = shift;

    $NIF =~ s/[-\.\s]//g;

    return uc $NIF;
}

=head2 check

=cut
sub check {
    my $self = shift;

    for (keys $Types) {
        if ( $self->{nif} =~ /$Types->{$_}->{re}/ ) {
            $self->{status} = $Types->{$_}->{val}->($self->{nif});
            $self->{type} = $_;
	    $self->{extra} = $Types->{$_}->{extra}->($self->{nif});
            $self->{nif_check} = $Types->{NIF}->{val}->($self->{nif},1) if $self->{status} == 0 && $self->{type} eq 'NIF';
        }
    }
    
}

=head1 AUTHOR

Harun Delgado, C<< <hdp at djmania.es> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-es-nif at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-ES-NIF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::ES::NIF

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-ES-NIF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-ES-NIF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-ES-NIF>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-ES-NIF/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Harun Delgado. L<http://djmania.es>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
