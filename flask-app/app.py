import os
from flask import Flask, url_for, request
from worker import celery
from celery.result import AsyncResult
import celery.states as states

env = os.environ
app = Flask(__name__)

@app.route('/ping/<string:ping_host>')
def do_ping(ping_host):
    task = celery.send_task('builds.do_ping', args=[ping_host], kwargs={})
    return "{url}".format(url=url_for('check_task', id=task.id, _external=True))

@app.route('/run_build', methods=['POST'])
def run_build():
    update = request.form['update']
    task = celery.send_task('builds.run_build', args=[update], kwargs={})
    return "{url}".format(url=url_for('check_task', id=task.id, _external=True))

@app.route('/send_status', methods=['POST'])
def send_status():
    recipient = request.form['recipient']
    subject = request.form['subject']
    body = request.form['body']
    passwd = request.form['passwd']
    task = celery.send_task('builds.send_status',
                            args=[recipient, subject, body, passwd], kwargs={})
    return "{url}".format(url=url_for('check_task', id=task.id, _external=True))

@app.route('/check/<string:id>')
def check_task(id):
    res = celery.AsyncResult(id)
    if res.state == states.PENDING:
        return res.state
    else:
        return str(res.result)

if __name__ == '__main__':
    app.run(debug=env.get('DEBUG',True),
            port=int(env.get('PORT',5000)),
            host=env.get('HOST','0.0.0.0')
    )
