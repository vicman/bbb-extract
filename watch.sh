#!/bin/bash -eu

#Si aparece este error  /bin/bash^M: intérprete erróneo: No existe el archivo o el directorio, ejecutar dos2unix nombrescript.sh

echo "Holillas"

DIRECTORY_TO_OBSERVE="/var/bigbluebutton/recording/raw/"      # folder to observe
REMOTE_URL="http://192.168.2.70//meeting/public/api/webhooks/receiver" #api to send data POST


#read folder
watch() {

  inotifywait -r -m -e create -e moved_to $DIRECTORY_TO_OBSERVE  | while read path action file;do
     if [[ "$file" = "events.xml" ]]; then  
      echo "Change detected date $(date) in ${path} action ${action} in file ${file}" \
      build ${path}    
  	fi
  done


}

# create zip
build() {

   cd $1   
   #extrae el nombre del directorio
   folder="${1%"${1##*[!/]}"}" # extglob-free multi-trailing-/ trim
   folder="${folder##*/}"                  # remove everything before the last /
   
   echo $folder;
  
   zip "${folder}.zip" "events.xml" 
   transfer "${folder}.zip" $folder
}

#send data to api
transfer() { 
  if [ $# -eq 0 ]; then
    echo -e "No arguments specified."; 
    return 1; 
  fi
  tmpfile=$( mktemp -t transferXXX ); 
  curl --progress-bar -i -X POST -H "Content-Type: multipart/form-data" \
          -F "data=@$1" -F "internal_id=$2" $REMOTE_URL >> $tmpfile ; 
  cat $tmpfile; 
  rm -f $tmpfile; 
  rm -f $1; 
}



watch