package Ship;

use LWP::UserAgent;
#use AnyEvent::HTTP::LWP::UserAgent;
#use AnyEvent;
use HTML::TreeBuilder;
use Storable;
$Storable::interwork_56_64bit = 1;

use Time::HiRes qw/time/;
use Data::Dumper;
use Encode qw/decode/;
use Parallel::ForkManager;

sub new{
    my $class = shift;
    my $self = bless {}, $class;
    $self->_init;
    return $self;
}

sub _init{
    my $self = shift;
    $self->{'attrorder'} = ["함선 종류", "모험 레벨", "교역 레벨", "전투 레벨", "세로돛성능", "가로돛성능", "조력", "내구력", "선회속도", "내파성", "장갑", "필요선원", "최대선원", "포문수", "창고", "보조돛", "특수장비", "추가장갑", "선측포", "선수포", "선미포"];

    #(-e "shipinfo")?
    $self->_init_from_file;
	#$self->_init_from_net;
}

sub _init_from_file{
    my $self = shift;
    $self->{'ship'} = retrieve('shipinfo');

    #my $temp = $tree->parse($ua->get("http://uwodbmirror.ivyro.net/kr/main.php?id=50000208")->content);
    #print $temp->as_HTML("&", "\t");
}

sub _init_from_net{
    my $self = shift;
#    my $aeua = AnyEvent::HTTP::LWP::UserAgent->new;
#    my $cv = AE::cv;

    my %ship_kind = ( "탐험용" => 1, "상업용" => 2, "전투용" => 3, "※캐쉬" => 9 );
    my %ship_html;
    my $ua = LWP::UserAgent->new;

    foreach (keys %ship_kind){
	my $tree = HTML::TreeBuilder->new;
	$ship_html{$_} = $tree->parse($ua->get("http://uwodbmirror.ivyro.net/kr/main.php?id=145&chp=" . $ship_kind{$_})->content);
    }

    #my $st = time * 1000;

=pod
    foreach my $ship_kind (keys %ship_kind){
	foreach my $ship ($ship_html{$ship_kind}->look_down( "href" => qr/\bmain\.php\?id=5\d{7}\b/, "hidefocus" => "hidefocus" )){
	    $cv->begin;
	    my $tree = HTML::TreeBuilder->new;
	    $ua->get_async("http://uwodbmirror.ivyro.net/kr/".$ship->attr_get_i('href'))->cb(
		sub {
		    my $r = shift->recv;
		    $self->{'함선정보'}{$ship->as_text} = $tree->parse($r->content);
		    $cv->end;
		});
	}
    }
=cut


    foreach my $ship_kind (keys %ship_kind){
	foreach my $ship ($ship_html{$ship_kind}->look_down( "href" => qr/\bmain\.php\?id=5\d{7}\b/, "hidefocus" => "hidefocus" )){
	    my $tree = HTML::TreeBuilder->new;
	    $self->{'함선정보'}{$ship->as_text} = $tree->parse($ua->get("http://uwodbmirror.ivyro.net/kr/".$ship->attr_get_i('href'))->content);
	}
    }


#    $pm = new Parallel::ForkManager(400);
=pod
    $pm->run_on_finish(
	sub {
	    my ($pid, $ex_code, $id, $ex_signal, $core_dump, $dsr) = @_;
	    my $tree = HTML::TreeBuilder->new;
	    $self->{'함선정보'}{$id->as_text} = $tree->parse($ua->get("http://uwodbmirror.ivyro.net/kr/".$id->attr_get_i('href'))->content);
	});

    foreach my $ship_kind (keys %ship_kind){
	foreach my $ship ($ship_html{$ship_kind}->look_down( "href" => qr/\bmain\.php\?id=5\d{7}\b/, "hidefocus" => "hidefocus" )){
	    $pm->start($ship) and next;
	    $pm->finish();
	}
    }

    $pm->$wait_all_children;
=cut

#    $cv->recv;

    #my $et = time * 1000;
    #print $et - $st."\n";

    foreach my $ship_kind (keys %ship_kind){
	my $ship_name;
	foreach ($ship_html{$ship_kind}->look_down(
		     sub { $_[0]->attr('href') =~ /main\.php\?id=5\d{7}/ or $_[0]->attr('class') =~ /level\d/ }
		 )){
	    if ($_->attr_get_i('href')){
		$ship_name = $_->as_text;
		$self->{'ship'}{$ship_name}{'함선 종류'} = $ship_kind;
	    } else {
		$self->{'ship'}{$ship_name}{$_->attr_get_i('title')} = $_->as_text;
	    }
	}
    }

    my $shipinfo = $self->{'함선정보'};
    my @sub_stat = qw/보조돛 선측포 특수장비 선수포 추가장갑 선미포/;

    foreach my $key (keys %{$shipinfo}){
	foreach ($shipinfo->{$key}->look_down(
		     'class' => qr/state\da?/
		 )){
	    if ($_->as_text =~ /(\d+)\/(\d+)/){
		$self->{'ship'}{$key}{'필요선원'} = $1;
		$self->{'ship'}{$key}{'최대선원'} = $2;
	    } else {
		$self->{'ship'}{$key}{$_->attr_get_i('title')} = $_->as_text;
	    }
	}

	foreach my $tag ($shipinfo->{$key}->look_down(_tag => "ul")){
	    foreach (@sub_stat){
		$tag->as_text =~ /$_.+?(\d+)/;
		#print $ship_key . "\t" . $_."\t".$1."\n";
		$self->{'ship'}{$key}{$_} = $1;
	    }
	}
    }

    store $self->{'ship'}, 'shipinfo';
}

sub info { shift->{'ship'} }
sub attrorder { shift->{'attrorder'} }
sub count{ scalar( keys %{shift->{'ship'}} ) }

sub grid_list{
    my ($self, $getCol, $order) = @_;
    my $ship_grid;

    foreach my $ship_name ( sort { $self->_sort($getCol, $order) } keys %{$self->info} ){
	push @{$ship_grid->{'함선명'}}, $ship_name;
	foreach ( @{$self->attrorder} ){
	    push @{$ship_grid->{'함선정보'}}, $self->info->{$ship_name}{$_};
	}
    }

    return $ship_grid;
}    

sub e_sort_grid{
    my $self = shift;

    return sub {
	my $order = shift;

	return sub{
	    my ($grid, $evt) = @_;
	    my $sort;
	    
	    $sort = $self->grid_list ( $evt->GetCol, $order );

	    $grid->draw_grid($sort->{'함선명'}, $self->attrorder, $sort->{'함선정보'});
	}
    }
}

sub _sort{
    my ($self, $getCol, $order) = @_;
    my @ship_cols = @{$self->attrorder};

	unless ( $getCol ){
	    ($order)?
		return $self->info->{$a}{$ship_cols[$getCol]} cmp $self->info->{$b}{$ship_cols[$getCol]} || $a cmp $b:
		return $self->info->{$b}{$ship_cols[$getCol]} cmp $self->info->{$a}{$ship_cols[$getCol]} || $a cmp $b;		
	} else {
	    ($order)?
		return $self->info->{$b}{$ship_cols[$getCol]} <=> $self->info->{$a}{$ship_cols[$getCol]} || $a cmp $b:
		return $self->info->{$a}{$ship_cols[$getCol]} <=> $self->info->{$b}{$ship_cols[$getCol]} || $a cmp $b;
	}
}

sub e_get_dubu{
    my ($self, $grid) = @_;

    return sub{


	my ($btn, $evt) = @_;
	my $pd = Wx::ProgressDialog->new( decode('utf8',"두부정보 업데이트"), '', 100, $btn, wxPD_CAN_ABORT|wxPD_AUTO_HIDE|wxPD_APP_MODAL|wxPD_ELAPSED_TIME|wxPD_ESTIMATED_TIME|wxPD_REMAINING_TIME);

	$pm = new Parallel::ForkManager(1);


	my $pid = $pm->start and goto NEXT;
	foreach (1 .. 100){
	    $pd->Update($_, decode('utf8',"두부 정보를 가져오는 중입니다...   ".$_." 초"));
	    sleep(1);
	}
	$pm->finish;
      NEXT:
	
	$self->_init_from_net;

	my $rows = $self->grid_list->{'함선명'};
	my $cells = $self->grid_list->{'함선정보'};

	$grid->draw_grid($rows, $self->attrorder, $cells);

	$pd->Destroy;
	kill 9, $pid;
    }
}

1;
