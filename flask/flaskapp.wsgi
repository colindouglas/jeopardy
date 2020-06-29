#flaskapp.wsgi
import sys
python_home = '/var/www/colindougl.as/jeopardy'

sys.path.insert(0, python_home)

activate_this = python_home + '/venv/bin/activate_this.py'
execfile(activate_this, dict(__file__=activate_this))

from app import app as application

