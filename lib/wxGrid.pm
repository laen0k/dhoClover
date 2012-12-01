package wxGrid;

use base 'Wx::Grid';
use Encode qw/encode decode/;
use Wx::Event qw/EVT_GRID_LABEL_LEFT_CLICK EVT_GRID_LABEL_RIGHT_CLICK/;;
use wxPerl::Styles 'wxVal';

sub new{
    my ($class, $frame, @args)  = @_;
    my $self = $class->SUPER::new( $frame, -1);
    $self->_init(@args);
    return $self;
}

sub _init{
    my ($self, $rows, $cols, $cells) = @_;

    $self->CreateGrid( scalar @{$rows}, scalar @{$cols} );
    $self->draw_grid( $rows, $cols, $cells );
    $self->SetRowLabelSize(150);
    $self->SetColLabelSize(80);
    $self->SetColLabelAlignment(wxVal('align_centre'), wxVal('align_bottom'));
    $self->AutoSizeColumns(1);
    $self->AutoSizeRows(1);
    $self->SetDefaultCellAlignment(wxVal('align_right'), wxVal('align_centre'));
}

sub evt_click{
    my ($self, $func) = @_;

    EVT_GRID_LABEL_RIGHT_CLICK( $self, $func->(0) );
    EVT_GRID_LABEL_LEFT_CLICK( $self, $func->(1) );
}

sub draw_grid{
    my ( $self, $rows, $cols, $cells ) = @_;

    $self->SetRowLabelValue( $_, decode('utf8', $rows->[$_]) ) foreach 0 .. $#{$rows};
    $self->SetColLabelValue( $_, _vText($cols->[$_]) ) foreach 0 .. $#{$cols};
    $self->SetCellValue( $_ / @{$cols}, $_ % @{$cols}, decode('utf8', $cells->[$_]) ) foreach 0 .. $#{$cells};
}

sub _vText {
    my $txt = decode('utf8', shift);
    $txt =~ s/\s//g;
    $txt =~ s/(.)/$1\n/g;
    return $txt;
}

1;
