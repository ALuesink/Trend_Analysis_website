"""Parse processed data to database or .txt file"""
import commands
import csv
import vcf
import numpy as np
import config

from sqlalchemy import create_engine, select, Table, MetaData

keuze = raw_input("Database upload or textfile[db/txt]: ")
if keuze != "db" and keuze != "txt":
	print("Please enter db or txt for your choice")
	keuze = raw_input("db or txt: ")

wkdir = "/hpc/cog_bioinf/diagnostiek/processed/Exomes/"


runs_path = commands.getoutput("find " + str(wkdir) + " -maxdepth 1 -mindepth 1").split()
#runs_path = ["171020_NB501012_0205_AHTFN2BGX3","171020_NB501012_0205_AHTFN2BGX3_old","171020_NB501012_0205_AHTFN2BGX3_old2","171023_NB501012_0206_AHMMVKBGX3","171025_NB501012_0207_AHLNK2BGX3"]
#runs_path = ["170927_NB501012_0196_AHMMVGBGX3", "170823_NB501039_0161_AH535HBGX3"]
#runs_path = ["170927_NB501012_0196_AHMMVGBGX3"]
filtered_runs_path = sorted(runs_path)

for run in runs_path:
	if "U_U" not in run and "_U" in run or "_M" in run.upper() or "Heranalyse" in run or "Test_100_exomes" in run or "_old2" in run:
		filtered_runs_path.remove(run)
	if "_old" in run:
		for i in runs_path:
			if run[:-4] in i and "_old" not in i:
				filtered_runs_path.remove(i)

data_table = []
run = ""
for run_path in filtered_runs_path:
	try:
#		print(run_path)
		run = run_path.split("/")[6]
#		runs_path = "/hpc/cog_bioinf/diagnostiek/processed/Exomes/171006_NB501012_0199_AHLNC5BGX3"
#		run = runs_path.split("/")[6]
#		run = run_path
		print(run)
		dic_samples = {}

		file_vcf = commands.getoutput("find " + str(wkdir) + str(run) + "/ -maxdepth 1 -iname \"*.filtered_variants.vcf\"")
#	print(vcf_file)
		with open(file_vcf, "r") as vcf_file:
			vcf_bestand = vcf.Reader(vcf_file)
			lijst_samples = vcf_bestand.samples
			for sample in lijst_samples:
#				print("sample vcf: "+sample)
				dic_samples[sample] = [0,0,0]
			for variant in vcf_bestand:
				lijst_variants = []
				if "DB" in variant.INFO:
					DB = 1
				else:	
					DB = 0
          			if not variant.FILTER:
       	               			PASS = 1
		        	else:
			       	        PASS = 0
				if variant.num_het != 0:
					het_samples = variant.get_hets()
					lijst_variants = [item.sample for item in het_samples]
				if variant.num_hom_alt != 0:
					hom_samples = [item.sample for item in variant.get_hom_alts()]
					lijst_variants.extend(hom_samples)
#				print(dic_samples)
#				print(lijst_variants)
				for item in lijst_variants:
					lijst = dic_samples[item]
					lijst[0] += 1
					lijst[1] += DB
					lijst[2] += PASS
					dic_samples[item] = lijst
		print("vcf klaar")				

		QCStats_file = commands.getoutput("find " + str(wkdir) + str(run) + "/QCStats/ -iname \"HSMetrics_summary.transposed.txt\"")
		runstats_file = commands.getoutput("find " + str(wkdir) + str(run) + "/ -iname \"run_stats.txt\"")

#		print(QCStats_file)
#		print(runstats_file)
			
		stats_run =[]
		with open(runstats_file, "r") as runstats:
#			print("start run_stats")
			run_stats = runstats.read()
			if "working" in run_stats:
				run_stats = run_stats.split("working")
				for sample_stats in run_stats[1:]:
					stats_sample = sample_stats.split("\n")
#					stats_run.append(stats_sample)
					sample_name = stats_sample[0].split("/")[-1]
					sample_name = sample_name.replace("_dedup.flagstat...", "")
					dup = stats_sample[15]
					perc = dup.split("%")[0].strip("\t").strip()
#					print(dic_samples)
#					print(sample_name)
					lijst = dic_samples[sample_name]
					lijst.append(perc)
					dic_samples[sample_name] = lijst
			else:
				for sample in dic_samples:
					lijst = dic_samples[sample]
					lijst.append(None)
					dic_samples[sample] = lijst

		with open(QCStats_file, "r") as QCstats:
#			print("start QCstats")
			sample = []
			qc_stats = QCstats.read().split("\n")
#			print(qc_stats)
			for l in qc_stats:
				regel = l.split("\t")
				sample.append(regel)
	
			qc_table = [list(i) for i in map(None,*sample)]
			qc_table[0][0] = "Sample"
			if not data_table:
#				print(qc_table[0])
				data_table_header = qc_table[0][:-1]
				data_table_header = [item.replace(" ","_") for item in data_table_header]
				data_table_header.extend(["Run", "Perc_duplication", "Number_variants", "Perc_dbSNP_variants","Perc_PASS_variants"])
				data_table.append(data_table_header)
	
			for stats in qc_table[1:]:
#				print(stats)
				stats = stats[:-1]
				stats[0] = stats[0].replace("_dedup","")
#				print("sample QCstats: "+stats[0])
				stats[2] = float(stats[2].strip("%"))
				index = [11,12,14,20,21,22,25,26,28,30,31,32,33,34,35,36]
#				print("voor: "+stats[12])
				for i in index:
					stats[i] = float(stats[i])*100
#				print("na: "+str(stats[12]))
				stats.extend([run])
					
				if stats[0] in dic_samples.keys():
					lijst = dic_samples.get(stats[0])
					variants = lijst[0]
					dbSNP = round(((float(lijst[1]) / variants) * 100), 5)
					PASS = round(((float(lijst[2]) / variants) * 100), 5)
#					print(lijst)
#					print(lijst[3])
					if lijst[3] is not None:
						dup = round(float(lijst[3]), 6)
					else:
						dup = None
				else:
					variants = None
					dbSNP = None
					PASS = None
					dup = None
				stats.extend([dup, variants, dbSNP, PASS])
				data_table.append(stats)
#				print("Stats: " + stats[0])
#				print(dup)

	except IOError:
		pass

if keuze == "txt":
	with open("oefentest_sample_processed.txt", "w") as table_file:
		writer = csv.writer(table_file, delimiter="\t")
		for row in data_table:
			writer.writerow(row)

if keuze == "db":
	metadata = MetaData()
#	engine = create_engine("mysql+pymysql://trendngs:-@wgs11.op.umcutrecht.nl/trendngs")
	engine = create_engine("mysql+pymysql://"+config.MySQL_DB["username"]+":"+config.MySQL_DB["password"]+"@"+config.MySQL_DB["host"]+"/"+config.MySQL_DB["database"], echo=False)

	conn = engine.connect()

	Run = Table("Run", metadata, autoload=True, autoload_with=engine)
	Sample_Processed = Table("Sample_Processed", metadata, autoload=True, autoload_with=engine)
	Bait_Set = Table("Bait_Set", metadata, autoload=True, autoload_with=engine)

	select_run = select([Run.c.Run_ID, Run.c.Run])
	result_run = conn.execute(select_run).fetchall()
	run_in_db = {}
	for run_db in result_run:
		run_in_db[run_db[1]] = run_db[0]

	select_baitset = select([Bait_Set.c.Bait_ID, Bait_Set.c.Bait_name])
	result_baitset = conn.execute(select_baitset).fetchall()
	baitset_in_db = {}
	for baitset in result_baitset:
		baitset_in_db[baitset[1]] = baitset[0]


	for regel in data_table[1:]:
		run_id = None
		run = regel[46]
#		print(run)
		if "_old" in run:
			run = run.strip("_old")
		elif "U_U" in run:
			run = run.split("_")
	                run = run[0]+"_"+run[1]+"_"+run[2]+"_"+run[3]
		run_id = run_in_db[run]
		
#		print(regel[0])
#		print(regel[15:20])
		bait_id = 0
		if regel[3] in baitset_in_db:
			bait_id = baitset_in_db[regel[3]]
		else:
			insert_BaitSet = Bait_Set.insert().values(Bait_name=regel[3], Genome_Size=regel[4], Bait_territory=regel[5], Target_territory=regel[6], Bait_design_efficiency=regel[7])
			con_BaitSet = conn.execute(insert_BaitSet)
			bait_id = con_BaitSet.inserted_primary_key
			baitset_in_db[regel[3]] = bait_id 			

		test = 123456
		
#		print(regel[47:50])

		insert_Sample = Sample_Processed.insert().values(Sample_name=regel[0], Total_number_of_reads=regel[1], Percentage_reads_mapped=regel[2], Total_reads=regel[8], PF_reads=regel[9], PF_unique_reads=regel[10], PCT_PF_reads=regel[11], PCT_PF_UQ_reads=regel[12], PCT_UQ_reads_aligned=regel[13], PCT_PF_UQ_reads_aligned=regel[14], PF_UQ_bases_aligned=regel[15], On_bait_bases=regel[16], Near_bait_bases=regel[17], Off_bait_bases=regel[18], On_target_bases=regel[19], PCT_selected_bases=regel[20], PCT_off_bait=regel[21], On_bait_vs_selected=regel[22], Mean_bait_coverage=regel[23], Mean_target_coverage=regel[24], PCT_usable_bases_on_bait=regel[25], PCT_usable_bases_on_target=regel[26], Fold_enrichment=regel[27], Zero_CVG_targets_PCT=regel[28], Fold_80_base_penalty=regel[29], PCT_target_bases_2X=regel[30], PCT_target_bases_10X=regel[31], PCT_target_bases_20X=regel[32], PCT_target_bases_30X=regel[33], PCT_target_bases_40X=regel[34], PCT_target_bases_50X=regel[35], PCT_target_bases_100X=regel[36], HS_library_size=regel[37], HS_penalty_10X=regel[38], HS_penalty_20X=regel[39], HS_penalty_30X=regel[40], HS_penalty_40X=regel[41], HS_penalty_50X=regel[42], HS_penalty_100X=regel[43], AT_dropout=regel[44],GC_dropout=regel[45],Duplication=regel[47],Number_variants=regel[48],PCT_dbSNP_variants=regel[49],PCT_PASS_variants=regel[50],Run_ID=run_id,Bait_ID=bait_id)

		conn.execute(insert_Sample)

	conn.close()
