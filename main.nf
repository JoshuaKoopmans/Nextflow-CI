#!/usr/bin/env nextflow

/*
 * Main nextflow script for the RNAseq pipeline
 */

// Set date as identifier
date = new java.util.Date().format("ddMMyyyyhhmmss")

// Show used parameters
log.info "Trim Galore! - N F - AUTOMATED TESTING ~  version 0.1"
log.info "====================================="
log.info "job id                 : $date"
//log.info "reads                  : ${params.reads}"
log.info "flow                   : ${params.flow}"
log.info "====================================="
log.info "\n"


flow = params.flow


if(flow == "all"){flow = "trim_galore"}

flow = flow.split(',').collect { it.trim() }

/*
 * Create a channel for input read files
 */
if (params.readPaths) {
    if (params.singleEnd) {
        Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [ file(row[1][0], checkIfExists: true) ] ] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
            .into { raw_reads_fastqc; raw_reads_trimgalore }
    } else {
        Channel
            .from(params.readPaths)
            .map { row -> [ row[0], [ file(row[1][0], checkIfExists: true), file(row[1][1], checkIfExists: true) ] ] }
            .ifEmpty { exit 1, "params.readPaths was empty - no input files supplied" }
            .into { raw_reads_fastqc; raw_reads_trimgalore }
    }
} else {
    Channel
        .fromFilePairs( params.reads, size: params.singleEnd ? 1 : 2 )
        .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nNB: Path requires at least one * wildcard!\nIf this is single-end data, please specify --singleEnd on the command line." }
        .into { raw_reads_fastqc; raw_reads_trimgalore }
}

/*
 * Start process trim_galore, used for filtering, trimming, and quality control of the reads
 * Split output, trimmed and filtered reads, into seperate channels for STAR, Salmon, Kallisto and FusionInspector
 * Save report and FastQC output for MultiQC
 * Save all output in directory trimmed_reads using sample_id as unique identifier
 * Parameter --fastqc, using FastQC to create a quality check report
 */


if("trim_galore" in flow){
    process trim_galore {
        label "trimming"

        publishDir = [path: "$PWD/$date/trimmed_reads", mode: 'copy', overwrite: 'true']
        tag "reads: $sample_id"

        input:
        set val(sample_id), file(reads) from raw_reads_trimgalore

        output:
        set val(sample_id), file("${sample_id}*.fq.gz") into trimmed_files, trimmed_files2, trimmed_files3, trimmed_files4
        file("${sample_id}*trimming_report.txt") into report
        file("${sample_id}*fastqc.html") into fastqc_html
        file("${sample_id}*fastqc.zip") into fastqc_zip

        script:
        def single = reads instanceof Path
        if(single)
            """
            trim_galore --fastqc --gzip ${reads}
            """
        else
            """
            trim_galore --paired --fastqc --gzip ${reads[0]} ${reads[1]}
            """
    }
} else {
 trimmed_files = Channel.empty()
 fastqc_zip = ""
}