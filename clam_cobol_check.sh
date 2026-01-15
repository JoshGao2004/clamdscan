script name:
clam_cobol_check.sh 
#!/bin/bash

LOG=/tmp/clamcheck.log
TIME=$(date +"%T")
TESTFILE=/software/xxx/clamtest.txt
HOSTNAME=`hostname`
EMAILADDR=xxxx@gmail.com
STATUS=0

# check if the clamerror.log exist, if yes, remove it
if [ !  -z  ${LOG} ]; then
        rm -rf ${LOG}
fi

# check if the clamtest.txt file exist, if no, create it
# always create the testfile with the correct permission

       touch ${TESTFILE}
       chown psadm2 ${TESTFILE}
       chgrp oinstall  ${TESTFILE}
       chmod 744  ${TESTFILE}


# check clamdAV

printf "\n-----------------------------\nChecking for clamAV: \n\n" >> ${LOG}

sudo su psadm2 -c "/bin/clamdscan  ${TESTFILE}" >> ${LOG}
if [ $? == 0 ]; then
        echo "${TIME}: All good!" >> ${LOG}
        MSGTEXT="${TIME}: Clam service is running ok as psadm2."
        # exit 0

elif [ $? == 127 ]; then
        echo "Error with clamdscan syntax." >> ${LOG}
        STATUS=1

else
        systemctl stop clamd@scan &
        systemctl start clamd@scan &
        MSGTEXT="${TIME}: Clam service was down. Started it up."
        echo ${MSGTEXT} >> ${LOG}
        echo ${MSGTEXT} | /bin/mailx -v -s "${HOSTNAME}: Clam service restarted" -r "xxx@gmail.ca" "${EMAILADDR}"
        STATUS=1

fi

printf "\n---------------------------------\nChecking for Cobol:\n\n" >> ${LOG}

# Check if Cobol processes mfcesd&lserv are running
if pgrep -x "mfcesd" >> /dev/null; then
        printf "mfcesd is running\n" >> ${LOG}

else
        /var/microfocuslicensing/bin/mfcesd
        printf "Cobol mfcesd process not running. Started it\n" >> ${LOG}
        STATUS=1
fi

if  pgrep -x "lserv" > /dev/null ; then
         printf "lserv is running"  >> ${LOG}

else
         /var/microfocuslicensing/bin/startlserv.sh
         printf "\nCobol lserv process not running. Started it" >> ${LOG}
         STATUS=1
fi

printf "\n---------------------------------\nChecking and cleaning dump files:\n\n" >> ${LOG}
cd /xxx
CORECOUNT=`ls -l core.* | wc -l`
printf "\nRemoving ${CORECOUNT} core dumps from DOMAIN..." >> ${LOG}
rm -f core.*

cd /xxx
CORECOUNT=`ls -l core.* | wc -l`
printf "\nRemoving ${CORECOUNT} core dumps from DOMAIN..." >> ${LOG}
rm -f core.*


exit ${STATUS}
