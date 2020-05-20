#!/bin/bash

if [[ " $@ " =~ " --help " ]]; then
	echo "Usage: processData [state/county list]"
	echo "Where [state/county list] is a list of strings representing the states you wish to process counties for, and the counties in that state."
	echo "By default, only the US and states will be processed/graphed. If you want to process Marion county in Indiana, run:"
	echo "./processData.sh Indiana Marion"
	exit
fi

if [ ! -d "../covid-19-data" ] 
then
    echo "Directory ../covid-19-data does not exist, please clone https://github.com/nytimes/covid-19-data to the same level as covid-19-graphing." 
    exit -1
fi

mkdir -p country
mkdir -p states
mkdir -p counties

function processFile {
	file=$1
	echo "$file"
	#supplement the data file with daily case/death differential
	awk -F "," '
		NR==1{print $0",newcases,newdeaths"}
		NR==2{pcase=$5; pdeath=$6; print $0",0,0"}
		NR>2{print $0","$5-pcase","$6-pdeath; pcase=$5; pdeath=$6}
	' "$file.csv" > tmp.csv && mv tmp.csv "$file.csv"
	#add moving average for cases and deaths
	awk -F "," '
		{c[NR]=$7; csum+=$7; d[NR]=$8; dsum+=$8}
		NR==1{print $0",newcases5daymovingavg,newdeaths5daymovingavg"}
		NR>1&&NR<=5{print $0",0,0"}
		NR>5{csum-=c[NR-5]; dsum-=d[NR-5]; print $0","csum/5","dsum/5}
	' "$file.csv" > tmp.csv && mv tmp.csv "$file.csv"
	#wait for the copy to finish, weird bug
	sleep .1
	#plot the entity
	gnuplot -e "titel='$file'; filename='$file.csv'; outpt='$file.svg" graph
}

#copy us data
usfile="country/us"
cat ../covid-19-data/us.csv > $usfile.csv
#supplement data with columns to match county structure
awk -F "," '
	{print $1",NA,NA,NA,"$2","$3}
' $usfile.csv > tmp.csv && mv tmp.csv $usfile.csv
processFile $usfile

#for each state in the states file
cat ../covid-19-data/us-states.csv | awk -F "," 'NR>1{print $2}' | sort -u | while read -r state; do
	#echo $state
	statefile="states/$state"
	#create a state specific data file
	cat ../covid-19-data/us-states.csv | head -n 1 | grep date > "$statefile.csv"
	cat ../covid-19-data/us-states.csv | grep "$state" >> "$statefile.csv"
	#supplement data with columns to match county structure
	awk -F "," '
		{print $1","$2","$3",NA,"$4","$5}
	' "$statefile.csv" > tmp.csv && mv tmp.csv "$statefile.csv"
	processFile "$statefile"

	#check if we're doing counties for this state
	if [[ " $@ " =~ " $state " ]]; then
		echo "Processing counties for $state"
	else
		continue
	fi
	
	#process each county in the state
	cat ../covid-19-data/us-counties.csv | grep $state | awk -F "," '{print $4}' | sort -u  | awk 'NF' | while read -r mip; do
		#find county name for mip
		county=$(cat ../covid-19-data/us-counties.csv | grep $mip | head -n 1 | awk -F "," '{print $2}')
		#check if we're processing this county in this state
		if [[ ! " $@ " =~ " $county " ]]; then
			continue
		fi
		if [[ "$state" == "$county" ]]; then
			#some states have other states as counties!
			continue
		fi
		countyfile="counties/${state}-${mip}-${county}"
		# create a county specific data file
		cat ../covid-19-data/us-counties.csv | head -n 1 | grep date > "$countyfile.csv"
		cat ../covid-19-data/us-counties.csv | grep $state | grep $mip >> "$countyfile.csv"
		#no supplement necessary for county file, already has proper number of columns
		processFile "$countyfile"
	done
done


	
	
