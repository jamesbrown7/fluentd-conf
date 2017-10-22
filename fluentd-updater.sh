#!/usr/bin/env bash

S3BUCKET_NAME="fluentd.conf.bucket"

FLUENTD_DEST="/etc/td-agent"
FLUENTD_CONF_NAME="td-agent.conf"

TMPDIR="/tmp"
ERR_LOG="${TMPDIR}/td-agent-cron.log"

function rotateLog() {
    tail -1000 ${ERR_LOG} > ${ERR_LOG}.tmp
    mv -f ${ERR_LOG}.tmp ${ERR_LOG}
}

function log() {
    echo "`date` ${*}" >> ${ERR_LOG}
}

function md5() {
    md5sum ${*} | cut -f1 -d' '
}

# Rotate the log file, if any
rotateLog

if [[ -r "${FLUENTD_DEST}/${FLUENTD_CONF_NAME}" ]]; then
    curMd5=`md5 ${FLUENTD_DEST}/${FLUENTD_CONF_NAME}`
fi

aws s3 cp s3://${S3BUCKET_NAME}/${FLUENTD_CONF_NAME} ${TMPDIR} 1>>/dev/null 2>>${ERR_LOG}
if [ ${?} -ne 0 ]; then
    log "AWS S3 copy of s3://${S3BUCKET_NAME}/${FLUENTD_CONF_NAME} failed, see above error message"
    exit 1
fi

if [ ! -r "${TMPDIR}/${FLUENTD_CONF_NAME}" ]; then
    log "s3://${S3BUCKET_NAME}/${FLUENTD_CONF_NAME} could not be read"
    exit 1
fi

newMd5=`md5 ${TMPDIR}/${FLUENTD_CONF_NAME}`

if [[ "${curMd5}" != "${newMd5}" ]]; then
    install -D -m 0644 "${TMPDIR}/${FLUENTD_CONF_NAME}" "${FLUENTD_DEST}/${FLUENTD_CONF_NAME}"
    if [ ${?} -ne 0 ]; then
        log "Install of ${FLUENTD_CONF_NAME}/${FLUENTD_DEST} failed, err=${?}"
        exit 1
    fi

    log "Fluentd.conf file changed in S3 bucket, new configuration successfully installed with md5: ${newMd5}"

    service td-agent reload 2>>${ERR_LOG} 1>/dev/null
    if [ ${?} -ne 0 ]; then
        log "td-agent reload failed, see above error message"
        exit 1
    fi
fi


rm -f "${TMPDIR}/${FLUENTD_CONF_NAME}"

exit 0