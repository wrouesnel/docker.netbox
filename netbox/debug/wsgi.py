# This wsgi.py is only added when PYTHON_REMOTE_DEBUGGING is set to "yes"
# The major change is it overrides application to install the debugger hooks.

import sys
sys.path.append('/debug/pycharm-debug-py3k.egg')  # replace by pycharm-debug.egg for Python 2.7
import pydevd

import os

from django.core.wsgi import get_wsgi_application


os.environ.setdefault("DJANGO_SETTINGS_MODULE", "netbox.settings")

_application = get_wsgi_application()

def application(env, start_response):
    if os.environ.get('DEV_NETBOX_REMOTE_DEBUG_ENABLE','no') == 'yes':
        # Start the remote debugger
        pydevd.settrace(os.environ['DEV_NETBOX_REMOTE_DEBUG_HOST'], 
                        port=int(os.environ['DEV_NETBOX_REMOTE_DEBUG_PORT']), 
                        stdoutToServer=True, stderrToServer=True, suspend=False)
    return _application(env, start_response)
