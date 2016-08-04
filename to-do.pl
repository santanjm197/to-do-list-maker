#! /usr/bin/perl -w

use strict;
use DateTime;
use DateTime::TimeZone;
use DateTime::Duration;
use File::Path qw(make_path remove_tree);
use FindBin;
use Cwd;


# ----------------------- #
#                         #
#     Initialization      #
#                         #    
# ----------------------- #


# Current user's timezone, updated upon startup
my $tzone = DateTime::TimeZone->new(name=>'local')->name();

# Current date information
my $cdt;

# Array used for quick reference of date info
my @dinfo;

# Array which holds DateTime objects corresponding to each day of this week
my @week;

# Directory of the script; used in searching for profiles
my $script_dir = $FindBin::Bin;

# Directory of currently loaded profile
my $prof_dir;

# The current working directory
my $cwd = getcwd();

# Stores the currently loaded profile, used for reads and writes to relevant files/directories
my $curr_prof;

# Hash of all possible commands to references of the subroutines they invoke
my %cmds = (
	"date"     => \&recalc_date,
        "load"     => \&load,
        "quit"     => \&quit,
        "add"      => \&add,
        "check"    => \&check,
        "list"     => \&list_tasks,
        "help"     => \&help,
	);

# Before proceeding, make sure that the current working directory is
# where the script itself is located, not where it was executed
unless ($cwd eq $script_dir) {
    chdir $script_dir;
    $cwd = getcwd();
}

# Check if there is a 'profiles' folder in the script's current directory,
# if not then create it
if (!-d "profiles") {
    print "No profiles folder found, creating...\n";
    make_path "./profiles";
    if (-d "./profiles") {
	print "Successfully created profiles folder in $script_dir\n";
	print "\n";
    }
    else {
	print "Failed to create profiles folder in $script_dir\n";
	exit 1;
    }
}
else {
    print "Profiles folder successfully located in $cwd\n";
}

# Now that profiles folder is established, there is no need to ever leave it
# since all profiles are contained in that folder
chdir "profiles";
$cwd = getcwd();

# Load/create a profile for the user, either from
my $arg_length = @ARGV;

# Only command line argument accepted is a profile name, which cannot contain whitespace
if ($arg_length > 1) {
    print "Too many command line arguments, only 1 (user profile) argument should be used\n";
    exit 2;
} 
elsif ($arg_length == 1) {
    my $profile = shift @ARGV;
    &load_profile($profile);
}
# No command line arguments found so prompt the user for a profile name
else {
    &load();
}

# Now that the user profile is loaded, start the command loop
&cmd_loop();


# ----------------------- #
#                         #
#   Profile Subroutines   #
#                         #    
# ----------------------- #


# sub load_profile
# parameters:
#    Scalar: name of profile to load/create
sub load_profile($) {
    my $profile = shift;
    # Make sure the script is reading from the starting directory before proceeding
    unless ($cwd eq "$script_dir/profiles") {
	chdir "$script_dir/profiles";
    }
    if (!-d "./$profile") {
	print "User profile $profile not found, creating...\n";
	make_path "./$profile" or die "Failed to create profile for $profile in $script_dir/profiles\n";
	if (-d "./$profile") {
	    print "Successfully created user profile $profile in $script_dir/profiles\n";
	    print "\n";
	}
    }
    else {
	print "User profile $profile found\n";
	print "\n";
    }
    $curr_prof = $profile;
    $prof_dir = "$script_dir/profiles/$curr_prof";
    &check_files();
}

# sub check_files
# Check to see if the required profile files ($current_profile.txt and $current_profile_tasks.txt)
# exist in the current profile's folder, creating them if they are not there
sub check_files {
    chdir $prof_dir;
    print "Checking for $curr_prof.txt...\n";
    if (-f "$curr_prof.txt") {
	print "Successfully located $curr_prof.txt\n";
    }
    else {
	print "$curr_prof.txt not found, creating...\n";
	&setup_profile();
	if (-f "$curr_prof.txt") {
	    print "Successfully created $curr_prof.txt\n";
	}
    }
    
    print "\nChecking for $curr_prof\_tasks.txt...\n";
    if (-f "$curr_prof\_tasks.txt") {
	print "Successfully located $curr_prof\_tasks.txt\n";
    }
    else {
	print "$curr_prof\_tasks.txt not found, creating...\n";
	open TASKS, ">$curr_prof\_tasks.txt" or die "File could not be created\n";
	if (-f "$curr_prof\_tasks.txt") {
	    print "Successfully created $curr_prof\_tasks.txt\n";
	}
	close TASKS;
    }
 }

# sub setup_profile
# Adds name and date to a new user's profile.txt file
sub setup_profile {
    open PROF, ">$curr_prof.txt" or die "File could not be created\n";
    print PROF "name:$curr_prof\n";
    &date();
    print PROF "last_active:";
    for (my $i = 0; $i < $#dinfo; $i++) {
	print PROF "$dinfo[$i],";
    }
    print PROF "$dinfo[$#dinfo]\n";
    close PROF;
}


# ----------------------- #
#                         #
#        Accessors        #
#                         #    
# ----------------------- #


# sub get_name
# Returns:
#    Scalar: $curr_prof.txt name field
sub get_name {
    chdir "profiles/$curr_prof";
    open PROF, "<$curr_prof.txt" or die "File could not be opened\n";
    while (<PROF>) {
	if (m/^name/) {
	    my @name_line = split /:/;
	    close PROF;
	    return pop @name_line;
	}
    }
    close PROF;
    print "No name found in $curr_prof.txt, adding it now...\n";
    open PROF, ">>$curr_prof.txt" or die "File could not be opened\n";
    print PROF "name:$curr_prof\n";
    close PROF;
    &get_name();
}

# sub get_last_active
# Returns:
#   Array: $curr_prof.txt last_active field
sub get_last_active {
    chdir "profiles/$curr_prof";
    open PROF, "<$curr_prof.txt" or die "File could not be opened\n";
    while (<PROF>) {
	if (m/^last_active/) {
	    my @last_active_date = split /:/;
	    close PROF;
	    shift @last_active_date;
	    return &create_date(split /,/, $last_active_date[0]);
	}
    }
    close PROF;
    print "No last_active date found in $curr_prof.txt, adding it now...\n";
    open PROF, ">>$curr_prof.txt" or die "File could not be opened\n";
    print PROF "last_active:";
    for (my $i = 0; $i < $#dinfo; $i++) {
	print PROF "$dinfo[$i],";
    }
    print PROF "$dinfo[$#dinfo]\n";
    close PROF;
    &get_last_active();
}


# ----------------------- #
#                         #
#        Mutators         #
#                         #    
# ----------------------- #


# sub set_last_active
# Parameters:
#    Array: The date info to update the file with
sub set_last_active(@) {
    open PROF, "<$curr_prof.txt" or die "File could not be opened\n";
    my @lines = <PROF>;
    close PROF;
    open PROF, ">$curr_prof.txt" or die "File could not be opened\n";
    for my $line (@lines) {
	print PROF $line unless $line =~ m/^last_active/;
    }
    close PROF;
    open PROF, ">>$curr_prof.txt" or die "File could not be opened\n";
    print PROF "last_active:";
    for (my $i = 0; $i < $#dinfo; $i++) {
	print PROF "$dinfo[$i],";
    }
    print PROF "$dinfo[$#dinfo]\n";
    close PROF;
}

# ----------------------- #
#                         #
#      Command Loop       #
#                         #    
# ----------------------- #


# sub cmd_loop
# Main program loop; used to read and interpret commands from the user
sub cmd_loop {
    print "\nWelcome to the to-list maker $curr_prof.\n";
    print "You were last active on...\n";
    &print_date(&get_last_active());
    print "\n\n";
    &date();
    print "It is now...\n";
    &print_date($cdt);
    print "\n\n";
    &set_last_active();
    # TO-DO add print of week's tasks here, check for tasks first
    print "Please enter a command (type \"help\" for a list of valid commands)\n";
    print "---> ";
    while (<STDIN>) {
	chomp;
	my $cmd = lc $_;
	my $curr_name = &get_name();
	for my $key (keys %cmds) {
	    &{$cmds{$key}}() if $key eq $cmd;
	}
	if ($curr_name ne &get_name()) {
	    last;
	}
	print "---> ";
    }
    &cmd_loop();
}

# sub print_date
# Parameters:
#    Scalar: The DateTime to be printed
sub print_date($) {
    my $dt = shift;
    my $wday = $dt->day_name();
    my $month = $dt->month_name();
    my @dinfo = &create_dinfo($dt);
    print "$wday, $month $dinfo[2] $dinfo[3] at " . $dinfo[4] . ":$dinfo[5]$dinfo[6]\n";
}

# sub print_task_date
# Parameters:
#    Scalar: The task date to be printed
sub print_task_date($) {
    my $dt = shift;
    my $wday = $dt->day_name();
    my $month = $dt->month_name();
    my @dinfo = &create_dinfo($dt);
    print "$wday, $month $dinfo[2] $dinfo[3]   ";
}

# sub print_tasks
# Prints a list of tasks in a formatted way
# Parameters:
#    Array: Tasks to be printed
sub print_tasks(@) {
    print "TaskID  Due Date                          Description\n";
    for my $task (@_) {
	my @task_line = split /:/, $task;
	print "$task_line[0]       ";
	@task_line = split /,/, $task_line[1];
	&print_task_date(&create_task_date(@task_line));
	print "$task_line[3]\n";
    }
}
	

# sub create_date
# Converts an array of date info into a DateTime object
# Parameters:
#    Array: in the form (day_of_week, month, day, year, hour, minute, am or pm)
# Returns:
#    Scalar: a DateTime obejct
sub create_date(@) {{
    return  DateTime->new(
	month         => $_[1],
	day           => $_[2],
	year          => $_[3],
	hour          => $_[4],
	minute        => $_[5],
	);
    }
}

# sub create_task_date
# Converts array of task info into a DateTime object
# Parameters:
#    Array: task info
# Returns:
#    Scalar: a DateTime object
sub create_task_date(@) {
    return DateTime->new(
	month         => $_[0],
	day           => $_[1],
	year          => $_[2],
	);
}

# sub create_dinfo
# Creates an array of date info about a DateTime object for easy writing to filies
# Parameters:
#    Scalar: DateTime object
# Returns:
#    Array: in the form (day_of_week, month, day, year, hour, minute, am or pm)
sub create_dinfo($) {
    my $dt = shift;
    return (
	$dt->day_of_week(),
	$dt->month(),
	$dt->day(),
	$dt->year(),
	$dt->hour(),
	$dt->minute(),
	$dt->am_or_pm(),
	);
}


# ----------------------- #
#                         #
#        Commands         #
#                         #    
# ----------------------- #


#sub add
# Adds a task to $curr_prof_tasks.txt
sub add {
    open TASKS, "<$curr_prof\_tasks.txt" or die "File could not be opened\n";
    my $taskID = 0;
    my $tinfo;
    my @lines = <TASKS>;
    for my $line (@lines) {
	my @old_tinfo = split /:/, $line;
	if ($taskID <= $old_tinfo[0]) {
	    $taskID = $old_tinfo[0] + 1;
	}
    }
    $tinfo = "$taskID:";
    print "What day this week will the task be due? (1=Monday - 7=Sunday): ";
    chomp($_ = <STDIN>);
    while ($_ > 7 or $_ < 1) {
	print "The due date must be between 1 and 7.\n";
        print "What day this week will the task be due? (1=Monday - 7=Sunday): ";
	chomp($_ = <STDIN>);
    }
    &this_week();
    # Look at each day of the week to figure out the month and day the assignment will be due
    for my $day (@week) {
	if ($_ == $day->day_of_week()) {
	    $tinfo = $tinfo . ($day->month()) . "," . ($day->day()) . "," . ($day->year()) . ",";
	    print "Assignment will be due " . ($day->day_name()) . " " . ($day->month_name()) . " " . ($day->day()) . " " . ($day->year()) . "\n";
	    last;
	}
    }
    print "Enter a description for the task (less than 50 characters with no commas): ";
    chomp($_ = <STDIN>);
    while (length $_ > 50 or $_ =~ m/,/) {
	print "$_ is an invalid task name.";
	print "Enter a description for the task (less than 50 characters with no commas): ";
	chomp($_ = <STDIN>);
    }
    $tinfo = $tinfo . "$_\n";
    &write_task($tinfo);
    print "Task successfully added\n";
}

# sub write_task
# Writes a task to the $curr_prof_tasks.txt file
# Parameters:
#    Scalar: The task information to write
sub write_task($) {
    my $tinfo = shift;
    open TASKS, ">>$curr_prof\_tasks.txt" or die "Failed to open file\n";
    print TASKS $tinfo;
    close TASKS;
}

# sub check
# Specify a completed or checked task, once completed it is removed from the tasks file
sub check {
    open TASKS, "<$curr_prof\_tasks.txt" or die "Failed to open file\n";
    my @lines = <TASKS>;
    close TASKS;
    my $lines_size = @lines;
    if ($lines_size <= 0) {
	print "You have no tasks to complete, hooray!\n";
	return;
    }
    &print_tasks(@lines);
    my @taskIDs;
    for my $line (@lines) {
	push(@taskIDs, (split /:/, $line)[0]);
    }
    print "Enter the TaskID of the task you wish to check off: ";
    chomp($_ = <STDIN>);
    for my $taskID (@taskIDs) {
	if ($_ == $taskID) {
	    &remove_task($taskID);
	}
    }
    print "Task has been removed.\n";
}

# sub remoove_task
# removes the specified task from the tasks file
# Parameters:
#    Scalar: The taskID to be removed
sub remove_task($) {
    my $taskID = $_[0];
    open TASKS, "<$curr_prof\_tasks.txt" or die "Failed to open file\n";
    my @lines = <TASKS>;
    close TASKS;
    open TASKS, ">$curr_prof\_tasks.txt" or die "failed to open file\n";
    for my $line (@lines) {
	$taskID =~ m/(\d+)/;
	my $ID = $1;
	$line =~ m/(\d+):/;
	print TASKS $line unless $ID == $1;
    }
    close TASKS;
    print "Successfully removed task\n";
}

# sub date
# Sets the values os $cdt and @dinfo to the current date and time
sub date {
    $cdt = DateTime->now(time_zone => $tzone);

    @dinfo = (
	$cdt->day_of_week(),
	$cdt->month(),
	$cdt->day(),
	$cdt->year(),
	$cdt->hour(),
	$cdt->minute(),
	$cdt->am_or_pm(),
	);
}

# sub recalc_date
# Recalculates the current date and time and then prints it
sub recalc_date {
    &date();
    print "It is now...\n";
    &print_date($cdt);
}

# sub this_week
# Calculate and the store DateTime objects for every day of this week
sub this_week {
    &date();
    push @week, $cdt->clone();
    push @week, $cdt->clone()->add(days => 1);
    push @week, $cdt->clone()->add(days => 2);
    push @week, $cdt->clone()->add(days => 3);
    push @week, $cdt->clone()->add(days => 4);
    push @week, $cdt->clone()->add(days => 5);
    push @week, $cdt->clone()->add(days => 6);
}

# sub help
# Prints out the usage message
sub help {
    print "Available commands are:\n";
    print "date    -    Gives the current date and time\n";
    print "load    -    Allows you to load or create a new user profile\n";
    print "add     -    Allows you to add a task\n";
    print "check   -    Allows you to check off a completed task\n";
    print "list    -    Lists the weeks currently assigned tasks by due date\n";
    print "help    -    Shows the valid commands\n";
    print "quit    -    Quits the program\n";
}

# sub load
# used to load a profile
sub load {
    print "Please enter the profile you wish to load (profiles cannot contain whitespace): ";
    chomp($_ = <STDIN>);
    # For simplicity's sake, disallow profiles with whitespace
    while (m/\s/) {
	print "Profiles cannot contain whitespace.\n";
	print "Please enter the profile you wish to load (profiles cannot contain whitespace): ";
	chomp($_ = <STDIN>);
    }
    &load_profile($_);
}

# sub list_tasks
# lists all currently assigned tasks
sub list_tasks {
    open TASKS, "<$curr_prof\_tasks.txt" or die "Failed to open file\n";
    my @lines = <TASKS>;
    close TASKS;
    &print_tasks(@lines);
}


# sub quit
# quits the program
sub quit {
    &date();
    &set_last_active();
    print"See you soon $curr_prof!\n";
    exit 0;
}
 
   
