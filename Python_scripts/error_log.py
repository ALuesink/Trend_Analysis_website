from sqlalchemy import create_engine, select, Table, MetaData, exc
import logging
import warnings
import sys
import config

def send_warnings_to_log(message, category, filename, lineno, file=None):
	logging.warning('%s:%s', category.__name__, message)

Naame= "Karel"
metadata = MetaData()
engine = create_engine("mysql+pymysql://"+config.MySQL_DB["username"]+":"+config.MySQL_DB["password"]+"@"+config.MySQL_DB["host"]+"/"+config.MySQL_DB["database"], echo=False)

conn = engine.connect()

logging.captureWarnings(True)
logging.basicConfig(filename='errorlog.log',format='%(asctime)s\t%(levelname)s\t%(message)s', level=logging.DEBUG, datefmt= '%d-%m-%Y %H:%M:%S')
#logger = logging.getLogger('py.warnings')
#logging.warning(name,"\t", message)

#old_showwarning = warnings.showwarning
warnings.showwarning = send_warnings_to_log

#warnings.warn('message')

Oefen = Table("Oefen", metadata, autoload=True, autoload_with=engine)

insert_Oefen = Oefen.insert().values(Naam=Naame, Lengte=125468658, Adres="Schaap")
#with warnings.catch_warnings():
#	warnings.simplefilter("error")
try:
	print("gewoon")
	conn.execute(insert_Oefen)
except Exception, e:
	print("exception")
#	print(repr(e))
	logger.error(e)
conn.close()


