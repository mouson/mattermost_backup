#!/usr/bin/env bash
BASEPATH=`dirname "${BASH_SOURCE[0]}"`

source ${BASEPATH}/conf.sh

use_message ()
{
	echo "USAGE: $0 [OPTIONS]"
	echo "OPTIONS:"
	echo "d Daily backup"
	echo "w Weekly backup"
	echo "m Monthly backup"
	exit 1
}

db_backup ()
{
    mkdir -pv "${BACKUP_PATH}/${BACKUP_DIR_NAME_}${TYPE}" || exit 1
    echo "Snapshot backuping ..."
    PGPASSWORD=${DB_PASS} ${PG_DUMP_PATH}pg_dump --username=${DB_USER} --host=${DB_HOST} --port=${DB_PORT} --dbname=${DB_NAME} > "${BACKUP_PATH}"/"${DB_BACKUP_NAME}"
    echo "(${DB_BACKUP_NAME}) done."
    echo
}

backup ()
{
    TYPE=$1
    echo "Backuping directory before sending it to a remote place..."
    mkdir -pv "${BACKUP_PATH}/${BACKUP_DIR_NAME_}${TYPE}" || exit 1
    cd "${BACKUP_PATH}/${BACKUP_DIR_NAME_}${TYPE}" || exit 1
    mv "${BACKUP_PATH}/${DB_BACKUP_NAME}" "${BACKUP_PATH}/${BACKUP_DIR_NAME_}${TYPE}"
    tar -czf "${BACKUP_PACKAGE_NAME}" "${DATA_HOME}" || exit 1
    # Make check sum file
    sha256sum "${BACKUP_PACKAGE_NAME}" > "${BACKUP_SHASUM_NAME}" || exit 1
    tar -czf ../"${BACKUP_DIR_NAME_}${TYPE}".tgz ${MODEL_BKP}* || exit 1
    # Send Backup File to remote path
    cd "${BACKUP_PATH}" || exit 1
    ${SCP} "${BACKUP_DIR_NAME_}${TYPE}".tgz "${SSH_USR}"@"${RHOST}":"${REMOTE_BACKUP_PATH}"
    rm -rf "${BACKUP_PATH:?}/"*
    echo "Check current archive chechsum done"
    echo "(${BACKUP_DIR_NAME_}${TYPE}) done."
}

remove_old ()
{
    echo "Remove old"
    TYPE=$1
    if [[ "${TYPE}" == day ]]; then
        TIME=1
    elif [[ "${TYPE}" == week ]]; then
        TIME=14
    elif [[ "${TYPE}" == month ]]; then
        TIME=60
    fi
    echo "${MODEL_BKP}*${TYPE}.tgz"
    echo "find ${REMOTE_BACKUP_PATH} -regex ${MODEL_BKP}*${TYPE}.tgz -mtime +${TIME} -exec rm {} \;"
    ${SSH} "${SSH_USR}"@"${RHOST}" "find ${REMOTE_BACKUP_PATH} -regex ${MODEL_BKP}*${TYPE}.tgz -ctime +${TIME} -exec rm {} \;"
}

check_ssh ()
{
    echo "Check SSH"
    ${SSH} "${SSH_USR}"@"${RHOST}" "touch ${REMOTE_BACKUP_PATH}/${SSH_TEST_FILE} && rm -f ${REMOTE_BACKUP_PATH}/${SSH_TEST_FILE}"
    if [[ $? != 0 ]]; then
        echo " Can not access to remote server !"
        echo " Check: hostname, remore user, ssh-keys, directory permissions !"
        exit 1
    fi
}

check_remote_sums ()
{
    echo "Check remote sums"
    ${SCP} checksum.sh "${SSH_USR}"@"${RHOST}":"${REMOTE_BACKUP_PATH}"
    ${SSH} "${SSH_USR}"@"${RHOST}" "bash ${REMOTE_BACKUP_PATH}/checksum.sh"
    if [[ $? -eq 0 ]]; then
        ${SSH} "${SSH_USR}"@"${RHOST}" "rm ${REMOTE_BACKUP_PATH}/checksum.sh && rm ${REMOTE_BACKUP_PATH}/${MODEL_BKP}{.tar.*,sql_*}"
        echo "Check remote sums done"
    else
        echo "Check remote sums failed."
    fi
}

if [[ $# -ne 1 ]]; then
    use_message
else
    if [[ "$1" == d ]]; then
        TYPE=day
    elif [[ "$1" == w ]]; then
        TYPE=week
    elif [[ "$1" == m ]]; then
        TYPE=month
    fi
    check_ssh
    remove_old ${TYPE}
    check_remote_sums
    db_backup
    backup ${TYPE}
fi

exit 0
