import sqlite3


def get_clue(q=None):

    db_file = 'clues.db'  # Path to SQLite DB

    # Open connection to db
    conn = None
    try:
        conn = sqlite3.connect(db_file)
    except sqlite3.Error as e:
        print('SQL connection failed')
        print(e)
        return None

    conn.row_factory = sqlite3.Row  # Apparently this is magic
    cursor = None
    if q:
        # Select a specific clue
        cursor = conn.execute("SELECT * FROM clues WHERE q_number=?;", (q,))
        clue = cursor.fetchall()
    else:
        # Select a random clue
        cursor = conn.execute('SELECT * FROM clues ORDER BY RANDOM() LIMIT 1;')
        clue = cursor.fetchall()

    conn.close()

    if clue:
        return dict(clue[0])  # Convert the first row to a dictionary
    else:
        return None

