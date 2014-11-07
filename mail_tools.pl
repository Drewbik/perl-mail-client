#!/usr/bin/perl

#Author: Andrew Porter
#Title: Drew's omnipotent mail script.

use strict;
use warnings;
use Mail::IMAPClient;
use Term::ANSIColor;
use Term::ReadKey;
use Email::Folder::Exchange;
use Net::SMTP;

my $do;

#Creates an IMAP connection.
system ("clear");
my $authmech = "NTLM";
print color("cyan"), "Welcome to Drew's mailbox script! We'll need details in order to connect:\n", color("reset");
print "Mailserver hostname/IP address?\n";
chomp (my $server = <STDIN>);
print "Email address?\n";
chomp (my $user = <STDIN>);
print "Password?\n";
ReadMode('noecho');
chomp (my $pass = <STDIN>);
ReadMode(0);
my $imap = Mail::IMAPClient->new(
		Server  => $server,
		User    => $user,
		Password  => $pass
		)
or die "IMAP Failure: $@";

#Menu.
system("clear");
while (42) {
	&menu();
	my $do=&getinput();
	if($do eq "1"){
		&delete_mail()
	}
	if($do eq "2"){
		&delete_subj()
	}
	if($do eq "3"){
		&size()
	}
	if($do eq "4"){
		&create_folder()
	}
	if($do eq "5"){
		&delete_ondate()
	}
	if($do eq "6"){
		&list_folders()
	}
	if($do eq "7"){
		&sent_since()
	}
	if($do eq "8"){
		&train()
	}
	if($do eq "9"){
		&quota()
	}
	if($do eq "10"){
		&spam()
	} 
	if($do eq "11"){
		&send_mail()
	}
	if($do eq "12"){
		&check_messages()
	}
	if($do eq "0"){
		&send_mail()
	}  else {
		print "That isn't an option! Try again...\n";
	} 
}

exit(0);

sub menu {
	print color("cyan"), "Options Menu - Enter a number!\n", color("reset");
	my $user = $imap->User();
	print "Currently logged into: $user\n";
	print "0 - Send mail (BETA)\n";
	print "1 - Delete mail: Before date.\n";
	print "2 - Delete mail: Mail Delivery Failures.\n";
	print "3 - Mailbox size.\n";
	print "4 - Create folder.\n";
	print "5 - Delete mail: On date.\n";
	print "6 - Show folders.\n";
	print "7 - Delete mail: Since date\n";
	print "8 - ASCII Train :)\n";
	print "9 - Quota\n";

}


#Subroutines

#Gets user input.
sub getinput(){
	my $option=<STDIN>;
	chomp($option);
	return $option;
}

#Check current messages
sub check_messages{
	print "Enter the folder you'd like to check:\n";
	chomp (my $check = <STDIN>);
	$imap->select($check);
#my @messages = ($imap->seen(), $imap->unseen);
#foreach my $id (@messages) {print "$id\n";}
	my @msgs = $imap->messages or die "Could not messages: $@\n";
	my $i;
	foreach $i (@msgs)
	{
		print "\$UID = $i\n";
	}
}

#Sending mail
sub send_mail{
#Testing SMTP connection
#my $smtp = Net::SMTP->new('mail91.extendcp.co.uk')
#	or die "Couldn't connect to SMTP server\n";
	#my $user1 = 'info@heartinternet.uk';
	print "Enter the recipient address:\n";
	my @recipients;
	chomp (my $_ = <STDIN>);
	push @recipients, $_;
	#	print "Wanna send to someone else?\nY/N\n";
	#	$do=&getinput();
	#	if($do eq "y" || $do eq "Y"){
	#		print "Enter additional address:\n";
	#		chomp (my $_ = <STDIN>);
	#		push @recipients, $_;
		print "Enter the subject:\n";
		chomp (my $subject = <STDIN>);
		print "Enter your message:\n";
		chomp (my $message = <STDIN>);
		my $mailer = new Net::SMTP(  
				$server,
				Port    =>      587,  
				Debug   => 1) || die "Cannot connect to smtp server";
		$mailer->auth($user, $pass);
		$mailer->mail($user);
		$mailer->recipient(@recipients);
		$mailer->data;

#$mailer->datasend("To: @recipients\n";
		$mailer->datasend("Subject: $subject");
		$mailer->datasend("\n");  
		$mailer->datasend($message);  
		$mailer->dataend;  
		$mailer->quit;	
		}

#Spam.
#Quota
sub quota{
	my $quotaroot = "Inbox";
	my $results = $imap->getquotaroot($quotaroot)
		or die "Couldn't get quota for $quotaroot: $@\n";
	print "The quota for $user is: $results\n";
}

#Train.
sub train(){
	system("/bin/bash /home/andrew.porter/train.sh");
}

#Delete since.
sub sent_since{
	system ("clear");
	print "Which folder are we removing mail from?\n";
	chomp (my $folder = <STDIN>);
	$imap->select($folder)
		or die "Nah, it cropped: $!\n";
	print "Since which date?\n";
	chomp (my $date = <STDIN>);
	my @msgs = $imap->sentsince($date);
	scalar(@msgs) and $imap->delete_message(\@msgs)
		or warn "No messages found since $date.\n";
	$imap->expunge($folder);
	$imap->close;
	print "Press enter to continue\n";
	<STDIN>;
}


sub delete_mail{
	system ("clear");
	print color("cyan"), "From which folder would you like to delete mail from?\n", color("reset");
	chomp (my $mailbox = <STDIN>);
	$imap->select($mailbox)
		or die "Unable to select mailbox: $!";
	print color("cyan"), "Would you like to delete mail from before a particular date? (Y/N)\n", color("reset");
	$do=&getinput();
	if($do eq "y" || $do eq "Y"){
		print color("cyan"), "Which date? (DD-MON-YYYY)\n", color("reset");
		chomp (my $date = <STDIN>);
		my @msgs = $imap->before($date);
		scalar(@msgs) and $imap->delete_message(\@msgs)
			or warn "No messages found before $date.\n";
		$imap->expunge($mailbox);
		$imap->close;
	} else {
		my @msgs = $imap->search('ALL');
		scalar(@msgs) and $imap->delete_message(\@msgs)
			or die "Couldn't get all messages\n";
		$imap->expunge($mailbox);
		$imap->close;
		print "Press ENTER to continue:\n";
		<STDIN>;
	}
}

#Delete mail delivery failures. 
sub delete_subj{
	print color("cyan"), "Enter the folder we're removing Mail Delivery failures from:\n", color("reset");
	chomp (my $mailbox = <STDIN>);
	$imap->select($mailbox);
	my $subject = "Mail delivery failed";
	my @msgs = $imap->search('SUBJECT' => $subject);
	scalar(@msgs) and $imap->delete_message(\@msgs);
	$imap->expunge($mailbox);
	$imap->close;
	print "Press ENTER to continue:\n";
	<STDIN>;
} 

#Delete on a specified date.
sub delete_ondate{
	print color("cyan"), "Please confirm the folder you'd like to remove mail from:\n", color("reset");
	chomp (my $mailbox = <STDIN>);
	$imap->select($mailbox);
	print color("cyan"), "Which date? (DD-MON-YYYY)\n", color("reset");
	chomp (my $date = <STDIN>);
	my @msgs = $imap->senton($date);
	scalar(@msgs) and $imap->delete_message(\@msgs)
		or warn "No messages found on $date.\n";
	$imap->expunge($mailbox);
	$imap->close;
	print "Press ENTER to continue:\n";
	<STDIN>
}


#Check mailbox size.
sub size {
#	my $folders = $imap->folders or die "Failed to get folders\n";
#	my $sizes = {};
#
#	foreach my $folder (@{$folders}){
#		$imap->examine($folder) or next;
#
#		if ($sizes->{$folder} > 1024 * 1024){
#		my	$size = int($sizes->{$folder} / (1024 * 1024)) . "MB";
#		}
#
#		next unless $size =~ /MB/;
#
#		print "$size\t$folder\n";
#	}
#	print "Press ENTER to continue\n";
#	<STDIN>;
}

#Create folder
sub create_folder{
	system ("clear");
	print color("cyan"), "Please enter the name of the folder you'd like to create on the mailbox:\n", color("reset");
	chomp (my $new_folder = <STDIN>);
	$imap->create ($new_folder);
	print "Successfully created $new_folder"
		or die "Could not create $new_folder: $@\n";
	print "Press ENTER to continue\n";
	<STDIN>;
}

#List folders
sub list_folders{
#	system ("clear");
#	print "$user currently has the following folders:\n";
#	print join(", ",$imap->folders),".\n";
#		if ($sizes->{$folder} > 1024 * 1024){
#			$size = int($sizes->{$folder} / (1024 * 1024)) . "MB";
#		}
#
#		next unless $size =~ /MB/;
#
#		print "$size\t$folder\n";
#print "Press ENTER to continue\n";
 #       <STDIN>;
	}

#Create folder
sub create_folder{
	system ("clear");
	print color("cyan"), "Please enter the name of the folder you'd like to create on the mailbox:\n", color("reset");
	chomp (my $new_folder = <STDIN>);
	$imap->create ($new_folder);
	print "Successfully created $new_folder"
		or die "Could not create $new_folder: $@\n";
	print "Press ENTER to continue\n";
	<STDIN>;
}

#List folders
sub list_folders{
	system ("clear");
	print "$user currently has the following folders:\n";
	print join(", ",$imap->folders),".\n";
	print "Press ENTER to continue\n";
	<STDIN>
}
