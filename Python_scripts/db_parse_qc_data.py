#! /usr/bin/env python
import commands
import csv
import config

from html_table_parser import HTMLTableParser
from utils import convert_numbers
from sqlalchemy import create_engine, select, Table, MetaData
from datetime import datetime

epoch = datetime.utcfromtimestamp(0)

keuze = raw_input("Database upload or textfile[db/txt]: ")
print(keuze)
if keuze != "db" and keuze != "txt":
	print("Please enter db or txt for your choice")
	keuze = raw_input("db or txt: ")

sequencers = ["hiseq_umc01", "nextseq_umc01", "nextseq_umc02"]
wkdir = "/hpc/cog_bioinf/diagnostiek/raw_data/"
#wkdir = "/hpc/cog_bioinf/diagnostiek/processed/Trend_analysis/Conversion_reports/"

if keuze == "db":
	### Database connectie, tabellen "maken" en sequencers die al in de database staan ophalen 
	metadata = MetaData()
	engine = create_engine("mysql+pymysql://"+config.MySQL_DB["username"]+":"+config.MySQL_DB["password"]+"@"+config.MySQL_DB["host"]+"/"+config.MySQL_DB["database"], echo=False)

	conn = engine.connect()

	Sequencer = Table("Sequencer",metadata,autoload=True,autoload_with=engine)
	Run = Table("Run",metadata,autoload=True,autoload_with=engine)
	Run_per_Lane = Table("Run_per_Lane",metadata,autoload=True,autoload_with=engine)
	Sample_Sequencer = Table("Sample_Sequencer",metadata,autoload=True,autoload_with=engine)

	select_sequencers = select([Sequencer])
	result_seq = conn.execute(select_sequencers).fetchall()
	seq_in_database = {}
	for seq in result_seq:
		seq_in_database[seq[1]] = seq[0]

	select_run = select([Run.c.Run, Run.c.Run_ID])
	result_run = conn.execute(select_run).fetchall()
	run_in_db = {}
	for run_db in result_run:
		run_in_db[run_db[0]] = run_db[1]

	print("connectie gemaakt")
#########################################################

	for sequencer in sequencers:
		seq_id = 0
		#check of de sequencer al in de database staat
		if sequencer in seq_in_database: #staat in de database, id uit de dictionary
			seq_id = seq_in_database[sequencer] 
		else: #nog niet in de database, toevoegen en primary key ophalen
			insert_Seq = Sequencer.insert().values(Naam=sequencer)
			con_Seq = conn.execute(insert_Seq)
			seq_id = con_Seq.inserted_primary_key
#		print(seq_id)
		runs_path = commands.getoutput("find " + str(wkdir) + str(sequencer) +"/ -maxdepth 1 -mindepth 1").split()
		for run_path in runs_path:
#			run = run_path.split("/")[8]
			run = run_path.split("/")[6]
			if run not in run_in_db and "TEST" not in run and "illumina" not in run and "rsync" not in run and "_2" not in run[-2:]:
				try:
					run_id = 0
					run = run_path.split("/")[6]
					print(run)	
					date = run.split("_")[0]
					date = "20" + date[0:2] + "-" + date[2:4] + "-" + date[4:6]
					
					datum = datetime.strptime(date, "%Y-%m-%d")
					as_Date = (datum-epoch).days
	
					lanehtml = commands.getoutput("find " + str(wkdir) + str(sequencer) + "/" + str(run) + "/Data/Intensities/BaseCalls/Reports/html/*/all/all/all/ -iname \"lane.html\"")
					laneBarcodehtml = commands.getoutput("find " + str(wkdir) + str(sequencer) + "/" + str(run) + "/Data/Intensities/BaseCalls/Reports/html/*/all/all/all/ -iname \"laneBarcode.html\"")

#			with open(lanehtml, "r") as lanes:
					html_lanes = open(lanehtml, "r").read()
        			        l = HTMLTableParser()
                			l.feed(html_lanes)
					lane_tables = l.tables #tables[1]==run tables[2]==lane
				
					run_stats = lane_tables[1][1]
					run_stats = [convert_numbers(item.replace(",","")) for item in run_stats]
					insert_Run = Run.insert().values(Run=str(run), Cluster_Raw=run_stats[0], Cluster_PF=run_stats[1], Yield_Mbases=run_stats[2], Seq_ID=seq_id, Sequencer=sequencer, Date=date, asDate=as_Date)
					con_Run = conn.execute(insert_Run)
					run_id = con_Run.inserted_primary_key
				
					for lane in lane_tables[2][1:]:
						lane = [convert_numbers(item.replace(",","")) for item in lane]
						insert_Lane = Run_per_Lane.insert().values(Lane=str(lane[0]), PF_Clusters=lane[1], PCT_of_lane=lane[2],PCT_perfect_barcode=lane[3], PCT_one_mismatch_barcode=lane[4], Yield_Mbases=lane[5], PCT_PF_Clusters=lane[6], PCT_Q30_bases=lane[7], Mean_Quality_Score=lane[8], Run_ID=run_id)
						conn.execute(insert_Lane)
		
#			with open(laneBarcodehtml, "r") as laneBarcode:
					html_sample = open(laneBarcodehtml, "r").read()
					lB = HTMLTableParser()
					lB.feed(html_sample)
					laneBarcode_tables = lB.tables #tables[1]==run tables[2]==sample_lane		
					for sample_lane in laneBarcode_tables[2][1:]:
						if sample_lane[1].upper() != "DEFAULT":
							sample_lane = [convert_numbers(item.replace(",","")) for item in sample_lane]
							insert_Sample = Sample_Sequencer.insert().values(Lane=str(sample_lane[0]),Project=sample_lane[1].upper(),Sample_name=sample_lane[2],Barcode_sequence=sample_lane[3],PF_Clusters=sample_lane[4],PCT_of_lane=sample_lane[5],PCT_perfect_barcode=sample_lane[6],PCT_one_mismatch_barcode=sample_lane[7],Yield_Mbases=sample_lane[8],PCT_PF_Clusters=sample_lane[9],PCT_Q30_bases=sample_lane[10],Mean_Quality_Score=sample_lane[11],Run_ID=run_id)
							conn.execute(insert_Sample)
				except IOError:
					pass

	conn.close()
	print("connectie gesloten")


if keuze == "txt":
	for sequencer in sequencers:
		run_table = []
		sample_lane_table = []
		
		runs_path = commands.getoutput("find " + str(wkdir) + str(sequencer) +"/ -maxdepth 1 -mindepth 1").split()
                for run_path in runs_path:
                        try:
				
                                run_id = 0
                                run = run_path.split("/")[6]
                                date = run.split("_")[0]
                                date = "20" + date[0:2] + "-" + date[2:4] + "-" + date[4:6]
                
                                lanehtml = commands.getoutput("find " + str(wkdir) + str(sequencer) + "/" + str(run) + "/Data/Intensities/BaseCalls/Reports/html/*/all/all/all/ -iname \"lane.html\"")
                                laneBarcodehtml = commands.getoutput("find " + str(wkdir) + str(sequencer) + "/" + str(run) + "/Data/Intensities/BaseCalls/Reports/html/*/all/all/all/ -iname \"laneBarcode.html\"")
                                html_sample = open(laneBarcodehtml, "r").read()
                                lB = HTMLTableParser()
                                lB.feed(html_sample)
                                laneBarcode_tables = lB.tables #tables[1]==run tables[2]==sample_lane				
				# Sample lane table
		                if not sample_lane_table:  # Set header
                		    #sample_lane_header = tables[2][0]
		                    sample_lane_header = [item.replace(" ", "_") for item in laneBarcode_tables[2][0]]
                		    sample_lane_header.extend(['Run', 'Sequencer',"Date"])
		                    sample_lane_table.append(sample_lane_header)

                		for sample_lane_row in laneBarcode_tables[2][1:]:
		                    sample_lane_row = [convert_numbers(item.replace(',', '')) for item in sample_lane_row]
		                    sample_lane_row[1] = sample_lane_row[1].upper()
                		    sample_lane_row.extend([run, sequencer,date])
		                    sample_lane_table.append(sample_lane_row)
				

#                       with open(lanehtml, "r") as lanes:
                                html_lanes = open(lanehtml, "r").read()
                                l = HTMLTableParser()
                                l.feed(html_lanes)
                                lane_tables = l.tables #tables[1]==run tables[2]==lane
				
		                if not run_table:
                		        run_table_header = [item.replace(" ", "_") for item in lane_tables[2][0]]
		                        run_table_header.extend([item.replace(" ", "_") for item in lane_tables[1][0]])
		                        run_table_header.extend(["Run","Sequencer","Date"])
                		        run_table.append(run_table_header)


		                run_row = [convert_numbers(item.replace(",", "")) for item in lane_tables[1][1]]
                		for lane_row in lane_tables[2][1:]:
		                        lane_row = [convert_numbers(item.replace(",","")) for item in lane_row]
		                        lane_row.extend(run_row)
                		        lane_row.extend([run,sequencer,date])
		                        run_table.append(lane_row)
		
			except IOError:
        	        	pass

	with open('run_table1.txt', 'w') as table_file:
        	writer = csv.writer(table_file, delimiter='\t')
                for row in run_table:
                	writer.writerow(row)

	with open('sample_lane_table1.txt', 'w') as table_file:
        	writer = csv.writer(table_file, delimiter='\t')
                for row in sample_lane_table:
                	writer.writerow(row)

