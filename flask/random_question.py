import sqlite3


def get_clue():
    db_file = 'data/clues.db'  # Path to SQLite DB

    # Open connection to db
    conn = None
    try:
        conn = sqlite3.connect(db_file)
    except sqlite3.Error as e:
        print('SQL connection failed')
        print(e)
        return None

    conn.row_factory = sqlite3.Row  # Apparently this is magic

    # Select a random clue, convert it to a dictionary
    cursor = conn.execute('SELECT * FROM clues ORDER BY RANDOM() LIMIT 1;')
    clue = dict(cursor.fetchall()[0])

    # Explicitly close the connection
    conn.close()
    return clue
