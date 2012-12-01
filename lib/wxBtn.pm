package wxBtn;

use base 'Wx::Button';
use Wx::Event qw/EVT_BUTTON/;
use utf8;

sub new{
    my ($class, $frame, $args) = @_;
    my $self = $class->SUPER::new( $frame, -1, "두부정보 새로고침");
    $self->_init($args);
    return $self;
}

sub _init{
}

sub evt_click{
    my ($self, $frame, $func) = @_;
    EVT_BUTTON( $frame, $self, $func );
}

1;
