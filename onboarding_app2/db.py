# db.py
import pymysql
from pymysql.cursors import DictCursor


def connect_db():
    return pymysql.connect(
        host="localhost",
        user="root",
        password="root",
        database="onboarding_training",
        port=3306,
        cursorclass=DictCursor
    )


def fetch_all(sql, params=None):
    conn = connect_db()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            return cursor.fetchall()
    finally:
        conn.close()


def fetch_one(sql, params=None):
    conn = connect_db()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            return cursor.fetchone()
    finally:
        conn.close()


def execute(sql, params=None):
    """
    Для INSERT/UPDATE/DELETE. Возвращает lastrowid.
    """
    conn = connect_db()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or ())
            conn.commit()
            return cursor.lastrowid
    finally:
        conn.close()
