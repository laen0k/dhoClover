#!/usr/bin/perl

use strict;
use warnings;
use Wx;

use lib 'lib';
use Ship;
use wxBtn;
use wxGrid;

use Wx qw(:sizer wxDefaultPosition wxDefaultSize
          wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new( undef, -1, 'dhoClover', [-1, -1], [800, 800]);

my $ship = Ship->new;
my $btn = wxBtn->new($frame, -1);
my $grid = wxGrid->new($frame, $ship->grid_list->{'함선명'}, $ship->attrorder, $ship->grid_list->{'함선정보'});

$btn->evt_click($frame, $ship->e_get_dubu($grid));
$grid->evt_click($ship->e_sort_grid);

my $top = Wx::BoxSizer->new( wxVERTICAL );
my $box = Wx::BoxSizer->new( wxVERTICAL );

$box->Add( $btn, 0, wxGROW);
$box->Add( $grid, 0, wxGROW);
$frame->SetSizer( $box );

$frame->Show;
$app->MainLoop;
