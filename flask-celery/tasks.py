import os
import io
import time
import subprocess
import select
import base64
import json
import smtplib

from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText

from celery import Celery

env=os.environ
CELERY_BROKER_URL=env.get('CELERY_BROKER_URL','redis://localhost:6379'),
CELERY_RESULT_BACKEND=env.get('CELERY_RESULT_BACKEND','redis://localhost:6379')
GMAIL_USER=env.get('GMAIL_USER','your_username@gmail.com')


celery= Celery('tasks',
                broker=CELERY_BROKER_URL,
                backend=CELERY_RESULT_BACKEND)


@celery.task(name='builds.send_status')
def send_status(recipient, subject, body, gmail_password):

    gmail_user = GMAIL_USER

    try:

        fromaddr = gmail_user
        toaddr = recipient
        msg = MIMEMultipart()
        msg['From'] = fromaddr
        msg['To'] = toaddr
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))
        email_text = msg.as_string()

        server = smtplib.SMTP_SSL('smtp.gmail.com')
        server.ehlo()
        server.login(gmail_user, gmail_password)
        server.sendmail(gmail_user, recipient, email_text)
        server.close()
        ret = 'Email sent'

    except smtplib.SMTPHeloError as err:
        ret = err.message

    return ret

@celery.task(name='builds.do_ping')
def do_ping(ping_host):

    process = subprocess.Popen(['ping', "-c", "1", ping_host],
                               stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT)

    output = process.communicate()[0]

    ret = process.wait()

    return ret

@celery.task(name='builds.run_build')
def run_build(request_data):

    result = 0
    output = ""

    try:
        git_update = json.loads(base64.b64decode(request_data))

        git_host = "git@gitolite"
        git_repository = git_update['repository']
        git_commit = git_update['commit']
        git_ref = git_update['ref']
        gmail_password = git_update['passwd']

        process = subprocess.Popen(["bash", "do_build.sh",
                                    git_host, git_repository, git_commit, git_ref],
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT)

        output = process.communicate()[0]

        ret = process.wait()

        get_email_process = subprocess.Popen(["bash",
                                              "get_email.sh", git_repository, git_commit],
                                             stdout=subprocess.PIPE,
                                             stderr=subprocess.STDOUT)

        get_email_output = get_email_process.communicate()[0]
        send_status(get_email_output,
                    'Project Update for ' + git_repository, output, gmail_password)

    except RuntimeError as err:
        output = 'Error parsing {}: {}'.format(request_data, err.message)

    return output
