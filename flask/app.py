from flask import Flask, render_template, url_for
from randclue import get_clue

app = Flask(__name__)

@app.route('/')
def random_clue():
    clue = get_clue()
    return render_template("question.html", content=clue)


@app.route('/q')
@app.route('/q/<q>')
def clue_lookup(q=None):
    clue = get_clue(q)
    if not clue:
        clue = get_clue()
    return render_template("question.html", content=clue)

@app.route('/layout')
def show_layout():
    return render_template("question.html", content=get_clue())


if __name__ == '__main__':
    app.run()
