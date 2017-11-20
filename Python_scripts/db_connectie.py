
from sqlalchemy import create_engine, select, Table, MetaData


metadata = MetaData()
engine = create_engine("mysql+pymysql://trendngs:-@wgs11.op.umcutrecht.nl/trendngs")
conn = engine.connect()

#sample_lanes1  = Table("sample_lanes1", metadata, autoload=True, autoload_with=engine)
#stmt = select([census]).limit(5)
#print(connection.execute(stmt).fetchall())

#run_lane = Table("run_lane",metadata, autoload=True, autoload_with=engine)
#ins = run_lane.insert().values(Lane=1, PF_Clusters_Lane=123,PCT_of_the_lane=12.2, Clusters_PF_Run=456,Yield_Run_Mbases=789, Run="slfjdlskfjsl", Sequencer="dsafjlsdfjl")
#result = connection.execute(ins)
#print(result.inserted_primary_key)

Sequencer = Table("Sequencer", metadata, autoload=True, autoload_with=engine)
Run = Table("Run", metadata, autoload=True, autoload_with=engine)

sequencers = ["test_Seq1", "seq2"]

for seq in sequencers:
	insert_Seq = Sequencer.insert().values(Naam=seq)
	con_Seq = conn.execute(insert_Seq)

	run = ["1","2","3"]
	for r in run:
		insert_Run = Run.insert().values(Run="test_Run"+r , Cluster_Raw=int(r), Cluster_PF=int(r)+10, Yield_Mbases=int(r)+20, SeqID=con_Seq.inserted_primary_key, Date="2017-10-18")
		conn.execute(insert_Run)


conn.close()
