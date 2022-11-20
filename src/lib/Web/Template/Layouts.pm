package Web::Template::Layouts;

use Dancer2 appname => 'Web';

my $plugins_dir = '/app/src/plugins';

my @plugins = do {
    opendir( my $dir, $plugins_dir );
    grep { $_ ne '.' && $_ ne '..' } readdir($dir);
};

{
    my ( $order, %order );
    map { $order{$_} = $order++ } split /,/,
      $ENV{TEMPLATE_LAYOUTS_SORTING_ORDER};

    sub _order {
        my ($plugin) = @_;
        $order{$plugin} //= 999999;
    }
}

my %files = ();

foreach my $plugin ( sort { _order($a) <=> _order($b) } @plugins ) {
    my $view_dir = "$plugins_dir/$plugin/src/views";
    next if !-d $view_dir;
    my $layout_dir = "$view_dir/layouts";
    next if !-d $layout_dir;
    foreach my $file ( split /\n/, qx{cd $view_dir; find layouts -type f} ) {
        my $path = join '', map { "{$_}" } map { s/\.tt$//; $_ } split /\//,
          $file;
        my $stash = eval "\$files$path //= []";
        push @$stash, "$plugin/$file";
    }
}

hook before_template_render => sub {
    var template => \%files;
};

1;
