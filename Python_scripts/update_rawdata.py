from html_table_parser import HTMLTableParser
from utils import convert_numbers
from sqlalchemy import create_engine, select, Table, MetaData
from datetime import datetime
import commands
import config
import re

wkdir = "/hpc/cog_bioinf/diagnostiek/raw_data/"

metadata = MetaData()
engine = create_engine("mysql+pymysql://"+config.MySQL_DB["username"]+":"+config.MySQL_DB["password"]+"@"+config.MySQL_DB["host"]+"/"+config.MySQL_DB["database"], echo=False)

Sequencer = Table("Sequencer",metadata,autoload=True,autoload_with=engine)
Run = Table("Run",metadata,autoload=True,autoload_with=engine)
Run_per_Lane = Table("Run_per_Lane",metadata,autoload=True,autoload_with=engine)
Sample_Sequencer = Table("Sample_Sequencer",metadata,autoload=True,autoload_with=engine)

def main():
    print("start")
    runs_db = getRuns_db()
    seq_runs = getRuns_hpcs(runs_db)
    dic_runstats, runs = laneHTML(seq_runs)
    dic_samplestats = laneBarcodeHTML(seq_runs)
    seq_db = getSequencers_db()
    print("start insert")
    insertDB(runs, dic_runstats, dic_samplestats, seq_db)
    

def getRuns_db():
    conn = engine.connect()
    select_run = select([Run.c.Run, Run.c.Run_ID])
    result_run = conn.execute(select_run).fetchall()
    run_in_db = {}
    for run in result_run:
        run_in_db[run[0]] = run[1]
    
    conn.close()
    return run_in_db
    
def getSequencers_db():
    conn = engine.connect()
    select_seq = select([Sequencer.c.Name, Sequencer.c.Seq_ID])
    result_seq = conn.execute(select_seq).fetchall()
    seq_in_db = {}
    for seq in result_seq:
        seq_in_db[seq[0]] = seq[1]
    
    conn.close()    
    return seq_in_db

def getRuns_hpcs(run_db): 
    sequencers = ["hiseq_umc01","nextseq_umc01","nextseq_umc02"]
    sequencer_runs = {}
    runs_list = []    
    for sequencer in sequencers:    
        runs_path = commands.getoutput("find " + str(wkdir) + str(sequencer) +"/ -maxdepth 1 -mindepth 1").split()
        runs = []
        for run_path in runs_path:
            run = run_path.split("/")[6]
            if re.match(r'[0-9]{6}_[A-Z0-9]{6,8}_[0-9]{4}_[A-Z0-9]{10}\b', run) and run not in run_db:
		print(run)
                runs.append(run)
        sequencer_runs[sequencer] = runs
    
    return sequencer_runs
    
def laneHTML(seq_runs):
    epoch = datetime.utcfromtimestamp(0)    
    dic_runstats = {}
    good_runs = []
    for seq, runs in seq_runs.iteritems():
        for run in runs:
	    try:
	        date = run.split("_")[0]
                date = "20" + date[0:2] + "-" + date[2:4] + "-" + date[4:6]
	        d = datetime.strptime(date, "%Y-%m-%d")
                as_date = (d-epoch).days
            
	        lanehtml = commands.getoutput("find " + str(wkdir) + str(seq) + "/" + str(run) + "//Data/Intensities/BaseCalls/Reports/html/*/all/all/all/ -iname \"lane.html\"")
            
                with open(lanehtml, "r") as lane:
                    html = lane.read()
               	    tableParser = HTMLTableParser()
                    tableParser.feed(html)
                    tables = tableParser.tables                         #tables[1]==run tables[2]==lane
                
                    stats_run = tables[1][1]
                    stats_run = [convert_numbers(item.replace(",", "")) for item in stats_run]
                    PCT_PF = (float(stats_run[1])/stats_run[0])*100
                    PCT_PF = float("{0:.2f}".format(PCT_PF))
                    stats_run.extend([date,as_date,seq,PCT_PF])                
                
                    stats_lane = []
                    for lane in tables[2][1:]:
                        lane = [convert_numbers(item.replace(",", "")) for item in lane]
                        stats_lane.append(lane)
                
                    dic_runstats[run] = [stats_run,stats_lane]
		    good_runs.append(run)
	    except IOError:
		print(run + " doesn't have a lane.html file")
		pass
                
    return dic_runstats, good_runs
    #stats_run = [Cluster_Raw, Cluster_PF, Yield_Mbases, Date, asDate, Sequencer, PCT_PF_Clusters]
    #stats_lane = [Lane, PF_Clusters, PCT_of_lane, PCT_perfect_barcode, PCT_one_mismatch_barcode, Yield_Mbases, PCT_PF_Clusters, PCT_Q30_bases, Mean_Quality_Score]
        
def laneBarcodeHTML(seq_runs):
    dic_samplestats = {}
    
    for seq, runs in seq_runs.iteritems():
        for run in runs:
	    try:
                samplehtml = commands.getoutput("find " + str(wkdir) + str(seq) + "/" + str(run) + "/Data/Intensities/BaseCalls/Reports/html/*/all/all/all/ -iname \"laneBarcode.html\"")
            
                with open(samplehtml, "r") as sample:
                    html = sample.read()
                    tableParser = HTMLTableParser()
                    tableParser.feed(html)
                    tables = tableParser.tables                         #tables[1]==run tables[2]==sample
		    sample_stats = []
                    for sample_lane in tables[2][1:]:
                        if sample_lane[1].upper() != "DEFAULT":
                            stats_sample_lane = [convert_numbers(item.replace(",","")) for item in sample_lane]
                            sample_stats.append(stats_sample_lane)
		    dic_samplestats[run] = sample_stats
	    except IOError:
		print(run + " doesn't have a laneBarcode.html file")    
		pass

    return dic_samplestats
    #stats_sample_lane = [Lane, Project, Sample, Barcode_sequence, PF_Clusters, PCT_of_the_lane, PCT_perfect_barcode, PCT_one_mismatch_barcode, Yield_Mbases, PCT_PF_Clusters, PCT_Q30_bases, Mean_Quality_Score]
    
def insertDB(runs, dic_runstats, dic_samplestats, seq_db):
    conn = engine.connect()
    for run in runs:
#	print(dic_runstats.get(run))
	print("insert "+ run)
	stats = dic_runstats.get(run)
        runstats = stats[0]
        lanestats = stats[1]
        samplestats = dic_samplestats.get(run)
        
        seq = runstats[5]
        seq_ID = seq_db.get(seq)
#        run_ID = 1 
#	print(runstats[3])        
        insert_Run = Run.insert().values(Run=str(run), Cluster_Raw=runstats[0], Cluster_PF=runstats[1], Yield_Mbases=runstats[2], Seq_ID=seq_ID, Date=runstats[3], asDate=runstats[4],Sequencer=runstats[5],PCT_PF_Cluster=runstats[6])
        con_Run = conn.execute(insert_Run)
        run_ID = con_Run.inserted_primary_key
#	print("run_ID " + str(run_ID))
        
#	print(lanestats)
	for lane in lanestats:
            insert_Lane = Run_per_Lane.insert().values(Lane=str(lane[0]), PF_Clusters=lane[1], PCT_of_lane=lane[2], PCT_perfect_barcode=lane[3], PCT_one_mismatch_barcode=lane[4], Yield_Mbases=lane[5], PCT_PF_Clusters=lane[6], PCT_Q30_bases=lane[7], Mean_Quality_Score=lane[8], Run_ID=run_ID)
            conn.execute(insert_Lane)
#        print(samplestats)
        for sample in samplestats:
#	    print(sample)
            insert_Sample = Sample_Sequencer.insert().values(Lane=str(sample[0]),Project=sample[1].upper(),Sample_name=sample[2],Barcode_sequence=sample[3],PF_Clusters=sample[4],PCT_of_lane=sample[5],PCT_perfect_barcode=sample[6],PCT_one_mismatch_barcode=sample[7],Yield_Mbases=sample[8],PCT_PF_Clusters=sample[9],PCT_Q30_bases=sample[10],Mean_Quality_Score=sample[11],Run_ID=run_ID)
            conn.execute(insert_Sample)
        
        
    conn.close()



main()
