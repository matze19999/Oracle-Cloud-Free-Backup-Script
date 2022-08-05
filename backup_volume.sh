#!/usr/bin/env bash
#source ~/.zshrc

PROFILE_NAME=DEFAULT
BACKUP_NAME=Full_Backup
COMPARTMENT_ID='ocid1.tenancy.oc1..******************************************' # Get this from your Oracle Profile
TMP_BACKUP_NAME=$(date +%Y-%m-%d_%H-%M-%S)

echo "Running at ${TMP_BACKUP_NAME}."
echo "Getting previous backup..."

OUTPUT=$(oci bv backup list --compartment-id ${COMPARTMENT_ID} --display-name ${BACKUP_NAME} --lifecycle-state AVAILABLE --query "data [0].{VolumeId:\"volume-id\",id:id}" --raw-output --profile ${PROFILE_NAME})
LAST_BACKUP_ID=$(echo $OUTPUT | /usr/bin/jq -r '.id')
VOLUME_ID=$(echo $OUTPUT | /usr/bin/jq -r '.VolumeId')

echo "Last backup id: $LAST_BACKUP_ID"
echo "Volume id: $VOLUME_ID"

echo "Creating new backup..."
NEW_BACKUP_ID=$(oci bv backup create --volume-id ${VOLUME_ID} --type FULL --display-name ${TMP_BACKUP_NAME} --wait-for-state AVAILABLE --query "data.id" --raw-output --profile ${PROFILE_NAME})

if [ -z "$NEW_BACKUP_ID" ]
then
    echo "New backup creation failed...Exiting script!"; exit
else
    echo "New backup id: $NEW_BACKUP_ID"
fi

echo "Deleting old backup..."
DELETED_BACKUP=$(oci bv backup delete --force --volume-backup-id ${LAST_BACKUP_ID} --wait-for-state TERMINATED --profile ${PROFILE_NAME})

echo "Renaming temp backup..."
RENAMED_BACKUP=$(oci bv backup update --volume-backup-id ${NEW_BACKUP_ID} --display-name ${BACKUP_NAME} --profile ${PROFILE_NAME})

echo "Backup process complete! Goodbye!"
