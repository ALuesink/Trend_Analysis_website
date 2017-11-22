"""Parse processed data"""

import commands
import csv
import vcf

wkdir = "/hpc/cog_bioinf/diagnostiek/processed/"

#report1 = "170925_NB501012_0195_AHLMHJBGX3"
#report2 = "170918_NB501039_0171_AHKM7MBGX3"
#report3 = "170915_NB501039_0170_AHMJWFBGX3"

#lijst_run = [report1]

#methodes = ["Exomes", "Genepanels"]
methode = "Exomes" 

dic_samples = {}
#for run_test in lijst_run:
reports_vcf = commands.getoutput("find " + str(wkdir) + str(methode) + "/*/ -maxdepth 1 -iname \"*.filtered_variants.vcf\"").split()
#print(reports_vcf)
print("vcf begin")
for report in reports_vcf:
	print(report)
	with open(report, "r") as bestand:
		vcf_reader = vcf.Reader(bestand)
#        vcf_reader = vcf.Reader(open(report, "r"))
	        lijst_samples = vcf_reader.samples
      		for sample in lijst_samples:
              		dic_samples[sample] = [0,0,0]
	        for record in vcf_reader:
      		        if "DB" in record.INFO:
              		        DB = 1
                	else:
      	                	DB = 0
                	if not record.FILTER:
      	                	PASS = 1
        	        else:
      	        	        PASS = 0
	                if record.num_het != 0 :
      		                het_samples = record.get_hets()
              		        het_samples = [item.sample for item in het_samples]
                      		for item in het_samples:
                              		lijst = dic_samples.get(item)
                                	lijst[0] += 1
        	                        lijst[1] += DB
      	        	                lijst[2] += PASS
              	        	        dic_samples[item] = lijst
                	if record.num_hom_alt != 0:
      	                	hom_samples = [item.sample for item in record.get_hom_alts()]
                	        for item in hom_samples:
      	                	        lijst = dic_samples.get(item)
              	                	lijst[0] += 1
                	                lijst[1] += DB
      	                	        lijst[2] += PASS
              	                	dic_samples[item] = lijst


#print(dic_samples)
data_table = []
print("eind vcf, begin andere stats")

#for run_test in lijst_run:
reports_QCStats = commands.getoutput("find " + str(wkdir) + str(methode) + "/*/QCStats/ -iname \"HSMetrics_summary.transposed.txt\"").split()
reports_runstats = commands.getoutput("find " + str(wkdir) + str(methode) + "/"+ str(report1) +"/ -iname \"run_stats.txt\"").split()

stats = []
for report in reports_runstats:
	with open(report, "r") as bestand:
#	line = open(report, "r").read().split("working")
		line = bestand.read().split("working")
		for l in line[1:]:
       			regel = l.split("\n")
	        	stats.append(regel)
print(stats)

dic_runstats = {} #dictionary voor duplicatie percentage
for sample in stats:
	run_sample = sample[0]
	sample_name = run_sample.split("/")[-1]
	sample_name = sample_name.replace("_dedup.flagstat...", "")
	dup = sample[15]
       	perc = dup.split("%")[0].strip("\t")
       	perc = perc.strip()        
       	dic_runstats[sample_name] = perc


for report in reports_QCStats:
	sample = []
	run = report.split("/")[6]
#	date = run.split("_")[0]              datum toevoegen, moet nog gedaan worden
	
	with open(report, "r") as bestand:
		line = bestand.read().split("\n")
		for l in line:
			regel = l.split("\t")[:-1]		
			sample.append(regel)
		sam = [list(i) for i in map(None,*sample)]	#lijst van QCStats
		sam[0][0] = "Sample"	

		if not data_table:
#			data_table_header = [item.replace(" ","_") for item in sam[0]]
			data_table_header = sam[0][:-1]
			data_table_header = [item.replace(" ", "_") for item in data_table_header]
			data_table_header.extend(["Run", "Duplication","Methode", "Number_variants", "Perc_dbSNP_variants","Perc_PASS_variants"])
			data_table.append(data_table_header)

		for row in sam[1:]:
			row = row[:-1]
			row[0] = row[0].replace("_dedup", "")
			row.extend([run])
			if row[0] in dic_runstats.keys():
				duplication = dic_runstats[row[0]]
			else:
				duplication = "NA"

			if row[0] in dic_samples.keys():
#					print(row[0])
				vcf_sample = dic_samples.get(row[0])
				variants = vcf_sample[0]
				perc_dbSNP = float(vcf_sample[1]) / variants
				perc_PASS = float(vcf_sample[2]) / variants
			else:
				variants = "NA"
				perc_dbSNP = "NA"
				perc_PASS = "NA"
			row.extend([duplication,methode,variants,perc_dbSNP,perc_PASS])
			data_table.append(row)

	

with open("processed_sample1.txt", "w") as table_file:
	writer = csv.writer(table_file, delimiter="\t")
	for row in data_table:
		writer.writerow(row)
		
print("done")
#print(data_table)
