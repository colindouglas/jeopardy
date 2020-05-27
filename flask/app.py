from flask import Flask
from randclue import get_clue

app = Flask(__name__)

page = '''
    <html>
    <head><title>Random Jeopardy</title></head>
    <body><center>
    From {round} on {date}<p>
    <h2>{cat}</h2>
    <b><i>... for ${val}</b></i><p>
    {clue}<p>
    <span style="color: black; background: black; span:hover {{ color: white}}">{resp}</span><p>
    <small><a href="/q/{pl}">permalink</a></body>
    </center>
    </html>
    '''

rounds = {"J": "Jeopardy!",
          "DJ": "Double Jeopardy!",
          "FJ": "Final Jeopardy!"}

def print_clue(clue, string):
    return string.format(cat=clue['category'],
                clue=clue['clue'],
                resp=clue['response'],
                pl=clue['q_number'],
                round=rounds[clue['round']],
                date=clue['date'],
                val=clue['value'])


@app.route('/')
def random_clue():
    clue = get_clue()
    return print_clue(clue, page)


@app.route('/q/')
@app.route('/q/<q>')
def specific_clue(q=None):
    if not (clue := get_clue(q)):
        clue = get_clue()
    return print_clue(clue, page)


if __name__ == '__main__':
    app.run()
