#! /usr/bin/env python
import commands
import csv

from html_table_parser import HTMLTableParser
from utils import convert_numbers

sequencers = ["hiseq_umc01", "nextseq_umc01", "nextseq_umc02"]
wkdir = "/hpc/cog_bioinf/diagnostiek/raw_data"

run_table = []
sample_lane_table = []

for sequencer in sequencers:
	report_sample = commands.getoutput("find " + str(wkdir) + "/" + str(sequencer) + "/*/Data/Intensities/BaseCalls/Reports/html/*/all/all/all/ -iname \"laneBarcode.html\"").split()
	for report in report_sample:
		run = report.split("/")[6]
		html = open(report, "r").read()
		p = HTMLTableParser()
		p.feed(html)
		tables = p.tables #tables[1]==run tables[2]==sample_lane
		
	        # Sample lane table
	        if not sample_lane_table:  # Set header
	            #sample_lane_header = tables[2][0]
	            sample_lane_header = [item.replace(" ", "_") for item in  tables[2][0]]
        	    sample_lane_header.extend(['Run', 'Sequencer'])
	            sample_lane_table.append(sample_lane_header)

	        for sample_lane_row in tables[2][1:]:
	            sample_lane_row = [convert_numbers(item.replace(',', '')) for item in sample_lane_row]
        	    sample_lane_row[1] = sample_lane_row[1].upper()
	            sample_lane_row.extend([run, sequencer])
        	    sample_lane_table.append(sample_lane_row)

	
        report_run = commands.getoutput("find " + str(wkdir) + "/" + str(sequencer) + "/*/Data/Intensities/BaseCalls/Reports/html/*/all/all/all/ -iname \"lane.html\"").split()
	for report in report_run:
		run = report.split("/")[6]
		html = open(report,"r").read()
		p = HTMLTableParser()
		p.feed(html)
		tables = p.tables #tables[1]==run tables[2]==lane

		if not run_table:
			run_table_header = [item.replace(" ", "_") for item in tables[2][0]]
			run_table_header.extend([item.replace(" ", "_") for item in tables[1][0]])
			run_table_header.extend(["Run","Sequencer"])
			run_table.append(run_table_header)

		
		run_row = [convert_numbers(item.replace(",", "")) for item in tables[1][1]]
		for lane_row in tables[2][1:]:
			lane_row = [convert_numbers(item.replace(",","")) for item in lane_row]
			lane_row.extend(run_row)
			lane_row.extend([run,sequencer])
			run_table.append(lane_row)

		
	

with open('run_table1.txt', 'w') as table_file:
    writer = csv.writer(table_file, delimiter='\t')
    for row in run_table:
        writer.writerow(row)

with open('sample_lane_table1.txt', 'w') as table_file:
    writer = csv.writer(table_file, delimiter='\t')
    for row in sample_lane_table:
        writer.writerow(row)

