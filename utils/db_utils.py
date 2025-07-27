import mysql.connector
from mysql.connector import Error
import logging


logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def get_db_connection():
    try:
        connection = mysql.connector.connect(
            host='localhost',
            database='GarageManagement',
            user='root',
            password='1234'
        )
        logger.debug("Database connection successful")
        return connection
    except Error as e:
        logger.error(f"Error connecting to MySQL: {e}")
        return None

def execute_query(query, params=None):
    connection = get_db_connection()
    if connection:
        try:
            cursor = connection.cursor()
            cursor.execute(query, params or ())
            connection.commit()
            logger.debug(f"Query executed successfully: {query}")
            return cursor
        except Error as e:
            logger.error(f"Error executing query: {e}")
        finally:
            cursor.close()
            connection.close()
    else:
        logger.error("Failed to get database connection")
    return None

def fetch_query(query, params=None):
    connection = get_db_connection()
    if connection:
        try:
            cursor = connection.cursor(dictionary=True)
            cursor.execute(query, params or ())
            result = cursor.fetchall()
            logger.debug(f"Query fetched successfully: {query}")
            return result
        except Error as e:
            logger.error(f"Error fetching query: {e}")
        finally:
            cursor.close()
            connection.close()
    else:
        logger.error("Failed to get database connection")
    return []