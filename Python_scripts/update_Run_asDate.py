from datetime import datetime
from sqlalchemy import create_engine, select, Table, MetaData, update
import config
epoch = datetime.utcfromtimestamp(0)

metadata = MetaData()

#engine = create_engine("mysql+pymysql://trendngs:-@wgs11.op.umcutrecht.nl/trendngs")
engine = create_engine("mysql+pymysql://"+config.MySQL_DB["username"]+":"+config.MySQL_DB["password"]+"@"+config.MySQL_DB["host"]+"/"+config.MySQL_DB["database"], echo=False)

conn = engine.connect()

Run = Table("Run",metadata,autoload=True,autoload_with=engine)

select_Run = select([Run.c.Run_ID, Run.c.Date])
result_Run = conn.execute(select_Run).fetchall()
Run_Date = {}

for run in result_Run:
	Run_Date[run[0]] = run[1]


Run_asDate = {}

for run, date in Run_Date.iteritems():
	datum = datetime.strptime(date, "%Y-%m-%d")
	asDate = (datum - epoch).days
	Run_asDate[run] = asDate

for run, date in Run_asDate.iteritems():
	update_Run = Run.update().where(Run.c.Run_ID==run).values(asDate=date)
	conn.execute(update_Run)
