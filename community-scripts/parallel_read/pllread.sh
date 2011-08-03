URL="Enter the complete url here";
for i in {1..1000};
do
echo $URL 
done | xargs -L1 -P50 wget -O /dev/null
