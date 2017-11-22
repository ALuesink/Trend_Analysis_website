import commands
import vcf
from sqlalchemy import create_engine, select, Table, MetaData
import config
metadata = MetaData()
#engine = create_engine("mysql+pymysql://trendngs:-@wgs11.op.umcutrecht.nl/trendngs")
engine = create_engine("mysql+pymysql://"+config.MySQL_DB["username"]+":"+config.MySQL_DB["password"]+"@"+config.MySQL_DB["host"]+"/"+config.MySQL_DB["database"], echo=False)
conn = engine.connect()

#wkdir = "/data/DIT-bgarray/Illumina/Exomes/"
wkdir = "/hpc/cog_bioinf/diagnostiek/processed/Exomes/"

runs_path = commands.getoutput("find " + str(wkdir) + " -maxdepth 1 -mindepth 1").split()

filtered_runs_path = sorted(runs_path)

for run in runs_path:
	if "U_U" not in run and "_U" in run or "_M" in run.upper() or "Heranalyse" in run or "Test_100_exomes" in run or "_old2" in run:
		filtered_runs_path.remove(run)
	if "_old" in run:
		for i in runs_path:
			if run[:-4] in i and "_old" not in i:
				filtered_runs_path.remove(i)

#runs = ["170519_NB501012_0140_AHJ7T2BGX2","170524_NB501012_0142_AHJCGVBGX2","161121_NB501012_0076_AHVGGLBGXY","161207_NB501012_0082_AHY2M2BGXY","170316_NB501012_0117_AHK577AFXX","170405_NB501012_0125_AHWCG7BGXY","170203_NB501012_0102_AH7MYJBGX2","170306_NB501039_0101_AHHFVGBGX2","170523_NB501039_0124_AHLLYYAFXX","170426_NB501039_0115_AHK5F5AFXX","170529_NB501039_0126_AHJ5JCBGX2","170524_NB501039_0125_AHL7MNBGX2","161118_NB501039_0066_AHV7KJBGXY","170217_NB501039_0097_AH7VL3BGX2","170104_NB501039_0085_AHG33YBGX2","161128_NB501039_0070_AH2GNGBGX2","170405_NB501039_0109_AHK7KGBGX2","161130_NB501039_0071_AHVW35BGXY","170320_NB501039_0104_AHWCCWBGXY","170418_NB501039_0111_AHLKNGBGX2","170322_NB501039_0105_AHKFCMAFXX","170510_NB501039_0118_AHMJLGBGX2","151028_NB501039_0005_AHJYC2BGXX","161221_NB501039_0080_AHY2YYBGXY","170314_NB501039_0102_AHWCVLBGXY","170118_NB501039_0090_AH7MYWBGX2","170227_NB501039_0098_AHJC5JBGX2","161219_NB501039_0079_AHY327BGXY","170203_NB501039_0094_AH7VF5BGX2","170413_NB501039_0110_AHHV75AFXX","170127_NB501039_0092_AHJ2GYAFXX","170303_NB501039_0100_AHJG75BGX2","170517_NB501039_0121_AHMJ25BGX2","161121_NB501039_0067_AHVF5FBGXY","170206_NB501039_0095_AHCFM3BGX2","170110_NB501039_0087_AHCFGTBGX2","170329_NB501039_0108_AHKGTHAFXX","170116_NB501039_0089_AH7VKGBGX2","161216_NB501039_0078_AHWYTWBGXY","161209_NB501039_0075_AHY2VMBGXY","161205_NB501039_0073_AHY2TTBGXY","170512_NB501039_0119_AHMLTGBGX2","161230_NB501039_0083_AHHTL3AFXX","170113_NB501039_0088_AHF5FJBGX2","170324_NB501039_0106_AHK7K3BGX2","170102_NB501039_0084_AHC7YYBGX2","161123_NB501039_0068_AHY3GNBGXY","161207_NB501039_0074_AHHN7LAFXX","170131_NB501039_0093_AH7VKFBGX2","161214_NB501039_0077_AHWWM3BGXY","161212_NB501039_0076_AHY35NBGXY","170215_NB501039_0096_AH7VJ2BGX2","170424_NB501039_0114_AHTGWFBGX2","161116_NB501039_0065_AHVNJKBGXY","170106_NB501039_0086_AH7MYNBGX2","170316_NB501039_0103_AHHW32BGX2","170515_NB501039_0120_AHL7JHBGX2","170421_NB501039_0113_AHK5FCAFXX","161223_NB501039_0081_AH7VFCBGX2","161202_NB501039_0072_AHHNJ3AFXX","170420_NB501039_0112_AHLGGMBGX2","170327_NB501039_0107_AHJ7K2BGX2","170508_NB501039_0117_AHTGWHBGX2","170505_NB501039_0116_AHKFL2AFXX","170301_NB501039_0099_AHC7Y2BGX2","161228_NB501039_0082_AHWYNLBGXY","170120_NB501039_0091_AH7JK7BGX2"]

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

select_run_processed = select([Run.c.Run]).where(Sample_Processed.c.Run_ID == Run.c.Run_ID)
result_run_processed = conn.execute(select_run_processed).fetchall()
run_processed_db = set()
for run in result_run_processed:
	run_processed_db.add(run[0])

#filtered_runs_path = [1]
data_table = []
for run_path in filtered_runs_path:
#for run in runs:
	try:
		run = run_path.split("/")[6]
#		run = "171020_NB501012_0205_AHTFN2BGX3_old"
		run_core = run
		if "_old" in run:
			run_core = run.strip("_old")
		elif "U_U" in run:
			run_core = run.split("_")
			run_core = run_core[0]+"_"+run_core[1]+"_"+run_core[2]+"_"+run_core[3]
		print(run)
#		print(run_core)
#		print(run + "\t" + run_core)
		if run not in run_processed_db:
			dic_samples = {}
			print(run + "\t" + "start vcf")
			file_vcf = commands.getoutput("find " + str(wkdir) + str(run) + "/ -maxdepth 1 -iname \"*.filtered_variants.vcf\"")
#	print(vcf_file)
			with open(file_vcf, "r") as vcf_file:
				vcf_bestand = vcf.Reader(vcf_file)
				lijst_samples = vcf_bestand.samples
				for sample in lijst_samples:
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

#			print(QCStats_file)
#			print(type(QCStats_file))
#			print(runstats_file)
#			print(type(runstats_file))
				
			stats_run =[]
			if runstats_file:
				with open(runstats_file, "r") as runstats:
					print("start run_stats")
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
				print("runstats klaar")
			if QCStats_file:
				with open(QCStats_file, "r") as QCstats:
					print("start QCstats")
					sample = []
					qc_stats = QCstats.read().split("\n")
					for l in qc_stats:
						regel = l.split("\t")[:-1]
						sample.append(regel)
		
					qc_table = [list(i) for i in map(None,*sample)]
					qc_table[0][0] = "Sample"
					if not data_table:
						data_table_header = qc_table[0][:-1]
						data_table_header = [item.replace(" ","_") for item in data_table_header]
						data_table_header.extend(["Run", "Perc_duplication", "Number_variants", "Perc_dbSNP_variants","Perc_PASS_variants"])
						data_table.append(data_table_header)
			
					for stats in qc_table[1:]:
						stats = stats[:-1]
						stats[0] = stats[0].replace("_dedup","")
						stats[2] = float(stats[2].strip("%"))
						index = [11,12,14,20,21,22,25,26,28,30,31,32,33,34,35,36]
						for i in index:
							stats[i] = float(stats[i])*100
		
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
#					print("Stats: " + stats[0] +"klaar")
					print("QCStats klaar")
#				print(dup)

	except IOError:
		pass

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
#		print(regel[47:50])

	insert_Sample = Sample_Processed.insert().values(Sample_name=regel[0], Total_number_of_reads=regel[1], Percentage_reads_mapped=regel[2], Total_reads=regel[8], PF_reads=regel[9], PF_unique_reads=regel[10], PCT_PF_reads=regel[11], PCT_PF_UQ_reads=regel[12], PCT_UQ_reads_aligned=regel[13], PCT_PF_UQ_reads_aligned=regel[14], PF_UQ_bases_aligned=regel[15], On_bait_bases=regel[16], Near_bait_bases=regel[17], Off_bait_bases=regel[18], On_target_bases=regel[19], PCT_selected_bases=regel[20], PCT_off_bait=regel[21], On_bait_vs_selected=regel[22], Mean_bait_coverage=regel[23], Mean_target_coverage=regel[24], PCT_usable_bases_on_bait=regel[25], PCT_usable_bases_on_target=regel[26], Fold_enrichment=regel[27], Zero_CVG_targets_PCT=regel[28], Fold_80_base_penalty=regel[29], PCT_target_bases_2X=regel[30], PCT_target_bases_10X=regel[31], PCT_target_bases_20X=regel[32], PCT_target_bases_30X=regel[33], PCT_target_bases_40X=regel[34], PCT_target_bases_50X=regel[35], PCT_target_bases_100X=regel[36], HS_library_size=regel[37], HS_penalty_10X=regel[38], HS_penalty_20X=regel[39], HS_penalty_30X=regel[40], HS_penalty_40X=regel[41], HS_penalty_50X=regel[42], HS_penalty_100X=regel[43], AT_dropout=regel[44],GC_dropout=regel[45],Duplication=regel[47],Number_variants=regel[48],PCT_dbSNP_variants=regel[49],PCT_PASS_variants=regel[50],Run_ID=run_id,Bait_ID=bait_id)

	conn.execute(insert_Sample)
conn.close()
