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

#supplement data with daily case/death differential
awk -F "," '
		NR==1{print $1","$2","$3",newcases,newdeaths"}
		NR==2{pcase=$2; pdeath=$3; print $1","$2","$3",0,0"}
		NR>2{print $1","$2","$3","$2-pcase","$3-pdeath; pcase=$2; pdeath=$3}
' ../covid-19-data/us.csv > country/us.csv
#add moving average for cases and deaths
awk -F "," '
	{c[NR]=$4; csum+=$4; d[NR]=$5; dsum+=$5}
	NR==1{print $1","$2","$3","$4","$5",newcases5daymovingavg,newdeaths5daymovingavg"}
	NR>1&&NR<=5{print $1","$2","$3","$4","$5",0,0"}
	NR>5{csum-=c[NR-5]; dsum-=d[NR-5]; print $1","$2","$3","$4","$5","csum/5","dsum/5}
' country/us.csv > country/tmp.csv && mv country/tmp.csv country/us.csv
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
	#add moving average for cases and deaths
	awk -F "," '
		{c[NR]=$6; csum+=$6; d[NR]=$7; dsum+=$7}
		NR==1{print $1","$2","$3","$4","$5","$6","$7",newcases5daymovingavg,newdeaths5daymovingavg"}
		NR>1&&NR<=5{print $1","$2","$3","$4","$5","$6","$7",0,0"}
		NR>5{csum-=c[NR-5]; dsum-=d[NR-5]; print $1","$2","$3","$4","$5","$6","$7","csum/5","dsum/5}
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
		if [[ " $@ " =~ " $county " ]]; then
			echo "Processing county $county"
		else
			continue
		fi
		if [[ "$state" == "$county" ]]; then
			#some states have other states as counties!
			continue
		fi
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
		#add moving average for cases and deaths
		awk -F "," '
			{c[NR]=$7; csum+=$7; d[NR]=$8; dsum+=$8}
			NR==1{print $1","$2","$3","$4","$5","$6","$7","$8",newcases5daymovingavg,newdeaths5daymovingavg"}
			NR>1&&NR<=5{print $1","$2","$3","$4","$5","$6","$7","$8",0,0"}
			NR>5{csum-=c[NR-5]; dsum-=d[NR-5]; print $1","$2","$3","$4","$5","$6","$7","$8","csum/5","dsum/5}
		' "counties/${state}-${mip}-${county}.csv" > counties/tmp.csv && mv counties/tmp.csv "counties/${state}-${mip}-${county}.csv"
		#wait for the copy to finish, weird bug
		sleep .1
		#plot the county
		gnuplot -e "titel='${state}-${mip}-${county}'; filename='counties/${state}-${mip}-${county}.csv'; outpt='counties/${state}-${mip}-${county}.png" graphCounty
		echo 
	done
done


	
	
