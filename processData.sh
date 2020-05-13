#!/bin/bash

#process us
awk -F "," '
		NR==1{print $1","$2","$3",newcases,newdeaths"}
		NR==2{pcase=$2; pdeath=$3; print $1","$2","$3",0,0"}
		NR>2{print $1","$2","$3","$2-pcase","$3-pdeath; pcase=$2; pdeath=$3}
' ../covid-19-data/us.csv > country/us.csv
gnuplot -e "titel='US'; filename='country/us.csv'; outpt='country/us.png" graphCountry

cat ../covid-19-data/us-states.csv | awk -F "," 'NR>1{print $2}' | sort -u | while read -r state; do
	echo $state
	# process the state
	cat ../covid-19-data/us-states.csv | grep date > "states/${state}.csv"
	cat ../covid-19-data/us-states.csv | grep "$state" >> "states/${state}.csv"
	awk -F "," '
		NR==1{print $1","$2","$3","$4","$5",newcases,newdeaths"}
		NR==2{pcase=$4; pdeath=$5; print $1","$2","$3","$4","$5",0,0"}
		NR>2{print $1","$2","$3","$4","$5","$4-pcase","$5-pdeath; pcase=$4; pdeath=$5}
	' "states/${state}.csv" > states/tmp.csv && mv states/tmp.csv "states/${state}.csv"
	gnuplot -e "titel='${state}'; filename='states/${state}.csv'; outpt='states/${state}.png" graphstate
	
	#only process indiana to start
	if [ "$state" != "Indiana" ]; then
		continue
	fi
	
	#process each county in the state
	cat ../covid-19-data/us-counties.csv | grep $state | awk -F "," '{print $4}' | sort -u | while read -r mip; do
		if [ "" == "$mip" ]; then
			continue
		fi
		echo -n "$state-$mip..."
		cat ../covid-19-data/us-counties.csv | grep date > "counties/${state}-${mip}.csv"
		cat ../covid-19-data/us-counties.csv | grep $state | grep $mip >> "counties/${state}-${mip}.csv"
		awk -F "," '
			NR==1{print $1","$2","$3","$4","$5","$6",newcases,newdeaths"}
			NR==2{pcase=$5; pdeath=$6; print $1","$2","$3","$4","$5","$6",0,0"}
			NR>2{print $1","$2","$3","$4","$5","$6","$5-pcase","$6-pdeath; pcase=$5; pdeath=$6}
		' "counties/${state}-${mip}.csv" > counties/tmp.csv && mv counties/tmp.csv "counties/${state}-${mip}.csv"
		sleep 1
		gnuplot -e "titel='${state}-${mip}'; filename='counties/${state}-${mip}.csv'; outpt='counties/${state}-${mip}.png" graphCounty
	done
done


	
	
