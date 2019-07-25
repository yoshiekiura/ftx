for file in $(ls lib/daemons/*)
do 
  vi +':w ++ff=unix' +':q' ${file}
  vi +':set fileformat=unix' +':w' +':q' ${file}
done
