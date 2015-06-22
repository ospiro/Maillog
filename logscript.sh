#!/bin/bash
#This script parses /var/log/maillog continuously into the following format TIMESTAMP SOURCE-IP SOURCE-ADDR SUBJ.
#Created by Oliver Spiro on June 22 2015

#trap keyboard interrupts to prevent tail -f from continuing.

trap 'pkill tail
echo " Exit cleanup successful";
exit' SIGINT SIGQUIT SIGHUP SIGTERM

# end of trap

#Mail log is CSV, awk is used to parse the input. The first awk chooses the relevent sections from the CSV,sed and the second awk remove the extraneous entries from them.

tail -f /var/log/maillog | grep --line-buffered "Passed"|sed s/{.*}/""/| awk -F"," -v ORS="" '{

#Everything from here on is awk.

print $1 $2; 	

for(i=10;i<=NF;++i){	        	#This loop makes sure to send the entire subject line through the pipe, even if it contains commas.
    if ($i ~ /.From:.*/){ 		#Terminates loop when reaches end of double quoted subject line, the regexp is designed to ignore bugs such as double quotes within the email subject.
        print "\n";
        break;
    }
    if($i~/.Subject:.*/){
        print $i;
    }
    else{
        print $i ",";
    }  	 	                        #Awk normally would delete the commas, so it is necessary to put them back in.
}

}' | awk -v ORS="" '{


if($9=="MYNETS"){				#This if statement deals with the occasional case wherein the source IP is preceded by "MYNETS LOCAL"
    print $1 " " $2 " " $3 " " $12 " " $13 " ";
    for(i=16;i<=NF;++i){
        print $i " ";
    }
    print "\n";
}


if ($9!="MYNETS"){				#This is the other case
    print $1 " " $2 " " $3 " " $10 " " $11 " ";
    for(i=14;i<=NF;++i){
        print $i " ";
    }
    print "\n";
}

}'
