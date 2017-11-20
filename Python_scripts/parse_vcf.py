import vcf
import commands

wkdir = "/hpc/cog_bioinf/diagnostiek/processed/Exomes"

reports_vcf = commands.getoutput("find " + str(wkdir) + "/*/ -maxdepth 1 -iname \"*.filtered_variants.vcf\"").split()
print(len(reports_vcf))

#report1 = commands.getoutput("find " + "/hpc/cog_bioinf/diagnostiek/processed/Exomes/170925_NB501012_0195_AHLMHJBGX3/170925_NB501012_0195_AHLMHJBGX3.filtered_variants.vcf")


#dic_samples = {key:[#variant,#dbSNP,#PASS],..}
dic_samples = {}
for report in reports_vcf:
	vcf_reader = vcf.Reader(open(report, "r"))
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
		if record.num_het != 0:
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

	
print(dic_samples)



