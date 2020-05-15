#!/bin/bash

if [[ " $@ " =~ " --help " ]]; then
	echo "Usage: processData [state list]"
	echo "Where [state list] is a list of strings representing the states you wish to process counties for."
	exit
fi

if [ ! -d "../covid-19-data" ] 
then
    echo "Directory ../covid-19-data does not exist, please clone https://github.com/nytimes/covid-19-data to the same level as covid-19-graphing." 
    exit -1
fi

#supplement data with daily case/death differential
awk -F "," '
		NR==1{print $1","$2","$3",newcases,newdeaths"}
		NR==2{pcase=$2; pdeath=$3; print $1","$2","$3",0,0"}
		NR>2{print $1","$2","$3","$2-pcase","$3-pdeath; pcase=$2; pdeath=$3}
' ../covid-19-data/us.csv > country/us.csv
#plot the us
gnuplot -e "titel='US'; filename='country/us.csv'; outpt='country/us.png" graphCountry

#for each state in the states file
cat ../covid-19-data/us-states.csv | awk -F "," 'NR>1{print $2}' | sort -u | while read -r state; do
	echo $state
	#create a state specific data file
	cat ../covid-19-data/us-states.csv | grep date > "states/${state}.csv"
	cat ../covid-19-data/us-states.csv | grep "$state" >> "states/${state}.csv"
	#supplement the data file with daily case/death differential
	awk -F "," '
		NR==1{print $1","$2","$3","$4","$5",newcases,newdeaths"}
		NR==2{pcase=$4; pdeath=$5; print $1","$2","$3","$4","$5",0,0"}
		NR>2{print $1","$2","$3","$4","$5","$4-pcase","$5-pdeath; pcase=$4; pdeath=$5}
	' "states/${state}.csv" > states/tmp.csv && mv states/tmp.csv "states/${state}.csv"
	#plot the state
	gnuplot -e "titel='${state}'; filename='states/${state}.csv'; outpt='states/${state}.png" graphstate
	
	if [[ " $@ " =~ " $state " ]]; then
		echo "Processing counties for $state"
	else
		continue
	fi
	
	#process each county in the state
	cat ../covid-19-data/us-counties.csv | grep $state | awk -F "," '{print $4}' | sort -u  | awk 'NF' | while read -r mip; do
		#find county name for mip
		county=$(cat ../covid-19-data/us-counties.csv | grep $mip | head -n 1 | awk -F "," '{print $2}')
		echo -n "$state-$mip-${county}..."
		# create a county specific data file
		cat ../covid-19-data/us-counties.csv | grep date > "counties/${state}-${mip}-${county}.csv"
		cat ../covid-19-data/us-counties.csv | grep $state | grep $mip >> "counties/${state}-${mip}-${county}.csv"
		#supplement the data file with daily case/death differential
		awk -F "," '
			NR==1{print $1","$2","$3","$4","$5","$6",newcases,newdeaths"}
			NR==2{pcase=$5; pdeath=$6; print $1","$2","$3","$4","$5","$6",0,0"}
			NR>2{print $1","$2","$3","$4","$5","$6","$5-pcase","$6-pdeath; pcase=$5; pdeath=$6}
		' "counties/${state}-${mip}-${county}.csv" > counties/tmp.csv && mv counties/tmp.csv "counties/${state}-${mip}-${county}.csv"
		#wait for the copy to finish, weird bug
		sleep .1
		#plot the county
		gnuplot -e "titel='${state}-${mip}-${county}'; filename='counties/${state}-${mip}-${county}.csv'; outpt='counties/${state}-${mip}-${county}.png" graphCounty
		echo 
	done
done


	
	
