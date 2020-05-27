from flask import Flask
from random_question import get_clue

app = Flask(__name__)


@app.route('/')
def hello_world():
    clue = get_clue()
    return '''
    <html>
    <head><title>Random Jeopardy</title></head>
    <body><center><h2>{cat}</h2>
    {clue}<p>
    <span style="color: black; background: black; span:hover {{ color: white}}">{resp}</span>
    <center></body>
    </html>
    '''.format(cat=clue['category'],
               clue=clue['clue'],
               resp=clue['response'])


if __name__ == '__main__':
    app.run()
